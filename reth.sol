// RVS we should remove the license
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
* @title rETH contract
* @author Refi
* @notice ...
* @dev TODO: we should structure the contracts folder better. 
* (e.g. rather than using "Ioracle.sol" can we move all interface contracts to "Interfaces"?) (done)
 */

import "./tokenHelpers/RERC20.sol";
import "./tokenHelpers/IERC20.sol";
import "./utils/Ownable.sol";
import "./ErrorReporter8.sol";
import "./utils/Pausable.sol";
import "./utils/ReentrancyGuard.sol";
import "./Interfaces/Ievaluator.sol";
import "./Interfaces/Ioracle.sol";
import "./Interfaces/IrefiSwap.sol";


/// RVS - I think this is the Harvest Vault but the naming doesn't make it easy to understand. 
/// We should discuss some possible naming conventions. For example "interfaceYieldVault"
interface interfaceYieldVault is IERC20 {
    function underlyingBalanceInVault() external view returns (uint256);

    function underlyingBalanceWithInvestment() external view returns (uint256);

    function governance() external view returns (address);

    function controller() external view returns (address);

    function deposit(uint256 amountWei) external;

    function depositFor(uint256 amountWei, address holder) external;

    function withdrawAll() external;

    function withdraw(uint256 numberOfShares) external;
}


/// RVS - interfaceYieldPool?
interface interfaceYieldPool {
    //view staked fUsdc
    function balanceOf(address) external view returns (uint256);

    // stake funds
    function stake(uint256 amount) external;

    //Unstake funds
    function withdraw(uint256 amount) external;

    //Rewards
    function getReward() external;
}

interface error {
    /**
     * @dev Possible error codes that we can return
     */
    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }
}

/// RVS - not sure what this is interfacing to...? - Interfacing to cDAI token
interface CErc20 is error {

    function borrowIndex() external view returns (uint256);

    function accrueInterest() external returns (uint256);

    function borrow(uint256) external returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function repayBorrow(uint256) external returns (uint256);

    function borrowBalanceCurrent(address user) external returns (uint256);

    function balanceOfUnderlying(address user) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (MathError, uint256);
}



/// RVS - not sure what this is interfacing to  -- interfacing to cEth
interface CEth is error, IERC20 {
    function mint() external payable;

    //function balanceOf(address owner) external view returns (uint256);

    function borrow(uint256) external returns (uint256);

    function repayBorrow() external payable;

    function borrowBalanceCurrent(address) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function balanceOfUnderlying(address user) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);
}

