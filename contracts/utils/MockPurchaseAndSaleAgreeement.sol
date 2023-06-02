//SPDX-License-Identifier: No-License

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../controllers/ApprovalManager.sol";

import "../libraries/AccessManager.sol";

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MockPurchaseAndSaleAgreement is AccessManager {
    address public currency;

    constructor(address _currency) {
        currency = _currency;
    }

    function exchange() external {
        uint256 balance = IERC20(currency).balanceOf(msg.sender);

        SafeERC20.safeTransferFrom(
            IERC20(currency),
            msg.sender,
            address(this),
            balance
        );
    }
}
