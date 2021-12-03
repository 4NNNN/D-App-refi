// RVS we should remove the license
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title Extends rETH contract functionality
 * @author Refi
 * @notice ...
 * @dev TODO: we should structure the contracts folder better.
 * (e.g. rather than using "Ioracle.sol" can we move all interface contracts to "Interfaces/<supplier>" where supplier would be Compound/Harvest/Uniswap/etc.?)
 **/

import "./Interfaces/ComptrollerInterface8.sol";
import "./ErrorReporter8.sol";
import "./Interfaces/Ioracle.sol";
import "./tokenHelpers/IERC20.sol";
import "./Interfaces/Ievaluator.sol";
import "./utils/Ownable.sol";
import "./Interfaces/IrefiSwap.sol";

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

interface CErc20 is error {
    /// RVS remove the below comments?

    //  enum MathError {
    //     NO_ERROR,
    //     DIVISION_BY_ZERO,
    //     INTEGER_OVERFLOW,
    //     INTEGER_UNDERFLOW
    // }

    function borrowIndex() external view returns (uint256);

    function accrueInterest() external returns (uint256);

    function mint(uint256) external returns (uint256);

    function borrow(uint256) external returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function repayBorrow(uint256) external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function borrowBalanceCurrent(address user) external returns (uint256);

    function balanceOfUnderlying(address user) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (MathError, uint256);
}

struct HarvestSnapshot {
    /// RVS
    /// @notice structure to store havestSnapshots

    uint256 priceEth;
    uint256 lendingAmt;
    uint256 yieldAmt;
    uint256 supplyEth;
    uint256 blockNo;
    uint256 tLTV;
    uint256 reserveAmount;
    uint256 exchangeRate;
    uint256 totalBorrowsEth;
}

/// RVS - copied from poc, inconsistent use of Capitals for naming?
/**
 * @notice Container for borrow balance information
 * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
 * @member interestIndex Global borrowIndex as of the most recent balance-changing action
 */
struct BorrowSnapshot {
    uint256 principal;
    uint256 interestIndex;
}

interface Ireth is IERC20 {
    function harvestData(uint256 index)
        external
        view
        returns (HarvestSnapshot memory);

    function accountBorrows(address user)
        external
        view
        returns (BorrowSnapshot memory);

    function lastHarvest() external view returns (uint256);
}

