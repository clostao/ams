// SPDX-License-Identifier: No license
pragma solidity ^0.8.13;

import "../interfaces/IStatusController.sol";

contract IncomeStatusController is IStatusController {
    constructor() {}

    uint256 public status;

    function setStatus(uint256 _status) external {
        status = _status;
    }
}
