pragma solidity ^0.4.24;

import "@0x/contracts-utils/contracts/src/LibBytes.sol";
import "./ERC20Token.sol";


contract RoboDexToken is ERC20Token {
    using LibBytes for bytes;

    // STRUCTURES

    enum TradeType {
        SHORT, // SELL
        LONG   // BUY
    }

    enum PositionState {
        NEW,
        OPENED,
        FILLING,
        FILLED,
        CLOSED
    }

    struct Position {
        address token;
        address maker;
        address taker;
        TradeType tradeType;
        uint256 amount;
        uint256 margin;
        uint256 openPrice;
        uint256 closePrice;
        uint256 filled;
        uint256 timestamp;
        PositionState state;
    }

    // EVENTS

    /// @dev Emits when position is opened.
    event PositionOpened(
        bytes32 id,
        address token,
        address indexed maker,
        address indexed taker,
        TradeType indexed tradeType,
        uint256 amount,
        uint256 margin,
        uint256 openPrice,
        uint256 closePrice
    );

    /// @dev Emits when position is opened.
    event PositionFilled(
        bytes32 id,
        address token,
        address indexed maker,
        address indexed taker,
        TradeType indexed tradeType,
        uint256 amount,
        uint256 margin,
        uint256 filled
    );

    /// @dev Emits when position is closed.
    event PositionClosed(
        bytes32 id,
        address token,
        address indexed maker,
        address indexed taker,
        TradeType indexed tradeType,
        uint256 amount,
        uint256 margin,
        uint256 filled,
        int256 pnl
    );
    
    // EXTERNAL FUNCTIONS

    constructor() public {
        _timeToLive = block.timestamp + INITIAL_LIFETIME;
    }

    function peddle(
        address from,
        address to,
        uint256 amount,
        bytes positionData,
        bytes dexData
    ) external returns (bool) {
        Position memory p = parsePositionData(positionData);
        if (from == p.maker) {
            p.taker = to;
        } else if (to == p.maker) {
            p.maker = from;
            p.taker = to;
        } else {
            revert("INVALID_CALL_FROM_ASSET_PROXY");
        }
        bytes32 pId = calculatePositionHash(p);
        if (_positions[pId].state != PositionState.NEW) {
            p = _positions[pId];
        }
        uint256 filled = safeAdd(p.filled, amount);
        require(
            filled <= p.amount,
            "INVALID_ASSET_AMOUNT"
        );
        bool isCreated = (filled == amount);
        bool isFullFilled = (filled == p.amount);
        // TODO: More checks
        if (isCreated) {
            transferToken(p.token, p.maker, address(this), p.margin);
            openPosition(pId, p);
        } else if (isFullFilled) {
            closePosition(pId, p, dexData);
        } else {
            fillPosition(pId, p, filled);
        }
        return true;
    }

    function getPositionCount(address maker) external view returns (uint64) {
        return _positionHashCounts[maker];
    }

    function getPositionHash(address maker, uint64 index) external view returns (bytes32) {
        return _positionHashes[maker][index];
    }

    function getPosition(bytes32 positionHash) external view returns (
        address token,
        address maker,
        address taker,
        TradeType tradeType,
        uint256 amount,
        uint256 margin,
        uint256 openPrice,
        uint256 closePrice,
        uint256 filled,
        uint256 timestamp,
        PositionState state
    ) {
        Position memory p = _positions[positionHash];
        token = p.token;
        maker = p.maker;
        taker = p.taker;
        tradeType = p.tradeType;
        amount = p.amount;
        margin = p.margin;
        openPrice = p.openPrice;
        closePrice = p.closePrice;
        filled = p.filled;
        timestamp = p.timestamp;
        state = p.state;
    }
    
    function openPosition(bytes32 pId, Position memory p) internal {
        require(
            isPositionNew(p) && _positions[pId].timestamp == 0,
            "POSITION_ALREADY_OPENED"
        );
        require(
            p.token != address(0),
            "INVALID_ERC20_TOKEN_ADDRESS"
        );
        require(
            p.maker != address(0) && p.taker != address(0) && p.maker != p.taker,
            "INVALID_TRADER_ADDRESSES"
        );
        require(
            p.tradeType == TradeType.SHORT || p.tradeType == TradeType.LONG,
            "INVALID_TRADE_TYPE"
        );
        // TODO: Add more checks (amount, margin, openPrice, closePrice)
        _positions[pId] = p;
        _positions[pId].timestamp = now;
        _positions[pId].state = PositionState.OPENED;
        uint64 positionHashIndex = _positionHashCounts[p.maker];
        _positionHashes[p.maker][positionHashIndex] = pId;
        _positionHashCounts[p.maker] = positionHashIndex + 1;
        emit PositionOpened(pId, p.token, p.maker, p.taker, p.tradeType, p.amount, p.margin, p.openPrice, p.closePrice);
    }
    
    function fillPosition(bytes32 pId, Position memory p, uint256 filled) internal {
        require(
            isPositionOpened(p) || isPositionFilling(p),
            "POSITION_ALREADY_OPENED"
        );
        require(
            p.token != address(0),
            "INVALID_ERC20_TOKEN_ADDRESS"
        );
        require(
            p.maker != address(0) && p.taker != address(0) && p.maker != p.taker,
            "INVALID_TRADER_ADDRESSES"
        );
        require(
            p.tradeType == TradeType.SHORT || p.tradeType == TradeType.LONG,
            "INVALID_TRADE_TYPE"
        );
        // TODO: Add more checks (amount, margin)
        _positions[pId].filled = filled;
        _positions[pId].state = PositionState.FILLING;
        emit PositionFilled(pId, p.token, p.maker, p.taker, p.tradeType, p.amount, p.margin, p.filled);
    }

    function closePosition(bytes32 pId, Position memory p, bytes data) internal {
        require(
            !isPositionClosed(p),
            "POSITION_ALREADY_CLOSED"
        );
        // TODO: Add more checks (margin, data)
        int256 pnl = calculatePNL(data);
        // TODO: Liquidate trades in the position
        transferTokenSigned(p.token, p.maker, p.taker, pnl);
        _positions[pId].state = PositionState.CLOSED;
        emit PositionClosed(pId, p.token, p.maker, p.taker, p.tradeType, p.amount, p.margin, p.filled, pnl);
    }

    function transferToken(address token, address from, address to, uint256 amount) internal {
        assembly {
            let ptr := mload(0x40)
            // Setup `ERC20Token.transferFrom` input data
            // bytes4(keccak256("transferFrom(address,address,uint256)")) = 0x23b872dd
            mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), from)
            mstore(add(ptr, 0x24), to)
            mstore(add(ptr, 0x44), amount)
            // Call `ERC20Token.transferFrom` using the calldata
            let success := call(
                gas,    // forward all gas
                token,  // call address of token contract
                0,      // don't send any ETH
                ptr,    // pointer to start of input
                0x64,   // length of input
                ptr,    // write output over input
                0x20    // output size should be 32 bytes
            )
            // Check return data
            // If there is no return data, we assume the token incorrectly
            // does not return a bool. In this case we expect it to revert
            // on failure, which was handled above.
            // If the token does return data, we require that it is a single
            // nonzero 32 bytes value.
            // So the transfer succeeded if the call succeeded and either
            // returned nothing, or returned a non-zero 32 byte value. 
            success := and(success, or(
                iszero(returndatasize),
                and(
                    eq(returndatasize, 0x20),
                    gt(mload(ptr), 0)
                )
            ))
            // Set storage pointer to new space
            mstore(0x40, add(ptr, 0x64))
            // Revert with `Error("TRANSFER_FAILED")` in case of error
            if iszero(success) {
                mstore(0x00, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000000f5452414e534645525f4641494c454400000000000000000000000000)
                mstore(0x60, 0x00)
                revert(0x00, 0x64)
            }
        }
    }

    function transferTokenSigned(address token, address from, address to, int256 amount) internal {
        if (amount > 0) {
            transferToken(token, from, to, uint256(amount));
        } else if (amount < 0) {
            transferToken(token, to, from, uint256(-amount));
        }
    }

    function parsePositionData(bytes data) internal pure returns (Position) {
        require(
            data.length == 224,
            "INVALID_POSITION_DATA_LENGTH"
        );
        address token = data.readAddress(12);
        address maker = data.readAddress(44);
        TradeType tradeType = (data[95] > 0 ? TradeType.LONG : TradeType.SHORT);
        uint256 amount = data.readUint256(96);
        uint256 margin = data.readUint256(128);
        uint256 openPrice = data.readUint256(160);
        uint256 closePrice = data.readUint256(192);
        require(
            token != address(0) && maker != address(0),
            "INVALID_POSITION_DATA_ADDRESSES"
        );
        require(
            amount > 0 && margin > 0 && openPrice > 0 && closePrice > 0,
            "INVALID_POSITION_DATA_VALUES"
        );
        return Position(
            token, maker, address(0), tradeType, amount, margin,
            openPrice, closePrice, 0, 0, PositionState.NEW
        );
    }

    function calculatePositionHash(Position memory p) internal pure returns (bytes32) {
        bytes memory data = abi.encodePacked(
            p.token,
            p.maker,
            p.taker,
            p.tradeType,
            p.amount,
            p.margin,
            p.openPrice,
            p.closePrice
        );
        return keccak256(data);
    }

    function calculatePNL(bytes data) internal pure returns (int256) {
        // TODO: Calculate PNL carefully
        return data.length < 32 ? int256(0) : int256(data.readBytes32(0));
    }

    function isPositionNew(Position memory p) internal pure returns (bool) {
        return p.state == PositionState.NEW;
    }

    function isPositionOpened(Position memory p) internal pure returns (bool) {
        return p.state == PositionState.OPENED;
    }

    function isPositionFilling(Position memory p) internal pure returns (bool) {
        return p.state == PositionState.FILLING;
    }

    function isPositionFilled(Position memory p) internal pure returns (bool) {
        return p.state == PositionState.FILLED;
    }

    function isPositionClosed(Position memory p) internal pure returns (bool) {
        return p.state == PositionState.CLOSED;
    }

    // FIELDS

    // Storage of open positions
    mapping (bytes32 => Position) internal _positions;

    // Storage of all known position IDs by account
    mapping (address => mapping (uint64 => bytes32)) internal _positionHashes;
    mapping (address => uint64) internal _positionHashCounts;

    // TTL which is not used yet
    uint256 internal _timeToLive;

    uint256 private constant INITIAL_LIFETIME = 21 days;
}
