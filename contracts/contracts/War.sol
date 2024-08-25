// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IResources {
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;
}

interface IShibaville {
    function occupyVille(uint256 villeId) external;
    function liberateVille(uint256 villeId) external;
    function burnTroops(uint256[] memory troopIds, uint256[] memory troopAmounts, address owner) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract War {
    address public shibavilleContract;
    IResources public resourcesContract;

    uint256 constant BATTLE_DELAY = 24 hours;

    struct Troop {
        uint256 id;
        uint256 amount;
    }

    struct Battle {
        uint256 attackerVilleId;
        uint256[] attackerTroopIds;
        uint256[] attackerTroopAmounts;
        uint256 defenderVilleId;
        uint256 startTime;
    }

    struct BattleOutcome {
        bool attackerWon;
        uint256[] attackerTroopsLost;
        uint256[] defenderTroopsLost;
    }

    mapping(uint256 => Troop[]) public villeTroops; // Keeps track of troops in each ville
    mapping(uint256 => Battle) public ongoingBattles; // Keeps track of ongoing battles by defender ville ID

    constructor(address _shibaville, address _resourcesContract) {
        shibavilleContract = _shibaville;
        resourcesContract = IResources(_resourcesContract);
    }

    modifier onlyShibavilleContract() {
        require(msg.sender == shibavilleContract, "Caller is not the Shibaville contract");
        _;
    }

    event BattleStarted(uint256 indexed defenderVilleId, uint256 indexed attackerVilleId, uint256 startTime);
    event BattleSimulated(uint256 indexed defenderVilleId, uint256 indexed attackerVilleId, bool attackerWon);

    function transferTroopsToWar(
        address owner,
        uint256[] memory troopIds,
        uint256[] memory troopAmounts
    ) internal {
        resourcesContract.safeBatchTransferFrom(owner, address(this), troopIds, troopAmounts);
    }

    function initiateBattle(
        uint256 attackerVilleId,
        uint256[] memory attackerTroopIds,
        uint256[] memory attackerTroopAmounts,
        uint256 defenderVilleId
    ) external onlyShibavilleContract {
        // Transfer attacker troops to the War contract
        address attackerOwner = tx.origin;
        transferTroopsToWar(attackerOwner, attackerTroopIds, attackerTroopAmounts);

        // Store the battle details
        ongoingBattles[defenderVilleId] = Battle({
            attackerVilleId: attackerVilleId,
            attackerTroopIds: attackerTroopIds,
            attackerTroopAmounts: attackerTroopAmounts,
            defenderVilleId: defenderVilleId,
            startTime: block.timestamp
        });

        emit BattleStarted(defenderVilleId, attackerVilleId, block.timestamp);
    }

    function addDefenderTroops(
        uint256 defenderVilleId,
        uint256[] memory defenderTroopIds,
        uint256[] memory defenderTroopAmounts
    ) external onlyShibavilleContract {
        require(block.timestamp < ongoingBattles[defenderVilleId].startTime + BATTLE_DELAY, "Battle delay period has passed");

        // Transfer defender troops to the War contract
        address defenderOwner = tx.origin;
        transferTroopsToWar(defenderOwner, defenderTroopIds, defenderTroopAmounts);

        // Add defender troops to the villeTroops mapping
        for (uint256 i = 0; i < defenderTroopIds.length; i++) {
            villeTroops[defenderVilleId].push(Troop(defenderTroopIds[i], defenderTroopAmounts[i]));
        }
    }

    function simulateBattle(uint256 defenderVilleId) external onlyShibavilleContract returns (BattleOutcome memory) {
        Battle memory battle = ongoingBattles[defenderVilleId];
        require(block.timestamp >= battle.startTime + BATTLE_DELAY, "Battle delay period has not passed");

        // Get defender troops
        Troop[] storage defenderTroops = villeTroops[defenderVilleId];
        uint256[] memory defenderTroopIds = new uint256[](defenderTroops.length);
        uint256[] memory defenderTroopAmounts = new uint256[](defenderTroops.length);

        for (uint256 i = 0; i < defenderTroops.length; i++) {
            defenderTroopIds[i] = defenderTroops[i].id;
            defenderTroopAmounts[i] = defenderTroops[i].amount;
        }

        // Simulate the battle
        BattleOutcome memory outcome = _simulateBattle(
            battle.attackerTroopIds,
            battle.attackerTroopAmounts,
            defenderTroopIds,
            defenderTroopAmounts
        );

        // Burn the dead troops
        if (outcome.attackerTroopsLost.length > 0) {
            address attackerOwner = IShibaville(shibavilleContract).ownerOf(battle.attackerVilleId);
            IShibaville(shibavilleContract).burnTroops(battle.attackerTroopIds, outcome.attackerTroopsLost, attackerOwner);
        }

        if (outcome.defenderTroopsLost.length > 0) {
            address defenderOwner = IShibaville(shibavilleContract).ownerOf(defenderVilleId);
            IShibaville(shibavilleContract).burnTroops(defenderTroopIds, outcome.defenderTroopsLost, defenderOwner);
        }

        // Update the ville state based on battle outcome
        if (outcome.attackerWon) {
            IShibaville(shibavilleContract).occupyVille(defenderVilleId);
            // Store surviving attacker troops in the defender's ville
            for (uint256 i = 0; i < battle.attackerTroopIds.length; i++) {
                uint256 remainingTroops = battle.attackerTroopAmounts[i] - outcome.attackerTroopsLost[i];
                if (remainingTroops > 0) {
                    villeTroops[defenderVilleId].push(Troop(battle.attackerTroopIds[i], remainingTroops));
                }
            }
        } else {
            // Defender wins, attacker loses
            delete villeTroops[defenderVilleId]; // Clear the occupying troops if any
        }

        emit BattleSimulated(defenderVilleId, battle.attackerVilleId, outcome.attackerWon);

        // Remove the battle from ongoingBattles mapping
        delete ongoingBattles[defenderVilleId];

        return outcome;
    }

    function liberateVille(
        uint256 villeId,
        uint256[] memory liberatorTroopIds,
        uint256[] memory liberatorTroopAmounts
    ) external onlyShibavilleContract returns (BattleOutcome memory) {
        // Transfer liberator troops to the War contract
        address liberatorOwner = tx.origin;
        transferTroopsToWar(liberatorOwner, liberatorTroopIds, liberatorTroopAmounts);

        // Get the occupying troops
        Troop[] storage occupyingTroops = villeTroops[villeId];
        uint256[] memory occupyingTroopIds = new uint256[](occupyingTroops.length);
        uint256[] memory occupyingTroopAmounts = new uint256[](occupyingTroops.length);

        for (uint256 i = 0; i < occupyingTroops.length; i++) {
            occupyingTroopIds[i] = occupyingTroops[i].id;
            occupyingTroopAmounts[i] = occupyingTroops[i].amount;
        }

        // Simulate the battle
        BattleOutcome memory outcome = _simulateBattle(liberatorTroopIds, liberatorTroopAmounts, occupyingTroopIds, occupyingTroopAmounts);

        // Burn the dead troops
        if (outcome.attackerTroopsLost.length > 0) {
            IShibaville(shibavilleContract).burnTroops(liberatorTroopIds, outcome.attackerTroopsLost, liberatorOwner);
        }

        if (outcome.defenderTroopsLost.length > 0) {
            IShibaville(shibavilleContract).burnTroops(occupyingTroopIds, outcome.defenderTroopsLost, address(this));
        }

        // Update the ville state based on battle outcome
        if (outcome.attackerWon) {
            IShibaville(shibavilleContract).liberateVille(villeId);
            delete villeTroops[villeId]; // Clear the occupying troops
        }

        return outcome;
    }

    function _simulateBattle(
        uint256[] memory attackerTroopIds,
        uint256[] memory attackerTroopAmounts,
        uint256[] memory defenderTroopIds,
        uint256[] memory defenderTroopAmounts
    ) internal pure returns (BattleOutcome memory) {
        uint256 attackerForce = _calculateForceWeight(attackerTroopIds, attackerTroopAmounts);
        uint256 defenderForce = _calculateForceWeight(defenderTroopIds, defenderTroopAmounts);

        uint256[] memory attackerTroopsLost = new uint256[](attackerTroopIds.length);
        uint256[] memory defenderTroopsLost = new uint256[](defenderTroopIds.length);

        bool attackerWon = attackerForce > defenderForce;

        if (attackerWon) {
            // Attacker wins, defender loses all troops
            for (uint256 i = 0; i < defenderTroopIds.length; i++) {
                defenderTroopsLost[i] = defenderTroopAmounts[i];
            }
            // Attacker loses a percentage of their troops based on the battle
            for (uint256 i = 0; i < attackerTroopIds.length; i++) {
                attackerTroopsLost[i] = attackerTroopAmounts[i] / 2; // Example loss, can be adjusted
            }
        } else {
            // Defender wins, attacker loses all troops
            for (uint256 i = 0; i < attackerTroopIds.length; i++) {
                attackerTroopsLost[i] = attackerTroopAmounts[i];
            }
            // Defender loses a percentage of their troops based on the battle
            for (uint256 i = 0; i < defenderTroopIds.length; i++) {
                defenderTroopsLost[i] = defenderTroopAmounts[i] / 2; // Example loss, can be adjusted
            }
        }

        return BattleOutcome({
            attackerWon: attackerWon,
            attackerTroopsLost: attackerTroopsLost,
            defenderTroopsLost: defenderTroopsLost
        });
    }

    function _calculateForceWeight(
        uint256[] memory troopIds,
        uint256[] memory troopAmounts
    ) internal pure returns (uint256) {
        uint256 totalForceWeight = 0;

        for (uint256 i = 0; i < troopIds.length; i++) {
            // Assuming the weight is proportional to the troop ID and amount
            totalForceWeight += troopIds[i] * troopAmounts[i];
        }

        return totalForceWeight;
    }

}
