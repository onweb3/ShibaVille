const hre = require("hardhat");

async function main() {
  const BaseURI = "https://metadata.shibaville.io/"; //Solver for Greenfield data recovery
  // Deploy shibaville main contract
  const shibaville = await hre.ethers.deployContract("ShibaVille", ["0xShiba"]);
  const dev = "0xB2972a5C242f98c1626Df11a52a1Edbc62Acd507";

  // Deploy Ville NFT contract and mint id 0 to the dev
  const Ville = await hre.ethers.deployContract("Ville", [
    shibaville.target,
    BaseURI + "ville/",
    dev,
  ]);

  // Deploy Building contract
  const Buildings = await hre.ethers.deployContract("Buildings", [
    shibaville.target,
    BaseURI + "buildings/",
  ]);

  // Deploy Building metadata contract
  const BuildingInfo = await hre.ethers.deployContract("BuildingInfo", [
    shibaville.target,
  ]);

  // Deploy Resources metadata contract
  const Resources = await hre.ethers.deployContract("Resources", [
    shibaville.target,
    BaseURI + "resources/",
    dev,
  ]);

  // Deploy Shares contract
  const Shares = await hre.ethers.deployContract("Shares", [
    shibaville.target,
    BaseURI + "shares/",
  ]);

  // Deploy War contract
  const War = await hre.ethers.deployContract("War", [
    shibaville.target,
    Resources.target,
  ]);

  // Deploy ShibaVile Gold contract
  const SVGold = await hre.ethers.deployContract("SVGold", [shibaville.target]);

  const contracts = {
    shibaville: shibaville.target,
    ville: Ville.target,
    buildings: Buildings.target,
    BuildingInfo: BuildingInfo.target,
    Resources: Resources.target,
    Shares: Shares.target,
    War: War.target,
    SVGold: SVGold.target,
  };
  console.log(contracts);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
