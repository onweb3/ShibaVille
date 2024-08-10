// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./Ville.sol";
import "./Buildings.sol";
import "./BuildingInfo.sol";
import "./BuildingStaking.sol";
import "./Resources.sol";
import "./Shares.sol";
import "./War.sol";



contract ShibaVille {
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

    Ville public VilleContract;
    Buildings public buildingsContract;
    BuildingInfo public buildingInfoContract;
    Resources public resourcesContract;
    Shares public sharesContract;
    War public warContract;
    mapping(uint256 => VilleInfo) public villes;
    mapping(string => bool) private villeNames;

    address public dev;
    address[] public authorizedContracts;

    // Constant for base energy cap
    uint256 public constant BASE_ENERGY_CAP = 95;

    constructor(string memory Ville_URI, string memory Buildings_URI, string memory Resources_URI, string memory Shares_URI) {
        VilleContract = new Ville(Ville_URI);
        addAuthorizedContract(address(VilleContract));
        buildingsContract = new Buildings(Buildings_URI);
        buildingInfoContract = new BuildingInfo();
        resourcesContract = new Resources(Resources_URI);
        sharesContract = new Shares(Shares_URI);
        warContract = War(address(resourcesContract));
        dev = msg.sender;
    }

   
    modifier authorizedOnly() {
        bool isAuthorized = false;
        for (uint i = 0; i < authorizedContracts.length; i++) {
            if (authorizedContracts[i] == msg.sender) {
                isAuthorized = true;
                break;
            }
        }
        require(isAuthorized, "Caller is not authorized");
        _;
    }

    modifier onlyDev() {
        require(msg.sender == dev, "Caller is not the dev!");
        _;
    }

    function addAuthorizedContract(address _contract) internal {
        authorizedContracts.push(_contract);
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


    function createVille(string memory villeName, uint256 referrer) public {
        require(villes[referrer].level >= 1, "The referrer has no ville");
        // Trims and convert the name to lower case for case-insensitive uniqueness
        villeName = trim(villeName);
        string memory lowerCaseName = toLowerCase(villeName);

        require(bytes(lowerCaseName).length > 0, "Ville name cannot be empty or spaces only");
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

        // Mint initial resources to the ville owner
        resourcesContract.mint(msg.sender, 0 /* Resource ID 0 Basic building materials(BBM) */, 100, "");
    }

    function getVille(uint256 tokenId) public view returns (VilleInfo memory) {
        return villes[tokenId];
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

    function updateVilleEnergy(uint256 tokenId, uint256 amountToDeduct) public authorizedOnly {
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

    function distributeResources(uint256 tokenId, uint256 resourceId, uint256 resourceAmount, uint256 referrer) public authorizedOnly {
        // We pay the referrer first
        uint256 referrerShare = (resourceAmount * 5) / 100;
        resourcesContract.mint(VilleContract.ownerOf(referrer), resourceId, referrerShare, "");
        resourceAmount -= referrerShare;

        // Get the holders of shares for this tokenId
        address[] memory holders = sharesContract.getHolders(tokenId);

        uint256 totalShares = 10000; // Total shares assumed to be 10000

        // Calculate resource distribution
        for (uint256 i = 0; i < holders.length; i++) {
            address holder = holders[i];
            uint256 holderShares = sharesContract.balanceOf(holder, tokenId);
            uint256 sharePercentage = (holderShares * 100 ether) / totalShares;
            uint256 holderResourceAmount = (resourceAmount * sharePercentage);

            // Mint resources to the holder
            resourcesContract.mint(holder, resourceId, holderResourceAmount, "");

            // Reduce the resource amount
            resourceAmount -= holderResourceAmount;
        }

        
    }
    

    function villeMint(uint256 tokenId, uint256 newExperience, uint256 energyToDeduct, uint256 resourceId, uint256 resourceAmount) public authorizedOnly {
        VilleInfo storage ville = villes[tokenId];
        
        // Deduct energy
        updateVilleEnergy(tokenId, energyToDeduct);
        
        // Update experience
        (ville.level, ville.experience) = calculateLevel(ville.level, ville.experience, newExperience);

        // Calculate resource distribution
        if (ville.occupied) {
            uint256 invaderVilleId = ville.occupiedBy;
            uint256 invaderShare = resourceAmount / 2;
            uint256 villeOwnerShare = resourceAmount - invaderShare;
            // Mint resources to the invader ville owner
            resourcesContract.mint(VilleContract.ownerOf(invaderVilleId), resourceId, invaderShare, "");
            // Distribute remaining resources
            distributeResources(tokenId, resourceId, villeOwnerShare, ville.referrer);
        } else {
            // Distribute all resources
            distributeResources(tokenId, resourceId, resourceAmount, ville.referrer);
        }
    }

    function createBuildingType(string memory name,
         uint256[] memory inputResourceIds,
         uint256[] memory inputResourceAmounts,
         uint256[] memory outputResourceIds,
         uint256[] memory outputResourceAmounts) external onlyDev returns (uint256) {

        uint typeId = buildingInfoContract.addNewType(name, inputResourceIds, inputResourceAmounts, outputResourceIds, outputResourceAmounts);

        return typeId;
    }

    function createBuilding(uint256 buildingType, uint256 theme, address to) external returns (uint256) {
        // Mint the ERC721 token and get the new tokenId
        uint256 tokenId = buildingsContract.safeMint(to);

        // add the building info
        buildingInfoContract.setBuildingData(tokenId, buildingType, theme);

        return tokenId;
    }

    function createShares(uint256 tokenId) public {
        require(VilleContract.ownerOf(tokenId) == msg.sender, "Sender does not own the token");
        require(!villes[tokenId].sharesIssued, "Shares already issued for this ville");
        require(villes[tokenId].level > 9, "You have to reach level 10 before issuing shares");

        villes[tokenId].sharesIssued = true;

        // Mint 100% shares to the ville owner
        sharesContract.mint(msg.sender, tokenId /* Share ID */, 10000 /* Total shares */, "");
    }

    function initiateBattle(uint256 attackerVilleId, uint256 defenderVilleId, uint256[] memory attackerTroopIds, uint256[] memory attackerTroopAmounts) public authorizedOnly {
        require(!villes[attackerVilleId].occupied, "Attacker ville is occupied");
        require(!villes[defenderVilleId].occupied, "Defender ville is already occupied");

        warContract.initiateBattle(attackerVilleId, attackerTroopIds, attackerTroopAmounts, defenderVilleId);
    }

    function finalizeBattle(uint256 attackerVilleId, uint256 defenderVilleId, bool attackerWon, uint256[] memory attackerTroopIds, uint256[] memory attackerTroopsLost, uint256[] memory defenderTroopIds, uint256[] memory defenderTroopsLost) public authorizedOnly {
        if (attackerWon) {
            villes[defenderVilleId].occupied = true;
            villes[defenderVilleId].occupiedBy = attackerVilleId;
        } else {
            villes[attackerVilleId].occupied = false;
        }

        // Burn dead troops for both attacker and defender 
        resourcesContract.burn(VilleContract.ownerOf(attackerVilleId), attackerTroopIds, attackerTroopsLost);
        
        resourcesContract.burn(VilleContract.ownerOf(defenderVilleId), defenderTroopIds, defenderTroopsLost);
        
    }

    function liberateVille(uint256 occupiedVilleId, uint256[] memory liberatorTroopIds, uint256[] memory liberatorTroopAmounts) public authorizedOnly {
        require(villes[occupiedVilleId].occupied, "Ville is not occupied");

        warContract.liberateVille(occupiedVilleId, liberatorTroopIds, liberatorTroopAmounts);
    }

    function finalizeLiberation(uint256 occupiedVilleId, bool liberatorWon, uint256[] memory liberatorTroopIds, uint256[] memory liberatorTroopsLost, uint256[] memory occupyingTroopIds, uint256[] memory occupyingTroopsLost) public authorizedOnly {
        if (liberatorWon) {
            villes[occupiedVilleId].occupied = false;
            villes[occupiedVilleId].occupiedBy = 0;
        }

        // Burn dead troops for both liberator and occupying troops
        resourcesContract.burn(VilleContract.ownerOf(occupiedVilleId), liberatorTroopIds, liberatorTroopsLost);
        resourcesContract.burn(VilleContract.ownerOf(occupiedVilleId), occupyingTroopIds, occupyingTroopsLost);
    }

}
