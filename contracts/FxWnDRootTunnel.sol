// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@maticnetwork/fx-portal/contracts/tunnel/FxBaseRootTunnel.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

import "./tokens/IWnD.sol";
import "./tokens/IConsumables.sol";

contract FxWnDRootTunnel is FxBaseRootTunnel, IERC721Receiver, Ownable, ERC1155Receiver {
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");
    IWnDRoot public wndRoot;
    IConsumables public consumablesRoot;

    constructor(address _checkpointManager, address _fxRoot)
        FxBaseRootTunnel(_checkpointManager, _fxRoot)
    {}

    function setContracts(
        address _wndRootAddress,
        address _consumablesRootAddress
    ) external onlyOwner {
        require(_wndRootAddress != address(0), "Invalid WnD Address");
        require(_consumablesRootAddress != address(0), "Invalid Con Address");

        wndRoot = IWnDRoot(_wndRootAddress);
        consumablesRoot = IConsumables(_consumablesRootAddress);
    }

    event Deposit(uint256[] _wndTokenIds, bytes message);

    // Sends from L1 -> L2. Tokens in L1 are held in this contract.
    function deposit(
        uint256[] calldata _wndTokenIds,
        uint256[] memory _consumableIds,
        uint256[] memory _consumableAmounts
    ) public {
        _preDeposit(_wndTokenIds, _consumableIds, _consumableAmounts);

        bytes memory message = abi.encode(
            DEPOSIT,
            abi.encode(
                msg.sender,
                _wndTokenIds,
                _consumableIds,
                _consumableAmounts
            )
        );
        _sendMessageToChild(message);
        emit Deposit(_wndTokenIds, message);
    }

    function _preDeposit(
        uint256[] memory _wndTokenIds,
        uint256[] memory _consumableIds,
        uint256[] memory _consumableAmounts
    ) internal {
        require(
            _consumableIds.length == _consumableAmounts.length,
            "Bad lengths"
        );

        // Transfer WnD
        for (uint256 i = 0; i < _wndTokenIds.length; i++) {
            uint256 _id = _wndTokenIds[i];
            require(_id != 0, "Bad Wnd ID");
            // Transfer to hold in this contract.
            wndRoot.safeTransferFrom(msg.sender, address(this), _id);
        }

        consumablesRoot.safeBatchTransferFrom(
            msg.sender,
            address(this),
            _consumableIds,
            _consumableAmounts,
            ""
        );
    }

    function _processMessageFromChild(bytes memory data) internal override {
        (
            address _to,
            uint256[] memory _wndTokenIds,
            uint256[] memory _consumableIds,
            uint256[] memory _consumableAmounts
        ) = abi.decode(data, (address, uint256[], uint256[], uint256[]));

        _processWithrawl(_wndTokenIds, _consumableIds, _consumableAmounts);
    }

    function _processWithrawl(
        uint256[] memory _wndTokenIds,
        uint256[] memory _consumableIds,
        uint256[] memory _consumableAmounts
    ) internal {
        // 721s can only be minted on L1. If this is a valid token,
        // it should be in this contract already.
        for (uint256 i = 0; i < _wndTokenIds.length; i++) {
            uint256 _tokenId = _wndTokenIds[i];
            require(_tokenId != 0, "Bad token id");
            require(address(this) == wndRoot.ownerOf(_tokenId), "Wrong owner");
            wndRoot.safeTransferFrom(address(this), msg.sender, _tokenId);
        }

        if (_consumableIds.length > 0) {
            address[] memory _addresses = new address[](_consumableIds.length);
            for (uint256 i = 0; i < _consumableIds.length; i++) {
                _addresses[i] = address(this);
            }

            uint256[] memory _balances = consumablesRoot.balanceOfBatch(
                _addresses,
                _consumableIds
            );

            for (uint256 i = 0; i < _consumableIds.length; i++) {
                uint256 _currentBalance = _balances[i];
                // They are requesting more than is held by this contract.
                //
                if (_currentBalance < _consumableAmounts[i]) {
                    consumablesRoot.mint(
                        _consumableIds[i],
                        uint16(_consumableAmounts[i] - _currentBalance),
                        address(this)
                    );
                }
            }

            consumablesRoot.safeBatchTransferFrom(
                address(this),
                msg.sender,
                _consumableIds,
                _consumableAmounts,
                ""
            );
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

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public override pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public override pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
