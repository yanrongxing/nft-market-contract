// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../../interfaces/IRarities.sol";
import "../../commons//OwnableInitializable.sol";
import "../../commons//NativeMetaTransaction.sol";
import "../../tokens/ERC721Initializable.sol";
import "../../libs/String.sol";

abstract contract ERC721BaseCollectionV3 is OwnableInitializable, ERC721Initializable, NativeMetaTransaction {
    using String for bytes32;
    using String for uint256;
    using String for address;
    using SafeMath for uint256;

    bytes32 constant public COLLECTION_HASH = keccak256("Decentraland Collection");
    uint8 constant public ITEM_ID_BITS = 40;
    uint8 constant public ISSUED_ID_BITS = 216;
    uint216 constant public MAX_ISSUED_ID = type(uint216).max;
    bytes32 constant internal EMPTY_CONTENT = bytes32(0);

    mapping(address => bool) public globalMinters;

    // Status
    uint256 public createdAt;
    bool public isInitialized;

    event BaseURI(string _oldBaseURI, string _newBaseURI);
    event SetGlobalMinter(address indexed _minter, bool _value);

   /*
    * Init functions
    */

    /**
     * @notice Init the contract
     */
    function initImplementation() public {
        require(!isInitialized, "initialize: ALREADY_INITIALIZED");
        isInitialized = true;
    }

    /**
     * @notice Create the contract
     * @param _name - name of the contract
     * @param _symbol - symbol of the contract
     * @param _baseURI - base URI for token URIs
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) external virtual {
        initImplementation();


        // Ownable init
        _initOwnable();
        // EIP712 init
        _initializeEIP712('Decentraland Collection', '2');
        // ERC721 init
        _initERC721(_name, _symbol);
        // Base URI init
        setBaseURI(_baseURI);

        createdAt = block.timestamp;

    }

    function _isMiner() internal view returns (bool) {
        return globalMinters[_msgSender()];
    }


    modifier onlyMiner() {
        require(
            _isMiner(),
            "onlyMiner: CALLER_IS_NOT_MINER"
        );
        _;
    }

    /**
     * @notice Set allowed account to manage items.
     * @param _minter - minter addresses
     * @param _value - values array
     */
    function setMinter(address _minter, bool _value) public onlyOwner {

        require(_minter != address(0), "setMinters: INVALID_MINTER_ADDRESS");
        require(globalMinters[_minter] != _value, "setMinters: VALUE_IS_THE_SAME");

        globalMinters[_minter] = _value;
        emit SetGlobalMinter(_minter, _value);
        
    }

    /**
     * @notice Issue tokens by item ids.
     * @dev Will throw if the items have reached its maximum or is invalid
     * @param _beneficiaries - owner of the tokens
     * @param _tokenIds - token ids
     */
    function mints(address[] calldata _beneficiaries, uint256[] calldata _tokenIds) external virtual onlyMiner{
        
        require(_beneficiaries.length == _tokenIds.length, "issueTokens: LENGTH_MISMATCH");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            super._mint(_beneficiaries[i], _tokenIds[i]);
        }
    }

    /**
     * @notice Issue a new token of the specified item.
     * @dev Will throw if the item has reached its maximum or is invalid
     * @param _beneficiary - owner of the token
     * @param _tokenId - token id
     */
    function mint(address _beneficiary, uint256 _tokenId) external virtual onlyMiner{
        
        // Mint token to beneficiary
        super._mint(_beneficiary, _tokenId);
    }

    function burn(uint256 tokenId) public virtual onlyMiner{
        _burn(tokenId);
    }


    function exists(uint256 tokenId) public view virtual returns (bool existsRes) {
        existsRes =  _exists(tokenId);
    }

    /*
    * URI functions
    */

    /**
     * @notice Set Base URI
     * @param _baseURI - base URI for token URIs
     */
    function setBaseURI(string memory _baseURI) public onlyOwner {
        emit BaseURI(baseURI(), _baseURI);
        _setBaseURI(_baseURI);
    }


    /*
    * Batch Transfer functions
    */

    /**
     * @notice Transfers the ownership of given tokens ID to another address.
     * Usage of this method is discouraged, use {safeBatchTransferFrom} whenever possible.
     * Requires the msg.sender to be the owner, approved, or operator.
     * @param _from current owner of the token
     * @param _to address to receive the ownership of the given token ID
     * @param _tokenIds uint256 ID of the token to be transferred
     */
    function batchTransferFrom(address _from, address _to, uint256[] calldata _tokenIds) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    /**
     * @notice Safely transfers the ownership of given token IDs to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param _from - current owner of the token
     * @param _to - address to receive the ownership of the given token ID
     * @param _tokenIds - uint256 ID of the tokens to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeBatchTransferFrom(address _from, address _to, uint256[] memory _tokenIds, bytes memory _data) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], _data);
        }
    }




}
