// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@src/executors/UniswapV2Executor.sol";
import {Test} from "../../lib/forge-std/src/Test.sol";
import {Constants} from "../Constants.sol";

contract UniswapV2ExecutorExposed is UniswapV2Executor {
    function decodeParams(bytes calldata data)
        external
        pure
        returns (
            IERC20 inToken,
            address target,
            address receiver,
            bool zeroForOne
        )
    {
        return _decodeData(data);
    }

    function getAmountOut(address target, uint256 amountIn, bool zeroForOne)
        external
        view
        returns (uint256 amount)
    {
        return _getAmountOut(target, amountIn, zeroForOne);
    }
}

contract UniswapV2ExecutorTest is UniswapV2ExecutorExposed, Test, Constants {
    using SafeERC20 for IERC20;

    UniswapV2ExecutorExposed uniswapV2Exposed;
    IERC20 WETH = IERC20(WETH_ADDR);
    IERC20 DAI = IERC20(DAI_ADDR);

    function setUp() public {
        uint256 forkBlock = 17323404;
        vm.createSelectFork(vm.rpcUrl("mainnet"), forkBlock);
        uniswapV2Exposed = new UniswapV2ExecutorExposed();
    }

    function testDecodeParams() public view {
        bytes memory params =
            abi.encodePacked(WETH_ADDR, address(2), address(3), false);

        (IERC20 tokenIn, address target, address receiver, bool zeroForOne) =
            uniswapV2Exposed.decodeParams(params);

        assertEq(address(tokenIn), WETH_ADDR);
        assertEq(target, address(2));
        assertEq(receiver, address(3));
        assertEq(zeroForOne, false);
    }

    function testDecodeParamsInvalidDataLength() public {
        bytes memory invalidParams =
            abi.encodePacked(WETH_ADDR, address(2), address(3));

        vm.expectRevert(UniswapV2Executor__InvalidDataLength.selector);
        uniswapV2Exposed.decodeParams(invalidParams);
    }

    function testAmountOut() public view {
        uint256 amountOut =
            uniswapV2Exposed.getAmountOut(WETH_DAI_POOL, 10 ** 18, false);
        uint256 expAmountOut = 1847751195973566072891;
        assertEq(amountOut, expAmountOut);
    }

    // triggers a uint112 overflow on purpose
    function testAmountOutInt112Overflow() public view {
        address target = 0x0B9f5cEf1EE41f8CCCaA8c3b4c922Ab406c980CC;
        uint256 amountIn = 83638098812630667483959471576;

        uint256 amountOut =
            uniswapV2Exposed.getAmountOut(target, amountIn, true);

        assertGe(amountOut, 0);
    }

    function testSwapUniswapV2() public {
        uint256 amountIn = 10 ** 18;
        uint256 amountOut = 1847751195973566072891;
        bool zeroForOne = false;
        bytes memory protocolData =
            abi.encodePacked(WETH_ADDR, WETH_DAI_POOL, BOB, zeroForOne);

        deal(WETH_ADDR, address(uniswapV2Exposed), amountIn);
        uniswapV2Exposed.swap(amountIn, protocolData);

        uint256 finalBalance = DAI.balanceOf(BOB);
        assertGe(finalBalance, amountOut);
    }

    function testDecodeIntegration() public {
        // Generated by the ExecutorStrategyEncoder - test_executor_strategy_encode
        bytes memory protocolData =
            hex"c02aaa39b223fe8d0a0e5c4f27ead9083c756cc288e6a0c2ddd26feeb64f039a2c41296fcb3f5640000000000000000000000000000000000000000100";

        (IERC20 tokenIn, address target, address receiver, bool zeroForOne) =
            uniswapV2Exposed.decodeParams(protocolData);

        assertEq(address(tokenIn), WETH_ADDR);
        assertEq(target, 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640);
        assertEq(receiver, 0x0000000000000000000000000000000000000001);
        assertEq(zeroForOne, false);
    }

    function testSwapIntegration() public {
        // Generated by the ExecutorStrategyEncoder - test_executor_strategy_encode
        bytes memory protocolData =
            hex"c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2a478c2975ab1ea89e8196811f51a7b7ade33eb111d96f2f6bef1202e4ce1ff6dad0c2cb002861d3e00";
        uint256 amountIn = 10 ** 18;
        uint256 amountOut = 1847751195973566072891;
        deal(WETH_ADDR, address(uniswapV2Exposed), amountIn);
        uniswapV2Exposed.swap(amountIn, protocolData);

        uint256 finalBalance = DAI.balanceOf(BOB);
        assertGe(finalBalance, amountOut);
    }
}
