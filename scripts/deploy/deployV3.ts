import { ethers } from "hardhat"
import * as ManaConfig from 'decentraland-mana/build/contracts/MANAToken.json'

import {
  MANA_BYTECODE, RESCUE_ITEMS_SELECTOR,
  SET_APPROVE_COLLECTION_SELECTOR,
  SET_EDITABLE_SELECTOR
} from './utils'


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
const DEFAULT_RARITY_PRICE = '100000000000000000000' // 100 MANA

const OWNER_CUT_PER_MILLION = 25000

const FEES_COLLECTOR_CUT_PER_MILLION = 0
const ROYALTIES_CUT_PER_MILLION = 25000
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
  // Deploy collection marketplace
  let acceptedToken: string = '';


  const Mana = new ethers.ContractFactory(ManaConfig.abi, MANA_BYTECODE, ethers.provider.getSigner())
  const mana = await Mana.deploy()
  
  acceptedToken = mana.address
  console.log('Mana:', acceptedToken)

  // Deploy the collection implementation
  const Collection = await ethers.getContractFactory("ERC721CollectionV3")
  const collectonImp = await Collection.deploy()
  console.log('Collection imp:', collectonImp.address)


  // Deploy the collection manager
  const CollectionManager = await ethers.getContractFactory("CollectionManagerV2")
  const collectionManager = await CollectionManager.deploy()
    console.log('Collection Manager :', collectionManager.address)

  // Deploy the forwarder
  const Forwarder = await ethers.getContractFactory("Forwarder")
  const forwarder = await Forwarder.deploy(owner, collectionManager.address)
  console.log('Forwarder:', forwarder.address)

  // Deploy the forwarder
  const ERC721CollectionFactoryV2 = await ethers.getContractFactory("ERC721CollectionFactoryV2")
  const collectionFactoryV2 = await ERC721CollectionFactoryV2.deploy(forwarder.address, collectonImp.address)
  console.log('Collection Factory:', collectionFactoryV2.address)


  const Marketplace = await ethers.getContractFactory("MarketplaceV3")
  const marketplace = await Marketplace.deploy(
    owner,
    collectionDeploymentsFeesCollector,
    acceptedToken,
    FEES_COLLECTOR_CUT_PER_MILLION
  )
  console.log('NFT Marketplace:', marketplace.address)


  const BidContract = await ethers.getContractFactory("ERC721BidV2")
  const bidContract = await BidContract.deploy(
    owner,
    collectionDeploymentsFeesCollector,
    acceptedToken,
    FEES_COLLECTOR_CUT_PER_MILLION
  )
  console.log('bidContract:', bidContract.address)

  mana.mint(accountAddress,"10000000000000000000000000")

}

// Contract deployed by: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
// Mana: 0x5FbDB2315678afecb367f032d93F642f64180aa3
// Collection imp: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
// Collection Manager : 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
// Forwarder: 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
// Collection Factory: 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
// NFT Marketplace: 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707
// bidContract: 0x0165878A594ca255338adfa4d48449f69242Eb8F

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
