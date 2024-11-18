// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./interfaces/ICurve3Pool.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Curve3PoolRouter {
    address immutable poolAddress;

    constructor (address _poolAddress) {
        poolAddress = _poolAddress;
    }

    function addLiquidity() external {

    }

    function getCoins() public view returns(address[] memory coins) {
        ICurve3Pool pool = ICurve3Pool(poolAddress);

        for (uint256 i = 0; i < 3; i++) {
            coins[i] = pool.coins(i);
        }
    }
}