// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../commons/Ownable.sol";
import "../commons/Pausable.sol";
import "../commons/ContextMixin.sol";
import "../commons/NativeMetaTransaction.sol";
import "../interfaces/IERC721Verifiable.sol";
import "../interfaces/IRoyaltiesManager.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";



contract MarketplaceV2 is Ownable, Pausable, NativeMetaTransaction {
  using Address for address;

  IERC20 public acceptedToken;

  struct Order {
    // Order ID
    bytes32 id;
    // Owner of the NFT
    address seller;
    // NFT registry address
    address nftAddress;
    // Price (in wei) for the published item
    uint256 price;
    // Time when this sale ends
    uint256 expiresAt;
  }

  // From ERC721 registry assetId to Order (to avoid asset collision)
  mapping (address => mapping(uint256 => Order)) public orderByAssetId;

  address public feesCollector;
  IRoyaltiesManager public royaltiesManager;

  uint256 public feesCollectorCutPerMillion;
  uint256 public royaltiesCutPerMillion;
  uint256 public publicationFeeInWei;


  bytes4 public constant InterfaceId_ValidateFingerprint = bytes4(
    keccak256("verifyFingerprint(uint256,bytes)")
  );

  bytes4 public constant ERC721_Interface = bytes4(0x80ac58cd);

  // EVENTS
  event OrderCreated(
    bytes32 id,
    uint256 indexed assetId,
    address indexed seller,
    address nftAddress,
    uint256 priceInWei,
    uint256 expiresAt
  );
  event OrderSuccessful(
    bytes32 id,
    uint256 indexed assetId,
    address indexed seller,
    address nftAddress,
    uint256 totalPrice,
    address indexed buyer
  );
  event OrderCancelled(
    bytes32 id,
    uint256 indexed assetId,
    address indexed seller,
    address nftAddress
  );

  event ChangedPublicationFee(uint256 publicationFee);
  event ChangedFeesCollectorCutPerMillion(uint256 feesCollectorCutPerMillion);
  event ChangedRoyaltiesCutPerMillion(uint256 royaltiesCutPerMillion);
  event FeesCollectorSet(address indexed oldFeesCollector, address indexed newFeesCollector);
  event RoyaltiesManagerSet(IRoyaltiesManager indexed oldRoyaltiesManager, IRoyaltiesManager indexed newRoyaltiesManager);


  /**
    * @dev Initialize this contract. Acts as a constructor
    * @param _owner - owner
    * @param _feesCollector - fees collector
    * @param _acceptedToken - Address of the ERC20 accepted for this marketplace
    * @param _royaltiesManager - Royalties manager contract
    * @param _feesCollectorCutPerMillion - fees collector cut per million
    * @param _royaltiesCutPerMillion - royalties cut per million
    */
  constructor (
    address _owner,
    address _feesCollector,
    address _acceptedToken,
    IRoyaltiesManager _royaltiesManager,
    uint256 _feesCollectorCutPerMillion,
    uint256 _royaltiesCutPerMillion
  )  {
    // EIP712 init
    _initializeEIP712('Decentraland Marketplace', '2');

    // Address init
    setFeesCollector(_feesCollector);
    setRoyaltiesManager(_royaltiesManager);

    // Fee init
    setFeesCollectorCutPerMillion(_feesCollectorCutPerMillion);
    setRoyaltiesCutPerMillion(_royaltiesCutPerMillion);

    require(_owner != address(0), "MarketplaceV2#constructor: INVALID_OWNER");
    transferOwnership(_owner);

    require(_acceptedToken.isContract(), "MarketplaceV2#constructor: INVALID_ACCEPTED_TOKEN");
    acceptedToken = IERC20(_acceptedToken);
  }


  /**
    * @dev Sets the publication fee that's charged to users to publish items
    * @param _publicationFee - Fee amount in wei this contract charges to publish an item
    */
  function setPublicationFee(uint256 _publicationFee) external onlyOwner {
    publicationFeeInWei = _publicationFee;
    emit ChangedPublicationFee(publicationFeeInWei);
  }

  /**
    * @dev Sets the share cut for the fees collector of the contract that's
    *  charged to the seller on a successful sale
    * @param _feesCollectorCutPerMillion - fees for the collector
    */
  function setFeesCollectorCutPerMillion(uint256 _feesCollectorCutPerMillion) public onlyOwner {
    feesCollectorCutPerMillion = _feesCollectorCutPerMillion;

    require(
      feesCollectorCutPerMillion + royaltiesCutPerMillion < 1000000,
      "MarketplaceV2#setFeesCollectorCutPerMillion: TOTAL_FEES_MUST_BE_BETWEEN_0_AND_999999"
    );

    emit ChangedFeesCollectorCutPerMillion(feesCollectorCutPerMillion);
  }

  /**
    * @dev Sets the share cut for the royalties that's
    *  charged to the seller on a successful sale
    * @param _royaltiesCutPerMillion - fees for royalties
    */
  function setRoyaltiesCutPerMillion(uint256 _royaltiesCutPerMillion) public onlyOwner {
    royaltiesCutPerMillion = _royaltiesCutPerMillion;

    require(
      feesCollectorCutPerMillion + royaltiesCutPerMillion < 1000000,
      "MarketplaceV2#setRoyaltiesCutPerMillion: TOTAL_FEES_MUST_BE_BETWEEN_0_AND_999999"
    );

    emit ChangedRoyaltiesCutPerMillion(royaltiesCutPerMillion);
  }

  /**
  * @notice Set the fees collector
  * @param _newFeesCollector - fees collector
  */
  function setFeesCollector(address _newFeesCollector) onlyOwner public {
      require(_newFeesCollector != address(0), "MarketplaceV2#setFeesCollector: INVALID_FEES_COLLECTOR");

      emit FeesCollectorSet(feesCollector, _newFeesCollector);
      feesCollector = _newFeesCollector;
  }

     /**
  * @notice Set the royalties manager
  * @param _newRoyaltiesManager - royalties manager
  */
  function setRoyaltiesManager(IRoyaltiesManager _newRoyaltiesManager) onlyOwner public {
      require(address(_newRoyaltiesManager).isContract(), "MarketplaceV2#setRoyaltiesManager: INVALID_ROYALTIES_MANAGER");


      emit RoyaltiesManagerSet(royaltiesManager, _newRoyaltiesManager);
      royaltiesManager = _newRoyaltiesManager;
  }


  /**
    * @dev Creates a new order
    * @param nftAddress - Non fungible registry address
    * @param assetId - ID of the published NFT
    * @param priceInWei - Price in Wei for the supported coin
    * @param expiresAt - Duration of the order (in hours)
    */
  function createOrder(
    address nftAddress,
    uint256 assetId,
    uint256 priceInWei,
    uint256 expiresAt
  )
    public
    whenNotPaused
  {
    _createOrder(
      nftAddress,
      assetId,
      priceInWei,
      expiresAt
    );
  }

  /**
    * @dev Cancel an already published order
    *  can only be canceled by seller or the contract owner
    * @param nftAddress - Address of the NFT registry
    * @param assetId - ID of the published NFT
    */
  function cancelOrder(address nftAddress, uint256 assetId) public whenNotPaused {
    _cancelOrder(nftAddress, assetId);
  }

  /**
    * @dev Executes the sale for a published NFT and checks for the asset fingerprint
    * @param nftAddress - Address of the NFT registry
    * @param assetId - ID of the published NFT
    * @param price - Order price
    * @param fingerprint - Verification info for the asset
    */
  function safeExecuteOrder(
    address nftAddress,
    uint256 assetId,
    uint256 price,
    bytes memory fingerprint
  )
   public
   whenNotPaused
  {
    _executeOrder(
      nftAddress,
      assetId,
      price,
      fingerprint
    );
  }

  /**
    * @dev Executes the sale for a published NFT
    * @param nftAddress - Address of the NFT registry
    * @param assetId - ID of the published NFT
    * @param price - Order price
    */
  function executeOrder(
    address nftAddress,
    uint256 assetId,
    uint256 price
  )
   public
   whenNotPaused
  {
    _executeOrder(
      nftAddress,
      assetId,
      price,
      ""
    );
  }

  /**
    * @dev Creates a new order
    * @param nftAddress - Non fungible registry address
    * @param assetId - ID of the published NFT
    * @param priceInWei - Price in Wei for the supported coin
    * @param expiresAt - Duration of the order (in hours)
    */
  function _createOrder(
    address nftAddress,
    uint256 assetId,
    uint256 priceInWei,
    uint256 expiresAt
  )
    internal
  {
    _requireERC721(nftAddress);

    address sender = _msgSender();

    IERC721Verifiable nftRegistry = IERC721Verifiable(nftAddress);
    address assetOwner = nftRegistry.ownerOf(assetId);

    require(sender == assetOwner, "MarketplaceV2#_createOrder: NOT_ASSET_OWNER");
    require(
      nftRegistry.getApproved(assetId) == address(this) || nftRegistry.isApprovedForAll(assetOwner, address(this)),
      "The contract is not authorized to manage the asset"
    );
    require(priceInWei > 0, "Price should be bigger than 0");
    require(expiresAt > block.timestamp + 1 minutes, "MarketplaceV2#_createOrder: INVALID_EXPIRES_AT");

    bytes32 orderId = keccak256(
      abi.encodePacked(
        block.timestamp,
        assetOwner,
        assetId,
        nftAddress,
        priceInWei
      )
    );

    orderByAssetId[nftAddress][assetId] = Order({
      id: orderId,
      seller: assetOwner,
      nftAddress: nftAddress,
      price: priceInWei,
      expiresAt: expiresAt
    });

    // Check if there's a publication fee and
    // transfer the amount to marketplace owner
    if (publicationFeeInWei > 0) {
      require(
        acceptedToken.transferFrom(sender, feesCollector, publicationFeeInWei),
        "MarketplaceV2#_createOrder: TRANSFER_FAILED"
      );
    }

    emit OrderCreated(
      orderId,
      assetId,
      assetOwner,
      nftAddress,
      priceInWei,
      expiresAt
    );
  }

  /**
    * @dev Cancel an already published order
    *  can only be canceled by seller or the contract owner
    * @param nftAddress - Address of the NFT registry
    * @param assetId - ID of the published NFT
    */
  function _cancelOrder(address nftAddress, uint256 assetId) internal returns (Order memory) {
    address sender = _msgSender();
    Order memory order = orderByAssetId[nftAddress][assetId];

    require(order.id != 0, "MarketplaceV2#_cancelOrder: INVALID_ORDER");
    require(order.seller == sender || sender == owner(), "MarketplaceV2#_cancelOrder: UNAUTHORIZED_USER");

    bytes32 orderId = order.id;
    address orderSeller = order.seller;
    address orderNftAddress = order.nftAddress;
    delete orderByAssetId[nftAddress][assetId];

    emit OrderCancelled(
      orderId,
      assetId,
      orderSeller,
      orderNftAddress
    );

    return order;
  }

  /**
    * @dev Executes the sale for a published NFT
    * @param nftAddress - Address of the NFT registry
    * @param assetId - ID of the published NFT
    * @param price - Order price
    * @param fingerprint - Verification info for the asset
    */
  function _executeOrder(
    address nftAddress,
    uint256 assetId,
    uint256 price,
    bytes memory fingerprint
  )
   internal returns (Order memory)
  {
    _requireERC721(nftAddress);

    address sender = _msgSender();

    IERC721Verifiable nftRegistry = IERC721Verifiable(nftAddress);

    if (nftRegistry.supportsInterface(InterfaceId_ValidateFingerprint)) {
      require(
        nftRegistry.verifyFingerprint(assetId, fingerprint),
        "MarketplaceV2#_executeOrder: INVALID_FINGERPRINT"
      );
    }
    Order memory order = orderByAssetId[nftAddress][assetId];

    require(order.id != 0, "MarketplaceV2#_executeOrder: ASSET_NOT_FOR_SALE");

    require(order.seller != address(0), "MarketplaceV2#_executeOrder: INVALID_SELLER");
    require(order.seller != sender, "MarketplaceV2#_executeOrder: SENDER_IS_SELLER");
    require(order.price == price, "MarketplaceV2#_executeOrder: PRICE_MISMATCH");
    require(block.timestamp < order.expiresAt, "MarketplaceV2#_executeOrder: ORDER_EXPIRED");
    require(order.seller == nftRegistry.ownerOf(assetId), "MarketplaceV2#_executeOrder: SELLER_NOT_OWNER");


    delete orderByAssetId[nftAddress][assetId];

    uint256 feesCollectorShareAmount;
    uint256 royaltiesShareAmount;
    address royaltiesReceiver;

    // Royalties share
    if (royaltiesCutPerMillion > 0) {
      royaltiesShareAmount = (price * royaltiesCutPerMillion) / 1000000;

      (bool success, bytes memory res) = address(royaltiesManager).staticcall(
        abi.encodeWithSelector(
            royaltiesManager.getRoyaltiesReceiver.selector,
            address(nftRegistry),
            assetId
        )
      );

      if (success) {
        (royaltiesReceiver) = abi.decode(res, (address));
        if (royaltiesReceiver != address(0)) {
          require(
            acceptedToken.transferFrom(sender, royaltiesReceiver, royaltiesShareAmount),
            "MarketplaceV2#_executeOrder: TRANSFER_FEES_TO_ROYALTIES_RECEIVER_FAILED"
          );
        }
      }
    }

    // Fees collector share
    {
      feesCollectorShareAmount = (price * feesCollectorCutPerMillion) / 1000000;
      uint256 totalFeeCollectorShareAmount = feesCollectorShareAmount;

      if (royaltiesShareAmount > 0 && royaltiesReceiver == address(0)) {
        totalFeeCollectorShareAmount += royaltiesShareAmount;
      }

      if (totalFeeCollectorShareAmount > 0) {
        require(
          acceptedToken.transferFrom(sender, feesCollector, totalFeeCollectorShareAmount),
          "MarketplaceV2#_executeOrder: TRANSFER_FEES_TO_FEES_COLLECTOR_FAILED"
        );
      }
    }

    // Transfer sale amount to seller
    require(
      acceptedToken.transferFrom(sender, order.seller, price - royaltiesShareAmount - feesCollectorShareAmount),
      "MarketplaceV2#_executeOrder: TRANSFER_AMOUNT_TO_SELLER_FAILED"
    );

    // Transfer asset owner
    nftRegistry.safeTransferFrom(
      order.seller,
      sender,
      assetId
    );

    emit OrderSuccessful(
      order.id,
      assetId,
      order.seller,
      nftAddress,
      price,
      sender
    );

    return order;
  }

  function _requireERC721(address nftAddress) internal view {
    require(nftAddress.isContract(), "MarketplaceV2#_requireERC721: INVALID_NFT_ADDRESS");

    IERC721 nftRegistry = IERC721(nftAddress);
    require(
      nftRegistry.supportsInterface(ERC721_Interface),
      "MarketplaceV2#_requireERC721: INVALID_ERC721_IMPLEMENTATION"
    );
  }
}
