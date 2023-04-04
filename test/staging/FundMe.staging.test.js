// This is the test that we can use on an actual testnet.
// this is the test that we basically going to run after we deploy some code
// just to see if everything is working approximatively the way we want it to

const { getNamedAccounts, ethers, network } = require("hardhat")
const { developmentChains } = require("../../helper-hardhat-config")
const { assert, expect } = require("chai")

// this ternary operator just means run that describe is we are not on a developmentChains c-a-d Hardhat or localhost
developmentChains.includes(network.name)
  ? describe.skip
  : describe("FundMe", async function () {
      let fundMe
      let deployer
      const sendValue = ethers.utils.parseEther("1")
      beforeEach(async function () {
        deployer = (await getNamedAccounts()).deployer
        // we do not do this code below here in the staging , because here we assume that the contract is already deployed
        //await deployments.fixture(["all"])
        fundMe = await ethers.getContract("FundMe", deployer)
      })
      it("allows people to fund and withdraw", async function () {
        await fundMe.fund({ value: sendValue })
        await fundMe.withdraw()
        const endingBalance = await fundMe.provider.getBalance(fundMe.address)
        assert.equal(endingBalance.toString(), "0")
      })
    })
