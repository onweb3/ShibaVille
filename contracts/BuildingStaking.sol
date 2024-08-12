// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IShibaVille {
     struct land {
        uint256 x;
        uint256 y;
        uint256 buildingId;
    }
    function villeMint(uint256 tokenId, uint256 newExperience, uint256 energyToDeduct, uint256 x, uint256 y, uint256 buildingId, bool update, uint256[] memory resourceIds, uint256[] memory resourceAmounts) external;
    function villeBurn(uint256 tokenId, uint256 energyToDeduct, uint256[] memory resourceIds, uint256[] memory resourceAmounts) external;
    function getlands(uint256 tokenId) external view returns (land[][] memory);
}

interface IBuildingInfo {
    struct BuildingData {
        uint256[] inputResourceIds;
        uint256[] inputResourceAmounts;
        uint256[] outputResourceIds;
        uint256[] outputResourceAmounts;
        uint256 level;
        uint256 theme;
    }

    function getBuildingData(uint256 buildingId) external view returns (BuildingData memory);
}

contract ERC721Staking {
    struct StakingInfo {
        uint256 buildingId;
        uint256 villeId;
        uint256 stakedAt;
        uint256 x;
        uint256 y;
    }

    mapping(uint256 => StakingInfo) public stakedBuildings;
    mapping(uint256 => uint256[]) public villeToStakedBuildings; // Mapping to hold staked buildings for each ville

    IERC721 public erc721Contract;
    IERC721 public villeContract;
    IShibaVille public shibaVilleContract;
    IBuildingInfo public buildingInfoContract;
    

    uint256 public constant MAX_STAKE_DURATION = 24 hours;
    uint256 public constant MIN_STAKE_DURATION = 1 hours;


    event Staked(address indexed staker, uint256 buildingId, uint256 villeId, uint256 position, uint256 timestamp);
    event Unstaked(address indexed staker, uint256 buildingId, uint256 villeId, uint256 timestamp);
    event Claimed(address indexed staker, uint256 buildingId, uint256 villeId, uint256 timestamp);

    constructor(address _villeContractAddress, address _erc721ContractAddress, address _buildingInfoContractAddress) {
        erc721Contract = IERC721(_erc721ContractAddress);
        villeContract = IERC721(_villeContractAddress);
        buildingInfoContract = IBuildingInfo(_buildingInfoContractAddress);
        shibaVilleContract = IShibaVille(msg.sender);
    }

    function stake(uint256 buildingId, uint256 villeId, uint256 x, uint256 y) external {
        require(stakedBuildings[buildingId].buildingId == 0, "Building is already staked");
        require(erc721Contract.ownerOf(buildingId) == msg.sender, "You do not own the building");
        require(villeContract.ownerOf(villeId) == msg.sender, "You do not own the ville");
        require(shibaVilleContract.getlands(villeId)[x][y].buildingId == 0 , "Position is already occupied");

        // Get resource data from BuildingInfo contract
        IBuildingInfo.BuildingData memory buildingData = buildingInfoContract.getBuildingData(buildingId);

        // Burn resources from ShibaVille contract
        shibaVilleContract.villeBurn(villeId, 5 /* Energy to deduct */, buildingData.inputResourceIds, buildingData.inputResourceAmounts);

        stakedBuildings[buildingId] = StakingInfo({
            buildingId: buildingId,
            villeId: villeId,
            stakedAt: block.timestamp,
            x: x,
            y: y
        });

        villeToStakedBuildings[villeId].push(buildingId); // Add buildingId to the ville's list of staked buildings

        erc721Contract.safeTransferFrom(msg.sender, address(this), buildingId);
        emit Staked(msg.sender, buildingId, villeId, x, block.timestamp);
    }

    function unstake(uint256 buildingId) external {
        StakingInfo storage stakingInfo = stakedBuildings[buildingId];
        require(stakingInfo.buildingId != 0, "Building is not staked");
        require(block.timestamp - stakingInfo.stakedAt >= MAX_STAKE_DURATION, "Building not staked for minimum duration");
        address villeOwner = villeContract.ownerOf(stakingInfo.villeId);

        // Get resource data from BuildingInfo contract
        IBuildingInfo.BuildingData memory buildingData = buildingInfoContract.getBuildingData(stakingInfo.buildingId);

        // Mint resources from ShibaVille contract
        shibaVilleContract.villeMint(stakingInfo.villeId, 5 * buildingData.level /* New experience */, 5 /* Energy to deduct */, stakingInfo.x, stakingInfo.y, stakingInfo.buildingId, true, buildingData.outputResourceIds, buildingData.outputResourceAmounts);

        erc721Contract.safeTransferFrom(address(this), villeOwner, stakingInfo.buildingId);

        emit Unstaked(villeOwner, stakingInfo.buildingId, stakingInfo.villeId, block.timestamp);
        delete stakedBuildings[stakingInfo.buildingId]; // Remove staking info

        // Remove buildingId from the ville's list of staked buildings
        uint256[] storage stakedBuildingsList = villeToStakedBuildings[stakingInfo.villeId];
        for (uint256 i = 0; i < stakedBuildingsList.length; i++) {
            if (stakedBuildingsList[i] == buildingId) {
                stakedBuildingsList[i] = stakedBuildingsList[stakedBuildingsList.length - 1];
                stakedBuildingsList.pop();
                break;
            }
        }
    }

    function claim(uint256 buildingId) external {
        StakingInfo storage stakingInfo = stakedBuildings[buildingId];
        require(stakingInfo.buildingId != 0, "Building is not staked");
        require(block.timestamp - stakingInfo.stakedAt >= MIN_STAKE_DURATION, "Building not staked for minimum claim duration");
        address villeOwner = villeContract.ownerOf(stakingInfo.villeId);

        // Get resource data from BuildingInfo contract
        IBuildingInfo.BuildingData memory buildingData = buildingInfoContract.getBuildingData(stakingInfo.buildingId);

        // Mint resources from ShibaVille contract
        shibaVilleContract.villeMint(stakingInfo.villeId, 5 * buildingData.level /* New experience */, 5 /* Energy to deduct */, stakingInfo.x, stakingInfo.y, stakingInfo.buildingId, false, buildingData.outputResourceIds, buildingData.outputResourceAmounts);

        stakingInfo.stakedAt = block.timestamp; // Reset the staking time

        emit Claimed(villeOwner, stakingInfo.buildingId, stakingInfo.villeId, block.timestamp);
    }

    function getStakeInfo(uint256 villeId) external view returns (StakingInfo[] memory) {
        uint256[] memory stakedBuildingIds = villeToStakedBuildings[villeId];
        StakingInfo[] memory stakingInfos = new StakingInfo[](stakedBuildingIds.length);

        for (uint256 i = 0; i < stakedBuildingIds.length; i++) {
            stakingInfos[i] = stakedBuildings[stakedBuildingIds[i]];
        }

        return stakingInfos;
    }

   
}
