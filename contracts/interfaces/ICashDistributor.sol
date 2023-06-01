// SPDX-License-Identifier: No license
pragma solidity ^0.8.13;

interface ICashDistributor {
    function distribute(uint256 status) external returns (uint256);
}
