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
        FILLED,
        CLOSED
    }

    struct Position {
        address baseToken;
        address quoteToken;
        address makerAddress;
        address takerAddress;
        TradeType tradeType;
        int256 amount;
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
        bytes32 positionId,
        address baseToken,
        address quoteToken,
        address indexed makerAddress,
        address indexed takerAddress,
        TradeType indexed tradeType,
        int256 amount,
        uint256 margin,
        uint256 openPrice,
        uint256 closePrice
    );

    /// @dev Emits when position is closed.
    event PositionClosed(
        bytes32 positionId,
        address indexed from,
        address indexed to,
        int256 amount
    );
    
    // EXTERNAL FUNCTIONS

    constructor() public {
        _timeToLive = block.timestamp + INITIAL_LIFETIME;
    }

    function peddle(
        bytes makerAssetData,
        bytes takerAssetData,
        bytes dexData
    ) external returns (bool) {
        Position memory makerPosition = parseAssetData(makerAssetData);
        Position memory takerPosition = parseAssetData(takerAssetData);
        bytes32 makerPositionId = calculatePositionHash(makerPosition);
        bytes32 takerPositionId = calculatePositionHash(takerPosition);
        address makerRequiredToken = address(0);
        if (makerPosition.tradeType == TradeType.SHORT) {
            makerRequiredToken = makerPosition.baseToken;
        } else if (makerPosition.tradeType == TradeType.LONG) {
            makerRequiredToken = makerPosition.quoteToken;
        } else {
            revert("POSITION_TRADE_TYPE_INVALID");
        }
        address takerRequiredToken = address(0);
        if (takerPosition.tradeType == TradeType.SHORT) {
            takerRequiredToken = takerPosition.baseToken;
        } else if (takerPosition.tradeType == TradeType.LONG) {
            takerRequiredToken = takerPosition.quoteToken;
        } else {
            revert("POSITION_TRADE_TYPE_INVALID");
        }
        // TODO: More checks
        if (!isPositionOpened(makerPositionId) && !isPositionOpened(takerPositionId)) {
            // Both maker and taker are opening positions
            transferToken(makerRequiredToken, makerPosition.makerAddress, address(this), makerPosition.margin);
            transferToken(takerRequiredToken, takerPosition.makerAddress, address(this), takerPosition.margin);
            openPosition(
                makerPosition.baseToken,
                makerPosition.quoteToken,
                makerPosition.makerAddress,
                makerPosition.takerAddress,
                makerPosition.tradeType,
                makerPosition.amount,
                makerPosition.margin,
                makerPosition.openPrice,
                makerPosition.closePrice
            );
            openPosition(
                takerPosition.baseToken,
                takerPosition.quoteToken,
                takerPosition.makerAddress,
                takerPosition.takerAddress,
                takerPosition.tradeType,
                takerPosition.amount,
                takerPosition.margin,
                takerPosition.openPrice,
                takerPosition.closePrice
            );
        } else if (!isPositionOpened(takerPositionId)) {
            // Taker is opening position
            transferToken(takerRequiredToken, takerPosition.makerAddress, address(this), takerPosition.margin);
            openPosition(
                takerPosition.baseToken,
                takerPosition.quoteToken,
                takerPosition.makerAddress,
                takerPosition.takerAddress,
                takerPosition.tradeType,
                takerPosition.amount,
                takerPosition.margin,
                takerPosition.openPrice,
                takerPosition.closePrice
            );
            closePosition(makerPositionId, makerPosition.makerAddress, takerPosition.makerAddress, dexData);
        } else if (!isPositionOpened(makerPositionId)) {
            // Maker is opening position
            transferToken(makerRequiredToken, makerPosition.makerAddress, address(this), makerPosition.margin);
            openPosition(
                makerPosition.baseToken,
                makerPosition.quoteToken,
                makerPosition.makerAddress,
                makerPosition.takerAddress,
                makerPosition.tradeType,
                makerPosition.amount,
                makerPosition.margin,
                makerPosition.openPrice,
                makerPosition.closePrice
            );
            closePosition(takerPositionId, takerPosition.makerAddress, makerPosition.makerAddress, dexData);
        }
    }

    function getPositionInfo(bytes32 positionId) external view returns (
        address baseToken,
        address quoteToken,
        address makerAddress,
        address takerAddress,
        TradeType tradeType,
        int256 amount,
        uint256 margin,
        uint256 openPrice,
        uint256 closePrice,
        uint256 filled,
        uint256 timestamp,
        PositionState state
    ) {
        Position memory position = _positions[positionId];
        baseToken = position.baseToken;
        quoteToken = position.quoteToken;
        makerAddress = position.makerAddress;
        takerAddress = position.takerAddress;
        tradeType = position.tradeType;
        amount = position.amount;
        margin = position.margin;
        openPrice = position.openPrice;
        closePrice = position.closePrice;
        filled = position.filled;
        timestamp = position.timestamp;
        state = position.state;
    }
    
    function openPosition(
        address baseToken,
        address quoteToken,
        address makerAddress,
        address takerAddress,
        TradeType tradeType,
        int256 amount,
        uint256 margin,
        uint256 openPrice,
        uint256 closePrice
    ) internal returns (bytes32 positionId) {
        require(
            baseToken != address(0) && quoteToken != address(0) && baseToken != quoteToken,
            "ERC20_TOKEN_ADDRESSES_INVALID"
        );
        require(
            makerAddress != address(0) && takerAddress != address(0) && makerAddress != takerAddress,
            "TRADER_ADDRESSES_INVALID"
        );
        require(
            tradeType == TradeType.SHORT || tradeType == TradeType.LONG,
            "TRADE_TYPE_INVALID"
        );
        Position memory position = Position(
            baseToken, quoteToken, makerAddress, takerAddress, tradeType,
            amount, margin, openPrice, closePrice, 0, now, PositionState.OPENED
        );
        positionId = calculatePositionHash(position);
        require(!isPositionOpened(positionId), "POSITION_ALREADY_OPENED");
        _positions[positionId] = position;
        emit PositionOpened(positionId, baseToken, quoteToken, makerAddress, takerAddress, tradeType, amount, margin, openPrice, closePrice);
    }

    function closePosition(
        bytes32 positionId,
        address makerAddress,
        address takerAddress,
        bytes dexData
    ) internal {
        Position storage position = _positions[positionId];
        require(
            position.state == PositionState.OPENED,
            "POSITION_IS_NOT_OPENED"
        );
        require(
            makerAddress != address(0) && takerAddress != address(0) && makerAddress != takerAddress,
            "TRADER_ADDRESSES_INVALID"
        );
        // TODO: Add more checks (makerAddress, takerAddress, dexData)
        int256 balance = calculatePNL(dexData);
        // TODO: Liquidate trades in the position
        if (position.tradeType == TradeType.SHORT) {
            // TODO
            //transferTokenSigned(position.baseToken, makerAddress, takerAddress, balance);
        } else if (position.tradeType == TradeType.LONG) {
            // TODO
            //transferTokenSigned(position.quoteToken, makerAddress, takerAddress, balance);
        } else {
            revert("POSITION_TRADE_TYPE_INVALID");
        }
        emit PositionClosed(positionId, makerAddress, takerAddress, balance);
    }

    function transferToken(address token, address payer, address payee, uint256 value) internal {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 4), payer)
            mstore(add(ptr, 36), payee)
            mstore(add(ptr, 68), value)
            /////// Call `ERC20Token.transferFrom` using the calldata ///////
            let success := call(
                gas,    // forward all gas
                token,  // call address of token contract
                0,      // don't send any ETH
                ptr,    // pointer to start of input
                100,    // length of input
                ptr,    // write output over input
                32      // output size should be 32 bytes
            )
            // Set storage pointer to new space
            mstore(0x40, add(ptr, 100)) 
            /////// Check return data. ///////
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
                    eq(returndatasize, 32),
                    gt(mload(ptr), 0)
                )
            ))
            if success {
                return(0, 0)
            }
            // Revert with `Error("TRANSFER_FAILED")`
            mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
            mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
            mstore(64, 0x0000000f5452414e534645525f4641494c454400000000000000000000000000)
            mstore(96, 0)
            revert(0, 100)
        }
    }

    function transferTokenSigned(address token, address payer, address payee, int256 value) internal {
        // TODO: ???
        if (value > 0) {
            transferToken(token, payer, payee, uint256(value));
        } else if (value < 0) {
            transferToken(token, payee, payer, uint256(-value));
        }
    }

    function parseAssetData(bytes assetData) internal pure returns (Position) {
        require(assetData.length == 320, "INVALID_ASSET_DATA_LENGTH");
        address baseToken = assetData.readAddress(12);
        address quoteToken = assetData.readAddress(46);
        address makerAddress = assetData.readAddress(76);
        address takerAddress = assetData.readAddress(108);
        TradeType tradeType = (assetData[159] > 0 ? TradeType.LONG : TradeType.SHORT);
        int256 amount = int256(assetData.readBytes32(160));
        uint256 margin = assetData.readUint256(192);
        uint256 openPrice = assetData.readUint256(224);
        uint256 closePrice = assetData.readUint256(256);
        uint256 timestamp = assetData.readUint256(288);
        return Position(
            baseToken, quoteToken, makerAddress, takerAddress, tradeType,
            amount, margin, openPrice, closePrice, 0, timestamp, PositionState.NEW
        );
    }

    function isPositionOpened(bytes32 positionId) internal view returns (bool) {
        return _positions[positionId].state == PositionState.OPENED;
    }

    function isPositionFilled(bytes32 positionId) internal view returns (bool) {
        return _positions[positionId].state == PositionState.FILLED;
    }

    function isPositionClosed(bytes32 positionId) internal view returns (bool) {
        return _positions[positionId].state == PositionState.CLOSED;
    }

    function calculatePositionHash(Position memory position) internal pure returns (bytes32) {
        bytes memory data = abi.encodePacked(
            position.baseToken,
            position.quoteToken,
            position.makerAddress,
            position.takerAddress,
            position.tradeType,
            position.amount,
            position.timestamp
        );
        return keccak256(data);
    }

    function calculatePNL(bytes dexData) internal pure returns (int256) {
        // TODO: Calculate PNL carefully
        return dexData.length < 32 ? int256(0) : int256(dexData.readBytes32(0));
    }

    // FIELDS

    // Storage of open positions
    mapping (bytes32 => Position) internal _positions;

    // Storage of all known position IDs by account
    mapping (address => mapping (uint64 => bytes32)) internal _positionHashes;
    mapping (address => uint64) internal _positionHashesCounts;

    // TTL which is not used yet
    uint256 internal _timeToLive;

    uint256 private constant INITIAL_LIFETIME = 21 days;
}
