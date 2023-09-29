const { ethers, network } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying Token contract with the account:", deployer.address);

  const Token = await ethers.getContractFactory("Token");
  const tokenContract = await Token.deploy(1000000); // 1,000,000 initial supply
  await tokenContract.deployed();

  console.log("Token contract deployed to:", tokenContract.address);

  console.log("Deploying Vesting contract with the account:", deployer.address);

  const Vesting = await ethers.getContractFactory("Vesting");
  const vestingContract = await Vesting.deploy(
    tokenContract.address,
    deployer.address,
    30 * 24 * 60 * 60, // 30 days in seconds
    10, // n (number of periods)
    ethers.utils.parseEther("1000000") // Total amount of tokens (in this example, 1,000,000 tokens)
  );
  await vestingContract.deployed();

  console.log("Vesting contract deployed to:", vestingContract.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
