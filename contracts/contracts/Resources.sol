// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Resources is ERC1155 {
    address public shibavilleContract;

    constructor(string memory uri) ERC1155(uri) {
        shibavilleContract = msg.sender;
    }

    modifier onlyShibavilleContract() {
        require(msg.sender == shibavilleContract, "Caller is not the Shibaville contract");
        _;
    }

    function mint(address to, uint256 id, uint256 amount, bytes memory data) external onlyShibavilleContract {
        _mint(to, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external onlyShibavilleContract {
        _mintBatch(to, ids, amounts, data);
    }

    function burnBatch(address from, uint256[] memory ids, uint256[] memory values) external onlyShibavilleContract {
        _burnBatch(from, ids, values);
    }

    

    

  
}
