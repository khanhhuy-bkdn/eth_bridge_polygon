const fs = require('fs');
const hre = require('hardhat');
const ethers = hre.ethers;

async function main() {
  const accounts = await ethers.getSigners();

  const { fxChild } = hre.network.config;

  console.log('=====================================================================================');
  console.log('ACCOUNTS:');
  console.log('=====================================================================================');
  for (let i = 0; i < accounts.length; i++) {
    const account = accounts[i];
    console.log(` Account ${i}: ${account.address}`);
  }

  const FxWnDChildTunnel = await ethers.getContractFactory("FxWnDChildTunnel");
  const WnD = await ethers.getContractFactory("WnD");

  console.log('=====================================================================================');
  console.log(`DEPLOYED CONTRACT ADDRESS TO:  ${hre.network.name}`);
  console.log('=====================================================================================');

  const wnD = await WnD.deploy("WnD", "WnD");
  await wnD.deployed();
  console.log(' WnD                     deployed to:', wnD.address);

  const fxWnDChildTunnel = await FxWnDChildTunnel.deploy(fxChild.address);
  await fxWnDChildTunnel.deployed();
  console.log(' FxWnDChildTunnel        deployed to:', fxWnDChildTunnel.address);

  const tx = await fxWnDChildTunnel.setContracts(wnD.address);
  await tx.wait();
  console.log('Finish.....................')

  // export deployed contracts to json (using for front-end)
  const contractAddresses = {
    "FxWnDChildTunnel": fxWnDChildTunnel.address,
    "WnD": wnD.address
  }
  await fs.writeFileSync("contracts_child.json", JSON.stringify(contractAddresses));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
