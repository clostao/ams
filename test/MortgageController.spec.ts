import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers, network } from "hardhat";
import {
  CashDistributor,
  FixedInterestRateController,
  IncomeStatusController,
  MintableToken,
  MortgageController,
} from "../typechain-types";
import { BigNumber } from "ethers";

describe("MortgageController", () => {
  let mortgageController: MortgageController;
  let interestRateController: FixedInterestRateController;
  let statusController: IncomeStatusController;
  let cashDistributor: CashDistributor;

  let mintableToken: MintableToken;

  const LENDER_AMOUNT = "1000000000000000000";
  const BORROWER_AMOUNT = "0";
  const INTREST_ANNUAL_RATE = "100000000000000000";

  let lender: SignerWithAddress;
  let borrower: SignerWithAddress;

  before(async () => {
    [lender, borrower] = await ethers.getSigners().then((_) => _.slice(0, 2));

    mintableToken = await ethers
      .getContractFactory("MintableToken")
      .then((cf) => cf.deploy("Test", "TST"));

    interestRateController = await ethers
      .getContractFactory("FixedInterestRateController")
      .then((cf) => cf.deploy(INTREST_ANNUAL_RATE));

    statusController = await ethers
      .getContractFactory("IncomeStatusController")
      .then((cf) => cf.deploy());

    cashDistributor = await ethers
      .getContractFactory("CashDistributor")
      .then((cf) =>
        cf.deploy(mintableToken.address, lender.address, borrower.address)
      );

    const mockedPurchaseAgreement = await ethers
      .getContractFactory("MockPurchaseAndSaleAgreement")
      .then((cf) => cf.deploy(mintableToken.address));

    mortgageController = await ethers
      .getContractFactory("MortgageController")
      .then((cf) =>
        cf.deploy(
          lender.address,
          borrower.address,
          mockedPurchaseAgreement.address,
          mintableToken.address,
          interestRateController.address,
          statusController.address,
          cashDistributor.address,
          LENDER_AMOUNT,
          BORROWER_AMOUNT
        )
      );
  });

  it("Init", async () => {
    expect(await mortgageController.lender()).to.equal(lender.address);
    expect(await mortgageController.borrower()).to.equal(borrower.address);
    expect(await mortgageController.currency()).to.equal(mintableToken.address);
    expect(await mortgageController.statusControllerAddress()).to.equal(
      statusController.address
    );
    expect(await mortgageController.cashDistributor()).to.equal(
      cashDistributor.address
    );
    expect(await mortgageController.lenderTokenAmount()).to.equal(
      LENDER_AMOUNT
    );
    expect(await mortgageController.borrowerTokenAmount()).to.equal(
      BORROWER_AMOUNT
    );
  });

  describe("Interest Accruing", () => {
    it("init successfully", async () => {
      await mintableToken.connect(lender).mint(lender.address, LENDER_AMOUNT);
      await mintableToken
        .connect(lender)
        .approve(mortgageController.address, LENDER_AMOUNT);
      await mortgageController.init();
    });

    it("failed to init twice", async () => {
      await expect(mortgageController.init()).to.be.revertedWith(
        "MortgageController: ALREADY_EXECUTED"
      );
    });

    it("initial outstanding balance macthes LENDER_AMOUNT", async () => {
      expect(await mortgageController.outstandingBalance()).to.be.equal(
        LENDER_AMOUNT
      );
    });

    it("initial outstanding balance macthes LENDER_AMOUNT", async () => {
      expect(await mortgageController.outstandingBalance()).to.be.equal(
        LENDER_AMOUNT
      );
    });

    it("distribute cashflow increases outstanding balance", async () => {
      expect(await mortgageController.outstandingBalance()).to.be.equal(
        LENDER_AMOUNT
      );

      const nextBlockTimestamp = await mortgageController
        .lastAccruedInterest()
        .then((_) => _.add(31536000));

      await time.setNextBlockTimestamp(nextBlockTimestamp);

      await mortgageController.distributeCashflow();

      const expectedOutstandingBalance = BigNumber.from(LENDER_AMOUNT)
        .mul(11)
        .div(10);
      expect(await mortgageController.outstandingBalance()).to.be.equal(
        expectedOutstandingBalance
      );
    });
  });
});
