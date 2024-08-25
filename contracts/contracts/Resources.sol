// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Resources is ERC1155 {
    address public shibavilleContract;

    constructor(address _shibaville, string memory uri, address _dev) ERC1155(uri) {
        shibavilleContract = _shibaville;
        /* Resource(BBM, FOOD, TECH, WORKER) */
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);
        for (uint i = 0; i < 4; i++) {
            ids[i] = i;
            amounts[i] = 100;
        }
        _mintBatch(_dev, ids, amounts, "");
    }

    modifier onlyShibavilleContract() {
        require(msg.sender == shibavilleContract, "Caller is not the Shibaville contract");
        _;
    }

    function mint(address to, uint256 id, uint256 amount) external onlyShibavilleContract {
        _mint(to, id, amount, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external onlyShibavilleContract {
        _mintBatch(to, ids, amounts, "");
    }

    function burnBatch(address from, uint256[] memory ids, uint256[] memory values) external onlyShibavilleContract {
        _burnBatch(from, ids, values);
    }

    

    

  
}
