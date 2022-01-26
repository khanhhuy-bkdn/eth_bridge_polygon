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

  // const fxWnDChildTunnel = await FxWnDChildTunnel.deploy(fxChild.address);
  // await fxWnDChildTunnel.deployed();
  // console.log(' FxWnDChildTunnel        deployed to:', fxWnDChildTunnel.address);

  const fxWnDChildTunnel = FxWnDChildTunnel.attach(ethers.utils.getAddress('0x16d60ad5CdE3Dd5F0101C48f786794FE33a70946'));
  const consumables = Consumables.attach(ethers.utils.getAddress('0x2a0b4c067dB1C9ac4e684aFB4Cdd84974B5BEeBC'));
  const wnD = WnD.attach(ethers.utils.getAddress('0x695C1546dee315733031ee35beF2cF67EaC92717'));

  console.log('Set contract.....................');
  const tx = await fxWnDChildTunnel.setContracts(wnD.address, consumables.address);
  await tx.wait();
  console.log('Finish.....................');

  console.log('Set addAdmin.....................');
  await consumables.setPaused(false);
  await consumables.addAdmin(fxWnDChildTunnel.address);
  await consumables.setType(1, 10000);

  await wnD.setPaused(false);
  await wnD.addAdmin(fxWnDChildTunnel.address);
  console.log('End set addAdmin.....................');

  // export deployed contracts to json (using for front-end)
  const contractAddresses = {
    "FxWnDChildTunnel": fxWnDChildTunnel.address,
    "WnD": wnD.address,
    "Consumables": consumables.address
  }
  await fs.writeFileSync("contracts_child.json", JSON.stringify(contractAddresses));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
