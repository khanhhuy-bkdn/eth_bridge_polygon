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
  const Consumables = await ethers.getContractFactory("Consumables");

  console.log('=====================================================================================');
  console.log(`DEPLOYED CONTRACT ADDRESS TO:  ${hre.network.name}`);
  console.log('=====================================================================================');

  // const wnD = await WnD.deploy("HWnD", "HWnD");
  // await wnD.deployed();
  // console.log(' WnD                     deployed to:', wnD.address);

  // const consumables = await Consumables.deploy();
  // await consumables.deployed();
  // console.log(' Consumables             deployed to:', consumables.address);

  // const fxWnDRootTunnel = await FxWnDRootTunnel.deploy(checkpointManager.address, fxRoot.address);
  // await fxWnDRootTunnel.deployed();
  // console.log(' FxWnDRootTunnel         deployed to:', fxWnDRootTunnel.address);

  const fxWnDRootTunnel = FxWnDRootTunnel.attach(ethers.utils.getAddress('0xA61E56D24e1b549C7801e1F1a022B6742E51fd6D'));
  const consumables = Consumables.attach(ethers.utils.getAddress('0x47FC25c3b03eafC7842F716BA63cB7cCCD9C44B3'));
  const wnD = WnD.attach(ethers.utils.getAddress('0xB419776820075891b81E9B46D12C3ca52f64Aaf7'));

  const tx = await fxWnDRootTunnel.setContracts(wnD.address, consumables.address);
  await tx.wait();
  console.log('Finish.....................');

  console.log('Set addAdmin.....................');
  await consumables.setPaused(false);
  await consumables.addAdmin(fxWnDRootTunnel.address);
  await consumables.setType(1, 10000);

  await wnD.setPaused(false);
  await wnD.addAdmin(fxWnDRootTunnel.address);
  console.log('End set addAdmin.....................');

  // export deployed contracts to json (using for front-end)
  const contractAddresses = {
    "FxWnDRootTunnel": fxWnDRootTunnel.address,
    "WnD": wnD.address,
    "Consumables": consumables.address
  }
  await fs.writeFileSync("contracts_root.json", JSON.stringify(contractAddresses));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
