// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract BuildingInfo {
    struct BuildingData {
        uint256[] inputResourceIds;
        uint256[] inputResourceAmounts;
        uint256[] outputResourceIds;
        uint256[] outputResourceAmounts;
        uint256 level;
        uint256 theme;
    }

    mapping(uint256 => BuildingData) public buildingData;

    address public shibavilleContract;

     modifier onlyShibavilleContract() {
        require(msg.sender == shibavilleContract, "Caller is not the Shibaville contract");
        _;
    }

    constructor() {
        shibavilleContract = msg.sender;
    }

    function setBuildingData(
        uint256 buildingId,
        uint256[] memory inputResourceIds,
        uint256[] memory inputResourceAmounts,
        uint256[] memory outputResourceIds,
        uint256[] memory outputResourceAmounts,
        uint256 theme
    ) external onlyShibavilleContract {
        require(inputResourceIds.length == inputResourceAmounts.length, "Input resources and amounts length mismatch");
        require(outputResourceIds.length == outputResourceAmounts.length, "Output resources and amounts length mismatch");

        buildingData[buildingId] = BuildingData({
            inputResourceIds: inputResourceIds,
            inputResourceAmounts: inputResourceAmounts,
            outputResourceIds: outputResourceIds,
            outputResourceAmounts: outputResourceAmounts,
            level: 1,
            theme: theme
        });
    }

    function getBuildingData(uint256 buildingId) external view returns (BuildingData memory) {
        return buildingData[buildingId];
    }

    // todo level update
}
