// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IForwarder.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC721CollectionV3.sol";
import "../interfaces/IERC721CollectionFactoryV2.sol";
import "../interfaces/IRarities.sol";
import "../commons/OwnableInitializable.sol";
import "../commons/NativeMetaTransaction.sol";


contract CollectionManagerV2 is OwnableInitializable, NativeMetaTransaction {

    using SafeMath for uint256;



    mapping(bytes4 => bool) public allowedCommitteeMethods;



    /**
    * @notice Create the contract
    */
    constructor(
    ) {
        // EIP712 init
        _initializeEIP712('Decentraland Collection Manager', '1');
        // Ownable init
        _initOwnable();
    }









    /**
    * @notice Create a collection
    * @param _forwarder - forwarder contract owner of the collection factory
    * @param _factory - collection factory
    * @param _salt - arbitrary 32 bytes hexa
    * @param _name - name of the contract
    * @param _symbol - symbol of the contract
    * @param _baseURI - base URI for token URIs
    */
    function createCollection(
        IForwarder _forwarder,
        IERC721CollectionFactoryV2 _factory,
        bytes32 _salt,
        string memory _name,
        string memory _symbol,
        string memory _baseURI
     ) external onlyOwner{
        require(address(_forwarder) != address(this), "CollectionManager#createCollection: FORWARDER_CANT_BE_THIS");

        bytes memory data = abi.encodeWithSelector(
            IERC721CollectionV3.initialize.selector,
            _name,
            _symbol,
            _baseURI
        );

        (bool success,) = _forwarder.forwardCall(address(_factory), abi.encodeWithSelector(_factory.createCollection.selector, _salt, data));
        require(
            success,
             "CollectionManager#createCollection: FORWARD_FAILED"
        );
    }

    /**
    * @notice Manage a collection
    * @param _forwarder - forwarder contract owner of the collection factory
    * @param _collection - collection to be managed
    * @param _data - call data to be used
    */
    function manageCollection(IForwarder _forwarder, IERC721CollectionV3 _collection, bytes calldata _data) external onlyOwner{
        require(address(_forwarder) != address(this), "CollectionManager#manageCollection: FORWARDER_CANT_BE_THIS");
        
        bool success;
        bytes memory res;

        (success, res) = address(_collection).staticcall(abi.encodeWithSelector(_collection.COLLECTION_HASH.selector));
        require(
            success && abi.decode(res, (bytes32)) == keccak256("Decentraland Collection"),
            "CollectionManager#manageCollection: INVALID_COLLECTION"
        );

        (success,) = _forwarder.forwardCall(address(_collection), _data);
        require(
            success,
            "CollectionManager#manageCollection: FORWARD_FAILED"
        );
    }
}