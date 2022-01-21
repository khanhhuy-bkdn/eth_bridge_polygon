// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@maticnetwork/fx-portal/contracts/tunnel/FxBaseChildTunnel.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./tokens/IWnD.sol";

contract FxWnDChildTunnel is FxBaseChildTunnel, IERC721Receiver, Ownable
{
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");
    IWnD public wndChild;

    constructor(address _fxChild) FxBaseChildTunnel(_fxChild) {}

    function setContracts(address _wndChildAddress) external onlyOwner
    {
        require(_wndChildAddress != address(0), "Invalid WnD Address");

        wndChild = IWnD(_wndChildAddress);
    }

    // Moves tokens from L2 -> L1. L2 tokens are burnt.
    function withdraw(
        uint256[] calldata _wndTokenIds
    ) external {
        _preWithdraw(
            _wndTokenIds
        );

        bytes memory message = abi.encode(
            msg.sender,
            _wndTokenIds
        );
        _sendMessageToRoot(message);
    }

    // Handles validation logic and actually transfering tokens to this contract.
    function _preWithdraw(uint256[] memory _wndTokenIds) internal {
        // Transfer WnD
        for (uint256 i = 0; i < _wndTokenIds.length; i++) {
            uint256 _id = _wndTokenIds[i];
            require(_id != 0, "Bad Wnd ID");
            // Transfer to hold in this contract.
            wndChild.transferFrom(msg.sender, address(this), _id);
        }
    }

    function _processMessageFromRoot(
        uint256, /* stateId */
        address sender,
        bytes memory data
    ) internal override validateSender(sender) {
        // decode incoming data
        (bytes32 syncType, bytes memory syncData) = abi.decode(
            data,
            (bytes32, bytes)
        );

        if (syncType == DEPOSIT) {
            (
                address _to,
                uint256[] memory _wndTokenIds
            ) = abi.decode(
                    syncData,
                    (
                        address,
                        uint256[]
                    )
                );

            _syncDeposit(
                _to,
                _wndTokenIds
            );
        } else {
            revert("Child: INVALID_SYNC_TYPE");
        }
    }

    // Handles a messagae from the root and creates/transfers tokens from this contract to the user in L2.
    function _syncDeposit(
        address _to,
        uint256[] memory _wndTokenIds
    ) internal {
        require(_wndTokenIds.length > 0, "Bad WnD lengths");

        for (uint256 i = 0; i < _wndTokenIds.length; i++) {
            uint256 _tokenId = _wndTokenIds[i];
            require(_tokenId != 0, "Bad token id");

            _createWnDIfNeeded(_tokenId);
            // Transfer to the alt tower.
            wndChild.transferFrom(address(this), _to, _tokenId);
        }
    }

    function _createWnDIfNeeded(uint256 _tokenId)
        private
    {
        if (wndChild.exists(_tokenId)) {
            return;
        }

        wndChild.mint(address(this), _tokenId);
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
