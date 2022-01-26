// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IConsumables is IERC1155 {
    function mint(uint256 typeId, uint256 qty, address recipient) external;
    function burn(uint256 typeId, uint256 qty, address burnFrom) external;
}