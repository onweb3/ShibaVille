const { expect } = require("chai");
const hre = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("ShibaVille", function () {
  it("Should Deploy Shibaville contract", async function () {
    const URI = "";
    const testName = "ShibaVille Gold";

    const shibaville = await hre.ethers.deployContract("SVGold");

    // assert that the value is correct
    expect(await shibaville.name()).to.equal(testName);
  });
});
