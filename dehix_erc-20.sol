// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract dxutToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("dehix", "dxut") {
    _mint(msg.sender, initialSupply);
}
}