pragma solidity ^0.4.24;

import "./RoboDexToken.sol";


contract RDXToken is RoboDexToken {
    // solhint-disable const-name-snakecase
    uint8 constant public decimals = 18;
    string constant public name = "0x Protocol Token";
    string constant public symbol = "RDX";
    // solhint-enable const-name-snakecase
}
