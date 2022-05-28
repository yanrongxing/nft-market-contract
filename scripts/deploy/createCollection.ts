import { ethers } from "hardhat"
import * as ManaConfig from 'decentraland-mana/build/contracts/MANAToken.json'

import {
  MANA_BYTECODE, RESCUE_ITEMS_SELECTOR,
  SET_APPROVE_COLLECTION_SELECTOR,
  SET_EDITABLE_SELECTOR
} from './utils'
var Web3 = require('web3');
var web3 = new Web3('http://localhost:8545');

const RARITIES = [
  { name: 'common', index: 0, value: 100000 },
  { name: 'uncommon', index: 1, value: 10000 },
  { name: 'rare', index: 2, value: 5000 },
  { name: 'epic', index: 3, value: 1000 },
  { name: 'legendary', index: 4, value: 100 },
  { name: 'mythic', index: 5, value: 10 },
  { name: 'unique', index: 6, value: 1 }
]
enum NETWORKS {
  'MUMBAI' = 'MUMBAI',
  'MATIC' = 'MATIC',
  'GOERLI' = 'GOERLI',
  'LOCALHOST' = 'LOCALHOST',
  'BSC_TESTNET' = 'BSC_TESTNET',
  'TIXON' = 'TIXON',
}

enum MANA {
  'MUMBAI' = '0x882Da5967c435eA5cC6b09150d55E8304B838f45',
  'MATIC' = '0xA1c57f48F0Deb89f569dFbE6E2B7f46D33606fD4',
  'GOERLI' = '0xe7fDae84ACaba2A5Ba817B6E6D8A2d415DBFEdbe',
  'LOCALHOST' = '0x5FbDB2315678afecb367f032d93F642f64180aa3',
  'BSC_TESTNET' = '0x00cca1b48a7b41c57821492efd0e872984db5baa',
  'TIXON' = '0x5FbDB2315678afecb367f032d93F642f64180aa3',
}

/**
 * @dev Steps:
 * Deploy the Collection implementation
 * Deploy the committee with the desired members. The owner will be the DAO bridge
 * Deploy the collection Manager. The owner will be the DAO bridge
 * Deploy the forwarder. Caller Is the collection manager.
 * Deploy the collection Factory. Owner is the forwarder.
 */
async function main() {
  const owner = process.env['OWNER']
  const collectionDeploymentsFeesCollector = process.env['OWNER']

  const account = ethers.provider.getSigner()
  const accountAddress = await account.getAddress()
  console.log(`Contract deployed by: ${accountAddress}`)

  const network = NETWORKS[(process.env['NETWORK'] || 'LOCALHOST') as NETWORKS]
  if (!network) {
    throw ('Invalid network')
  }

  console.log(`Contract deployed by network: ${network}`)

  // Deploy the collection implementation
  // const Collection = await ethers.getContractFactory("ERC721CollectionV3")
  // const collectonImp = await Collection.deploy()
  // console.log('Collection imp:', collectonImp.address)


  // Deploy the collection manager
  let collectionManagerAddress = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";
  let forwardAddress = "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9";
  let factoryAddress = "0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9";
  const CollectionManager = await ethers.getContractFactory("CollectionManagerV2")
  const collectionManager = await CollectionManager.attach(collectionManagerAddress);

  const salt = web3.utils.randomHex(32)
  console.log(`Contract deployed by salt: ${salt}`)
  const result = await collectionManager.createCollection(
    forwardAddress,
    factoryAddress,
    salt,
    "TEST",
    "TEST",
    "TEST-url"
  );
  let waitRes = await result.wait();
  waitRes.logs.forEach((a: { address: any; }) => {
    console.log(a.address)
  });
  const Collection = await ethers.getContractFactory("ERC721CollectionV3")
  const collectionContract = await Collection.attach(waitRes.logs[1].address);
  const collectionOwner = await collectionContract.owner();
  console.log(`collection address  is : ${waitRes.logs[1].address}`)
  console.log(`collection Owner  is : ${collectionOwner}`)

  await collectionManager.manageCollection(
    forwardAddress,
    waitRes.logs[1].address,
    web3.eth.abi.encodeFunctionCall(
      {
        inputs: [
          {
            internalType: "address",
            name: "_beneficiaries",
            type: "address"
          },
          {
            internalType: "bool",
            name: "_tokenIds",
            type: "bool"
          }
        ],
        name: "setMinter",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
      },
      [forwardAddress,true]
    )
  )
  
  await collectionManager.manageCollection(
    forwardAddress,
    waitRes.logs[1].address,
    web3.eth.abi.encodeFunctionCall(
      {
        inputs: [
          {
            internalType: "address[]",
            name: "_beneficiaries",
            type: "address[]"
          },
          {
            internalType: "uint256[]",
            name: "_tokenIds",
            type: "uint256[]"
          }
        ],
        name: "mints",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
      },
      [[accountAddress,accountAddress,accountAddress,accountAddress],[1,2,3,4]]
    )
  )
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