contract evaluator is TokenErrorReporter, Ownable, Ieval {
    /// RVS - need to update RefiTroller name
    /// RVS - these contract values should be configurable
    ComptrollerInterface public immutable RefiTroller;
    address public immutable reth;
    ComptrollerInterface ExCompTroller =
        ComptrollerInterface(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    IOracle Exoracle = IOracle(0x6D2299C48a8dD07a872FDd0F8233924872Ad1071);
    CErc20 ExcDAI = CErc20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    CErc20 Exceth = CErc20(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);
    /// @notice address of Compound's Comp Tokens
    address constant comp = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    /// @notice Instance of Harvest.finance's FARM token
    address constant farm = (0xa0246c9032bC3A600820415aE600c6388619A14D);
    /// @notice Instance of DAI token
    address constant dai = (0x6B175474E89094C44Da98b954EedeAC495271d0F);
    struct HarvestTriggers {
        uint256 minTime;
        uint256 minCompDAI; //DAI value of COMP tokens required to allow harvest
        uint256 minFarmDAI; //DAI value of FARM tokens required to allow harvest
    }
    HarvestTriggers public harvestTriggers;
    IrSwap public rswap;
    struct DepositRestrictions {
        uint256 userMaxSupply;
        uint256 vaultMaxSupply;
    }
    DepositRestrictions public depositRestrictions;
    /// used in the bots for various checks like liquidation
    mapping(address => bool) interacted;
    address[] users;

    constructor(
        address _reth,
        address _controller,
        address _rswap
    ) {
        reth = _reth;
        rswap = IrSwap(_rswap);
        RefiTroller = ComptrollerInterface(_controller);
        harvestTriggers = HarvestTriggers({
            minTime: 1000,
            minCompDAI: 1 * 10**18,
            minFarmDAI: 1 * 10**18
        });
        depositRestrictions = DepositRestrictions({
            userMaxSupply: 100*10**18,
            vaultMaxSupply: 500*10**18
        });
    }

    function changeHarvestTriggers(
        uint256 newTime,
        uint256 _minCompUSD,
        uint256 _minFarmUSD
    ) external {
        require(msg.sender == owner(), "Not Authorised");
        harvestTriggers = HarvestTriggers({
            minTime: newTime,
            minCompDAI: _minCompUSD,
            minFarmDAI: _minFarmUSD
        });
    }

    function changeDepositRestrictions(
        uint256 userMaxSupply,
        uint256 vaultMaxSupply
    ) external onlyOwner {
        depositRestrictions = DepositRestrictions({
            userMaxSupply: userMaxSupply,
            vaultMaxSupply: vaultMaxSupply
        });
    }

    /** RVS
     * @notice checks if a borrow is allowed to be made by a specific user
     * @param user users address
     * @param amount amount the user wants to borrow
     * @dev currency is assumed to be rETH
     * @return uint with the liquidity ???
     **/
    function borrowCheck(address user, uint256 amount)
        external
        view
        override
        returns (uint,uint256)
    {
        /// RVS
        /// Check if the RefiTroller would allow the user to borrow the requested amount
        uint256 allowed = RefiTroller.borrowAllowed(reth, user, amount);
        if (allowed != uint256(Error.NO_ERROR)) {
            /// RVS updating error message
            revert("Insufficient Balance");
        }

        /// RVS
        /// Check if the liquidity of the vault contract (reth)???
        (uint256 err, uint256 liquidity, uint256 shortfall) = ExCompTroller
            .getAccountLiquidity(reth);
        /// RVS - updating error codes originally ("Error", "nonHealthy LTV", "No liquidity available")
        /// Are these errors ever visible to the user?
        /// Should we be unstaking if not enough vault liquidity is available?

        require(
            err == 0,
            "Error in confirming if sufficient liquidity is available"
        );
        if(shortfall>0){
            return (shortfall/Exoracle.getUnderlyingPrice(address(ExcDAI)),0);
        }
        require(

            liquidity > 0,
            "Not enough liquidity available to support borrow"
        );
        uint256 price = Exoracle.getUnderlyingPrice(address(ExcDAI));
        require(
            ((liquidity * 10**18) / price) >= amount,
            /// RVS - updating error code, originally ("Not Sufficient Liquidity")
            "Not enough liquidity available to support borrow"
        );
        return (0,liquidity);
    }

    /** RVS
     * @notice : Get the loan to value of vault
     * @dev : Need to understand the override method...?
     * @return : uint mantissa of loan to value
     */
    function vaultLTV() external override returns (uint256) {
        /// RVS
        /// "priceInDai" = "cETH to ETH price" * "Vault balance of cETH" / "cUSDC to ETH"
        /// Why are we calling everything USDC not DAI in the code?
        /// Should we not use Compound to get the price of cETH?
        uint256 priceInDai = (Exoracle.getUnderlyingPrice(address(Exceth)) *
            Exceth.balanceOfUnderlying(reth)) /
            Exoracle.getUnderlyingPrice(address(ExcDAI));
        return (ExcDAI.borrowBalanceCurrent(reth) * 10**18) / (priceInDai);
    }

    /** RVS
     * @notice check if the user is allowed to withdraw the requested amount and return vault shortfall if so
     * @param user user for who the check should be performed
     * TODO: inconsistent use of account vrs user?
     * @param rAmount in cETH requested to withdraw (should this not be rETH?)
     * TODO: inconsistent use of amount/cAmount?
     * @return uint with vault shortfall or reverts if the user doesn't have enough funds to support transaction
     */
    function withdrawCheck(address user, uint256 rAmount)
        external
        override
        returns (uint256)
    {
        /// RVS
        /// Check if the user is allowed to redeem the requested amount of tokens
        uint256 err = RefiTroller.redeemAllowed(
            address(this),
            user,
            rAmount
        );
        /// RVS
        /// If the user is allowed to withdraw, check if the vault has enough liquidity to withdraw
        if (err == uint256(Error.NO_ERROR)) {
            uint256 err2;
            uint256 shortfall;
            (err2, , shortfall) = ExCompTroller.getHypotheticalAccountLiquidity(
                reth,
                address(Exceth),
                rAmount,
                0
            );
            require(err2 == uint256(Error.NO_ERROR), "Error From Compound");
            return
                (shortfall * 10**18) /
                Exoracle.getUnderlyingPrice(address(ExcDAI));
        }
        /// RVS - updated error code. Original "repay"
        revert("Withdraw not allowed");
    }

    /** RVS
     * @notice Calculate how much will be distributed to the user from a range of harvests
     * @param user address of the user to commit
     * @param initialH first harvest to include in the evaluation
     * @param finalH last harvest to include in the evaluation
     * @dev safemath?
     * @dev outcome could be misleading as it doesn't factor in upto which harvest the user has been committed
     * @return rewards returns the amount due to the user in total as well as from the last harvest (lastRewards)
     */

    function evalCommit(
        address user,
        uint256 initialH,
        uint256 finalH
    ) external view override returns (uint256 rewards, uint256 lastRewards) {
        /// RVS - get a BorrowSnapshot of the user (principal & interestIndex) from the reth contract
        BorrowSnapshot memory borrowData = Ireth(reth).accountBorrows(user);
        uint256 rewardsTotal;
        uint256 lastrewards;
        /// RVS - get the users' balance
        uint256 bal = Ireth(reth).balanceOf(user);
        /// RVS - loop through the specified harvests
        for (uint256 i = initialH; i < finalH; i++) {
            /// RVS - get the snapshot of the harvest
            /// @dev using "lastHarvest" here feels slightly inappropriate
            HarvestSnapshot memory lastHarvest = Ireth(reth).harvestData(i);
            /// RVS - dLender = "Harvest Lender Profit in ETH (converted from DAI)" * "User Bal in ETH" / "Harvest Supply in ETH"

            uint256 dLender = (lastHarvest.lendingAmt *
                (bal * lastHarvest.exchangeRate)) / lastHarvest.supplyEth;
            /// RVS - determine how much could be harvested with
            uint256 denom = ((lastHarvest.supplyEth * lastHarvest.tLTV) /
                10**18) - lastHarvest.totalBorrowsEth;

            /// RVS - determine the users allocation to the harvest
            /// TODO: To avoid under/overcommitting the bal amount should reflect the balance at time of harvest...(?)
            uint256 num = (lastHarvest.yieldAmt *
                (((bal * lastHarvest.exchangeRate) * lastHarvest.tLTV) -
                    (borrowData.principal * lastHarvest.priceEth))) / 10**18;
            num = num / (denom);
            lastrewards = dLender + num;
            rewardsTotal += lastrewards;
        }
        return (rewardsTotal, lastrewards);
    }

    function harvestCheck() external view override returns (bool) {
        uint256 compRewardsDAI = rswap.minOut(
            IERC20(comp).balanceOf(address(reth)),
            comp,
            dai
        );
        uint256 farmRewardsDAI = rswap.minOut(
            IERC20(farm).balanceOf(address(reth)),
            farm,
            dai
        );
        if (
            Ireth(reth).lastHarvest() + harvestTriggers.minTime <=
            block.timestamp ||
            compRewardsDAI >= harvestTriggers.minCompDAI ||
            farmRewardsDAI >= harvestTriggers.minFarmDAI
        ) {
            return true;
        }
        return false;
    }

    function depositCheck(address user, uint256 amount) external override {
        uint256 exchangeRate = Exceth.exchangeRateCurrent();
        require(
            (Ireth(reth).balanceOf(user) * exchangeRate)/10**18 + amount <
                depositRestrictions.userMaxSupply,
            "LIM00"
        ); //USER LIMIT Exceeded
        require(
            (Ireth(reth).totalSupply() * exchangeRate)/10**18 + amount <
                depositRestrictions.vaultMaxSupply,
            "LIM01"
        );
        if (interacted[user] == false) {
            users.push(user);
            interacted[user] = true;
        }
    }
}
