import { expect } from "chai";
import { ethers } from "hardhat";
import {
  ApprovalManager,
  ERC20,
  ERC721,
  MintableNFT,
  MintableToken,
  PurchaseAndSaleAgreement,
} from "../typechain-types";

describe("PurchaseAndSaleAgreement", () => {
  let purchaseAndSaleAgreement: PurchaseAndSaleAgreement;

  let erc20Address: MintableToken;

  let asset: MintableNFT;

  let approvalManager: ApprovalManager;

  let buyer: string;
  let seller: string;

  const ASSET_ID = 0;
  const AMOUNT = "1000000000000000000";
  const DEPOSIT_LIFESPAN = "1000000000";

  before(async () => {
    const MintableToken = await ethers.getContractFactory("MintableToken");
    erc20Address = await MintableToken.deploy("Test", "TST");

    const MintableNFT = await ethers.getContractFactory("MintableNFT");
    asset = await MintableNFT.deploy("Test", "TST");

    const ApprovalManaager = await ethers.getContractFactory("ApprovalManager");
    const stakeholderAddresses = await ethers
      .getSigners()
      .then((signers) => signers.slice(0, 2).map((_) => _.address));
    approvalManager = await ApprovalManaager.deploy(stakeholderAddresses);

    [buyer, seller] = stakeholderAddresses;

    const PurchaseAndSaleAgreement = await ethers.getContractFactory(
      "PurchaseAndSaleAgreement"
    );

    purchaseAndSaleAgreement = await PurchaseAndSaleAgreement.deploy(
      asset.address,
      ASSET_ID,
      erc20Address.address,
      AMOUNT,
      DEPOSIT_LIFESPAN,
      approvalManager.address,
      buyer,
      seller
    );
  });

  describe("correct initialization", () => {
    it("should be deployed", async function () {
      expect(purchaseAndSaleAgreement.address).not.to.be.undefined;
    });

    it("should have the correct asset", async function () {
      expect(await purchaseAndSaleAgreement.assetAddress()).to.equal(
        asset.address
      );
    });

    it("should have the correct asset id", async function () {
      expect(await purchaseAndSaleAgreement.tokenId()).to.equal(ASSET_ID);
    });

    it("should have the correct erc20", async function () {
      expect(await purchaseAndSaleAgreement.tokenAddress()).to.equal(
        erc20Address.address
      );
    });

    it("should have the correct amount", async function () {
      expect(await purchaseAndSaleAgreement.amount()).to.equal(AMOUNT);
    });

    it("should have the correct stakeholders", async function () {
      expect(await purchaseAndSaleAgreement.buyer()).to.equal(buyer);
      expect(await purchaseAndSaleAgreement.seller()).to.equal(seller);
    });
  });

  describe("deposit", () => {
    let sellerAsset: MintableNFT;
    let sellerPurchaseAndSaleAgreement: PurchaseAndSaleAgreement;

    before(async () => {
      sellerAsset = asset.connect(ethers.provider.getSigner(seller));
      sellerPurchaseAndSaleAgreement = purchaseAndSaleAgreement.connect(
        ethers.provider.getSigner(seller)
      );
    });

    it("should deposit token id", async function () {
      await sellerAsset.mint(seller, ASSET_ID);
      await sellerAsset.approve(purchaseAndSaleAgreement.address, ASSET_ID);
      await sellerPurchaseAndSaleAgreement.depositAsset();
    });

    it("should deposit the correct amount", async function () {
      expect(sellerPurchaseAndSaleAgreement.depositAsset()).to.be.revertedWith(
        "PurchaseAndSaleAgreement: ALREADY_DEPOSITED"
      );
    });

    it("should deposit the correct amount", async function () {
      expect(sellerPurchaseAndSaleAgreement.withdrawAsset()).to.be.revertedWith(
        "PurchaseAndSaleAgreement: DEADLINE_NOT_REACHED"
      );
    });
  });

  describe("exchange", () => {
    let buyerErc20: MintableToken;
    let buyerPurchaseAndSaleAgreement: PurchaseAndSaleAgreement;

    let buyerApproval: ApprovalManager;
    let sellerApproval: ApprovalManager;

    before(async () => {
      buyerPurchaseAndSaleAgreement = purchaseAndSaleAgreement.connect(
        ethers.provider.getSigner(buyer)
      );
      buyerErc20 = erc20Address.connect(ethers.provider.getSigner(buyer));
      buyerApproval = approvalManager.connect(ethers.provider.getSigner(buyer));
      sellerApproval = approvalManager.connect(
        ethers.provider.getSigner(seller)
      );
    });

    it("should fail without approvals", async function () {
      await buyerErc20.mint(buyer, AMOUNT);
      await buyerErc20.approve(purchaseAndSaleAgreement.address, AMOUNT);
      await expect(buyerPurchaseAndSaleAgreement.exchange()).to.be.revertedWith(
        "PurchaseAndSaleAgreement: PENDING_STAKEHOLDERS_APPROVALS"
      );
    });

    it("should perform asset exchange", async function () {
      await buyerErc20.mint(buyer, AMOUNT);
      await buyerErc20.approve(purchaseAndSaleAgreement.address, AMOUNT);
      await buyerApproval.approve();
      await sellerApproval.approve();
      await buyerPurchaseAndSaleAgreement.exchange();
      await asset
        .ownerOf(ASSET_ID)
        .then((owner) => expect(owner).to.equal(buyer));
    });
  });
});
