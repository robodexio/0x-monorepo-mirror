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

    struct Position {
        ERC20Token baseToken;
        ERC20Token quoteToken;
        address owner;
        address trader;
        TradeType tradeType;
        int256 amount;
        uint256 margin;
        uint256 price;
        uint256 filled;
        uint256 timestamp;
    }

    // EVENTS

    /// @dev Emits when position is opened.
    event PositionOpened(
        uint256 positionId,
        address baseToken,
        address quoteToken,
        address indexed owner,
        address indexed trader,
        TradeType indexed tradeType,
        int256 amount,
        uint256 margin,
        uint256 price
    );

    /// @dev Emits when position is closed.
    event PositionClosed(
        uint256 positionId,
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
        uint256 dexData
    ) external returns (bool) {
        Position memory makerPosition = parseAssetData(makerAssetData);
        Position memory takerPosition = parseAssetData(takerAssetData);
        uint256 makerPositionId = calculatePositionHash(makerPosition);
        uint256 takerPositionId = calculatePositionHash(takerPosition);
        bool makerOpening = isPositionOpened(makerPositionId);
        bool takerOpening = isPositionOpened(takerPositionId);
        // TODO: More checks
        if (makerOpening && takerOpening) {
            // Both maker and taker are opening positions
            transferToken(makerPosition.baseToken, makerPosition.owner, address(this), makerPosition.margin);
            transferToken(takerPosition.baseToken, takerPosition.owner, address(this), takerPosition.margin);
            openPosition(
                makerPosition.baseToken,
                makerPosition.quoteToken,
                makerPosition.owner,
                makerPosition.trader,
                makerPosition.tradeType,
                makerPosition.amount,
                makerPosition.margin,
                makerPosition.price
            );
            openPosition(
                takerPosition.baseToken,
                takerPosition.quoteToken,
                takerPosition.owner,
                takerPosition.trader,
                takerPosition.tradeType,
                takerPosition.amount,
                takerPosition.margin,
                takerPosition.price
            );
        } else if (takerOpening) {
            // Taker is opening position
            transferToken(takerPosition.baseToken, takerPosition.owner, address(this), takerPosition.margin);
            openPosition(
                takerPosition.baseToken,
                takerPosition.quoteToken,
                takerPosition.owner,
                takerPosition.trader,
                takerPosition.tradeType,
                takerPosition.amount,
                takerPosition.margin,
                takerPosition.price
            );
            closePosition(makerPositionId, makerPosition.owner, takerPosition.owner, dexData);
        } else if (makerOpening) {
            // Maker is opening position
            transferToken(makerPosition.baseToken, makerPosition.owner, address(this), makerPosition.margin);
            openPosition(
                makerPosition.baseToken,
                makerPosition.quoteToken,
                makerPosition.owner,
                makerPosition.trader,
                makerPosition.tradeType,
                makerPosition.amount,
                makerPosition.margin,
                makerPosition.price
            );
            closePosition(takerPositionId, takerPosition.owner, makerPosition.owner, dexData);
        }
    }

    function getPositionInfo(uint256 positionId) external view returns (
        address baseToken,
        address quoteToken,
        address owner,
        address trader,
        TradeType tradeType,
        int256 amount,
        uint256 margin,
        uint256 price,
        uint256 filled,
        uint256 timestamp
    ) {
        Position memory position = _positions[positionId];
        baseToken = position.baseToken;
        quoteToken = position.quoteToken;
        owner = position.owner;
        trader = position.trader;
        tradeType = position.tradeType;
        amount = position.amount;
        margin = position.margin;
        price = position.price;
        filled = position.filled;
        timestamp = position.timestamp;
    }
    
    function openPosition(
        address baseToken,
        address quoteToken,
        address owner,
        address trader,
        TradeType tradeType,
        int256 amount,
        uint256 margin,
        uint256 price
    ) internal returns (uint256 positionId) {
        require(
            baseToken != address(0) && quoteToken != address(0) && baseToken != quoteToken,
            "ERC20_TOKEN_ADDRESSES_INCORRECT"
        );
        require(
            owner != address(0) && trader != address(0) && owner != trader,
            "TRADER_ADDRESSES_INCORRECT"
        );
        require(
            tradeType == TradeType.SHORT || tradeType == TradeType.LONG,
            "TRADE_TYPE_INCORRECT"
        );
        Position memory position = Position(
            ERC20Token(baseToken), ERC20Token(quoteToken),
            owner, trader, tradeType, amount, margin, price, 0, now
        );
        positionId = calculatePositionHash(position);
        require(_positions[positionId].timestamp == 0, "POSITION_ALREADY_OPENED");
        _positions[positionId] = position;
        emit PositionOpened(positionId, baseToken, quoteToken, owner, trader, tradeType, amount, margin, price);
    }

    function closePosition(
        uint256 positionId,
        address owner,
        address trader,
        uint256 dexData
    ) internal {
        Position storage position = _positions[positionId];
        require(
            position.timestamp > 0,
            "POSITION_IS_NOT_OPENED"
        );
        require(
            owner != address(0) && trader != address(0) && owner != trader,
            "TRADER_ADDRESSES_INCORRECT"
        );
        // TODO: Add more checks (owner, trader, dexData)
        int256 balance = calculatePNL(dexData);
        // TODO: Liquidate trades in the position
        if (position.tradeType == TradeType.SHORT) {
            // TODO
            transferTokenSigned(position.baseToken, owner, trader, balance);
        } else if (position.tradeType == TradeType.LONG) {
            // TODO
            transferTokenSigned(position.quoteToken, owner, trader, balance);
        } else {
            revert("POSITION_IS_NOT_OPENED");
        }
        emit PositionClosed(positionId, owner, trader, balance);
    }

    // function test() internal {
    //     TODO: Unpack
    //     TODO: Business logic
    //     if (from != address(0)) {
    //         bool signatureValid = validateSignature(from, value, side, pnl, timeLock, signature);
    //         require(signatureValid, "INVALID_ORDER_SIGNATURE");
    //         if (to != address(0)) { 
    //             changePositionOwner(from, to, value, side);
    //         } else {
    //             liquidatePosition(from, value, side);
    //         }
    //     } 
    //     else {
    //         require(to != address(0), "INVALID_OPEN_ADDRESS");
    //         createPosition(from, to, value, side);
    //     }
    // }

    // function validateSignature(
    //     address from,
    //     uint256 value,
    //     TradeType tradeType,
    //     int256 pnl,
    //     uint256 timeLock,
    //     bytes signature
    // )
    //     internal
    //     pure
    //     returns (bool)
    // {
    //     require(signature.length == 65, "INVALID_ORDER_SIGNATURE_LENGTH");
    //     uint8 v = uint8(signature[0]);
    //     bytes32 r = signature.readBytes32(1);
    //     bytes32 s = signature.readBytes32(33);
    //     bytes memory data = abi.encodePacked(from, value, tradeType, pnl, timeLock);
    //     bytes32 dataHash = keccak256(data);
    //     address recovered = ecrecover(dataHash, v, r, s);
    //     return true/*signerAddress == recovered*/;
    // }

    function transferToken(ERC20Token token, address payer, address payee, uint256 value) internal {
        require(
            token.transferFrom(payer, payee, uint256(value)),
            "UNABLE_TO_TRANSFER_ERC20_TOKEN"
        );
    }

    function transferTokenSigned(ERC20Token token, address payer, address payee, int256 value) internal {
        // TODO: ???
        if (value > 0) {
            transferToken(token, payer, payee, uint256(value));
        } else if (value < 0) {
            transferToken(token, payee, payer, uint256(-value));
        }
    }

    function parseAssetData(bytes assetData) internal pure returns (Position) {
        // TODO: Check
        require(assetData.length == 130, "INCORRECT_ASSET_DATA_LENGTH");
        address baseToken = assetData.readAddress(0);
        address quoteToken = assetData.readAddress(32);
        address owner = assetData.readAddress(64);
        address trader = assetData.readAddress(96);
        TradeType tradeType = (assetData[128] > 0 ? TradeType.LONG : TradeType.SHORT);
        int256 amount = int256(assetData.readBytes32(160));
        uint256 margin = assetData.readUint256(192);
        uint256 price = assetData.readUint256(224);
        uint256 filled = assetData.readUint256(256);
        uint256 timestamp = assetData.readUint256(288);
        return Position(
            ERC20Token(baseToken), ERC20Token(quoteToken),
            owner, trader, tradeType, amount, margin, price, filled, timestamp
        );
    }

    function isPositionOpened(uint256 positionId) internal view returns (bool) {
        return _positions[positionId].timestamp > 0 && _positions[positionId].margin > 0;
    }

    function isPositionFilled(uint256 positionId) internal view returns (bool) {
        return _positions[positionId].timestamp > 0 && _positions[positionId].filled == 0;
    }

    function calculatePositionHash(Position memory position) internal pure returns (uint256) {
        bytes memory data = abi.encodePacked(
            position.baseToken,
            position.quoteToken,
            position.owner,
            position.trader,
            position.tradeType,
            position.amount,
            position.timestamp
        );
        bytes32 dataHash = keccak256(data);
        return uint256(dataHash);
    }

    function calculatePNL(uint256 dexData) internal pure returns (int256) {
        // TODO: ???
        return int256(dexData);
    }
    
    // TODO:
    // function changePositionOwner
    // function liquidatePosition

    // FIELDS

    mapping (uint256 => Position) internal _positions;

    uint256 internal _timeToLive;

    uint256 private constant INITIAL_LIFETIME = 14 days;
}
