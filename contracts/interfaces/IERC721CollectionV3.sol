// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;


interface IERC721CollectionV3 {
    function COLLECTION_HASH() external view returns (bytes32);
    function setMinter(address _minter, bool _value) external;
    function mint(address _beneficiary, uint256 _tokenId) external;
    function burn(uint256 tokenId)external;
    function exists(uint256 tokenId) external view  returns (bool);
    function setBaseURI(string memory _baseURI) external;
    function decodeTokenId(uint256 _tokenId) external view returns (uint256, uint256);
    function setApproved(bool _value) external;
    /// @dev For some reason using the Struct Item as an output parameter fails, but works as an input parameter
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) external;
}