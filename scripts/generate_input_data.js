require('dotenv').config();
const { POSClient, use }  = require("@maticnetwork/maticjs");
const { providers, ethers, Wallet }  = require( "ethers");
const HDWalletProvider  = require( "@truffle/hdwallet-provider");
const { Web3ClientPlugin } = require("@maticnetwork/maticjs-web3");

use(Web3ClientPlugin);

async function main() {

    let posClient = new POSClient();

    // Test net
    let pk = process.env.DEPLOY_ACCOUNT;
    let parent = new HDWalletProvider(pk, `https://goerli.infura.io/v3/${process.env.INFURA_API_KEY}`);
    let child = new HDWalletProvider(pk, `https://rpc-mumbai.maticvigil.com`);

    try {
        posClient = await posClient.init({
            network: "testnet", //L1 network "mainnet"
            version: "mumbai", // L2 network "matic"
            parent: {
                provider: parent,
                defaultConfig: {
                    from: "0x4c5f8A8dB33f0FD7B5bE3b53aa27Cf4B65fE496f" // Wallet address
                }
            },
            child: {
                provider: child,
                defaultConfig: {
                    from: "0x4c5f8A8dB33f0FD7B5bE3b53aa27Cf4B65fE496f" // Wallet address
                }
            }
        });

        const payload = await posClient
            .exitUtil
            .buildPayloadForExit(
                "0x2a4894ae09913184e4003c6718137b29558ddecb65fbb088f6b0afaaa178f930", // L2 Withdraw hash
                "0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036", // This is a constant, use this value!
                false
            ).catch(err => console.log(err));

        console.log(payload)
    } catch(error) {
        console.log(error)
    }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});