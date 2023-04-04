// import
// main function
// calling of main function

// Meaning :
// const helperConfig = require("../helper-hardhat-config")
// const networkConfig = helperConfig.networkConfig
const { network } = require("hardhat")
const { networkConfig, developmentChains } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")

// Here , what happen is whenever we run a deploy script : yarn hardhat deploy , hardhat automatically call
// the anonymous function below and pass it the hre ( hardhat runtime environment almost egal to hardhat object).
// this means that the 2 parameters inside the async function are like that :
// const { getNamedAccounts, deployments} = hre

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments
  //grab deployer account from name account
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId

  // The if here means that we have deployed a Moack , and the else means we did not deploy a moack
  let ethUsdPriceFeedAddress

  if (developmentChains.includes(network.name)) {
    const ethUsdAggregator = await deployments.get("MockV3Aggregator")
    ethUsdPriceFeedAddress = ethUsdAggregator.address
  } else {
    // here we use the address based on the chain we are on
    ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"]
    // But what if the chain we are on does not have the address (EX: hardhat or localhost)
    // for us to interact with that contract and get the price conversion from eth to USD ?
    // that's where mocks come into play. we then have to write our own contract ( see : 00-deploy-mocks file)
  }
  const args = [ethUsdPriceFeedAddress]
  const fundMe = await deploy("FundMe", {
    from: deployer,
    args: args,
    log: true,
    waitConfiramtions: network.config.blockConfirmations || 1,
  })
  // Here we only want to  verify the contract on etherscan only if we deployed on a real test net or blockchain , well
  // not on hardhat network or localhost
  if (
    !developmentChains.includes(network.name) &&
    process.env.ETHERSCAN_API_KEY
  ) {
    await verify(fundMe.address, args)
  }
  log("----------------------------------------------------------")
}
module.exports.tags = ["all", "fundme"]
