const { expect } = require("chai");
const hre = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("ShibaVille", function () {
  it("Should Deploy Shibaville contract", async function () {
    const URI = "";
    const testName = "ShibaVille Gold";

    const shibaville = await hre.ethers.deployContract("ShibaVille", [
      "0xShiba",
    ]);
    const dev = await shibaville.dev();
    // console.log(shibaville);
    const Ville = await hre.ethers.deployContract("Ville", [
      shibaville.target,
      URI,
      dev,
    ]);
    const Buildings = await hre.ethers.deployContract("Buildings", [
      shibaville.target,
      URI,
    ]);
    //console.log(Buildings.target);
    const BuildingInfo = await hre.ethers.deployContract("BuildingInfo", [
      shibaville.target,
    ]);
    const Resources = await hre.ethers.deployContract("Resources", [
      shibaville.target,
      URI,
      dev,
    ]);
    const Shares = await hre.ethers.deployContract("Shares", [
      shibaville.target,
      URI,
    ]);
    const War = await hre.ethers.deployContract("War", [
      shibaville.target,
      Resources.target,
    ]);
    const SVGold = await hre.ethers.deployContract("SVGold", [
      shibaville.target,
    ]);

    const initResult = await shibaville.init(
      Ville.target,
      Buildings.target,
      BuildingInfo.target,
      Resources.target,
      Shares.target,
      War.target,
      SVGold.target
    );
    //console.log(initResult);

    // assert that the value is correct
    expect(await shibaville.doesVilleNameExist(testName)).to.equal(false);
    expect(await shibaville.VilleContract()).to.equal(Ville.target);
    expect(await shibaville.buildingsContract()).to.equal(Buildings.target);
    expect(await shibaville.buildingInfoContract()).to.equal(
      BuildingInfo.target
    );
    expect(await shibaville.resourcesContract()).to.equal(Resources.target);
    expect(await shibaville.sharesContract()).to.equal(Shares.target);
    expect(await shibaville.warContract()).to.equal(War.target);
    expect(await shibaville.goldContract()).to.equal(SVGold.target);

    // We constractor will mint the first ville id=0 for the dev
    const villeId = 0; // Ville ID
    expect(await Ville.ownerOf(villeId)).to.equal(dev);
    expect(await Resources.balanceOf(dev, 0)).to.equal(100);
    expect(await Resources.balanceOf(dev, 1)).to.equal(100);
    expect(await Resources.balanceOf(dev, 2)).to.equal(100);
    expect(await Resources.balanceOf(dev, 3)).to.equal(100);

    // add a building type // id = 0
    await shibaville.createBuildingType(
      "Mine",
      [1],
      [5],
      [0],
      [25],
      [0, 3],
      [50, 10],
      5
    );

    const theme = 0; // Visual themes of the game

    // create a building id start at 1
    await shibaville.createBuilding(villeId, 0, theme);
    const buildingId = 1;
    expect(await Buildings.ownerOf(buildingId)).to.equal(dev);
    expect(await Resources.balanceOf(dev, 0)).to.equal(50);
    expect(await Resources.balanceOf(dev, 1)).to.equal(100);
    expect(await Resources.balanceOf(dev, 2)).to.equal(100);
    expect(await Resources.balanceOf(dev, 3)).to.equal(90);

    // stake a building
    const position = { x: 10, y: 12 };
    await Buildings.setApprovalForAll(shibaville.target, true);
    await Resources.setApprovalForAll(shibaville.target, true);
    await shibaville.stake(buildingId, villeId, position.x, position.y);
    let lands = await shibaville.getLands(villeId);
    console.log("after stake", lands[10][12]);
    expect(await Buildings.ownerOf(buildingId)).to.equal(shibaville.target);
    expect(await Resources.balanceOf(dev, 0)).to.equal(50);
    expect(await Resources.balanceOf(dev, 1)).to.equal(95);
    expect(await Resources.balanceOf(dev, 2)).to.equal(100);
    expect(await Resources.balanceOf(dev, 3)).to.equal(90);

    // claim reward
    await time.increase(3600);
    await shibaville.claim(buildingId, villeId, position.x, position.y);
    expect(await Resources.balanceOf(dev, 0)).to.equal(75);
    lands = await shibaville.getLands(villeId);
    console.log("after claim", lands[10][12]);
    // unstake
    await time.increase(3600);
    await shibaville.unstake(buildingId, villeId, position.x, position.y);
    expect(await Buildings.ownerOf(buildingId)).to.equal(dev);
    lands = await shibaville.getLands(villeId);
    console.log("after unstake", lands[10][12]);
  });
});
