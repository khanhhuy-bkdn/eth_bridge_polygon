const fs = require('fs');
const hre = require('hardhat');
const ethers = hre.ethers;
const contract = require('../contracts_child.json');

async function main() {
  const accounts = await ethers.getSigners();

  const { fxRoot, checkpointManager } = hre.network.config;

  console.log('=====================================================================================');
  console.log('ACCOUNTS:');
  console.log('=====================================================================================');
  for (let i = 0; i < accounts.length; i++) {
    const account = accounts[i];
    console.log(` Account ${i}: ${account.address}`);
  }

  const FxWnDRootTunnel = await ethers.getContractFactory("FxWnDRootTunnel");
  const WnD = await ethers.getContractFactory("WnD");

  console.log('=====================================================================================');
  console.log(`DEPLOYED CONTRACT ADDRESS TO:  ${hre.network.name}`);
  console.log('=====================================================================================');

  const wnD = await WnD.deploy("WnD", "WnD");
  await wnD.deployed();
  console.log(' WnD                     deployed to:', wnD.address);

  const fxWnDRootTunnel = await FxWnDRootTunnel.deploy(checkpointManager.address, fxRoot.address);
  await fxWnDRootTunnel.deployed();
  console.log(' FxWnDRootTunnel         deployed to:', fxWnDRootTunnel.address);

  const tx = await fxWnDRootTunnel.setContracts(wnD.address);
  await tx.wait();
  console.log('Finish.....................')

  // // Set child for root
  // const setERC721Child = await fxWnDRootTunnel.setFxChildTunnel(contract.FxWnDChildTunnel);
  // console.log(setERC721Child);
  // await setERC721Child.wait();
  // console.log("FxWnDChildTunnel set");

  // export deployed contracts to json (using for front-end)
  const contractAddresses = {
    "FxWnDRootTunnel": fxWnDRootTunnel.address,
    "WnD": wnD.address
  }
  await fs.writeFileSync("contracts_root.json", JSON.stringify(contractAddresses));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
