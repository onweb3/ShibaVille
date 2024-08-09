// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Resources is ERC1155 {
    address public shibavilleContract;
    address public owner;

    constructor(string memory uri) ERC1155(uri) {
        owner = msg.sender;
    }

    modifier onlyShibavilleContract() {
        require(msg.sender == shibavilleContract, "Caller is not the Shibaville contract");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    function mint(address to, uint256 id, uint256 amount, bytes memory data) external onlyShibavilleContract {
        _mint(to, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external onlyShibavilleContract {
        _mintBatch(to, ids, amounts, data);
    }

    function setShibavilleContract(address _shibavilleContract) external onlyOwner {
        shibavilleContract = _shibavilleContract;
    }

    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }
}
