// SPDX-License-Identifier: No license

pragma solidity ^0.8.13;

contract ApprovalManager {
    address[] public stakeholders;

    mapping(address => bool) public approvedStakeholders;

    constructor(address[] memory _stakeholders) {
        for (uint i = 0; i < _stakeholders.length; i++) {
            stakeholders.push(_stakeholders[i]);
        }
    }

    function approve() external {
        approvedStakeholders[msg.sender] = true;
    }

    function isApproved() public view returns (bool) {
        for (uint i = 0; i < stakeholders.length; i++) {
            if (!approvedStakeholders[stakeholders[i]]) {
                return false;
            }
        }
        return true;
    }
}
