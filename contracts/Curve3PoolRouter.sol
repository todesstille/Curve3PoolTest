// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ICurve3Pool.sol";
import "./interfaces/ICurveRegistry.sol";

// Uncomment this line to use console.log
import "hardhat/console.sol";

contract Curve3PoolRouter {
    using SafeERC20 for *;

    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address immutable registryAddress;

    constructor (address _registryAddress) {
        registryAddress = _registryAddress;
    }

    function addLiquidity(address poolAddress, address[] calldata tokens, uint256[] calldata amounts) external {
        require(tokens.length == 3 && amounts.length == 3, "C3PR: wrong data");
        require(tokens[0] != tokens[1] && tokens[0] != tokens[2] && tokens[1] != tokens[2], "C3PR: wrong data");

        address[] memory coins = getCoins(poolAddress);

        for (uint i = 0; i < tokens.length; i++) {
            require(_addressIsInArray(tokens[i], coins), "C3PR: wrong data");
        }

        uint256[3] memory poolAmounts;
        for (uint i = 0; i < coins.length; i++) {
            for (uint j = 0; j < tokens.length; j++) {
                if (coins[i] == tokens[j]) {
                    poolAmounts[i] = amounts[j];
                    IERC20(coins[i]).safeApprove(poolAddress, amounts[j]);
                }
            }
        }

        ICurve3Pool(poolAddress).add_liquidity(poolAmounts, 0);
    }

    function removeLiquidityOneToken(address poolAddress, address token, uint256 amount) external {
        address[] memory coins = getCoins(poolAddress);
        int128 i = 3;
        for (uint256 j = 0; j < 3; j++) {
            if (coins[j] == token) i = int128(int256(j));
        }
        require(i < 3, "C3PR: Wrong token");

        IERC20 lpToken = IERC20(getLiquidityToken(poolAddress));
        lpToken.approve(poolAddress, type(uint256).max);

        ICurve3Pool(poolAddress).remove_liquidity_one_coin(amount, i, 0);
    }

    function swapToken(address poolAddress, address tokenIn, address tokenOut, uint256 amountIn) external {
        address[] memory coins = getCoins(poolAddress);

        int128 i = 3;
        for (uint256 k = 0; k < 3; k++) {
            if (coins[k] == tokenIn) i = int128(int256(k));
        }
        require(i < 3, "C3PR: Wrong token");

        int128 j = 3;
        for (uint256 k = 0; k < 3; k++) {
            if (coins[k] == tokenOut) j = int128(int256(k));
        }
        require(j < 3, "C3PR: Wrong token");

        require(i != j, "C3PR: Same tokens");

        IERC20 token = IERC20(coins[uint256(uint128(i))]);
        token.approve(poolAddress, amountIn);

        ICurve3Pool(poolAddress).exchange(i, j, amountIn, 0);
    }

    receive() external payable {}

    function withdraw(address tokenAddress, uint256 amount) external {
        if (tokenAddress == NATIVE) {
            payable(msg.sender).transfer(amount);
        } else {
            IERC20(tokenAddress).safeTransfer(msg.sender, amount);
        }
    }

    function getCoins(address poolAddress) public view returns(address[] memory coins) {
        coins = new address[](3);
        ICurve3Pool pool = ICurve3Pool(poolAddress);

        for (uint256 i = 0; i < 3; i++) {
            coins[i] = pool.coins(i);
        }
    }

    function getLiquidityToken(address poolAddress) public view returns(address lpToken) {
        return ICurveRegistry(registryAddress).get_lp_token(poolAddress);
    }

    function _addressIsInArray(address addressSingle, address[] memory addressArray) internal pure returns (bool) {
        for (uint k = 0; k < addressArray.length; k++) {
            if (addressSingle == addressArray[k]) return true;
        }

        return false;
    }
}