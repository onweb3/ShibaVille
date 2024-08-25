// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Shares is ERC1155 {
    address public shibavilleContract;

    
    // Mapping to keep track of holders for each tokenId
    mapping(uint256 => address[]) private tokenHolders;
    mapping(uint256 => mapping(address => bool)) private holderExists;
    
    constructor(address _shibaville, string memory uri) ERC1155(uri) {
        shibavilleContract = _shibaville;
    }

    modifier onlyShibavilleContract() {
        require(msg.sender == shibavilleContract, "Caller is not the Shibaville contract");
        _;
    }


    function mint(address to, uint256 id, uint256 amount, bytes memory data) external onlyShibavilleContract {
        _mint(to, id, amount, data);
        _addHolder(id, to);
    }


    function getHolders(uint256 tokenId) public view returns (address[] memory, uint256[] memory) {
        address[] memory addresses = tokenHolders[tokenId];
        uint256[] memory balances = new uint256[](addresses.length);
        
        for (uint i = 0; i < addresses.length; i++) {
            balances[i] = balanceOf(addresses[i], tokenId);
        }
        return (addresses, balances);
    }

    function _addHolder(uint256 tokenId, address holder) internal {
        if (!holderExists[tokenId][holder]) {
            tokenHolders[tokenId].push(holder);
            holderExists[tokenId][holder] = true;
        }
    }

    function _removeHolder(uint256 tokenId, address holder) internal {
        uint256 length = tokenHolders[tokenId].length;
        for (uint256 i = 0; i < length; i++) {
            if (tokenHolders[tokenId][i] == holder) {
                tokenHolders[tokenId][i] = tokenHolders[tokenId][length - 1];
                tokenHolders[tokenId].pop();
                holderExists[tokenId][holder] = false;
                break;
            }
        }
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data)
        public override
    {
        super.safeTransferFrom(from, to, id, amount, data);

        // Update holder balances
        if (from != address(0)) {
            uint256 balanceFrom = balanceOf(from, id);
            if (balanceFrom == amount) {
                _removeHolder(id, from);
            }
        }

        if (to != address(0)) {
            _addHolder(id, to);
        }
    }

    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public override
    {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);

        // Update holder balances
        if (from != address(0)) {
            for (uint256 i = 0; i < ids.length; i++) {
                uint256 balanceFrom = balanceOf(from, ids[i]);
                if (balanceFrom == amounts[i]) {
                    _removeHolder(ids[i], from);
                }
            }
        }

        if (to != address(0)) {
            for (uint256 i = 0; i < ids.length; i++) {
                _addHolder(ids[i], to);
            }
        }
    }
}
