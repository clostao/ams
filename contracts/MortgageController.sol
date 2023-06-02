// SPDX-License-Identifier: No license

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./PurchaseAndSaleAgreement.sol";

import "./libraries/AccessManager.sol";
import "./interfaces/ICashDistributor.sol";
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
    address public cashDistributor;

    // mortgage conditions
    IERC20 public currency;

    uint256 public lenderTokenAmount;
    uint256 public borrowerTokenAmount;

    // mortgage status

    bool initialized;
    uint256 public outstandingBalance;
    uint256 public lastAccruedInterest;

    modifier recalculatesDebt() {
        accrueInterest();
        _;
    }

    constructor(
        address _lender,
        address _borrower,
        address _purchaseAddress,
        address _currencyAddress,
        address _interestRateController,
        address _statusControllerAddress,
        address _cashDistributor,
        uint256 _lenderTokenAmount,
        uint256 _borrowerTokenAmount
    ) {
        lender = _lender;
        borrower = _borrower;
        purchaseAddress = _purchaseAddress;
        interestRateController = _interestRateController;
        statusControllerAddress = _statusControllerAddress;
        cashDistributor = _cashDistributor;
        currency = IERC20(_currencyAddress);
        lenderTokenAmount = _lenderTokenAmount;
        borrowerTokenAmount = _borrowerTokenAmount;
        propertyManager = msg.sender;
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

    function distributeCashflow() public recalculatesDebt {
        uint256 status = IStatusController(statusControllerAddress).status();

        uint256 balance = IERC20(currency).balanceOf(address(this));
        SafeERC20.safeTransfer(currency, cashDistributor, balance);

        uint256 lenderPayment = ICashDistributor(cashDistributor).distribute(
            status
        );

        outstandingBalance -= lenderPayment;
    }

    function accrueInterest() internal onlySender(propertyManager) {
        uint256 interestRate = IInterestRateController(interestRateController)
            .get();

        uint256 accruedTime = block.timestamp - lastAccruedInterest;
        uint256 effectiveInterestRate = (accruedTime * interestRate) /
            (365 days);

        uint256 accumulatedInterest = (outstandingBalance *
            effectiveInterestRate) / 1e18;

        outstandingBalance += accumulatedInterest;
    }

    function repay(uint256 amount)
        external
        onlySender(borrower)
        recalculatesDebt
    {
        SafeERC20.safeTransferFrom(currency, borrower, lender, amount);
        outstandingBalance -= amount;
    }
}
