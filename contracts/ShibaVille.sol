// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import "./Ville.sol";
import "./Buildings.sol";
import "./BuildingInfo.sol";
import "./Resources.sol";
import "./Shares.sol";
import "./War.sol";
import "./SVGold.sol";


contract ShibaVille {

    struct Land {
        uint256 x;
        uint256 y;
        uint256 buildingId;
        uint256 stakedAt;
    }

    struct VilleInfo {
        string name;
        Land[16][16] grid;
        uint256 energy;
        uint256 lastEnergyFilled;
        uint256 referrer;
        uint256 level;
        uint256 experience;
        bool occupied;
        uint256 occupiedBy;
        bool sharesIssued;
    }

    Ville public VilleContract;
    Buildings public buildingsContract;
    BuildingInfo public buildingInfoContract;
    Resources public resourcesContract;
    Shares public sharesContract;
    War public warContract;
    SVGold public goldContract;

    mapping(uint256 => VilleInfo) public villes;
    mapping(string => bool) private villeNames;
    

    address public dev;

    // Constant for base energy cap
    uint256 public constant BASE_ENERGY_CAP = 95;
    // Staking constants
    uint256 public constant MAX_STAKE_DURATION = 24 hours;
    uint256 public constant MIN_STAKE_DURATION = 1 hours;

    //Events
    event Staked(address indexed staker, uint256 buildingId, uint256 villeId, uint256 position, uint256 timestamp);
    event Unstaked(address indexed staker, uint256 buildingId, uint256 villeId, uint256 timestamp);
    event Claimed(address indexed staker, uint256 buildingId, uint256 villeId, uint256 timestamp);

    constructor(string memory Ville_URI, string memory Buildings_URI, string memory Resources_URI, string memory Shares_URI) {
        VilleContract = new Ville(Ville_URI);
        buildingsContract = new Buildings(Buildings_URI);
        buildingInfoContract = new BuildingInfo();
        resourcesContract = new Resources(Resources_URI);
        sharesContract = new Shares(Shares_URI);
        warContract = War(address(resourcesContract));
        goldContract = new SVGold();
        dev = msg.sender;
    }
   

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

    function toLowerCase(string memory str) internal pure returns (string memory) {
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

    function initLands(uint256 size) internal pure returns (Land[16][16] memory) {
        Land[16][16] memory lands;
        for (uint x = 0; x < size; x++) {
             for (uint y = 0; y < size; y++) {
                Land memory empty = Land(x, y, 0, 0);
                lands[x][y] = empty;
             }
        }

        return lands;
    }
    function createVille(string memory villeName, uint256 referrer) public {
        require(villes[referrer].level >= 1, "The referrer has no ville");
        // Trims and convert the name to lower case for case-insensitive uniqueness
        villeName = trim(villeName);
        string memory lowerCaseName = toLowerCase(villeName);

        require(bytes(lowerCaseName).length > 0, "Ville name cannot be empty or spaces only");
        require(!villeNames[lowerCaseName], "Ville name must be unique");

        uint256 tokenId = VilleContract.safeMint(msg.sender);
        Land[16][16] memory emptyLands = initLands(16);
        villes[tokenId] = VilleInfo({
            name: villeName,
            grid: emptyLands,
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

        // Mint initial resources to the ville owner
        resourcesContract.mint(msg.sender, 0 /* Resource ID 0 Basic building materials(BBM) */, 100, "");
    }

    function getVille(uint256 tokenId) public view returns (VilleInfo memory) {
        return villes[tokenId];
    }

    function getlands(uint256 tokenId) public view returns (Land[16][16] memory) {
        return villes[tokenId].grid;
    }

    function doesVilleNameExist(string memory villeName) public view returns (bool) {
        return villeNames[villeName];
    }

    function getVilleEnergy(uint256 tokenId) public view returns (uint256) {
        VilleInfo storage ville = villes[tokenId];
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

    function updateVilleEnergy(uint256 tokenId, uint256 amountToDeduct) internal {
        VilleInfo storage ville = villes[tokenId];
        uint256 currentEnergy = getVilleEnergy(tokenId);

        require(currentEnergy >= amountToDeduct, "Not enough energy to deduct");

        ville.energy = currentEnergy - amountToDeduct;
        ville.lastEnergyFilled = block.timestamp;
    }

    function calculateLevel(uint256 currentLevel, uint256 currentExperience, uint256 newExperience) public pure returns (uint256 level, uint256 remainingExperience) {
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

    
    function distributeResources(uint256 tokenId, uint256[] memory resourceIds, uint256[] memory resourceAmounts, uint256 referrer) internal {
        // We pay the referrer first
        uint256[] memory referrerShare = new uint256[](resourceIds.length);
        for (uint i = 0; i < resourceIds.length; i++) {
            uint share = (resourceAmounts[i] * 5) / 100; // 5% share
            referrerShare[i] = share;
            resourceAmounts[i] -= share;
        }
        resourcesContract.mintBatch(VilleContract.ownerOf(referrer), resourceIds, referrerShare, "");
        
        // Get the holders of shares for this tokenId
        (address[] memory holders, uint256[] memory balances) = sharesContract.getHolders(tokenId);
        
        // note to the reader! there is a huge room for optimization but we leave it like this for now, we will change when we optimize the whole contract
        // Calculate resource distribution
         
        for (uint h = 0; h < holders.length; h++) {
            uint256[] memory holderResourceAmount = new uint256[] (resourceIds.length);
            for (uint i = 0; i < resourceIds.length; i++) {
                uint256 sharePercentage = (balances[h] * 100 ether) / 10000 /*Total shares */;
                holderResourceAmount[h] = ((resourceAmounts[i] / 5) * sharePercentage); // 20% for share holders
            }
            // Mint resources to the holder
            resourcesContract.mintBatch(holders[h], resourceIds, holderResourceAmount, "");
         }

        // Mint 80% to ville owner
        for (uint i = 0; i < resourceIds.length; i++) {
            resourceAmounts[i] -= resourceAmounts[i] / 5;
        }
        resourcesContract.mintBatch(VilleContract.ownerOf(tokenId), resourceIds, resourceAmounts, "");
    }
    

    function villeMint(uint256 tokenId, uint256 newExperience, uint256 energyToDeduct, uint256[] memory resourceIds, uint256[] memory resourceAmounts) internal {
        VilleInfo storage ville = villes[tokenId];
        
        // Deduct energy
        updateVilleEnergy(tokenId, energyToDeduct);
        
        // Update experience
        (ville.level, ville.experience) = calculateLevel(ville.level, ville.experience, newExperience);

        // Calculate resource distribution
        if (ville.occupied) {
            uint256 invaderVilleId = ville.occupiedBy;
            uint256[] memory invaderShare = new uint256[](resourceIds.length);
            for (uint i = 0; i < resourceIds.length; i++) {

            invaderShare[i] = resourceAmounts[i] / 2;
            resourceAmounts[i] -= invaderShare[i];
            }
            // Mint resources to the invader ville owner
            resourcesContract.mintBatch(VilleContract.ownerOf(invaderVilleId), resourceIds, invaderShare, "");
        } 
        // Distribute remaining resources
        distributeResources(tokenId, resourceIds, resourceAmounts, ville.referrer);

    }

    function villeBurn(uint256 tokenId, uint256 energyToDeduct, uint256[] memory resourceId, uint256[] memory resourceAmount) internal {
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

    function createBuildingType(string memory name,
         uint256[] memory inputResourceIds,
         uint256[] memory inputResourceAmounts,
         uint256[] memory outputResourceIds,
         uint256[] memory outputResourceAmounts) external onlyDev returns (uint256) {

        uint typeId = buildingInfoContract.addNewType(name, inputResourceIds, inputResourceAmounts, outputResourceIds, outputResourceAmounts);

        return typeId;
    }
    // DEV related functions


    function createBuilding(uint256 buildingType, uint256 theme, address to) external returns (uint256) {
        // Mint the ERC721 token and get the new tokenId
        uint256 tokenId = buildingsContract.safeMint(to);

        // add the building info
        buildingInfoContract.setBuildingData(tokenId, buildingType, theme);

        return tokenId;
    }

    function stake(uint256 buildingId, uint256 villeId, uint256 x, uint256 y) external {
        require(buildingsContract.ownerOf(buildingId) == msg.sender, "You do not own the building");
        require(VilleContract.ownerOf(villeId) == msg.sender, "You do not own the ville");
        require(villes[villeId].grid[x][y].buildingId == 0 , "This land is already occupied");

        // Get resource data from BuildingInfo contract
        BuildingInfo.BuildingData memory buildingData = buildingInfoContract.getBuildingData(buildingId);

        // Burn resources from ShibaVille contract
        villeBurn(villeId, 5, buildingData.inputResourceIds, buildingData.inputResourceAmounts);
        // Transfer the building to shibaville
        buildingsContract.safeTransferFrom(msg.sender, address(this), buildingId);
        // Update the Land
        Land memory target = villes[villeId].grid[x][y];
        target.buildingId = buildingId;
        target.stakedAt = block.timestamp;

        emit Staked(msg.sender, buildingId, villeId, x, block.timestamp);
    }

    function unstake(uint256 buildingId, uint256 villeId, uint256 x, uint256 y) external {
        require(buildingsContract.ownerOf(buildingId) == msg.sender, "You do not own the building");
        require(VilleContract.ownerOf(villeId) == msg.sender, "You do not own the ville");
        Land storage LandInfo = villes[villeId].grid[x][y];
        require(LandInfo.buildingId == buildingId, "Building is not staked");
        require(block.timestamp - LandInfo.stakedAt >= MIN_STAKE_DURATION, "Building not staked for minimum duration");
        address villeOwner = msg.sender;

        // Get resource data from BuildingInfo contract
        BuildingInfo.BuildingData memory buildingData = buildingInfoContract.getBuildingData(LandInfo.buildingId);

        // Mint resources from ShibaVille contract
        villeMint(villeId, 5 * buildingData.level /* New experience */, 5 /* Energy to deduct */, buildingData.outputResourceIds, buildingData.outputResourceAmounts);

        VilleContract.safeTransferFrom(address(this), villeOwner, LandInfo.buildingId);

        emit Unstaked(villeOwner, LandInfo.buildingId, villeId, block.timestamp);
        LandInfo.buildingId = 0; // Remove staking info
        LandInfo.stakedAt = 0; // Remove staking info
    }

    function claim(uint256 buildingId, uint256 villeId, uint256 x, uint256 y) external {
        require(VilleContract.ownerOf(villeId) == msg.sender, "You do not own the ville");
        Land storage LandInfo = villes[villeId].grid[x][y];
        require(LandInfo.buildingId == buildingId, "Building is not staked");
        require(block.timestamp - LandInfo.stakedAt >= MIN_STAKE_DURATION, "Building not staked for minimum claim duration");
        address villeOwner = msg.sender;

        // Get resource data from BuildingInfo contract
        BuildingInfo.BuildingData memory buildingData = buildingInfoContract.getBuildingData(LandInfo.buildingId);

        // Mint resources
        villeMint(villeId, 5 * buildingData.level /* New experience */, 1 /* Energy to deduct */, buildingData.outputResourceIds, buildingData.outputResourceAmounts);

        LandInfo.stakedAt = block.timestamp; // Reset the staking time

        emit Claimed(villeOwner, LandInfo.buildingId, villeId, block.timestamp);
    }

    function createShares(uint256 tokenId) public {
        require(VilleContract.ownerOf(tokenId) == msg.sender, "Sender does not own the token");
        require(!villes[tokenId].sharesIssued, "Shares already issued for this ville");
        require(villes[tokenId].level > 9, "You have to reach level 10 before issuing shares");

        villes[tokenId].sharesIssued = true;

        // Mint 100% shares to the ville owner
        sharesContract.mint(msg.sender, tokenId /* Share ID */, 10000 /* Total shares */, "");
    }

    function initiateBattle(uint256 attackerVilleId, uint256 defenderVilleId, uint256[] memory attackerTroopIds, uint256[] memory attackerTroopAmounts) internal {
        require(!villes[attackerVilleId].occupied, "Attacker ville is occupied");
        require(!villes[defenderVilleId].occupied, "Defender ville is already occupied");

        warContract.initiateBattle(attackerVilleId, attackerTroopIds, attackerTroopAmounts, defenderVilleId);
    }

    function finalizeBattle(uint256 attackerVilleId, uint256 defenderVilleId, bool attackerWon, uint256[] memory attackerTroopIds, uint256[] memory attackerTroopsLost, uint256[] memory defenderTroopIds, uint256[] memory defenderTroopsLost) internal {
        if (attackerWon) {
            villes[defenderVilleId].occupied = true;
            villes[defenderVilleId].occupiedBy = attackerVilleId;
        } else {
            villes[attackerVilleId].occupied = false;
        }

        // Burn dead troops for both attacker and defender 
        resourcesContract.burnBatch(VilleContract.ownerOf(attackerVilleId), attackerTroopIds, attackerTroopsLost);
        
        resourcesContract.burnBatch(VilleContract.ownerOf(defenderVilleId), defenderTroopIds, defenderTroopsLost);
        
    }

    function liberateVille(uint256 occupiedVilleId, uint256[] memory liberatorTroopIds, uint256[] memory liberatorTroopAmounts) internal {
        require(villes[occupiedVilleId].occupied, "Ville is not occupied");

        warContract.liberateVille(occupiedVilleId, liberatorTroopIds, liberatorTroopAmounts);
    }

    function finalizeLiberation(uint256 occupiedVilleId, bool liberatorWon, uint256[] memory liberatorTroopIds, uint256[] memory liberatorTroopsLost, uint256[] memory occupyingTroopIds, uint256[] memory occupyingTroopsLost) internal {
        if (liberatorWon) {
            villes[occupiedVilleId].occupied = false;
            villes[occupiedVilleId].occupiedBy = 0;
        }

        // Burn dead troops for both liberator and occupying troops
        resourcesContract.burnBatch(VilleContract.ownerOf(occupiedVilleId), liberatorTroopIds, liberatorTroopsLost);
        resourcesContract.burnBatch(VilleContract.ownerOf(occupiedVilleId), occupyingTroopIds, occupyingTroopsLost);
    }

}
