// Check dans contract on va creer un fake contract ( Test / MockV3Aggregator.sol)
const { network } = require("hardhat")
const {
  developmentChains,
  DECIMALS,
  INITIAL_ANSWER,
} = require("../helper-hardhat-config")

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments
  //grab deployer account from name account
  const { deployer } = await getNamedAccounts()

  if (developmentChains.includes(network.name)) {
    log("Local network detected! Deploying mocks...")
    await deploy("MockV3Aggregator", {
      contract: "MockV3Aggregator",
      from: deployer,
      log: true,
      args: [DECIMALS, INITIAL_ANSWER],
    })

    log("Mocks deployed!!!!")
    log("----------------------------------------------------------")
  }
}

// Is there a way where we can only run our deploy-mocks ? yes
// mocks : pour run only the deploy-mocks script
// we then write in the console : yarn hardhat deploy --tags mocks
module.exports.tags = ["all", "mocks"]
