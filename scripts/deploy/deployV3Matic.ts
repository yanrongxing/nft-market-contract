import { ethers } from "hardhat"
import * as ManaConfig from 'decentraland-mana/build/contracts/MANAToken.json'

import {
  MANA_BYTECODE, RESCUE_ITEMS_SELECTOR,
  SET_APPROVE_COLLECTION_SELECTOR,
  SET_EDITABLE_SELECTOR
} from './utils'


const FEES_COLLECTOR_CUT_PER_MILLION = 0
/**
 * @dev Steps:
 * Deploy the Collection implementation
 * Deploy the committee with the desired members. The owner will be the DAO bridge
 * Deploy the collection Manager. The owner will be the DAO bridge
 * Deploy the forwarder. Caller Is the collection manager.
 * Deploy the collection Factory. Owner is the forwarder.
 */
async function main() {
  const owner = '0xbCD9E832c7Bb911889D0F68613812662CB1396EE'
  const collectionDeploymentsFeesCollector = '0xbCD9E832c7Bb911889D0F68613812662CB1396EE'

  const account = ethers.provider.getSigner()
  const accountAddress = await account.getAddress()
  console.log(`Contract deployed by: ${accountAddress}`)


  // Deploy collection marketplace
  let acceptedToken: string = '0x60E57e4AD9af84A2E7424A2ecb5dCa0c328183EA';


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


}
// NFT MARKETPLACE: 0x91f6d91c1345707D57212371cFf12A62709E43BF
// BID CONTRACT: 0x6fd3958d1b352fD8b18EA00e3Aee530D51556663
// ERC20: 0x60E57e4AD9af84A2E7424A2ecb5dCa0c328183EA
// ERC721: 0x0B96d89854aCDb0373A1A761BB6071D13E4f7be5
// ERC1155: 0x31f325A9D4E7e8E8A2E8b3f4a2eD20Fc4E907133

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
