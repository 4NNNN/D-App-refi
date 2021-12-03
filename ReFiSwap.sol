//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Interfaces/IrefiSwap.sol";
import "./utils/TransferHelper.sol";
import "./Interfaces/ISwapRouter.sol";
import "./Interfaces/IUniswapV3Factory.sol";
import "./Interfaces/IUniswapV3PoolState.sol";

interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

contract rSwap is IrSwap {
    uint24[] feeValues = [10000, 3000, 500];
    uint256 slippage = 5 * 10**16;
    uint256 denom = 10**18;
    uint256 timeout = 3000;
    uint256 minAmountOut = 30 * 10**18;
    //mapping (address => mapping(address=>uint)) fees;
    // mapping(address => mapping(address=>address)) paths;
    address constant uniswapV3Factory =
        0x1F98431c8aD98523631AE4a59f267346ea31F984;
    ISwapRouter constant swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    address constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    function changeVariables(uint256 slip, uint256 _timeout) external {
        slippage = slip;
        timeout = _timeout;
    }

    function checkPrice(address token0, address token1)
        public
        view
        override
        returns (uint24)
    {
        uint160 max = 0;
        uint24 fee;
        for (uint256 i = 0; i < 3; i++) {
            address poolAddress = IUniswapV3Factory(uniswapV3Factory).getPool(
                token0,
                token1,
                feeValues[i]
            );
            if (poolAddress != address(0)) {
                (uint160 val, , , , , , ) = IUniswapV3PoolState(poolAddress)
                    .slot0();
                val = (val * (1000000 - feeValues[i])) / 1000000;
                if (max <= val) {
                    max = val;
                    fee = feeValues[i];
                }
            }
        }
        require(max != 0, "Price Check error");
        return fee;
    }

    function minOut(
        uint256 a,
        address t0,
        address t1
    ) public override view returns (uint256) {
        uint24 fee1 = checkPrice(t0, weth);
        uint24 fee2 = checkPrice(t1, weth);
        address poolAddress0 = IUniswapV3Factory(uniswapV3Factory).getPool(
            t0,
            weth,
            fee1
        );
        address poolAddress1 = IUniswapV3Factory(uniswapV3Factory).getPool(
            t1,
            weth,
            fee2
        );
        require(
            poolAddress0 != address(0) || poolAddress1 != address(0),
            "Zero address error"
        );
        (uint160 val0, , , , , , ) = IUniswapV3PoolState(poolAddress0).slot0();
        (uint160 val1, , , , , , ) = IUniswapV3PoolState(poolAddress1).slot0();

        uint256 eths = ((uint256(val0)**2) * 10**18) / 2**192;
        //eths = eths*(1000000-fee2)/1000000;
        //revert("reached");
        uint256 dais = ((2**192) * 10**18) / uint256(val1)**2;
        //a = a *(1000000-fee2)/1000000;
        return (a * eths * dais) / 10**36;
    }

    function swap(
        address token0,
        address token1,
        uint256 amountIn
    ) external override returns (uint256) {
        uint256 amountOutmin = (minOut(amountIn, token0, token1) *
            (denom - slippage)) / denom;
        if (amountOutmin < minAmountOut) {
            return 0;
        }
        TransferHelper.safeTransferFrom(
            token0,
            msg.sender,
            address(this),
            amountIn
        );
        TransferHelper.safeApprove(token0, address(swapRouter), amountIn);
        ISwapRouter.ExactInputParams memory params = ISwapRouter
            .ExactInputParams({
                path: encode(token0, token1),
                recipient: msg.sender,
                deadline: block.timestamp + timeout,
                amountIn: amountIn,
                amountOutMinimum: amountOutmin //amountOutmin
            });

        // Executes the swap.
        uint256 amountOut = swapRouter.exactInput(params);
        return amountOut;
    }

    function swapDaiforEth(uint256 amount) external override returns (uint256) {
        uint24 fee = checkPrice(dai, weth);
        address poolAddress = IUniswapV3Factory(uniswapV3Factory).getPool(
            dai,
            weth,
            fee
        );
        require(poolAddress != address(0), "Zero address error");
        (uint160 val, , , , , , ) = IUniswapV3PoolState(poolAddress).slot0();
        uint256 eths = ((uint256(val)**2) * 10**18) / 2**192;
        uint256 amountOutmin = (eths * (denom - slippage)) / denom;

        TransferHelper.safeTransferFrom(dai, msg.sender, address(this), amount);
        TransferHelper.safeApprove(dai, address(swapRouter), amount);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: dai,
                tokenOut: weth,
                fee: fee,
                recipient: msg.sender,
                deadline: block.timestamp + timeout,
                amountIn: amount,
                amountOutMinimum: amountOutmin,
                sqrtPriceLimitX96: 0
            });
        uint256 amountOut = swapRouter.exactInputSingle(params);

        return amountOut;
    }

    function oracleMismatch() external view override returns (bool) {}

    function encode(address t0, address t1)
        internal
        view
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                t0,
                checkPrice(t0, weth),
                weth,
                checkPrice(t1, weth),
                t1
            );
    }

    // function getComp (uint amount) external payable {
    //     //TransferHelper.safeTransferFrom(weth,msg.sender,address(this),amount);
    //     TransferHelper.safeApprove(weth,address(swapRouter),amount);
    //     ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
    //         .ExactInputSingleParams({
    //             tokenIn : weth,
    //             tokenOut : 0xc00e94Cb662C3520282E6f5717214004A7f26888,
    //             fee : 3000,
    //             recipient : address(this),
    //             deadline : block.timestamp+3000,
    //             amountIn : 1000000000000000000,
    //             amountOutMinimum : 0,
    //             sqrtPriceLimitX96 : 0
    //         });
    //         swapRouter.exactInputSingle(params);
    // }
    // function Balance(address token,address a ) external view returns (uint){
    //     return IERC20(token).balanceOf(a);
    // }
    //     function wrap() external payable {
    //     IWETH9(weth).deposit{value:msg.value}();
    //     IWETH9(weth).transfer(msg.sender,msg.value);
    // }
    // function wraphere() external payable {
    //     IWETH9(weth).deposit{value:msg.value}();
    // }
    // function balance(address a) external view returns (uint){
    //     return IWETH9(weth).balanceOf(a);
    // }
}
