pragma solidity ^0.4.24;

import "@0x/contracts-utils/contracts/src/LibBytes.sol";
import "@0x/contracts-utils/contracts/src/SafeMath.sol";
import "./interfaces/IRoboDexToken.sol";


contract RoboDexToken is IRoboDexToken, SafeMath {
    using LibBytes for bytes;

    // EVENTS

    event Verify0x(
        address indexed from,
        address indexed to,
        Side indexed side,
        uint256 value,
        int256 pnl,
        uint256 timeLock        
    );

    // PUBLIC FUNCTIONS

    constructor() public {
        _timeToLive = block.timestamp + 14 days;
        _totalSupply = INITIAL_SUPPLY;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    /// @dev Sends `value` amount of tokens to account `to` from account `msg.sender`.
    /// @param to The address of the tokens recipient.
    /// @param value The amount of tokens to be transferred.
    /// @return True if transfer was successful.
    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /// @dev Sends `value` amount of tokens to account `to` from account `from` if enough amount of
    /// tokens are approved by account `from` to spend by account `msg.sender`.
    /// @param from The address of the tokens sender.
    /// @param to The address of the tokens recipient.
    /// @param value The amount of tokens to be transferred.
    /// @param side TODO: Describe it.
    /// @param pnl TODO: Describe it.
    /// @param timeLock TODO: Describe it.
    /// @return True if transfer was successful.
    function transferFrom(
        address from,
        address to,
        uint256 value,
        Side side,
        int256 pnl,
        uint256 timeLock
    )
        external
        returns (bool)
    {
        emit Verify0x(from, to, side, value, pnl, timeLock);

        // TODO: Unpack
        // TODO: Business logic
        
        // if (from != address(0)) {
        //     bool signatureValid = validateSignature(from, value, side, pnl, timeLock, signature);
        //     require(signatureValid, "INVALID_ORDER_SIGNATURE");
        //     if (to != address(0)) { 
        //         changePositionOwner(from, to, value, side);
        //     } else {
        //         liquidatePosition(from, value, side);
        //     }
        // } 
        // else {
        //     require(to != address(0), "INVALID_OPEN_ADDRESS");
        //     createPosition(from, to, value, side);
        // }

        // TODO: Change this standard logic
        //_decreaseAllowance(from, msg.sender, value);
        //_transfer(from, to, value);
        return true;
    }

    /// @dev Approves account with address `spender` to spend `value` amount of tokens on behalf of account `msg.sender`.
    /// Beware that changing an allowance with this method brings the risk that someone may use both the old
    /// and the new allowance by an unfortunate transaction ordering. One possible solution to mitigate this
    /// rare condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    /// https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    /// @param spender Address which will be allowed to spend the tokens.
    /// @param value Amount of tokens to allow to be spent.
    /// @return True if approve was successful.
    function approve(address spender, uint256 value) external returns (bool) {
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /// @dev Increases the amount of tokens that account `msg.sender` allowed to spend by account `spender`.
    /// Method approve() should be called when _allowances[spender] == 0. To decrement allowance
    /// it is better to use this function to avoid 2 calls (and waiting until the first transaction is mined).
    /// @param spender The address from which the tokens can be spent.
    /// @param value The amount of tokens to increase the allowance by.
    /// @return True if approve was successful.
    function increaseAllowance(address spender, uint256 value) external returns (bool) {
        require(spender != address(0));
        _increaseAllowance(msg.sender, spender, value);
        return true;
    }

    /// @dev Decreases the amount of tokens that account `msg.sender` allowed to spend by account `spender`.
    /// Method approve() should be called when _allowances[spender] == 0. To decrement allowance
    /// it is better to use this function to avoid 2 calls (and waiting until the first transaction is mined).
    /// @param spender The address from which the tokens can be spent.
    /// @param value The amount of tokens to decrease the allowance by.
    /// @return True if approve was successful.
    function decreaseAllowance(address spender, uint256 value) external returns (bool) {
        require(spender != address(0));
        _decreaseAllowance(msg.sender, spender, value);
        return true;
    }

    /// @dev Returns total amount of supplied tokens.
    /// @return Total amount of supplied tokens.
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /// @dev Returns the balance of account with address `owner`.
    /// @param owner The address from which the balance will be retrieved.
    /// @return Amount of tokens hold by account with address `owner`.
    function balanceOf(address owner) external view returns (uint256) {
        return _balances[owner];
    }

    /// @dev Returns the amount of tokens hold by account `owner` and approved to spend by account `spender`.
    /// @param owner The address of the account owning tokens.
    /// @param spender The address of the account able to transfer the tokens owning by account `owner`.
    /// @return Amount of tokens allowed to spend.
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    // TODO:
    // function changePositionOwner
    // function liquidatePosition
    // function createPosition 

    // INTERNAL FUNCTIONS

    function validateSignature(
        address from,
        uint256 value,
        Side side,
        int256 pnl,
        uint256 timeLock,
        bytes signature
    )
        internal
        pure
        returns (bool)
    {
        require(signature.length == 65, "INVALID_ORDER_SIGNATURE_LENGTH");
        uint8 v = uint8(signature[0]);
        bytes32 r = signature.readBytes32(1);
        bytes32 s = signature.readBytes32(33);
        bytes memory data = abi.encodePacked(from, value, side, pnl, timeLock);
        bytes32 dataHash = keccak256(data);
        address recovered = ecrecover(dataHash, v, r, s);
        return true/*signerAddress == recovered*/;
    }

    /// @dev Transfers tokens from account with address `from` to account with address `to`.
    /// @param from The address of the tokens sender.
    /// @param to The address of the tokens recipient.
    /// @param value The amount of tokens to be transferred.
    function _transfer(address from, address to, uint256 value) internal {
        require(value > 0 && value <= _balances[from]);
        _balances[from] = safeSub(_balances[from], value);
        _balances[to] = safeAdd(_balances[to], value);
        emit Transfer(from, to, value);
    }

    /// @dev Increases the amount of tokens that account `owner` allowed to spend by account `spender`.
    /// Method approve() should be called when _allowances[spender] == 0. To decrement allowance
    /// it is better to use this function to avoid 2 calls (and waiting until the first transaction is mined).
    /// @param owner The address which owns the tokens.
    /// @param spender The address from which the tokens can be spent.
    /// @param value The amount of tokens to increase the allowance by.
    function _increaseAllowance(address owner, address spender, uint256 value) internal {
        require(value > 0);
        _allowances[owner][spender] = safeAdd(_allowances[owner][spender], value);
        emit Approval(owner, spender, _allowances[owner][spender]);
    }

    /// @dev Decreases the amount of tokens that account `owner` allowed to spend by account `spender`.
    /// Method approve() should be called when _allowances[spender] == 0. To decrement allowance
    /// it is better to use this function to avoid 2 calls (and waiting until the first transaction is mined).
    /// @param owner The address which owns the tokens.
    /// @param spender The address from which the tokens can be spent.
    /// @param value The amount of tokens to decrease the allowance by.
    function _decreaseAllowance(address owner, address spender, uint256 value) internal {
        require(value > 0 && value <= _allowances[owner][spender]);
        _allowances[owner][spender] = safeSub(_allowances[owner][spender], value);
        emit Approval(owner, spender, _allowances[owner][spender]);
    }

    /// @dev Internal function that mints specified amount of tokens and assigns it to account `receiver`.
    /// This encapsulates the modification of balances such that the proper events are emitted.
    /// @param receiver The address that will receive the minted tokens.
    /// @param value The amount of tokens that will be minted.
    function _mint(address receiver, uint256 value) internal {
        require(receiver != address(0));
        require(value > 0);
        _balances[receiver] = safeAdd(_balances[receiver], value);
        _totalSupply = safeAdd(_totalSupply, value);
        emit Transfer(address(0), receiver, value);
    }

    /// @dev Internal function that burns specified amount of tokens of a given address.
    /// @param burner The address from which tokens will be burnt.
    /// @param value The amount of tokens that will be burnt.
    function _burn(address burner, uint256 value) internal {
        require(burner != address(0));
        require(value > 0 && value <= _balances[burner]);
        _balances[burner] = safeSub(_balances[burner], value);
        _totalSupply = safeSub(_totalSupply, value);
        emit Transfer(burner, address(0), value);
    }

    // FIELDS

    // Mapping of address => address => amount of open contracts
    mapping (address => mapping (address => uint256)) internal _openContracts;

    // Mapping of address => side of open short positions
    mapping (address => Side) internal _sides;

    uint256 internal _timeToLive;

    uint256 internal _totalSupply;
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;

    // Amount of initially supplied tokens is constant and equals to 1,000,000,000
    uint256 private constant INITIAL_SUPPLY = 10**27;
}
