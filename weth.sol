//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./tokenHelpers/ERC20.sol";

contract weth is ERC20 {
    constructor() ERC20("WETH","WETH"){}
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
}