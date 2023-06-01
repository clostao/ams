// SPDX-License-Identifier: No license
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CashDistributor {
    IERC20 public currency;
    address public lender;
    address public borrower;

    constructor(
        address _currency,
        address _lender,
        address _borrower
    ) {
        currency = IERC20(_currency);
        lender = _lender;
        borrower = _borrower;
    }

    function distribute(uint256 status) external returns (uint256) {
        uint256 balance = IERC20(currency).balanceOf(address(this));

        if (status == 0) {
            SafeERC20.safeTransfer(currency, lender, balance);
            return balance;
        } else if (status == 1) {
            uint256 lenderAmount = balance / 2;
            uint256 borrowerAmount = balance - lenderAmount;
            SafeERC20.safeTransfer(currency, lender, lenderAmount);
            SafeERC20.safeTransfer(currency, borrower, borrowerAmount);
            return lenderAmount;
        } else if (status == 2) {
            uint256 lenderAmount = balance / 3;
            uint256 borrowerAmount = balance - lenderAmount;
            SafeERC20.safeTransfer(currency, lender, lenderAmount);
            SafeERC20.safeTransfer(currency, borrower, borrowerAmount);
            return lenderAmount;
        } else {
            revert("MortgageController: INVALID_STATUS");
        }
    }
}
