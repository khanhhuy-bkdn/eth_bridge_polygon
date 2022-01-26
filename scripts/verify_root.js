const contract = require('../contracts_root.json');
const hre = require('hardhat');

async function main() {
  const { fxRoot, checkpointManager } = hre.network.config;

  console.log('=====================================================================================');
  console.log('VERIFY:');
  console.log('=====================================================================================');

  try {
    await hre.run("verify:verify", {
      address: contract.FxWnDRootTunnel,
      constructorArguments: [checkpointManager.address, fxRoot.address],
    });
  } catch (e) {
    console.log(e.message);
  }

  try {
    await hre.run("verify:verify", {
      address: contract.WnD,
      constructorArguments: ["WnD", "WnD"],
    });
  } catch (e) {
    console.log(e.message);
  }

  try {
    await hre.run("verify:verify", {
      address: contract.Consumables,
    });
  } catch (e) {
    console.log(e.message);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
