// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract AccessManager is AccessControl {
    modifier onlySender(address expectedSender) {
        require(
            msg.sender == expectedSender,
            string(
                abi.encodePacked(
                    "AccessManager: expected sender is ",
                    Strings.toHexString(expectedSender)
                )
            )
        );
        _;
    }
}
