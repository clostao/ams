// SPDX-License-Identifier: No license
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ICashDistributor.sol";

contract MockCashDistributor is ICashDistributor {
    constructor() {}

    function distribute(
        uint256 /*status*/
    ) external pure returns (uint256) {
        return 0;
    }
}
