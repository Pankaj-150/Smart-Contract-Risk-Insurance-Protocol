const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  const Insurance = await ethers.getContractFactory("SmartContractInsurance");
  const contract = await Insurance.deploy(deployer.address);
  await contract.deployed();
  console.log("SmartContractInsurance deployed to:", contract.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
