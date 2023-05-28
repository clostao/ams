//SPDX-License-Identifier: No-License

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./controllers/ApprovalManager.sol";

import "./libraries/AccessManager.sol";

pragma solidity ^0.8.13;

contract PurchaseAndSaleAgreement is AccessManager {
    // Asset configuration
    address public assetAddress;
    uint256 public tokenId;

    // ERC20 configuration
    address public tokenAddress;
    uint256 public amount;

    // contract configuration
    address public buyer;
    address public seller;

    uint256 public depositLifeSpan;
    address public approvalManagerAddress;

    // contract status
    uint256 public deadline = 0;

    constructor(
        address _assetAddress,
        uint256 _tokenId,
        address _tokenAddress,
        uint256 _amount,
        uint256 _depositLifeSpan,
        address _approvalManagerAddress,
        address _buyer,
        address _seller
    ) {
        assetAddress = _assetAddress;
        tokenId = _tokenId;

        tokenAddress = _tokenAddress;
        amount = _amount;

        buyer = _buyer;
        seller = _seller;

        depositLifeSpan = _depositLifeSpan;
        approvalManagerAddress = _approvalManagerAddress;
    }

    function depositAsset() external onlySender(seller) {
        require(deadline == 0, "PurchaseAndSaleAgreement: ALREADY_DEPOSITED");

        IERC721(assetAddress).transferFrom(msg.sender, address(this), tokenId);
        deadline = block.timestamp + depositLifeSpan;
    }

    function withdrawAsset() external onlySender(seller) {
        require(
            block.timestamp > deadline,
            "PurchaseAndSaleAgreement: DEADLINE_NOT_REACHED"
        );

        IERC721(assetAddress).transferFrom(address(this), msg.sender, tokenId);
    }

    function exchange() external onlySender(buyer) {
        bool stakeholderApproved = ApprovalManager(approvalManagerAddress)
            .isApproved();
        require(
            stakeholderApproved,
            "PurchaseAndSaleAgreement: PENDING_STAKEHOLDERS_APPROVALS"
        );
        IERC721(assetAddress).transferFrom(address(this), buyer, tokenId);
        SafeERC20.safeTransferFrom(IERC20(tokenAddress), buyer, seller, amount);
    }
}