/// RVS - need to rename this contract (I think to "rETH"?)
contract rETH is
    ERC20,
    Ownable,
    error,
    TokenErrorReporter,
    Pausable,
    ReentrancyGuard
{
    /// RVS - briefly discussed in past but not sure this naming convention is working well for us right now
    
    //mapping(address=>uint) userDeposits;
    /// @notice Instance of Compound's ceth
    CEth Exceth;
    /// @notice Instance of Compound's Excdai
    CErc20 Excdai;
    /// @notice Instance of DAI token
    IERC20Metadata constant dai =
        IERC20Metadata(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    /// @notice Instance of Compound's Oracle
    IOracle Exoracle;
    /// @notice Instance of Compound's Comptroller
    ComptrollerInterface ExCompTroller;
    /// @notice Instance of Harvest.finance's Expool
    interfaceYieldPool Expool;
    /// @notice The number of harvest don till now
    /// @dev RVS does index need to be uint256...? (note: irrelevant if we don't store it next to another smaller number though...?)
    /// @dev rename to "harvestIndex"?
    uint256 public index;

    /// @notice address of Compound's Comp Tokens
    address constant comp = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    /// @notice Instance of Harvest.finance's FARM token
    IERC20 constant farm = IERC20(0xa0246c9032bC3A600820415aE600c6388619A14D);
    /// @notice Instance of Harvest.finance's DAI Vault
    interfaceYieldVault Exvault;
    /// @notice Minimum amount of DAI required to Deposit on Harvest.Finance
    //uint256 public min_depo = 1000000;

    /**
     * @notice Container for Harvest Information
     * @member priceEth Conversion factor from Eth to Dai 
     * @dev: RVS call this priceEthDai? 
     * @member lendingAmt amount of profit obtained from lender protocol
     * @member yieldAmt amount of profit earned from Yield protocol
     * @membersupplyEth Total Eth supplied to the lender
     * @member blockNo block number at the time of harvest
     * @member tLTV target LTV of Vault at the time of Harvest
     * @member reserveAmount reserve Factor of the Vault at the time of harvest
     * @member exchangeRate the factor which multiplies with cEth to give Eth amount (scaled to 10^18)
     * @member totalBorrowsEth total borrow Amount taken by the users
     */
    struct harvestSnapshot {
        uint256 priceEthDai;
        uint256 lendingAmt;
        uint256 yieldAmt;
        uint256 supplyEth;
        uint256 blockNo;
        uint256 tLTV;
        uint256 reserveAmount;
        uint256 exchangeRate;
        uint256 totalBorrowsEth;
    }

    //mapping(address => uint256) public userBorrow;
    //uint256 public totalUserBorrows;

    /// RVS - comments not matching struct
    /**
     * @notice Container for user earnings in a harvest information
     * @member uptillHarvest till which harvest the data has been calculated
     * @member rewards User's share of the earnings from all Harvests (lender + Yield)
     * @member lastRewards User's share of the earning from last harvest
     * @member repaid Total Auto repayments till now
     */
    struct data {
        uint256 uptillHarvest;
        uint256 rewards;
        uint256 lastRewards;
        uint256 repaid;
    }
    /// @notice Earnings of user in all the harvests
    mapping(address => data) public userData;

    /// @notice Array string Data of Each Harvest
    harvestSnapshot[] public harvestData;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint256 principal;
        uint256 interestIndex;
    }

    /**
     * @notice Mapping of user addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) public accountBorrows;

    /**
     * @notice Total outstanding borrow balances of users
     */
    BorrowSnapshot public totalUserBorrows;
    struct Store {
        uint256 tLTV;
        uint256 maxLTV;
        uint256 minLTV;
        uint256 min_depo;
        uint256 reserveFactor;
    }
    //Set maximum, minimum and target LTV for the Vault
    Store public store;

    IrSwap rswap;

    address constant weth = 0x0537F3f7fF3c15A63B0CF7EC155E54FF91C0754D;

    /// @notice Stored LTV of Vault
    uint256 public vaultLTVStored;

    //events

    event ConfigUpdated(
        uint256 tLTV,
        uint256 maxLTV,
        uint256 minLTV,
        uint256 minimum_deposit_Harvest,
        uint reserveFactor
    );
    event refitrollerChanged(address newcontroller);

    event raccrued(uint256 principal, uint256 interestIndex);

    event deposited(address user, uint256 amount, uint256 rAmount);

    event withdrawn(address user, uint256 amount, uint256 rAmount);

    event claimedVault(uint256 time, uint256 comp, uint256 farm);

    event harvested(
        uint256 harvestNo,
        uint256 priceEthusdc,
        uint256 lenderDAI,
        uint256 yieldDAI,
        uint256 supplyEth,
        uint256 tltv,
        uint256 reserveEarned,
        uint256 exchangeRate,
        uint256 totalBorrowsEthUsers
    );

    event borrowed(address user, uint amount);

    uint256 public lastHarvest;

    uint256 public invested;
    //Note: edit remaining
    Ieval public eval;

    address public stabilityUserContract;

    constructor(address refiController,address _rswap)
        ERC20("MTFi", "MTFI", refiController)
    {
        initialize(refiController,_rswap);
    }

    /// @notice This sets the initial values in the contract
    /// @dev RVS: initial setup feels messy right now. 
    /// @dev RVS: Can we initialise all values in the same place?
    /// @dev RVS: It doesn't feel right to hardcode these contract addresses
    function initialize(address refiController,address _rswap) internal {
        
        RefiTroller = ComptrollerInterface(
            refiController
        );
        Exceth = CEth(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);
        Exoracle = IOracle(0x6D2299C48a8dD07a872FDd0F8233924872Ad1071);
        ExCompTroller = ComptrollerInterface(
            0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B
        );
        Exvault = interfaceYieldVault(0xab7FA2B2985BCcfC13c6D86b1D5A17486ab1e04C); /// Harvest Vault
        Expool = interfaceYieldPool(0x15d3A64B2d5ab9E152F16593Cdebc4bB165B5B4A); ///  Harvest Pool
        Excdai = CErc20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643); /// Compound's DAI Token
        
        // Enter into Eth and Dai market on Compound
        address[] memory any = new address[](2);
        any[0] = address(Exceth);
        any[1] = address(Excdai);
        ExCompTroller.enterMarkets(any);


        harvestData.push();
        index = 0;
        store = Store({
            tLTV : 5 * 10**17, // 0.5
            maxLTV : 7 * 10**17, // 0.7
            minLTV : 3 * 10**17, //0.3
            min_depo : 10 * 10**18,// 10 DAI
            reserveFactor : 10**16 //1%
        });
        rswap = IrSwap(_rswap); /// UniSwap Swap Router
    }

    receive() external payable {
    }
    /**
     * @notice DAO Triggerable pause on 'repay/withdraw only'
     */
    function pause() external onlyOwner {
        _pause();
    }
    /**
     * @notice DAO Triggerable unpause on 'repay/withdraw only'
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    /**
     * @notice DAO Triggerable pause on all functions
     */
    function pauseAll() public onlyOwner {
        _pauseAll();
        _pause();
    }
    /**
     * @notice DAO Triggerable unpause on all functions
     */
    function unpauseAll() external onlyOwner {
        _unpauseAll();
        _unpause();
    }

    /**
     * @notice changes current refitroller
     * @param newCompt the address of new implementation
     */
    function changeAddresses(address newCompt, address newrs, address _eval) external onlyOwner {
        RefiTroller = ComptrollerInterface(newCompt);
        stabilityUserContract = newrs;
        eval = Ieval(_eval);
        emit refitrollerChanged(newCompt);
    }

    /**
     * @notice Sets the values of LTVs
     * @param tLTV target LTV of Vault, This is the LTV we want the Vault to hold at maximum times
     * @param maxLTV Maximum value of LTV, If vaultLTV exceeds this value, Rebalance needs to be triggered
     * @param minLTV Minimum value of LTV, If vaultLTV preceeds this value, Rebalance needs to be triggered
     * @dev RVS - to limit the protocol size for MVP where will we be able to configure a) max supply per user b) max supply overall?
     */
    function setConfig(
        uint256 tLTV,
        uint256 maxLTV,
        uint256 minLTV,
        uint256 min_depo,
        uint reserveFactor
    )
        external
        onlyOwner
    {
        store = Store({
            tLTV : tLTV, 
            maxLTV : maxLTV, 
            minLTV : minLTV, 
            min_depo : min_depo,
            reserveFactor : reserveFactor
        });
        emit ConfigUpdated(tLTV, maxLTV, minLTV, min_depo,reserveFactor);
    }


    // function transfer
    /**
     * @notice Commits Users and applies accrued interest to total Borrows
     * @param user Address of the user to be committed
     * @dev need to be called before any User operation
     */
    function _beforeEach(address user) internal whenNotPausedAll {
        accrueInterest();
        _commitUser(user, index);
        //Auto Repayment
        uint256 borrowBal = borrowBalanceCurrent(user);
        if (borrowBal > 0) {
            if (
                userData[user].rewards - userData[user].lastRewards >= borrowBal
            ) {
                userData[user].repaid += accountBorrows[user].principal;
                accountBorrows[user].principal = 0;
                userData[user].rewards -= borrowBal;

            } else {
                userData[user].repaid += (userData[user].rewards -
                    userData[user].lastRewards);
                userData[user].rewards = userData[user].lastRewards;
                accountBorrows[user].principal -= (userData[user].rewards -
                    userData[user].lastRewards);
            }
        }
    }

    /**
     * @notice Applies accrued interest to total borrows
     * @dev This calculates interest accrued from the last checkpointed block
     *   up to the current block and writes new checkpoint to storage./
     * @dev RVS - why is this not just called "accrueInterest"?
     */
    function accrueInterest() public {

        
        ///accrue interest on the lender DAI token
        uint256 err = Excdai.accrueInterest();

        /// RVS - this if statement seems redundant...?
        if (err != uint256(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted liquidation failed
            revert('COMP_ERR'); //Compound accrue error
        }
        uint256 principalTimesIndex;
        uint256 result;
        uint256 borrowIndex = Excdai.borrowIndex();
        
        /// return function if we have 0 user borrows
        /// Does it make sense to include this as it would still need to be evaluated every time?
        if (totalUserBorrows.principal == 0) {
            return;
        }

        /* Calculate new user borrow balance using the interest index:
         *  recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
         */
        principalTimesIndex = totalUserBorrows.principal * borrowIndex;

        result = (principalTimesIndex / totalUserBorrows.interestIndex);

        totalUserBorrows.interestIndex = borrowIndex;
        totalUserBorrows.principal = result;
        emit raccrued(result, borrowIndex);
    }

    /**
     * @notice Evaluates current borrow balance of a user
     * @param user The address whose balance should be calculated
     * @return borrow balance of the user
     */
    function borrowBalanceCurrent(address user) public returns (uint256) {
        /// RVS - I noticed that Compound "mandates" that the accrueInterest() function completes successfully. Shouldn't we do the same?
        accrueInterest();
        uint256 borrowIndex = Excdai.borrowIndex();
        accountBorrows[user].principal = borrowBalanceStored(user);
        accountBorrows[user].interestIndex = borrowIndex;
        return accountBorrows[user].principal;
    }

    /**
     * @notice Return the borrow balance of user based on stored data
     * @param user The address whose balance should be calculated
     * @return The calculated balance
     */
    function borrowBalanceStored(address user)
        public
        view
        returns (uint256)
    {
        (MathError err, uint256 result) = borrowBalanceStoredInternal(user);
        require(
            err == MathError.NO_ERROR,
            "BBS_FAIL" //borrowBalanceStored: borrowBalanceStoredInternal failed
        );
        return result;
    }

    /**
     * @notice Return the borrow balance of user based on stored data
     * @param user The address whose balance should be calculated
     * @return (error code, the calculated balance or 0 if error code is non-zero)
     */
    function borrowBalanceStoredInternal(address user)
        internal
        view
        returns (MathError, uint256)
    {
        /* Note: we do not assert that the market is up to date */
        //MathError mathErr;
        uint256 principalTimesIndex;
        uint256 result;
        uint256 borrowIndex = Excdai.borrowIndex();

        /* Get borrowBalance and borrowIndex */
        BorrowSnapshot storage borrowSnapshot = accountBorrows[user];

        /* If borrowBalance = 0 then borrowIndex is likely also 0.
         * Rather than failing the calculation with a division by 0, we immediately return 0 in this case.
         */
        if (borrowSnapshot.principal == 0) {
            return (MathError.NO_ERROR, 0);
        }

        /* Calculate new borrow balance using the interest index:
         *  recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
         */
        principalTimesIndex = borrowSnapshot.principal * borrowIndex;

        result = (principalTimesIndex / borrowSnapshot.interestIndex);

        return (MathError.NO_ERROR, result);
    }

    /**
     * @notice Returns the current LTV of the Vault
     * @dev Function managed in evaluator contract
     * @dev Should be "internal"?
     * @return The calculated LTV scaled by 10^18
     */
    function vaultLTVmantissa() public returns (uint256) {
        vaultLTVStored = eval.vaultLTV();
        return vaultLTVStored;
    }

    /**
     * @notice Sender Supplies Eth and Receives Reth in return
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     */
    function deposit() external payable {
        _beforeEach(msg.sender);
        _deposit(msg.sender, msg.value);
    }

    /**
     * @notice Sender Supplies Eth and Receives Reth in return
     * @param user The User Address Supplying Eth
     * @param amount Amount of Eth that User Supplied
     */
    function _deposit(address user, uint256 amount) internal {
        eval.depositCheck(user, amount);
        ///  Get vault balance of cETH
        /// TODO: change "init" to be more readable. E.g "vaultTokens"
        uint256 vaultTokens = Exceth.balanceOf(address(this));
        /// RVS: Deposit funds to lender
        Exceth.mint{value: amount}();
        /// RVS: Calculate by how much the vault balance has increased
        /// TODO: would suggest updating "camt" to something more reable (e.g. vaultTokenIncrease)
        uint256 vaultTokenIncrease = Exceth.balanceOf(address(this)) - vaultTokens;
        /// @dev RVS: can't seem to find the mint function anywhere. What am I missing?
        _mint(user, vaultTokenIncrease);
        //userCSupply[user] += vaultTokenIncrease;
        emit deposited(user, amount, vaultTokenIncrease);
    }

    /**
     * @notice Sender redeems Rtokens in exchanges of unserlying asset
     * @param rAmount The amount of Ctokens to be Redeemed
     * @dev RVS: use of cAmount seems incorrect. Isn't the user redeeming rAmount?
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     */
    function withdraw(uint256 rAmount) external {
        _beforeEach(msg.sender);
        _withdraw(msg.sender, rAmount);
    }

    /**
     * @notice Sender redeems Rtokens in exchanges of unserlying asset
     * @param rAmount The amount of Ctokens to be Redeemed
     * @param user The Account who wants to Redeem
     * @dev RVS: use of cAmount seems incorrect. Isn't the user redeeming rAmount?
     * @dev RVS: Believe we need something to keep track of the vault borrowing costs
     */
    function _withdraw(address user, uint256 rAmount) internal {
        /// RVS: Check if user is allowed to withdraw and if so what the vault shortfall is to honour the withdraw
        uint256 shortfall = eval.withdrawCheck(user, rAmount);
        /// RVS: withdraw the shortfall amount if required
        if (shortfall > 0) {
            if(shortfall>dai.balanceOf(address(this))){
            _withdrawPool(shortfall - dai.balanceOf(address(this)));
            }
            require(
                /// RVS: updated error message
                dai.balanceOf(address(this)) >= shortfall,
                "INSUFF" //Insufficient vault funds
            );
            /// RVS: Repay the required borrow amount
            dai.approve(address(Excdai), shortfall);
            Excdai.repayBorrow(shortfall );
        }
        /// RVS: burn the users rETH tokens and redeem cETH
        /// @dev is it not better to burn after redeeming the cETH?
        _burn(user, rAmount);
        uint256 amount = address(this).balance;
        require(Exceth.redeem(rAmount) == 0, "EXT_COMP_ERROR");
        amount = address(this).balance-amount;

        /// RVS: @dev what happens if "address(this)" has a non-zero balance at the start?
        /// @dev interested in how "payable" works. To discuss
        
        (bool sent, ) = payable(user).call{value: amount}("");
        require(sent, "ETH_ERR"); //Failed to send Ether
        emit withdrawn(user, amount, rAmount);
    }

    /** RVS
     * @notice Function to withdraw specified amount from our Yieldfarm into the vault
     * @param amount amount to be withdrawn
     * @dev RVS: Believe we need something to keep track of yield interest earned
     * @dev RVS: How are we using the "invested" variable?
     */
    function _withdrawPool(uint256 amount) internal {
        require(Exvault.underlyingBalanceWithInvestment()>=amount,'INSUFF');
        invested -= amount;
        /// RVS: Is this the best way to convert amount > amountf? To discuss
        uint256 amountf = ((amount ) * Exvault.totalSupply()) /
            Exvault.underlyingBalanceWithInvestment();
            amountf++;
        Expool.withdraw(amountf);
        Exvault.withdraw(amountf);
    }

    /**
     * @notice Initials a new Harvest if any of the condition is statisfied for more infomation refer Documentation
     * @dev RVS: I don't see anywhere where the harvest is being restricted at all...?
     */
    function harvest() external whenNotPaused {
        accrueInterest();
        require(eval.harvestCheck()==true,'Harvest Not Allowed');
        /// RVS: I don't see where this parameter is used...? (used by bots currently but will be use here as checks to take place in contract)
        lastHarvest = block.timestamp;
        uint256 amountOut;
        uint256 amountOut2;
        /// RVS: Get the total amount deposited with the yield farm (including interest earned)
        uint256 amount = (Expool.balanceOf(address(this)) *
            Exvault.underlyingBalanceWithInvestment()) / Exvault.totalSupply();
        /// RVS: Determine the difference between the current deposit and the last time we tracked, e.g. yield interest earned
           if(amount>=invested){
        amount = amount - invested;
        /// RVS: Update the amount invested
        invested += amount;
        }else{
            amount=0;
        }
        if(IERC20(comp).balanceOf(address(this))>0){
        // RVS: Approve Uniswap to use comp tokens
        IERC20(comp).approve(
            address(rswap),
            IERC20(comp).balanceOf(address(this))
        );

        /// RVS: Swap comp tokens to DAI
        amountOut = rswap.swap(
            comp,
            address(dai),
            IERC20(comp).balanceOf(address(this))
        );
        }
        if(farm.balanceOf(address(this))>0){
            /// RVS: approve Uniswap to use farm tokens
        farm.approve(address(rswap), farm.balanceOf(address(this)));
        /// RVS: swap farm tokens to DAI
        amountOut2 = rswap.swap(
            address(farm),
            address(dai),
            farm.balanceOf(address(this))
        );
        }
        /// RVS: Log the harvest
        _capture(amountOut, amountOut2 + amount);
        /// Track the harvest rewards for the stabilityUserContract (covering all users) and convert these to ETH (withdrawing if necessary)
        _commitStability();
    }
    /** RVS
     * @notice Claim rewards from both the lender and yield protocols
     * RVS: This is checked in the bot contract. There is no perceived risk in claiming continously (other than gas costs)
     */
    function claimRewards() external {
        ExCompTroller.claimComp(address(this));
        Expool.getReward();
        emit claimedVault(
            block.timestamp,
            IERC20(comp).balanceOf(address(this)),
            farm.balanceOf(address(this))
        );
    }

    function _commitStability() internal {
        _commitUser(stabilityUserContract, index);
        if(userData[stabilityUserContract].rewards>0){
        if (
            /// RVS: Check if we have the amount available locally, if not withdraw to enable swap
            dai.balanceOf(address(this)) <
            userData[stabilityUserContract].rewards
        ) {
            _withdrawPool(
                userData[stabilityUserContract].rewards -
                    dai.balanceOf(address(this))
            );
        }
        dai.approve(address(rswap), userData[stabilityUserContract].rewards);
        uint256 amountEth = rswap.swapDaiforEth(
            userData[stabilityUserContract].rewards
        );
        _deposit(stabilityUserContract, amountEth);
        }
    }

    /**
     * @notice Captures and stores data at the time of Harvest
     * @param comprewards The amount earned through lender protocol
     * @param farmrewards The amount earned through yield protocol
     * @dev RVS: Does it make sense to to make sure all "harvest" related functions are named as such (.e.g. _harvestCapture)
     */
    function _capture(uint256 comprewards, uint256 farmrewards) internal {
        /// RVS: Store harvest snapshot
        uint rsvAmt;
        if(index!=0){
            rsvAmt = harvestData[index - 1].reserveAmount;
        }
        rsvAmt += (farmrewards * store.reserveFactor) /
                10**18;
        harvestData[index] = harvestSnapshot({
            priceEthDai : (Exoracle.getUnderlyingPrice(address(Exceth))*10**18)/
            Exoracle.getUnderlyingPrice(address(Excdai)),
            lendingAmt: comprewards,
            yieldAmt: farmrewards-rsvAmt,
            supplyEth: Exceth.balanceOfUnderlying(address(this)),
            /// RVS: why are we storing the timestamp and not just the block number? (done)
            blockNo: (block.number),
            tLTV: store.tLTV,
            /// RVS: Why are we storing the reserve amount? (reserve factor alone should suffice) (changed in new contract)
            reserveAmount: rsvAmt,
            exchangeRate: Exceth.exchangeRateCurrent(),
            /// RVS: Where do we factor in the borrow index (e.g. interest) (function is only  called by harvest which applies index) (done)
            totalBorrowsEth: totalUserBorrows.principal*10**18
                 /((Exoracle.getUnderlyingPrice(address(Exceth)) * 10**18) /
                 Exoracle.getUnderlyingPrice(address(Excdai)))
        });

        
        harvestData.push();
        emit harvested(
            index,
            harvestData[index].priceEthDai,
            comprewards,
            farmrewards-rsvAmt,
            harvestData[index].supplyEth,
            store.tLTV,
            harvestData[index].reserveAmount,
            harvestData[index].exchangeRate,
            harvestData[index].totalBorrowsEth
        );
        index++;
    }

    /** RVS
     * @notice Used by user to claim rewards on the protocol, only applicable if users' loan has been paid off
     * @dev RVS: This relies on the ".rewards" amount being reset properly, need to check. This happens in _beforeEach function (tocheck)
     * @dev RVS: need to understand the logic of excluding "lastRewards" here. (depends on first point)
     */
    function claimUser() external {
        _beforeEach(msg.sender);
        /// RVS: Calculate amount that can be claimed
        uint256 amountTotal = userData[msg.sender].rewards -
            userData[msg.sender].lastRewards;
        require(amountTotal > 0, "No rewards");

        if (dai.balanceOf(address(this)) < amountTotal) {
            _withdrawPool(amountTotal - dai.balanceOf(address(this)));
        }
        dai.transfer(msg.sender, amountTotal);
    }

    /** RVS
     * @notice commits a list of users
     * @param userToCommit as an array of userAddresses to commit
     * @dev RVS: should this not be "usersToCommit"?
     * @param tillHarvest index of harvest up to which the users should be committed
     * @dev RVS: I'd always assumed that we'd commit upto the last harvest. Is there a specific reason not to do this? (this is to ensure we have a way to group harvests in case there are too many) (done)
     */
    function commitUsers(address[] memory userToCommit, uint256 tillHarvest)
        external
    {
        for (uint256 i = 0; i < userToCommit.length; i++) {
            _commitUser(userToCommit[i], tillHarvest);
        }
        //rewards
    }

    /** RVS
     * @notice commits a specific user
     * @param user address of user
     * @param tillH index of harvest up to which the user should be committed
     * @dev RVS: can't we use the same param name as above? (tillHarvest)
     * @dev RVS: I can't see anywhere that the users loan would be repaid. Need to understand if/how compounding works in this case
     * @dev Rachit to look into the above. Users who don't interact with the platform themselves should still benefit from lower borrow interest payments over time
     * @dev RVS: need to discuss the costs & reward structure for this function...
     * @dev Confirmed there is no reward for running this function (therefore it is currenlty a protocol cost)
     */
    function _commitUser(address user, uint256 tillH) internal {
        if (userData[user].uptillHarvest < tillH) {
            /// RVS: Update userData with latest rewards
            (userData[user].rewards, userData[user].lastRewards) = eval.evalCommit(user, userData[user].uptillHarvest, tillH);
            userData[user].uptillHarvest = tillH;
        }
    }

    /** RVS
     * @notice function for user to borrow DAI in specified amount
     * @param amount amount of DAI to be borrowed
     */
    function borrow(uint256 amount) external whenNotPaused {
        _beforeEach(msg.sender);
        _borrow(msg.sender, amount);
    }

    /** RVS
     * @notice internal function to support _borrow
     * @param user  address of user requesting to borrow
     * @param amount amount of DAI to be borrowed
     * @dev RVS: would be nice to understand why we sometimes use borrow & _borrow pattern and sometimes not
     * @dev RVS: we seem have missed a function to pull funds from yieldfarm if needed...
     * @dev RVS: we weem to be inconsistent on when to return a no error and when to not return anything.
     * @dev RVS: the "borrow()" function doesn't seem to have a mechanism to deal with the response from the "_borrow()" function...
     * @dev carefulmath? (any solidity >0.8.0 contracts have this by default)
     */
    function _borrow(address user, uint256 amount) internal {
        /// RVS: Check if a) the user is allowed to borrow the amount and b) the vault has enough liquidity to support
        (uint shortfallDai,) = eval.borrowCheck(user, amount);
        uint newAmount = amount-shortfallDai;
        if(shortfallDai>0){
            if(shortfallDai>dai.balanceOf(address(this))){
                _withdrawPool(shortfallDai);
            }
            
        }

        /// @dev RVS: shouldn't we get the borrowIndex after the Excdai.borrow() in case it has updated since?
        

        /// RVS: Borrow the required amount from the lender
        /// Note: this has the potential to go wrong if we've already maxed on our borrow amount for the vault... (this would actually fail on borrowCheck, but still needs fixing)
        require(Excdai.borrow(newAmount)==uint256(Error.NO_ERROR),'COMP_ERR');
        uint256 borrowIndex = Excdai.borrowIndex();

        /// RVS: Store updates
        totalUserBorrows.principal += amount ;
        totalUserBorrows.interestIndex = borrowIndex;
        accountBorrows[user].principal += amount ;
        accountBorrows[user].interestIndex = borrowIndex;
        //totalBorrows = vars.totalBorrowsNew;

        dai.transfer(user, amount);
        emit borrowed(user,amount);
    }



    /** RVS
     * @notice takeLoan completes both a deposit & borrow function in one go
     * @param amountOut amount of DAI to be borrowed
     */
    function takeLoan(uint256 amountOut)
        external
        payable
        whenNotPaused
    {
        _beforeEach(msg.sender);
        _deposit(msg.sender, msg.value);
        _borrow(msg.sender, amountOut);
    }
    /** RVS
     * @notice rebalance the vault to remain healthy
     */
    function rebalance() external whenNotPaused {
        accrueInterest();
        uint256 currentLTV = vaultLTVmantissa();
        uint256 bal = dai.balanceOf(address(this));
        /// RVS: If current LTV is higher than max -> repay loan
        if (currentLTV >= store.maxLTV) {
            /// RVS: Determine collateral in eth
            uint256 currentCollateral = (Exceth.balanceOfUnderlying(
                address(this)
            ) * Exoracle.getUnderlyingPrice(address(Exceth))) / Exoracle.getUnderlyingPrice(address(Excdai));
            /// RVS: Calculate amount required in ETH
            /// @dev RVS: Not sure I understand the calculation (fixed)
            /// Situation: Supply 1000 ETH, Borrowed 800 ETH, Target LTV 70%, Current LTV 80%
            /// Calculation: (80% - 70%) * 1,000 = 100 / 80% = 142.857 ETH
            /// Expectation: 800 - ( 1,000 * 70% ) = 100 ETH
            uint256 amountRequired = ((currentLTV - store.tLTV) *
                currentCollateral) / 10**18 ;
            if (amountRequired <= bal) {
                dai.approve(address(Excdai), amountRequired);
                Excdai.repayBorrow(amountRequired);
            } else {
                /// RVS: Fetch from Yieldfarm
                amountRequired = amountRequired - dai.balanceOf(address(this));

                require(
                    (Expool.balanceOf(address(this)) *
                        Exvault.underlyingBalanceWithInvestment()) /
                        Exvault.totalSupply() >=
                        amountRequired,
                    "INSUFF_DEFI" //Insufficient money in defi protocol
                );
                _withdrawPool(amountRequired);
                dai.approve(address(Excdai), amountRequired);
                Excdai.repayBorrow(amountRequired);
            }
        /// RVS: If current LTV is lower than minimum -> take loan
        } else if (currentLTV <= store.minLTV) {
            /// RVS: Collateral value in DAI (@dev need to fix to ensure DAI<>USDC conversion considered)
            uint256 currentCollateral = (Exceth.balanceOfUnderlying(
                address(this)
            ) * Exoracle.getUnderlyingPrice(address(Exceth))) / 10**18;
            /// RVS: Calculate amount to borrow in DAI
            uint256 amountRequired = ((store.tLTV - currentLTV) *
                currentCollateral) / (10**18);

            Excdai.borrow(amountRequired);
            bal += amountRequired;
        } 
        if (bal > store.min_depo) {
            dai.approve(address(Exvault), bal);
            Exvault.deposit(bal);
            invested += bal;
            _stake();
        } 
    }

    /** RVS
     * @notice stake yieldfarm tokens in the yieldfarm
     */
    function _stake() internal {
        uint256 amt = Exvault.balanceOf(address(this));
        Exvault.approve(address(Expool), amt);
        Expool.stake(amt);
    }

    /** RVS
     * @notice function for users to repay their loan
     */
    function repay(address user, uint256 amount) external {
        _beforeEach(msg.sender);
        _repay(msg.sender, user, amount);
    }
    /** RVS
     * @notice function for users to repay their Whole loan
     */
    function repayAll(address user) external {
        _beforeEach(msg.sender);
        _repay(msg.sender, user, accountBorrows[user].principal);
    }
    function _repay(
        address payer,
        address user,
        uint256 amount
    ) internal returns (uint256) {
        uint256 borrowIndex = Excdai.borrowIndex();
        /// RVS: Don't we loose track of how much the user is due to pay in interest if we do it this way? - is already tracked in _beforeEach
        accountBorrows[user].principal -= amount;
        accountBorrows[user].interestIndex = borrowIndex;
        dai.transferFrom(payer, address(this), amount);
        return amount;
    }

    /** RVS
     * @notice repay user loan and withdraw in the same transaction
     */
    function repaywithdraw(
        address user,
        uint256 amount,
        uint256 rAmount
    ) external {
        _beforeEach(user);
        _repay(msg.sender, user, amount);
        _withdraw(msg.sender, rAmount);
    }

    /** RVS
     * @notice function to liquidate a borrower if they are undercollateralised
     */
    function liquidateBorrow(address reciever, address borrower, uint256 repayAmount) external {
        (uint256 err, ) = liquidateBorrowInternal(reciever, borrower, repayAmount);
        require(uint256(Error.NO_ERROR) == err, "LIQ_ERR"); //error in liquidation
    }

    /** RVS
     * @notice internal function to liquidate a borrower
     */
    function liquidateBorrowInternal(address reciever, address borrower, uint256 repayAmount)
        internal
        nonReentrant
        returns (uint256, uint256)
    {
        accrueInterest();

        return liquidateBorrowFresh(reciever, borrower, repayAmount);
    }

    /**
     * @notice The liquidator liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of this cToken to be liquidated
     * @param liquidator The address repaying the borrow and seizing collateral
     * @param repayAmount The amount of the underlying borrowed asset to repay
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
     * @dev RVS: think this is the Compound code but can you highlight any changes?
     */
    function liquidateBorrowFresh(
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) internal returns (uint256, uint256) {
        /* Fail if liquidate not allowed */
        uint256 allowed = RefiTroller.liquidateBorrowAllowed(
            address(this),
            address(this),
            liquidator,
            borrower,
            repayAmount
        );
        if (allowed != 0) {
            return (
                failOpaque(
                    Error.COMPTROLLER_REJECTION,
                    FailureInfo.LIQUIDATE_COMPTROLLER_REJECTION,
                    allowed
                ),
                0
            );
        }

        /* Fail if borrower = liquidator */
        if (borrower == liquidator) {
            return (
                fail(
                    Error.INVALID_ACCOUNT_PAIR,
                    FailureInfo.LIQUIDATE_LIQUIDATOR_IS_BORROWER
                ),
                0
            );
        }

        /* Fail if repayAmount = 0 */
        if (repayAmount == 0) {
            return (
                fail(
                    Error.INVALID_CLOSE_AMOUNT_REQUESTED,
                    FailureInfo.LIQUIDATE_CLOSE_AMOUNT_IS_ZERO
                ),
                0
            );
        }

        /* Fail if repayAmount = UnLimited */
        if (repayAmount == ~uint256(0)) {
            return (
                fail(
                    Error.INVALID_CLOSE_AMOUNT_REQUESTED,
                    FailureInfo.LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX
                ),
                0
            );
        }

        /* Fail if repayBorrow fails */
        uint256 actualRepayAmount = _repay(liquidator, borrower, repayAmount);
        // if (repayBorrowError != uint256(Error.NO_ERROR)) {
        //     return (
        //         fail(
        //             Error(repayBorrowError),
        //             FailureInfo.LIQUIDATE_REPAY_BORROW_FRESH_FAILED
        //         ),
        //         0
        //     );
        // }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /* We calculate the number of collateral tokens that will be seized */
        (uint256 amountSeizeError, uint256 seizeTokens) = RefiTroller
            .liquidateCalculateSeizeTokens(
                address(Excdai),
                address(Exceth),
                actualRepayAmount
            );
        require(
            amountSeizeError == uint256(Error.NO_ERROR),
            "LIQ01" //LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED
        );

        /* Revert if borrower collateral token balance < seizeTokens */
        require(
            this.balanceOf(borrower) >= seizeTokens,
            "LIQ02"//LIQUIDATE_SEIZE_TOO_MUCH
        );

        // If this is also the collateral, run seizeInternal to avoid re-entrancy, otherwise make an external call
        uint256 seizeError = seizeInternal(liquidator, borrower, seizeTokens);

        /* Revert if seize tokens fails (since we cannot be sure of side effects) */
        if (seizeError != uint256(Error.NO_ERROR)) {
            return (seizeError, 0);
        }
        return (uint256(Error.NO_ERROR), actualRepayAmount);
    }

    /**
     * @notice Transfers collateral tokens (this market) to the liquidator.
     * @dev Called only during an in-kind liquidation, or by liquidateBorrow during the liquidation of another CToken.
     *  Its absolutely critical to use msg.sender as the seizer cToken and not a parameter.
     * @param liquidator The user receiving seized collateral
     * @param borrower The user having collateral seized
     * @param seizeTokens The number of cTokens to seize
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     * @dev RVS: think this is the Compound code but can you highlight any changes?

     */
    function seizeInternal(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) internal returns (uint256) {
        /* Fail if seize not allowed */
        uint256 allowed = RefiTroller.seizeAllowed(
            address(this),
            address(this),
            liquidator,
            borrower,
            seizeTokens
        );
        if (allowed != 0) {
            return allowed;
        }

        /* Fail if borrower = liquidator */
        if (borrower == liquidator) {
            return (
                fail(
                    Error.INVALID_ACCOUNT_PAIR,
                    FailureInfo.LIQUIDATE_LIQUIDATOR_IS_BORROWER
                )
            );
        }

        uint256 incentive = RefiTroller.liquidationIncentiveMantissa();
        uint256 val = ((incentive - 10**18) * seizeTokens) / incentive;
        userCSupply[borrower] = userCSupply[borrower] - seizeTokens;
        seizeTokens -= val;
        userCSupply[liquidator] += seizeTokens;
        /// RVS: @dev this needs some though as the bot will now not earn anything (so it costs us money to execute liquidations)
        userCSupply[stabilityUserContract] += val;
        return uint256(Error.NO_ERROR);
    }

    /** RVS
    * @notice function to get a snapshot of the users user
    * @param user user for who we want to get the information
    * @return (error, rTokenbalance, borrowBalance, exchangerateMantissa)
    * @dev would be interesting to understand how this is used
     */
    function getAccountSnapshot(address user)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rTokenBalance = userCSupply[user];
        uint256 borrowBalance;
        uint256 exchangeRateMantissa;

        MathError mErr;

        (mErr, borrowBalance) = borrowBalanceStoredInternal(user);
        if (mErr != MathError.NO_ERROR) {
            return (uint256(Error.MATH_ERROR), 0, 0, 0);
        }

        (exchangeRateMantissa) = Exceth.exchangeRateStored();
        return (
            uint256(Error.NO_ERROR),
            rTokenBalance,
            borrowBalance,
            exchangeRateMantissa
        );
    }

    function claimReserve() external onlyOwner {
        uint256 amountTotal = harvestData[index - 1].reserveAmount;
        require(amountTotal > 0, "NA"); //No rewards for claim
        harvestData[index - 1].reserveAmount = 0;
        if (dai.balanceOf(address(this)) < amountTotal) {
            _withdrawPool(amountTotal - dai.balanceOf(address(this)));
        }
        dai.transfer(msg.sender, amountTotal);
    }

    function emergencyWithdraw() external {
        require(rswap.oracleMismatch(), "MIS_ERR"); //Require Mismatch
        _pauseAll();
        _pause();
    }
}
