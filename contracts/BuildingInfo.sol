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

    struct buildingType {
        string name; //eg house
        uint256[] inputResourceIds;
        uint256[] inputResourceAmounts;
        uint256[] outputResourceIds;
        uint256[] outputResourceAmounts;
        bool exist;
    }

    mapping(uint256 => BuildingData) public buildingData;
    mapping(uint256 => buildingType) private types;
    address public shibavilleContract;
    uint256 counter = 0;

     modifier onlyShibavilleContract() {
        require(msg.sender == shibavilleContract, "Caller is not the Shibaville contract");
        _;
    }

    constructor() {
        shibavilleContract = msg.sender;
    }

    function setBuildingData(
        uint256 buildingId,
        uint256 buildingtype,
        uint256 theme
    ) external onlyShibavilleContract {
        require(types[buildingtype].exist, "This buildingtype dose not exist");
        buildingType memory requirements = types[buildingtype];
        buildingData[buildingId] = BuildingData({
            inputResourceIds: requirements.inputResourceIds,
            inputResourceAmounts: requirements.inputResourceAmounts,
            outputResourceIds: requirements.outputResourceIds,
            outputResourceAmounts: requirements.outputResourceAmounts,
            level: 1,
            theme: theme
        });
    }

    function addNewType(string memory name,
         uint256[] memory inputResourceIds,
         uint256[] memory inputResourceAmounts,
         uint256[] memory outputResourceIds,
         uint256[] memory outputResourceAmounts) external onlyShibavilleContract returns (uint256) {

        uint256 newId = counter + 1;
        types[newId] = buildingType({
            name: name,
            inputResourceIds: inputResourceIds,
            inputResourceAmounts: inputResourceAmounts,
            outputResourceIds: outputResourceIds,
            outputResourceAmounts: outputResourceAmounts,
            exist: true
        });

        counter++;
    return newId;
    }

    function getBuildingData(uint256 buildingId) external view returns (BuildingData memory) {
        return buildingData[buildingId];
    }

    // todo level update
}
