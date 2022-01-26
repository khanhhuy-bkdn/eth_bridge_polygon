// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@maticnetwork/fx-portal/contracts/tunnel/FxBaseChildTunnel.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

import "./tokens/IWnD.sol";
import "./tokens/IConsumables.sol";

contract FxWnDChildTunnel is
    FxBaseChildTunnel,
    IERC721Receiver,
    Ownable,
    ERC1155Receiver
{
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");
    IWnD public wndChild;
    IConsumables public consumables;

    constructor(address _fxChild) FxBaseChildTunnel(_fxChild) {}

    function setContracts(address _wndChildAddress, address _consumablesAddress)
        external
        onlyOwner
    {
        require(_wndChildAddress != address(0), "Invalid WnD Address");
        require(_consumablesAddress != address(0), "Invalid consumables");

        wndChild = IWnD(_wndChildAddress);
        consumables = IConsumables(_consumablesAddress);
    }

    // Moves tokens from L2 -> L1. L2 tokens are burnt.
    function withdraw(
        uint256[] calldata _wndTokenIds,
        uint256[] memory _consumablesIds,
        uint256[] memory _consumablesAmounts
    ) external {
        _preWithdraw(_wndTokenIds, _consumablesIds, _consumablesAmounts);

        bytes memory message = abi.encode(
            msg.sender,
            _wndTokenIds,
            _consumablesIds,
            _consumablesAmounts
        );
        _sendMessageToRoot(message);
    }

    // Handles validation logic and actually transfering tokens to this contract.
    function _preWithdraw(
        uint256[] memory _wndTokenIds,
        uint256[] memory _consumablesIds,
        uint256[] memory _consumablesAmounts
    ) internal {
        require(
            _consumablesIds.length == _consumablesAmounts.length,
            "Bad lengths"
        );
        // Transfer WnD
        for (uint256 i = 0; i < _wndTokenIds.length; i++) {
            uint256 _id = _wndTokenIds[i];
            require(_id != 0, "Bad Wnd ID");
            // Transfer to hold in this contract.
            wndChild.transferFrom(msg.sender, address(this), _id);
        }

        consumables.safeBatchTransferFrom(
            msg.sender,
            address(this),
            _consumablesIds,
            _consumablesAmounts,
            ""
        );
    }

    event ProcessFromRoot(address sender, bytes data);

    event MessageFromRoot(
        address _to,
        uint256[] _wndTokenIds,
        uint256[] _consumableIds,
        uint256[] _consumableAmounts
    );

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

        emit ProcessFromRoot(sender, data);

        if (syncType == DEPOSIT) {
            (
                address _to,
                uint256[] memory _wndTokenIds,
                uint256[] memory _consumableIds,
                uint256[] memory _consumableAmounts
            ) = abi.decode(
                    syncData,
                    (address, uint256[], uint256[], uint256[])
                );

            _syncDeposit(_to, _wndTokenIds, _consumableIds, _consumableAmounts);

            emit MessageFromRoot(
                _to,
                _wndTokenIds,
                _consumableIds,
                _consumableAmounts
            );
        } else {
            revert("Child: INVALID_SYNC_TYPE");
        }
    }

    // Handles a messagae from the root and creates/transfers tokens from this contract to the user in L2.
    function _syncDeposit(
        address _to,
        uint256[] memory _wndTokenIds,
        uint256[] memory _consumableIds,
        uint256[] memory _consumableAmounts
    ) internal {
        // require(_wndTokenIds.length > 0, "Bad WnD lengths");
        require(
            _consumableIds.length == _consumableAmounts.length,
            "Bad Consumable Amounts"
        );

        for (uint256 i = 0; i < _wndTokenIds.length; i++) {
            uint256 _tokenId = _wndTokenIds[i];
            require(_tokenId != 0, "Bad token id");

            _createWnDIfNeeded(_tokenId);
            // Transfer to the alt tower.
            wndChild.transferFrom(address(this), _to, _tokenId);
        }

        if (_consumableIds.length > 0) {
            address[] memory _addresses = new address[](_consumableIds.length);
            for (uint256 i = 0; i < _consumableIds.length; i++) {
                _addresses[i] = address(this);
            }

            uint256[] memory _balances = consumables.balanceOfBatch(
                _addresses,
                _consumableIds
            );

            for (uint256 i = 0; i < _consumableIds.length; i++) {
                uint256 _currentBalance = _balances[i];
                // They are requesting more than is held by this contract.
                //
                if (_currentBalance < _consumableAmounts[i]) {
                    consumables.mint(
                        _consumableIds[i],
                        uint16(_consumableAmounts[i] - _currentBalance),
                        address(this)
                    );
                }
            }

            consumables.safeBatchTransferFrom(
                address(this),
                _to,
                _consumableIds,
                _consumableAmounts,
                ""
            );
        }
    }

    function _createWnDIfNeeded(uint256 _tokenId) private {
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

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function testMessageFromRoot(bytes memory data) external {
        // decode incoming data
        (bytes32 syncType, bytes memory syncData) = abi.decode(
            data,
            (bytes32, bytes)
        );

        if (syncType == DEPOSIT) {
            (
                address _to,
                uint256[] memory _wndTokenIds,
                uint256[] memory _consumableIds,
                uint256[] memory _consumableAmounts
            ) = abi.decode(
                    syncData,
                    (address, uint256[], uint256[], uint256[])
                );

            _syncDeposit(_to, _wndTokenIds, _consumableIds, _consumableAmounts);

            emit MessageFromRoot(
                _to,
                _wndTokenIds,
                _consumableIds,
                _consumableAmounts
            );
        } else {
            revert("Child: INVALID_SYNC_TYPE");
        }
    }
}
