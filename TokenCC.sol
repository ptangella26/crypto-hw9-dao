//SPDX-License-Identifier: MIT
//nww7sm, Prabhath Tangella

pragma solidity ^0.8.33;

import "./ITokenCC.sol";
import "./ERC20.sol";

contract TokenCC is ITokenCC, ERC20 {
    constructor() ERC20("InviniCoin", "INVI") {
        _mint(msg.sender, 1000000 * 10 ** 10);
    }

    function decimals() public pure override (ERC20, IERC20Metadata) returns (uint8) {
        return 10;
    }

    function requestFunds() external pure {
        revert();
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC20).interfaceId ||
              interfaceId == type(IERC20Metadata).interfaceId || interfaceId == type(ITokenCC).interfaceId;
    }
}
