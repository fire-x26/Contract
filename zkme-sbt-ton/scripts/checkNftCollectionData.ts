import { Address, beginCell, toNano } from '@ton/core';
import { ZkmeSbt } from '../wrappers/ZkmeSbt';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const nftCollection = provider.open(ZkmeSbt.fromAddress(Address.parse('EQAvuCAd5t4MP6XdLDAxsN_yMYbuuVVfnW_r2PHiOszNM44z')));  //Provide NFT

    console.log('Querying NFT addresses for indices 0 to 3:');

    const nftAddress = await nftCollection.getGetZkmeContentV2(BigInt(1));
    console.log(nftAddress);


    console.log('NFT address querying completed');
}