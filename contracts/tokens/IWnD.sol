// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IWnDRoot {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function ownerOf(uint256 _tokenId) external returns(address);
    function approve(address _to, uint256 _tokenId) external;
}

interface IWnD is IERC721 {
    function mint(address _to, uint256 _tokenId) external;
    function burn(uint256 _tokenId) external;
    function exists(uint256 _tokenId) external view returns(bool);
}
