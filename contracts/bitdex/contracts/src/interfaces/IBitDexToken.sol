pragma solidity ^0.4.24;


contract IBitDexToken {

    enum Side {
        SHORT, // Also means 'SELL'
        LONG   // Also means 'BUY'
    }

    /// @dev Emits when ownership of any tokens changes by any mechanism.
    /// This event also emits when tokens are created (`from` == 0) and destroyed (`to` == 0).
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    /// @dev Emits when the approved address for a tokens is changed or reaffirmed.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @dev Sends `value` amount of tokens to account `to` from account `msg.sender`.
    /// @param to The address of the tokens recipient.
    /// @param value The amount of tokens to be transferred.
    /// @return True if transfer was successful.
    function transfer(address to, uint256 value) external returns (bool);

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
        returns (bool);
    
    /// @dev Approves account `spender` by account `msg.sender` to spend `value` amount of tokens.
    /// @param spender The address of the account able to transfer the tokens.
    /// @param value The new amount of tokens to be approved for transfer.
    /// @return True if approve was successful.
    function approve(address spender, uint256 value) external returns (bool);

    /// @dev Returns total amount of supplied tokens.
    /// @return Total amount of supplied tokens.
    function totalSupply() external view returns (uint256);
    
    /// @dev Returns the balance of account with address `owner`.
    /// @param owner The address from which the balance will be retrieved.
    /// @return Amount of tokens hold by account with address `owner`.
    function balanceOf(address owner) external view returns (uint256);

    /// @dev Returns the amount of tokens hold by account `owner` and approved to spend by account `spender`.
    /// @param owner The address of the account owning tokens.
    /// @param spender The address of the account able to transfer the tokens owning by account `owner`.
    /// @return Amount of tokens allowed to spend.
    function allowance(address owner, address spender) external view returns (uint256);
}
