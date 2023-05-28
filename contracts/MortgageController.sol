// SPDX-License-Identifier: No license

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./PurchaseAndSaleAgreement.sol";

import "./libraries/AccessManager.sol";
import "./interfaces/IInterestRateController.sol";
import "./interfaces/IStatusController.sol";

contract MortgageController is AccessManager {
    // mortage agents
    address public lender;
    address public borrower;

    // external dependencies
    address public purchaseAddress;
    address public propertyManager;
    address public interestRateController;
    address public statusControllerAddress;

    // mortgage conditions
    IERC20 currency;

    uint256 lenderTokenAmount;
    uint256 borrowerTokenAmount;

    // mortgage status

    bool initialized;
    uint256 outstandingBalance;
    uint256 lastAccruedInterest;

    modifier recalculatesDebt() {
        accrueInterest();
        _;
    }

    constructor(
        address _lender,
        address _borrower,
        address _purchaseAddress,
        address _currencyAddress,
        address _statusControllerAddress,
        uint256 _lenderTokenAmount,
        uint256 _borrowerTokenAmount
    ) {
        lender = _lender;
        borrower = _borrower;
        purchaseAddress = _purchaseAddress;
        statusControllerAddress = _statusControllerAddress;
        currency = IERC20(_currencyAddress);
        lenderTokenAmount = _lenderTokenAmount;
        borrowerTokenAmount = _borrowerTokenAmount;
    }

    function init() external {
        require(initialized == false, "MortgageController: ALREADY_EXECUTED");

        // both agents deposit the agreed amount
        SafeERC20.safeTransferFrom(
            currency,
            lender,
            address(this),
            lenderTokenAmount
        );

        SafeERC20.safeTransferFrom(
            currency,
            borrower,
            address(this),
            borrowerTokenAmount
        );

        // approves allowance to PurchaseAndSaleAgreement
        IERC20(currency).approve(
            purchaseAddress,
            lenderTokenAmount + borrowerTokenAmount
        );

        // Executes purchase
        PurchaseAndSaleAgreement(purchaseAddress).exchange();

        // Init mortgage status
        initialized = true;
        outstandingBalance = lenderTokenAmount;
        lastAccruedInterest = block.timestamp;
    }

    function distributePropertyCashflows() public recalculatesDebt {
        uint256 balance = IERC20(currency).balanceOf(address(this));

        uint256 status = IStatusController(statusControllerAddress).status();

        if (status == 0) {
            SafeERC20.safeTransferFrom(
                currency,
                address(this),
                lender,
                balance
            );
        } else if (status == 1) {
            uint256 lenderAmount = balance / 2;
            uint256 borrowerAmount = balance - lenderAmount;
            SafeERC20.safeTransferFrom(
                currency,
                address(this),
                lender,
                lenderAmount
            );
            SafeERC20.safeTransferFrom(
                currency,
                address(this),
                borrower,
                borrowerAmount
            );
        } else if (status == 2) {
            uint256 lenderAmount = balance / 3;
            uint256 borrowerAmount = balance - lenderAmount;
            SafeERC20.safeTransferFrom(
                currency,
                address(this),
                lender,
                lenderAmount
            );
            SafeERC20.safeTransferFrom(
                currency,
                address(this),
                borrower,
                borrowerAmount
            );
        } else {
            revert("MortgageController: INVALID_STATUS");
        }
    }

    function accrueInterest() internal onlySender(propertyManager) {
        uint256 interestRate = IInterestRateController(interestRateController)
            .get();

        uint256 accruedTime = block.timestamp - lastAccruedInterest;
        uint256 effectiveInterestRate = (accruedTime * interestRate) /
            (365 days);

        outstandingBalance =
            (outstandingBalance * effectiveInterestRate) /
            1e18;
    }

    function repay(address from, uint256 amount)
        external
        onlySender(lender)
        recalculatesDebt
    {
        SafeERC20.safeTransferFrom(currency, from, address(this), amount);
    }
}
