**Shibaville: A Fully On-Chain City building Game**

Shibaville is a on-chain city-building strategy video game built on the new Binance Chain (OPBNB) and Greenfield.
All game mechanics, rules, and actions are embedded in smart contracts, ensuring a transparent, fair, and accessible experience for players across multiple platforms.
In Shibaville, players immerse themselves in building, resource management, and strategic warfare while contributing to a vibrant and dynamic in-game economy.

### Key Features

- **On-Chain Gameplay**: Every aspect of gameplay is on-chain, ensuring fairness and transparency for all players.
- **Fair-Launch**: Shibaville is a community project, No pre-minted tokens, No ICO, all contracts start from zero.
- **Cross-Platform Access**: Play seamlessly from web browsers, Mobile devices, or build your own scripts.
- **Unique Upgradable NFTs**: Each ville and building NFT are upgradedable with extra unique 3D visual representations.
- **Open Source**: Shibaville is fully open-source under the MIT license, inviting contributions and innovation from the community.
- **Referral System**: An incentivized referral system encourages players to grow the community, enhancing engagement and growth.

### Game Mechanics

1. **Player Registration**

   - **Action**: Players register by creating a unique name.
   - **Result**: A ville NFT is minted, representing the player’s ville, with initial resources allocated.

2. **Ville Management**

   - **Ville NFT**: This NFT represents the player’s ville, including level, rank, unique name, and dynamic attributes.
   - **Building NFTs**: Each building is represented as an NFT, it can be upgraded with unique traits that impact resource production and strategy.
   - **Placement**: Players strategically place buildings in their ville, influencing resource management and gameplay strategy.
   - **Shares**: Ville shares as token represent 20% of the ville income that can be transfered to other wallets.

3. **Resource Management**

   - **Multi-Token Contract**: Manages in-game resources such as food, basic building materials, minerals, gases , and technology.
   - **SVGold Contract**: ERC20 token (SVGOLD) minted and used by the player for upgrades and minting heavy war units.
   - **Resource Generation**: Buildings produce resources over time, influenced by their traits and positioning.
   - **Minting and Burning**: Resources are minted when buildings are staked and burned when new buildings created or upgraded.

4. **Army and Warfare**

   - **Army Units**: Minted from army buildings using resources, represented as multi-tokens.
   - **Warfare Mechanics**: Players deploy their army units to attack other villes, collect taxes, and climb the ranks.
   - **War Taxes**: Conquered villes pay ongoing taxes to the invader, generating continuous resource income.

5. **Referral System**
   - **Referral Incentives**: Players earn rewards by inviting others, receiving a percentage of the resources generated by their referees.
   - **Growth Rewards**: The system encourages community expansion, increasing the user base and engagement.

### Smart Contract Architecture

- **Main Contract (Game mode)**
  - **Handles**: Player registration, building minting, resource management, and placements.
  - **Integration**: Interfaces with BSC's standards for NFTs and multi-token contracts, managing resources, shares and units.
  - **Ville Metadata**: On-chain metadata for ville NFTs, representing the player’s ville and state.
  - **Interaction**: This contract is responsable for all interactions of the game, from creating a ville to invade others.
- **Ville Contract (BEP-721)**
  - **Transfer Logic**: Ensures buildings follow the ville NFT upon transfer.
- **Building Contract (BEP-721)**
  - **Transfer Logic**: Ensures buildings follow the ville NFT upon transfer.
- **BuildingInfo (Metadata)**
  - **Unique Traits**: Each building NFT has unique attributes that affect gameplay.
- **Multi-Token Contract for Resources and Units**
  - **BEP-1155**: Manages multiple resource types and army units.
  - **Scalability**: Allows adding new resource and unit types without redeploying contracts.
- **Ville Shares Contract (BEP-1155)**
  - **Shares**: Manages ville shares as token that ville owner can transfer to other wallets.
  - **Funding**: User can get funded to keep playing by selling 20% of the ville to investors.
- **War Contract (Game Mechanics)**
  - **Invade**: Use units to invade other villes and collect a 50% tax from all the resources collected.
  - **Gun for hire**: Player can use units to defende clients in exchange of one time payment.

### Conclusion

Shibaville is pioneering a new era of blockchain gaming by fully leveraging on-chain mechanics to ensure fairness, transparency, and scalability.
The game’s initial contracts offer a streamlined experience, showcasing core functionalities. Future updates will expand on these mechanics, introducing more complex interactions, dynamic gameplay, and an engaging user experience.
By building on OPBNB and fostering an open-source community, Shibaville is poised to set new standards in the web3 on-chain gaming space.

---

### Links

## Website: https://shibaville.io

## x: https://x.com/ShibaVille_io

---
