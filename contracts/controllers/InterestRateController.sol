// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "../interfaces/IInterestRateController.sol";

contract FixedInterestRateController is IInterestRateController {
    uint256 public fixedRate;

    constructor(uint256 _fixedRate) {
        fixedRate = _fixedRate;
    }

    function get() external view returns (uint256) {
        return fixedRate;
    }
}
