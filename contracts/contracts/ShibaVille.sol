// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IVille {
    function safeMint(address to) external returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IBuildings {
     function safeMint(address to) external returns (uint256);
     function ownerOf(uint256 tokenId) external view returns (address owner);
     function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IBuildingInfo {
    // BuildingIfo structs
    struct BuildingData {
        buildingType data;
        uint256 level;
        uint256 theme;
    }

    struct buildingType {
        string name; //eg house
        uint256[] inputResourceIds;
        uint256[] inputResourceAmounts;
        uint256[] outputResourceIds;
        uint256[] outputResourceAmounts;
        uint256[] costResourceIds;
        uint256[] costResourceAmounts;
        uint256 energyCost;
        bool exist;
    }

    function addNewType(string memory name,
         uint256[] memory inputResourceIds,
         uint256[] memory inputResourceAmounts,
         uint256[] memory outputResourceIds,
         uint256[] memory outputResourceAmounts,
         uint256[] memory costResourceIds,
         uint256[] memory costResourceAmounts,
         uint256 energyCost) external returns (uint256);
    function setBuildingData(uint256 buildingId, uint256 buildingtype, uint256 theme) external;
    function getBuildingData(uint256 buildingId) external view returns (BuildingData memory);
    function getBuildingType(uint256 typeId) external view returns (buildingType memory);
}   

interface IResources {
    function mint(address to, uint256 id, uint256 amount) external;
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external;
    function burnBatch(address from, uint256[] memory ids, uint256[] memory values) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

interface IShares {
    function getHolders(uint256 tokenId) external view returns (address[] memory, uint256[] memory);
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;
}

interface IWar {
    function initiateBattle(uint256 attackerVilleId, uint256[] memory attackerTroopIds, uint256[] memory attackerTroopAmounts, uint256 defenderVilleId) external;
    function liberateVille(uint256 villeId, uint256[] memory liberatorTroopIds, uint256[] memory liberatorTroopAmounts) external;
}

interface ISVGold {
    
}

contract ShibaVille is IERC721Receiver {
    struct Land {
        uint256 buildingId;
        uint256 stakedAt;
    }

    struct VilleInfo {
        string name;
        uint256 energy;
        uint256 lastEnergyFilled;
        uint256 referrer;
        uint256 level;
        uint256 experience;
        bool occupied;
        uint256 occupiedBy;
        bool sharesIssued;
    }

    IVille public VilleContract;
    IBuildings public buildingsContract;
    IBuildingInfo public buildingInfoContract;
    IResources public resourcesContract;
    IShares public sharesContract;
    IWar public warContract;
    ISVGold public goldContract;

    mapping(uint256 => VilleInfo) public villes;
    mapping(uint256 => Land[16][16]) public grid;
    mapping(string => bool) private villeNames;

    address public dev;

    // Constants
    uint256 public constant BASE_ENERGY_CAP = 95;
    uint256 public constant MAX_STAKE_DURATION = 24 hours;
    uint256 public constant MIN_STAKE_DURATION = 1 hours;
    uint256 public constant BASE_EXP = 5;

    //Events
    event Staked(
        address indexed staker,
        uint256 buildingId,
        uint256 villeId,
        uint256 position,
        uint256 timestamp
    );
    event Unstaked(
        address indexed staker,
        uint256 buildingId,
        uint256 villeId,
        uint256 timestamp
    );
    event Claimed(
        address indexed staker,
        uint256 buildingId,
        uint256 villeId,
        uint256 timestamp
    );
    event NewTypeAdded(uint256 indexed timestamp, uint256 typeId);

    constructor(string memory _devname) {
        // Create the first ville for the dev
        villes[0] = VilleInfo({
            name: _devname,
            energy: 100,
            lastEnergyFilled: block.timestamp,
            referrer: 0,
            level: 1,
            experience: 0,
            occupied: false,
            occupiedBy: 0,
            sharesIssued: false
        });

        villeNames[_devname] = true;

        dev = msg.sender;
    }

    function createVille(string memory villeName, uint256 referrer) public {
        require(villes[referrer].level >= 1, "The referrer has no ville");
        // Trims and convert the name to lower case for case-insensitive uniqueness
        villeName = trim(villeName);
        string memory lowerCaseName = toLowerCase(villeName);

        require(
            bytes(lowerCaseName).length > 0,
            "Ville name cannot be empty or spaces only"
        );
        require(!villeNames[lowerCaseName], "Ville name must be unique");

        uint256 tokenId = VilleContract.safeMint(msg.sender);
        villes[tokenId] = VilleInfo({
            name: villeName,
            energy: 100,
            lastEnergyFilled: block.timestamp,
            referrer: referrer,
            level: 1,
            experience: 0,
            occupied: false,
            occupiedBy: 0,
            sharesIssued: false
        });

        villeNames[lowerCaseName] = true;

       
        /* Resource(BBM, FOOD, TECH, WORKER) */
        uint256[] memory ids = new uint256[](4);
        uint256[] memory amounts = new uint256[](4);
        for (uint i = 0; i < 4; i++) {
            ids[i] = i;
            amounts[i] = 100;
        }

        // Mint initial resources to the ville owner
        resourcesContract.mintBatch(msg.sender, ids, amounts);
    }

    function getVille(uint256 tokenId) public view returns (VilleInfo memory) {
        return villes[tokenId];
    }

    function getLands(
        uint256 tokenId
    ) public view returns (Land[16][16] memory) {
        return grid[tokenId];
    }

    function doesVilleNameExist(
        string memory villeName
    ) public view returns (bool) {
        return villeNames[villeName];
    }

    function getVilleEnergy(uint256 tokenId) public view returns (uint256) {
        VilleInfo memory ville = villes[tokenId];
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - ville.lastEnergyFilled;
        uint256 hoursElapsed = timeElapsed / 1 hours;
        uint256 potentialEnergy = ville.energy + hoursElapsed;
        uint256 energyCap = calculateEnergyScale(ville.level);

        if (potentialEnergy > energyCap) {
            return energyCap;
        } else {
            return potentialEnergy;
        }
    }

    function calculateEnergyScale(uint256 level) public pure returns (uint256) {
        return BASE_ENERGY_CAP + (level * 5);
    }

    function updateVilleEnergy(
        uint256 tokenId,
        uint256 amountToDeduct
    ) internal {
        VilleInfo storage ville = villes[tokenId];
        uint256 currentEnergy = getVilleEnergy(tokenId);

        require(currentEnergy >= amountToDeduct, "Not enough energy to deduct");

        ville.energy = currentEnergy - amountToDeduct;
        ville.lastEnergyFilled = block.timestamp;
    }

    function calculateLevel(
        uint256 currentLevel,
        uint256 currentExperience,
        uint256 newExperience
    ) public pure returns (uint256 level, uint256 remainingExperience) {
        uint256 requiredExperience = (currentLevel * 25) + 300; // Base required experience for level up
        uint256 totalExperience = currentExperience + newExperience; // Total experience after adding new experience

        if (totalExperience >= requiredExperience) {
            level = currentLevel + 1; // Level up
            remainingExperience = totalExperience - requiredExperience; // Calculate remaining experience
        } else {
            level = currentLevel; // No level up
            remainingExperience = totalExperience; // No change in remaining experience
        }
    }

    function distributeResources(
        uint256 tokenId,
        uint256[] memory resourceIds,
        uint256[] memory resourceAmounts,
        uint256 referrer
    ) internal {
        // We pay the referrer first
        uint256[] memory referrerShare = new uint256[](resourceIds.length);
        for (uint i = 0; i < resourceIds.length; i++) {
            uint share = (resourceAmounts[i] * 5) / 100; // 5% share
            referrerShare[i] = share;
            resourceAmounts[i] -= share;
        }
        resourcesContract.mintBatch(
            VilleContract.ownerOf(referrer),
            resourceIds,
            referrerShare
        );

        // Get the holders of shares for this tokenId
        (address[] memory holders, uint256[] memory balances) = sharesContract
            .getHolders(tokenId);

        // note to the reader! there is a huge room for optimization but we leave it like this for now, we will change when we optimize the whole contract
        // Calculate resource distribution

        for (uint h = 0; h < holders.length; h++) {
            uint256[] memory holderResourceAmount = new uint256[](
                resourceIds.length
            );
            for (uint i = 0; i < resourceIds.length; i++) {
                uint256 sharePercentage = (balances[h] * 100 ether) /
                    10000 /*Total shares */;
                holderResourceAmount[h] = ((resourceAmounts[i] / 5) *
                    sharePercentage); // 20% for share holders
            }
            // Mint resources to the holder
            resourcesContract.mintBatch(
                holders[h],
                resourceIds,
                holderResourceAmount
            );
        }

        // Remove 20% of the share holders
        for (uint i = 0; i < resourceIds.length; i++) {
            resourceAmounts[i] -= resourceAmounts[i] / 5;
        }
        // Mint 80% to ville owner
        resourcesContract.mintBatch(
            VilleContract.ownerOf(tokenId),
            resourceIds,
            resourceAmounts
        );
    }

    function villeMint(
        uint256 tokenId,
        uint256 newExperience,
        uint256[] memory resourceIds,
        uint256[] memory resourceAmounts
    ) internal {
        VilleInfo storage ville = villes[tokenId];

        // Update experience
        (ville.level, ville.experience) = calculateLevel(
            ville.level,
            ville.experience,
            newExperience
        );

        // Calculate resource distribution
        if (ville.occupied) {
            uint256 invaderVilleId = ville.occupiedBy;
            uint256[] memory invaderShare = new uint256[](resourceIds.length);
            for (uint i = 0; i < resourceIds.length; i++) {
                invaderShare[i] = resourceAmounts[i] / 2;
                resourceAmounts[i] -= invaderShare[i];
            }
            // Mint resources to the invader ville owner
            resourcesContract.mintBatch(
                VilleContract.ownerOf(invaderVilleId),
                resourceIds,
                invaderShare
            );
        }
        // Distribute remaining resources
        distributeResources(
            tokenId,
            resourceIds,
            resourceAmounts,
            ville.referrer
        );
    }

    function villeBurn(
        uint256 tokenId,
        uint256 energyToDeduct,
        uint256[] memory resourceId,
        uint256[] memory resourceAmount
    ) internal {
        address villeOwner = VilleContract.ownerOf(tokenId);

        // Deduct energy
        updateVilleEnergy(tokenId, energyToDeduct);

        resourcesContract.burnBatch(villeOwner, resourceId, resourceAmount);
    }

    // DEV related functions
    modifier onlyDev() {
        require(msg.sender == dev, "Caller is not the dev!");
        _;
    }

    function init(
        address _ville,
        address _buildings,
        address _buildingInfo,
        address _resources,
        address _shares,
        address _war,
        address _gold
    ) external onlyDev {
        VilleContract = IVille(_ville);
        buildingsContract = IBuildings(_buildings);
        buildingInfoContract = IBuildingInfo(_buildingInfo);
        resourcesContract = IResources(_resources);
        sharesContract = IShares(_shares);
        warContract = IWar(_war);
        goldContract = ISVGold(_gold);
    }

    function createBuildingType(
        string memory name,
        uint256[] memory inputResourceIds,
        uint256[] memory inputResourceAmounts,
        uint256[] memory outputResourceIds,
        uint256[] memory outputResourceAmounts,
        uint256[] memory costResourceIds,
        uint256[] memory costResourceAmounts,
        uint256 energyCost
    ) external onlyDev {
        uint256 typeId = buildingInfoContract.addNewType(
            name,
            inputResourceIds,
            inputResourceAmounts,
            outputResourceIds,
            outputResourceAmounts,
            costResourceIds,
            costResourceAmounts,
            energyCost
        );
        emit NewTypeAdded(block.timestamp, typeId);
    }

    // DEV related functions

    function createBuilding(
        uint256 villeId,
        uint256 buildingTypeId,
        uint256 theme
    ) external {
        require(
            VilleContract.ownerOf(villeId) == msg.sender,
            "You don't own this ville!"
        );
        IBuildingInfo.buildingType memory typeData = buildingInfoContract
            .getBuildingType(buildingTypeId);
        require(typeData.exist, "This type doesn't exist yet!");
        // check balance
        for (uint i = 0; i < typeData.costResourceIds.length; i++) {
            require(
                resourcesContract.balanceOf(
                    msg.sender,
                    typeData.costResourceIds[i]
                ) >= typeData.costResourceAmounts[i],
                "You don't have the cost required to mint this type of building!"
            );
        }
        // burn the tokens
        resourcesContract.burnBatch(
            msg.sender,
            typeData.costResourceIds,
            typeData.costResourceAmounts
        );

        // Mint the ERC721 token and get the new tokenId
        uint256 tokenId = buildingsContract.safeMint(msg.sender);

        // add the building info
        buildingInfoContract.setBuildingData(tokenId, buildingTypeId, theme);

        //add event
    }

    function stake(
        uint256 buildingId,
        uint256 villeId,
        uint256 x,
        uint256 y
    ) external {
        require(
            buildingsContract.ownerOf(buildingId) == msg.sender,
            "You do not own the building"
        );
        require(
            VilleContract.ownerOf(villeId) == msg.sender,
            "You do not own the ville"
        );
        require(
            grid[villeId][x][y].buildingId == 0,
            "This land is already occupied"
        );

        // Get resource data from BuildingInfo contract
        IBuildingInfo.BuildingData memory buildingData = buildingInfoContract
            .getBuildingData(buildingId);
        // Deduct energy
        updateVilleEnergy(villeId, buildingData.data.energyCost * 5);
        // Burn resources from ShibaVille contract
        villeBurn(
            villeId,
            5,
            buildingData.data.inputResourceIds,
            buildingData.data.inputResourceAmounts
        );
        // Transfer the building to shibaville
        buildingsContract.safeTransferFrom(
            msg.sender,
            address(this),
            buildingId
        );
        // Update the Land
        grid[villeId][x][y].buildingId = buildingId;
        grid[villeId][x][y].stakedAt = block.timestamp;

        emit Staked(msg.sender, buildingId, villeId, x, block.timestamp);
    }

    function unstake(
        uint256 buildingId,
        uint256 villeId,
        uint256 x,
        uint256 y
    ) external {
        require(
            buildingsContract.ownerOf(buildingId) == msg.sender,
            "You do not own the building"
        );
        require(
            VilleContract.ownerOf(villeId) == msg.sender,
            "You do not own the ville"
        );
        Land storage LandInfo = grid[villeId][x][y];
        require(LandInfo.buildingId == buildingId, "Building is not staked");
        require(
            block.timestamp - LandInfo.stakedAt >= MIN_STAKE_DURATION,
            "Building not staked for minimum duration"
        );
        address villeOwner = msg.sender;

        // Get resource data from BuildingInfo contract
        IBuildingInfo.BuildingData memory buildingData = buildingInfoContract
            .getBuildingData(LandInfo.buildingId);
        // Deduct energy
        updateVilleEnergy(villeId, buildingData.data.energyCost * 5);

        // Mint resources from ShibaVille contract
        villeMint(
            villeId,
            BASE_EXP * buildingData.level,
            buildingData.data.outputResourceIds,
            buildingData.data.outputResourceAmounts
        );

        VilleContract.safeTransferFrom(
            address(this),
            villeOwner,
            LandInfo.buildingId
        );

        emit Unstaked(
            villeOwner,
            LandInfo.buildingId,
            villeId,
            block.timestamp
        );
        LandInfo.buildingId = 0; // Remove staking info
        LandInfo.stakedAt = 0; // Remove staking info
    }

    function claim(
        uint256 buildingId,
        uint256 villeId,
        uint256 x,
        uint256 y
    ) external {
        require(
            VilleContract.ownerOf(villeId) == msg.sender,
            "You do not own the ville"
        );
        Land storage LandInfo = grid[villeId][x][y];
        require(LandInfo.buildingId == buildingId, "Building is not staked");
        require(
            block.timestamp - LandInfo.stakedAt >= MIN_STAKE_DURATION,
            "Building not staked for minimum claim duration"
        );
        address villeOwner = msg.sender;

        // Get resource data from BuildingInfo contract
        IBuildingInfo.BuildingData memory buildingData = buildingInfoContract
            .getBuildingData(LandInfo.buildingId);

        // Deduct energy
        updateVilleEnergy(villeId, buildingData.data.energyCost);
        // Mint resources
        villeMint(
            villeId,
            5 * buildingData.level,
            buildingData.data.outputResourceIds,
            buildingData.data.outputResourceAmounts
        );

        LandInfo.stakedAt = block.timestamp; // Reset the staking time

        emit Claimed(villeOwner, LandInfo.buildingId, villeId, block.timestamp);
    }

    function createShares(uint256 tokenId) public {
        require(
            VilleContract.ownerOf(tokenId) == msg.sender,
            "Sender does not own the token"
        );
        require(
            !villes[tokenId].sharesIssued,
            "Shares already issued for this ville"
        );
        require(
            villes[tokenId].level > 9,
            "You have to reach level 10 before issuing shares"
        );

        villes[tokenId].sharesIssued = true;

        // Mint 100% shares to the ville owner
        sharesContract.mint(
            msg.sender,
            tokenId /* Share ID */,
            10000 /* Total shares */,
            ""
        );
    }

    function initiateBattle(
        uint256 attackerVilleId,
        uint256 defenderVilleId,
        uint256[] memory attackerTroopIds,
        uint256[] memory attackerTroopAmounts
    ) internal {
        require(
            !villes[attackerVilleId].occupied,
            "Attacker ville is occupied"
        );
        require(
            !villes[defenderVilleId].occupied,
            "Defender ville is already occupied"
        );

        warContract.initiateBattle(
            attackerVilleId,
            attackerTroopIds,
            attackerTroopAmounts,
            defenderVilleId
        );
    }

    function finalizeBattle(
        uint256 attackerVilleId,
        uint256 defenderVilleId,
        bool attackerWon,
        uint256[] memory attackerTroopIds,
        uint256[] memory attackerTroopsLost,
        uint256[] memory defenderTroopIds,
        uint256[] memory defenderTroopsLost
    ) internal {
        if (attackerWon) {
            villes[defenderVilleId].occupied = true;
            villes[defenderVilleId].occupiedBy = attackerVilleId;
        } else {
            villes[attackerVilleId].occupied = false;
        }

        // Burn dead troops for both attacker and defender
        resourcesContract.burnBatch(
            VilleContract.ownerOf(attackerVilleId),
            attackerTroopIds,
            attackerTroopsLost
        );

        resourcesContract.burnBatch(
            VilleContract.ownerOf(defenderVilleId),
            defenderTroopIds,
            defenderTroopsLost
        );
    }

    function liberateVille(
        uint256 occupiedVilleId,
        uint256[] memory liberatorTroopIds,
        uint256[] memory liberatorTroopAmounts
    ) internal {
        require(villes[occupiedVilleId].occupied, "Ville is not occupied");

        warContract.liberateVille(
            occupiedVilleId,
            liberatorTroopIds,
            liberatorTroopAmounts
        );
    }

    function finalizeLiberation(
        uint256 occupiedVilleId,
        bool liberatorWon,
        uint256[] memory liberatorTroopIds,
        uint256[] memory liberatorTroopsLost,
        uint256[] memory occupyingTroopIds,
        uint256[] memory occupyingTroopsLost
    ) internal {
        if (liberatorWon) {
            villes[occupiedVilleId].occupied = false;
            villes[occupiedVilleId].occupiedBy = 0;
        }

        // Burn dead troops for both liberator and occupying troops
        resourcesContract.burnBatch(
            VilleContract.ownerOf(occupiedVilleId),
            liberatorTroopIds,
            liberatorTroopsLost
        );
        resourcesContract.burnBatch(
            VilleContract.ownerOf(occupiedVilleId),
            occupyingTroopIds,
            occupyingTroopsLost
        );
    }

    // Utils
    function trim(string memory str) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        uint256 start = 0;
        uint256 end = strBytes.length;

        while (start < end && strBytes[start] == 0x20) {
            start++;
        }
        while (end > start && strBytes[end - 1] == 0x20) {
            end--;
        }

        bytes memory trimmedBytes = new bytes(end - start);
        for (uint256 i = start; i < end; i++) {
            trimmedBytes[i - start] = strBytes[i];
        }

        return string(trimmedBytes);
    }

    function toLowerCase(
        string memory str
    ) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase characters are in the range 0x41 ('A') to 0x5A ('Z')
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // Convert to lowercase by adding 32 to the ASCII value
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        require(msg.sender == address(buildingsContract), "Wrong NFT");
        return this.onERC721Received.selector;
    }
}
