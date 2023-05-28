// SPDX-License-Identifier: No license
pragma solidity ^0.8.13;

interface IInterestRateController {
    function get() external returns (uint256);
}
