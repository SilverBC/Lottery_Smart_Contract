const hre = require("hardhat");


async function main() {
  const Lottery = await hre.ethers.getContractFactory("Lottery_Smart_Contract");
  const lottery = await Lottery.deploy();

  await lottery.deployed();

  console.log("success!", lottery.address);


}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
