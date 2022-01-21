// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@maticnetwork/fx-portal/contracts/tunnel/FxBaseRootTunnel.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./tokens/IWnD.sol";

contract FxWnDRootTunnel is FxBaseRootTunnel, IERC721Receiver, Ownable {
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");
    IWnDRoot public wndRoot;

    constructor(
        address _checkpointManager,
        address _fxRoot
    ) FxBaseRootTunnel(_checkpointManager, _fxRoot) {

    }

    function setContracts(
        address _wndRootAddress
    )
        external onlyOwner
    {
        require(_wndRootAddress != address(0), "Invalid WnD Address");
        wndRoot = IWnDRoot(_wndRootAddress);
    }

    event Deposit(uint256[] _wndTokenIds, bytes message);
    // Sends from L1 -> L2. Tokens in L1 are held in this contract.
    function deposit(
        uint256[] calldata _wndTokenIds)
        public
    {
        _preDeposit(_wndTokenIds);

        bytes memory message = abi.encode(DEPOSIT, abi.encode(msg.sender, _wndTokenIds));
        _sendMessageToChild(message);
        emit Deposit(_wndTokenIds, message);
    }

    function _preDeposit(
        uint256[] memory _wndTokenIds)
        internal
    {
        // Transfer WnD
        for(uint256 i = 0; i < _wndTokenIds.length; i++) {
            uint256 _id = _wndTokenIds[i];
            require(_id != 0, "Bad Wnd ID");
            // Transfer to hold in this contract.
            wndRoot.safeTransferFrom(msg.sender, address(this), _id);
        }
    }

    function _processMessageFromChild(bytes memory data) internal override {
        (address _to, uint256[] memory _wndTokenIds) = abi.decode(
            data,
            (address, uint256[])
        );

        _processWithrawl(_wndTokenIds);
    }

    function _processWithrawl(
        uint256[] memory _wndTokenIds)
        internal
    {
        // 721s can only be minted on L1. If this is a valid token,
        // it should be in this contract already.
        for(uint256 i = 0; i < _wndTokenIds.length; i++) {
            uint256 _tokenId = _wndTokenIds[i];
            require(_tokenId != 0, "Bad token id");
            require(address(this) == wndRoot.ownerOf(_tokenId), "Wrong owner");
            wndRoot.safeTransferFrom(address(this), msg.sender, _tokenId);
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}