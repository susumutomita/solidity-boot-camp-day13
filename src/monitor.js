// const ethers = require('ethers');
import { ethers } from 'ethers';

// config();

// async function main() {
//   const provider = new ethers.providers.WebSocketProvider('wss://mainnet.infura.io/ws/v3/');
//   provider.on('pending', async (tx) => {
//     console.log(`New block: ${tx}`);
//   }
//   );
// }
// main();

// // Infuraを使ってEthereumネットワークに接続する例
const provider = ethers.getDefaultProvider(
  "goerli",
  {
    // alchemy: `Alchemy API Token`,
    // etherscan: `Etherscan API Token`,
    infura: ``,
    // pocket: `Pocket Network Application ID or { applicationId, applicationSecretKey }`,
    // quorum: `The number of backends that must agree (default: 2 for mainnet, 1 for testnets)`,
  }
);

provider.on('block', (blockNumber) => {
  console.log(`New block: ${blockNumber}`);

  provider.getTransactions(blockNumber).then((block) => {
    console.log(block);
  });
});
