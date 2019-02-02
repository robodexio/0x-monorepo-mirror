pragma solidity ^0.4.24;

import "./BitDexToken.sol";


contract BDTToken is BitDexToken {
    // solhint-disable const-name-snakecase
    uint8 constant public decimals = 18;
    string constant public name = "0x Protocol Token";
    string constant public symbol = "BDT";
    // solhint-enable const-name-snakecase
}
