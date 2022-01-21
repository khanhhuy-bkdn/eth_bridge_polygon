// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./IWnD.sol";
import "@maticnetwork/fx-portal/contracts/tunnel/FxBaseRootTunnel.sol";
import "../utils/Adminable.sol";

contract WnD is IWnD, ERC721Enumerable, Adminable, Pausable {
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        _pause();
    }

    /** EXTERNAL */

    /**
    * Mint a token - any payment / game logic should be handled in the game contract.
    * This will just generate random traits and mint a token to a designated address.
    */
    function mint(address _to, uint256 _tokenId) external override whenNotPaused onlyAdminOrOwner {
        _safeMint(_to, _tokenId);
    }

    /**
    * Burn a token - any game logic should be handled before this function.
    */
    function burn(uint256 _tokenId) external override whenNotPaused onlyAdminOrOwner {
        _burn(_tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) onlyAdminOrOwner {
        _transfer(from, to, tokenId);
    }

    /** Lock down transfers for anything that isn't a game contract on L2.
    * You should only be able to play the game on L2, so any transfers should be from game logic.
    * This is crucial to ensure game state is preserved */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override onlyAdminOrOwner {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /** ADMIN */

    /**
    * enables owner to pause / unpause minting
    */
    function setPaused(bool _paused) external onlyAdminOrOwner {
        if(_paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    function exists(uint256 _tokenId) external view override returns(bool) {
        return _exists(_tokenId);
    }

    function ownerOf(uint256 _tokenId) public view override(ERC721, IERC721) returns(address) {
        return super.ownerOf(_tokenId);
    }

}