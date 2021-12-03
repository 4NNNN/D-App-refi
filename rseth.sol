//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./tokenHelpers/ERC20.sol";
import "./tokenHelpers/IERC20.sol";
import "./utils/Ownable.sol";

interface Ireth is IERC20{
    function deposit() external payable;
    function withdraw(uint256 cAmount) external returns (uint256);
    function userCSupply(address user) external returns (uint);
}

contract rseth is ERC20,Ownable {
    Ireth immutable reth;
    uint public cooldownPeriod = 180;
    uint public freezePeriod = 500;
    //mapping (address => uint) public userrsSupply;
    struct releaseTrack{
        uint timeAsked;
        uint cAmount;
    }
    mapping (address => releaseTrack) public releaseStatus;
    event periodsChanged(uint newCPeriod,uint newFPeriod);
    event deposited(address user, uint amount, uint rsAmount);
    event requestWithdraw(address user,uint requestedcAmount,uint canWithdrawTime);
    event withdrawn(address user,uint amountWithdrawn,uint cAmountWithdrawn);

    constructor(address _reth) ERC20("rsreth","rsreth"){
        reth = Ireth(_reth);
    }
    receive() external payable {
        //emit Received(msg.sender, msg.value);
    }
    function setPeriods(uint cperiod,uint fperiod) external onlyOwner {
        cooldownPeriod = cperiod;
        freezePeriod = fperiod;
        emit periodsChanged(cperiod,fperiod);
    }
    function stake() external payable {
        _stake(msg.sender, msg.value);
    }

    /**
     * @notice Sender Supplies Eth and Receives rsEth in return
     * @param account The User Address Supplying Eth
     * @param amount Amount of Eth that User Supplied
     */
    function _stake(address account, uint256 amount) internal {
        uint256 init = reth.balanceOf(address(this));
        reth.deposit{value: amount}();
        uint256 rsamt = reth.balanceOf(address(this)) - init;
        _mint(account, rsamt);

        //userrsSupply[account] += rsamt;
        emit deposited(account,amount,rsamt);
    }

    function requestRelease(uint cAmount) external {
        uint maxAmount = reth.balanceOf(address(this)) * balanceOf(msg.sender)/totalSupply();
        require(cAmount<=maxAmount,'Not sufficient balance');
        releaseStatus[msg.sender] = releaseTrack({timeAsked:block.timestamp,cAmount:cAmount});
        emit requestWithdraw(msg.sender, cAmount, block.timestamp+cooldownPeriod);
    }

    function withdraw(address account,uint cAmount) external {
        require(releaseStatus[account].timeAsked+cooldownPeriod<block.timestamp,'Please wait for cooldown');
        require(releaseStatus[account].timeAsked+cooldownPeriod>block.timestamp,'Claim Period Over');
        require(releaseStatus[account].cAmount >= cAmount,'You requested for lower amount');
        releaseStatus[account] = releaseTrack({timeAsked:0,cAmount:0});
        _burn(account,cAmount * totalSupply()/reth.balanceOf(address(this)));
        uint amount1 =  address(this).balance;
        reth.withdraw(cAmount);
        uint amount =  address(this).balance - amount1;
        (bool sent, ) = payable(account).call{value: amount}("");
        require(sent, "Failed to send Ether");
        emit withdrawn(account, amount, cAmount);
    }
    //function claimRewards() external{}
}