// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IConsumables.sol";
import "../utils/Adminable.sol";

contract Consumables is IConsumables, ERC1155, Adminable, Pausable {

    using Strings for uint256;

    // struct to store each trait's data for metadata and rendering
    struct Image {
        string name;
        string png;
    }

    struct TypeInfo {
        uint256 mints;
        uint256 burns;
        uint256 maxSupply;
    }

    mapping(uint256 => TypeInfo) private typeInfo;
    // storage of each image data
    mapping(uint256  => Image) public traitData;

    constructor() ERC1155("") {
        _pause();
    }

    // Mint a token - any payment / game logic should be handled in the game contract.
    function mint(uint256 typeId, uint256 qty, address recipient) external override whenNotPaused onlyAdminOrOwner {
        require(typeInfo[typeId].mints - typeInfo[typeId].burns + qty <= typeInfo[typeId].maxSupply, "All tokens minted");
        typeInfo[typeId].mints += qty;
        _mint(recipient, typeId, qty, "");
    }

    // Burn a token - any payment / game logic should be handled in the game contract.
    function burn(uint256 typeId, uint256 qty, address burnFrom) external override whenNotPaused onlyAdminOrOwner {
        typeInfo[typeId].burns += qty;
        _burn(burnFrom, typeId, qty);
    }

    function setType(uint256 typeId, uint256 maxSupply) external onlyAdminOrOwner {
        require(typeInfo[typeId].mints <= maxSupply, "max supply too low");
        typeInfo[typeId].maxSupply = maxSupply;
    }

    function setPaused(bool _paused) external onlyAdminOrOwner {
        if(_paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    function getInfoForType(uint256 typeId) external view returns(TypeInfo memory) {
        require(typeInfo[typeId].maxSupply > 0, "invalid type");
        return typeInfo[typeId];
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public virtual override(IERC1155, ERC1155) onlyAdminOrOwner {
        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes memory data) public virtual override(IERC1155, ERC1155) onlyAdminOrOwner {
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function balanceOf(address account, uint256 id) public view virtual override(IERC1155, ERC1155) returns (uint256) {
        return super.balanceOf(account, id);
    }

    function uri(uint256 typeId) public view override returns (string memory) {
        require(typeInfo[typeId].maxSupply > 0, "invalid type");
        Image memory img = traitData[typeId];
        string memory metadata = string(abi.encodePacked(
            '{"name": "',
            img.name,
            '", "description": "Mysterious items spawned from the Sacrificial Alter of the Wizards & Dragons Tower. Fabled to hold magical properties, only Act 1 tower guardians will know the truth in the following acts. All the metadata and images are generated and stored 100% on-chain. No IPFS. NO API. Just the Ethereum blockchain.", "image": "data:image/svg+xml;base64,',
            _base64(bytes(_drawSVG(typeId))),
            '", "attributes": []',
            "}"
        ));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            _base64(bytes(metadata))
        ));
    }

    function uploadImage(uint256 typeId, Image calldata image) external onlyAdminOrOwner {
        traitData[typeId] = Image(
            image.name,
            image.png
        );
    }

    function _drawImage(Image memory image) private pure returns (string memory) {
        return string(abi.encodePacked(
            '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
            image.png,
            '"/>'
        ));
    }

    function _drawSVG(uint256 typeId) private view returns (string memory) {
        string memory svgString = string(abi.encodePacked(
            _drawImage(traitData[typeId])
        ));

        return string(abi.encodePacked(
            '<svg id="alter" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
            svgString,
            "</svg>"
        ));
    }

    /** BASE 64 - Written by Brech Devos */

    string private constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function _base64(bytes memory data) private pure returns (string memory) {
        if(data.length == 0) {
            return "";
        }

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
        // set the actual output length
        mstore(result, encodedLen)

        // prepare the lookup table
        let tablePtr := add(table, 1)

        // input ptr
        let dataPtr := data
        let endPtr := add(dataPtr, mload(data))

        // result ptr, jump over length
        let resultPtr := add(result, 32)

        // run over the input, 3 bytes at a time
        for {} lt(dataPtr, endPtr) {}
        {
            dataPtr := add(dataPtr, 3)

            // read 3 bytes
            let input := mload(dataPtr)

            // write 4 characters
            mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
            resultPtr := add(resultPtr, 1)
            mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
            resultPtr := add(resultPtr, 1)
            mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
            resultPtr := add(resultPtr, 1)
            mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
            resultPtr := add(resultPtr, 1)
        }

        // padding with '='
        switch mod(mload(data), 3)
        case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
        case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }
}