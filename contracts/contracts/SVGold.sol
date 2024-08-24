// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SVGold is ERC20 {
    address public shibavilleContract;

    constructor() ERC20("ShibaVille Gold", "SVG") {
        shibavilleContract = msg.sender;
    }

    modifier onlyMainContract() {
        require(msg.sender == shibavilleContract, "Only the main Shibaville contract can mint tokens.");
        _;
    }

    function mint(address to, uint256 amount) external onlyMainContract {
        _mint(to, amount);
    }

}