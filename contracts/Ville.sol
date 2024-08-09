// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Ville is ERC721URIStorage {
    using Strings for uint256;

    uint256 private _currentTokenId = 0;
    address public shibavilleContract;
    address public owner;
    string private _baseTokenURI;

    constructor(string memory baseTokenURI) ERC721("Ville", "VLLE") {
        owner = msg.sender;
        _baseTokenURI = baseTokenURI;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
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
        string memory tokenURI = string(abi.encodePacked(_baseTokenURI, newTokenId.toString()));
        _setTokenURI(newTokenId, tokenURI);

        return newTokenId;
    }

    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        owner = newOwner;
    }

    function setShibaContractAddress(address _shibavilleContract) external onlyOwner {
        require(_shibavilleContract != address(0), "ShibaContract is the zero address");
        shibavilleContract = _shibavilleContract;
    }
}
