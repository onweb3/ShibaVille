// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Buildings is ERC721URIStorage {
    using Strings for uint256;

    uint256 private _currentTokenId = 0;
    address public shibavilleContract;
    string private _baseTokenURI;

    constructor(string memory baseTokenURI) ERC721("Buildings", "BLDG") {
        shibavilleContract = msg.sender;
        _baseTokenURI = baseTokenURI;
    }

    modifier onlyShibavilleContract() {
        require(msg.sender == shibavilleContract, "Caller is not the Shibaville contract");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function safeMint(address to) external onlyShibavilleContract returns (uint256) {
        _currentTokenId++;
        uint256 newTokenId = _currentTokenId;
        _safeMint(to, newTokenId);

        // Concatenate the base URI and tokenId to create the full URI
        //string memory tokenURI = string(abi.encodePacked(_baseTokenURI, newTokenId.toString()));
        _setTokenURI(newTokenId, newTokenId.toString());

        return newTokenId;
    }

    

    
}
