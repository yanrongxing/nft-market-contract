
// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../commons/Ownable.sol";
import "../commons/Pausable.sol";
import "../commons/ContextMixin.sol";
import "../commons/NativeMetaTransaction.sol";
import "../interfaces/IERC721Verifiable.sol";
import "../interfaces/IRoyaltiesManager.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";



contract MarketplaceV3 is Ownable, Pausable, NativeMetaTransaction {
  using Address for address;

  IERC20 public acceptedToken;

  struct Order {
    // Order ID
    bytes32 id;
    // Owner of the NFT
    address seller;
    // NFT registry address
    address tokenAddress;
    uint256 tokenId;
    // Price (in wei) for the published item
    uint256 price;
    // Time when this sale ends
    uint256 expiresAt;
    // Time when this sale ends
    uint256 quantity;
    
  }

  // From ERC721 registry tokenId to Order (to avoid asset collision)
  mapping(bytes32 => Order) public orderById;

  address public feesCollector;

  uint256 public feesCollectorCutPerMillion;
  uint256 public publicationFeeInWei;


  bytes4 public constant InterfaceId_ValidateFingerprint = bytes4(
    keccak256("verifyFingerprint(uint256,bytes)")
  );

  bytes4 public constant ERC721_Interface = bytes4(0x80ac58cd);
  bytes4 public constant ERC1155_Interface = bytes4(0xd9b67a26);
  

  // EVENTS
  event OrderCreated(
    bytes32 id,
    uint256 indexed tokenId,
    address indexed seller,
    address tokenAddress,
    uint256 priceInWei,
    uint256 expiresAt,
    uint256 quantity
  );
  event OrderSuccessful(
    bytes32 id,
    uint256 indexed tokenId,
    address indexed seller,
    address tokenAddress,
    address indexed buyer,
    uint256 quantity
  );
  event OrderCancelled(
    bytes32 id,
    uint256 indexed tokenId,
    address indexed seller,
    address tokenAddress,
    uint256 quantity
  );

  event ChangedPublicationFee(uint256 publicationFee);
  event ChangedFeesCollectorCutPerMillion(uint256 feesCollectorCutPerMillion);
  event FeesCollectorSet(address indexed oldFeesCollector, address indexed newFeesCollector);


  /**
    * @dev Initialize this contract. Acts as a constructor
    * @param _owner - owner
    * @param _feesCollector - fees collector
    * @param _acceptedToken - Address of the ERC20 accepted for this marketplace
    * @param _feesCollectorCutPerMillion - fees collector cut per million
    */
  constructor (
    address _owner,
    address _feesCollector,
    address _acceptedToken,
    uint256 _feesCollectorCutPerMillion
  )  {
    // EIP712 init
    _initializeEIP712('Decentraland Marketplace', '2');

    // Address init
    setFeesCollector(_feesCollector);

    // Fee init
    setFeesCollectorCutPerMillion(_feesCollectorCutPerMillion);

    require(_owner != address(0), "MarketplaceV3#constructor: INVALID_OWNER");
    transferOwnership(_owner);

    require(_acceptedToken.isContract(), "MarketplaceV3#constructor: INVALID_ACCEPTED_TOKEN");
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
      feesCollectorCutPerMillion  < 1000000,
      "MarketplaceV3#setFeesCollectorCutPerMillion: TOTAL_FEES_MUST_BE_BETWEEN_0_AND_999999"
    );

    emit ChangedFeesCollectorCutPerMillion(feesCollectorCutPerMillion);
  }



  /**
  * @notice Set the fees collector
  * @param _newFeesCollector - fees collector
  */
  function setFeesCollector(address _newFeesCollector) onlyOwner public {
      require(_newFeesCollector != address(0), "MarketplaceV3#setFeesCollector: INVALID_FEES_COLLECTOR");

      emit FeesCollectorSet(feesCollector, _newFeesCollector);
      feesCollector = _newFeesCollector;
  }

  /**
    * @dev Creates a new order
    * @param tokenAddress - Non fungible registry address
    * @param tokenId - ID of the published NFT
    * @param priceInWei - Price in Wei for the supported coin
    * @param expiresAt - Duration of the order (in hours)
    */
  function createOrder(
    address tokenAddress,
    uint256 tokenId,
    uint256 priceInWei,
    uint256 expiresAt,
    uint256 quantity
  )
    public
    whenNotPaused
  {
    _createOrder(
      tokenAddress,
      tokenId,
      priceInWei,
      expiresAt,
      quantity
    );
  }

  /**
    * @dev Cancel an already published order
    *  can only be canceled by seller or the contract owner
    * @param id - order id
    */
  function cancelOrder(bytes32 id) public whenNotPaused {
    _cancelOrder(id);
  }

  /**
    * @dev Executes the sale for a published NFT and checks for the asset fingerprint
    * @param id order id
    * @param fingerprint - Verification info for the asset
    */
  function safeExecuteOrder(
    bytes32 id,
    uint256 quantity,
    bytes memory fingerprint
  )
   public
   whenNotPaused
  {
    _executeOrder(
      id,
      quantity,
      fingerprint
    );
  }

  /**
    * @dev Executes the sale for a published NFT
    * @param id - order id
    * @param quantity - Order quantity
    */
  function executeOrder(
    bytes32 id,
    uint256 quantity
  )
   public
   whenNotPaused
  {
    _executeOrder(
      id,
      quantity,
      ""
    );
  }

  /**
    * @dev Creates a new order
    * @param tokenAddress - Non fungible registry address
    * @param tokenId - ID of the published NFT
    * @param priceInWei - Price in Wei for the supported coin
    * @param expiresAt - Duration of the order (in hours)
    */
  function _createOrder(
    address tokenAddress,
    uint256 tokenId,
    uint256 priceInWei,
    uint256 expiresAt,
    uint256 quantity
  )
    internal
  {
    bool isERC721;
    bool isERC1155;
    (isERC721,isERC1155) = _requireERC721OrERC1155(tokenAddress);


    address sender = _msgSender();
    IERC721Verifiable nftRegistry = IERC721Verifiable(tokenAddress);
    IERC1155 erc1155Registry = IERC1155(tokenAddress);
    if(isERC721){
      address assetOwner = nftRegistry.ownerOf(tokenId);

      require(sender == assetOwner, "MarketplaceV3#_createOrder: NOT_ASSET_OWNER");
      require(
        nftRegistry.getApproved(tokenId) == address(this) || nftRegistry.isApprovedForAll(assetOwner, address(this)),
        "The contract is not authorized to manage the asset"
      );
    }
    if(isERC1155){
      uint256 balance = erc1155Registry.balanceOf(sender, tokenId);
      require(balance >= quantity, "MarketplaceV3#_createOrder: ERC1155 Insufficient balance");
      require(
        erc1155Registry.isApprovedForAll(sender, address(this)),
        "The contract is not authorized to manage the asset"
      );
    }


    require(priceInWei > 0, "Price should be bigger than 0");
    require(expiresAt > block.timestamp + 1 minutes, "MarketplaceV3#_createOrder: INVALID_EXPIRES_AT");

    bytes32 orderId = keccak256(
      abi.encodePacked(
        block.timestamp,
        sender,
        tokenId,
        tokenAddress,
        priceInWei,
        quantity
      )
    );

    orderById[orderId] = Order({
      id: orderId,
      seller: sender,
      tokenAddress: tokenAddress,
      tokenId: tokenId,
      price: priceInWei,
      expiresAt: expiresAt,
      quantity: quantity
    });

    // Check if there's a publication fee and
    // transfer the amount to marketplace owner
    if (publicationFeeInWei > 0) {
      require(
        acceptedToken.transferFrom(sender, feesCollector, publicationFeeInWei),
        "MarketplaceV3#_createOrder: TRANSFER_FAILED"
      );
    }

    emit OrderCreated(
      orderId,
      tokenId,
      sender,
      tokenAddress,
      priceInWei,
      expiresAt,
      quantity
    );
  }

  /**
    * @dev Cancel an already published order
    *  can only be canceled by seller or the contract owner
    * @param id - order id
    */
  function _cancelOrder(bytes32 id) internal returns (Order memory) {
    address sender = _msgSender();
    Order memory order = orderById[id];

    require(order.id != 0, "MarketplaceV3#_cancelOrder: INVALID_ORDER");
    require(order.seller == sender || sender == owner(), "MarketplaceV3#_cancelOrder: UNAUTHORIZED_USER");

    bytes32 orderId = order.id;
    address orderSeller = order.seller;
    address ordertokenAddress = order.tokenAddress;
    uint256 quantity = order.quantity;
    uint256 tokenId = order.tokenId;
    delete orderById[id];

    emit OrderCancelled(
      orderId,
      tokenId,
      orderSeller,
      ordertokenAddress,
      quantity
    );

    return order;
  }

  /**
    * @dev Executes the sale for a published NFT
    * @param id order id
    * @param fingerprint - Verification info for the asset
    */
  function _executeOrder(
    bytes32 id,
    uint256 quantity,
    bytes memory fingerprint
  )
   internal returns (Order memory)
  {
    Order memory order = orderById[id];
    
    uint256 orderPrice = order.price * quantity;

    bool isERC721;
    bool isERC1155;
    (isERC721,isERC1155) = _requireERC721OrERC1155(order.tokenAddress);



    IERC721Verifiable nftRegistry = IERC721Verifiable(order.tokenAddress);
    IERC1155 erc1155Registry = IERC1155(order.tokenAddress);

    if (isERC721 && nftRegistry.supportsInterface(InterfaceId_ValidateFingerprint)) {
      require(
        nftRegistry.verifyFingerprint(order.tokenId, fingerprint),
        "MarketplaceV2#_executeOrder: INVALID_FINGERPRINT"
      );
    }


    require(order.id != 0, "MarketplaceV3#_executeOrder: ASSET_NOT_FOR_SALE");

    require(order.seller != address(0), "MarketplaceV3#_executeOrder: INVALID_SELLER");
    require(order.seller != _msgSender(), "MarketplaceV3#_executeOrder: SENDER_IS_SELLER");
    require(block.timestamp < order.expiresAt, "MarketplaceV3#_executeOrder: ORDER_EXPIRED");
    require(quantity <= order.quantity, "MarketplaceV3#_executeOrder: Inventory shortage");

    if(isERC721){
      require(order.seller == nftRegistry.ownerOf(order.tokenId), "MarketplaceV3#_executeOrder: SELLER_NOT_OWNER");
    }else if(isERC1155){
      uint256 balance = erc1155Registry.balanceOf(order.seller, order.tokenId);
      require(balance >= quantity, "MarketplaceV3#_createOrder: ERC1155 Insufficient balance");
    }

    
    // Fees collector share
    uint256 feesCollectorShareAmount = (orderPrice * feesCollectorCutPerMillion) / 1000000;
    
    if (feesCollectorShareAmount > 0) {
      require(
        acceptedToken.transferFrom(_msgSender(), feesCollector, feesCollectorShareAmount),
        "MarketplaceV3#_executeOrder: TRANSFER_FEES_TO_FEES_COLLECTOR_FAILED"
      );
    }
    

    // Transfer sale amount to seller
    require(
      acceptedToken.transferFrom(_msgSender(), order.seller, orderPrice - feesCollectorShareAmount),
      "MarketplaceV3#_executeOrder: TRANSFER_AMOUNT_TO_SELLER_FAILED"
    );

    // Transfer asset owner
    if(isERC721){
      nftRegistry.safeTransferFrom(
        order.seller,
        _msgSender(),
        order.tokenId
      );
    }else if(isERC1155){
      erc1155Registry.safeTransferFrom(
        order.seller,
        _msgSender(),
        order.tokenId,
        quantity,
        id
      );
      orderById[id].quantity = orderById[id].quantity-quantity;
    }

    if(orderById[id].quantity <= 0){
      delete orderById[id];
    }
    emit OrderSuccessful(
      id,
      order.tokenId,
      order.seller,
      order.tokenAddress,
      _msgSender(),
      quantity
    );

    return order;
  }

  function _requireERC721OrERC1155(address tokenAddress) internal view returns(bool isERC721,bool isERC1155) {
    require(tokenAddress.isContract(), "MarketplaceV3#_requireERC721OrERC1155: INVALID_ERC721OrERC1155_ADDRESS");

    IERC721 nftRegistry = IERC721(tokenAddress);
    IERC1155 erc1155Registry = IERC1155(tokenAddress);
    isERC721 = nftRegistry.supportsInterface(ERC721_Interface);
    isERC1155 = erc1155Registry.supportsInterface(ERC1155_Interface);
    require(
      isERC721
      || isERC1155
      ,
      "MarketplaceV3#_requireERC721OrERC1155: INVALID_ERC721OrERC1155_IMPLEMENTATION"
    );
  }
}
