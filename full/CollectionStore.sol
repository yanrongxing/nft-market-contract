// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File @openzeppelin/contracts/math/SafeMath.sol@v3.4.2

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


// File contracts/interfaces/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;


interface IERC20 {
    function balanceOf(address from) external view returns (uint256);
    function transferFrom(address from, address to, uint tokens) external returns (bool);
    function transfer(address to, uint tokens) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function burn(uint256 amount) external;
}


// File contracts/interfaces/IERC721CollectionV2.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;


interface IERC721CollectionV2 {
    function COLLECTION_HASH() external view returns (bytes32);

    struct ItemParam {
        string rarity;
        uint256 price;
        address beneficiary;
        string metadata;
    }
    function creator() external view returns (address);
    function issueTokens(address[] calldata _beneficiaries, uint256[] calldata _itemIds) external;
    function decodeTokenId(uint256 _tokenId) external view returns (uint256, uint256);
    function setApproved(bool _value) external;
    /// @dev For some reason using the Struct Item as an output parameter fails, but works as an input parameter
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address _creator,
        bool _shouldComplete,
        bool _isApproved,
        address _rarities,
        ItemParam[] memory _items
    ) external;
    function items(uint256 _itemId) external view returns (string memory, uint256, uint256, uint256, address, string memory, string memory);
}


// File contracts/commons/ContextMixin.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;


abstract contract ContextMixin {
    function _msgSender()
        internal
        view
        virtual
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}


// File contracts/commons/OwnableInitializable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableInitializable is ContextMixin {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function _initOwnable () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/commons/EIP712Base.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;


contract EIP712Base {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 public domainSeparator;

    // supposed to be called once while initializing.
    // one of the contractsa that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name,
        string memory version
    )
        internal
    {
        domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getChainId() public pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, messageHash)
            );
    }
}


// File contracts/commons/NativeMetaTransaction.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "NMT#executeMetaTransaction: SIGNER_AND_SIGNATURE_DO_NOT_MATCH"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            msg.sender,
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call{value: msg.value}(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "NMT#executeMetaTransaction: CALL_FAILED");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) external view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NMT#verify: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}


// File contracts/markets/v2/CollectionStore.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;
contract CollectionStore is OwnableInitializable, NativeMetaTransaction {
    using SafeMath for uint256;


    struct ItemToBuy {
        IERC721CollectionV2 collection;
        uint256[] ids;
        uint256[] prices;
        address[] beneficiaries;
    }

    uint256 constant public BASE_FEE = 1000000;
    IERC20 public acceptedToken;
    uint256 public fee;
    address public feeOwner;

    event Bought(ItemToBuy[] _itemsToBuy);
    event SetFee(uint256 _oldFee, uint256 _newFee);
    event SetFeeOwner(address indexed _oldFeeOwner, address indexed _newFeeOwner);

    /**
    * @notice Constructor of the contract.
    * @param _acceptedToken - Address of the ERC20 token accepted
    * @param _feeOwner - address where fees will be transferred
    * @param _fee - fee to charge for each sale
    */
    constructor(address _owner, IERC20 _acceptedToken, address _feeOwner, uint256 _fee) {
        // EIP712 init
        _initializeEIP712('Decentraland Collection Store', '1');
        // Ownable init
        _initOwnable();

        acceptedToken = _acceptedToken;
        feeOwner = _feeOwner;
        setFee(_fee);

        transferOwnership(_owner);
    }

    /**
    * @notice Buy collection's items.
    * @dev There is a maximum amount of NFTs that can be issued per call by the block's limit.
    * @param _itemsToBuy - items to buy
    */
    function buy(ItemToBuy[] memory _itemsToBuy) external {
        uint256 totalFee = 0;
        address sender = _msgSender();

        for (uint256 i = 0; i < _itemsToBuy.length; i++) {
            ItemToBuy memory itemToBuy = _itemsToBuy[i];
            IERC721CollectionV2 collection = itemToBuy.collection;
            uint256 amountOfItems = itemToBuy.ids.length;

            require(amountOfItems == itemToBuy.prices.length, "CollectionStore#buy: LENGTH_MISMATCH");

            for (uint256 j = 0; j < amountOfItems; j++) {
                uint256 itemId = itemToBuy.ids[j];
                uint256 price = itemToBuy.prices[j];

                (uint256 itemPrice, address itemBeneficiary) = getItemBuyData(collection, itemId);
                require(price == itemPrice, "CollectionStore#buy: ITEM_PRICE_MISMATCH");

                if (itemPrice > 0) {
                    // Calculate sale share
                    uint256 saleShareAmount = itemPrice.mul(fee).div(BASE_FEE);
                    totalFee = totalFee.add(saleShareAmount);

                    // Transfer sale amount to the item beneficiary
                    require(
                        acceptedToken.transferFrom(sender, itemBeneficiary, itemPrice.sub(saleShareAmount)),
                        "CollectionStore#buy: TRANSFER_PRICE_FAILED"
                    );
                }
            }

            // Mint Token
            collection.issueTokens(itemToBuy.beneficiaries, itemToBuy.ids);
        }

        if (totalFee > 0) {
            // Transfer share amount for fees owner
            require(
                acceptedToken.transferFrom(sender, feeOwner, totalFee),
                "CollectionStore#buy: TRANSFER_FEES_FAILED"
            );
        }
        emit Bought(_itemsToBuy);
    }

    /**
     * @notice Get item's price and beneficiary
     * @param _collection - collection address
     * @param _itemId - item id
     * @return uint256 of the item's price
     * @return address of the item's beneficiary
     */
    function getItemBuyData(IERC721CollectionV2 _collection, uint256 _itemId) public view returns (uint256, address) {
      (,,,uint256 price, address beneficiary,,) = _collection.items(_itemId);
       return (price, beneficiary);
    }

    // Owner functions

    /**
     * @notice Sets the fee of the contract that's charged to the seller on each sale
     * @param _newFee - Fee from 0 to 999,999
     */
    function setFee(uint256 _newFee) public onlyOwner {
        require(_newFee < BASE_FEE, "CollectionStore#setFee: FEE_SHOULD_BE_LOWER_THAN_BASE_FEE");
        require(_newFee != fee, "CollectionStore#setFee: SAME_FEE");

        emit SetFee(fee, _newFee);
        fee = _newFee;
    }

    /**
     * @notice Set a new fee owner.
    * @param _newFeeOwner - Address of the new fee owner
     */
    function setFeeOwner(address _newFeeOwner) external onlyOwner {
        require(_newFeeOwner != address(0), "CollectionStore#setFeeOwner: INVALID_ADDRESS");
        require(_newFeeOwner != feeOwner, "CollectionStore#setFeeOwner: SAME_FEE_OWNER");

        emit SetFeeOwner(feeOwner, _newFeeOwner);
        feeOwner = _newFeeOwner;
    }
}
