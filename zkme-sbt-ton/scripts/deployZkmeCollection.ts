import { Address, beginCell,contractAddress, fromNano, toNano } from '@ton/core';
import { ZkmeSbt } from '../wrappers/ZkmeSbt';
import { NetworkProvider } from '@ton/blueprint';
import { prepareTactDeployment } from "@tact-lang/deployer";
import fs from "fs";
import path from "path";

export async function run(provider: NetworkProvider) {
    const OFFCHAIN_CONTENT_PREFIX = 0x01;
    const CONTENT_URL = "https://ipfs.zk.me/ipns/sbt.zk.me/"; // Change to your content URL
    const NFT_PRICE = toNano('0');

    const contentCell = beginCell().storeInt(OFFCHAIN_CONTENT_PREFIX, 8).storeStringRefTail(CONTENT_URL).endCell();

    // Use the sender's address as the owner
    const owner = Address.parse("0QBy2wQ_EYIcVGWQ95Tj1Fws1EggBE5gfweB3hFd5MvolJa3");

    if (!owner) {
        console.log("Owner address is undefined");
        return;
    }

    //let init = await SbtCollection.init(owner, contentCell, NFT_PRICE);

    // let address = contractAddress(0, init);
    // let data = init.data.toBoc();
    // let pkg = fs.readFileSync(path.resolve(__dirname, "../build/sbtCollection", "tact_SbtCollection.pkg"));
    // let testnet = true;
    //
    // // Prepareing
    // console.log("Uploading package...");
    // let prepare = await prepareTactDeployment({ pkg, data, testnet });
    //
    // // Deploying
    // console.log("==============================================");
    // console.log("Contract Address");
    // console.log("==============================================");
    // console.log();
    // console.log(address.toString({ testOnly: testnet }));
    // console.log();
    // console.log("==============================================");
    // console.log("Please, follow deployment link");
    // console.log("==============================================");
    // console.log();
    // console.log(prepare);
    // console.log();
    // console.log("==============================================");

    let cooperator = Address.parse("EQCmJQxMJWYCR70lqiHKVWEJmf4gQWVlEeEh4G4B46zxfCsn")
    const nftCollection = provider.open(await ZkmeSbt.fromInit
    (owner, contentCell, {
        $$type: "RoyaltyParams",
        numerator: 0n, // 350n = 35%
        denominator: 10n,
        destination: owner,
    },cooperator));

    console.log('NFT collection will be deployed at:', nftCollection.address);

    // Deploy the contract and mint the first NFT
    await nftCollection.send(
        provider.sender(),
        {
            value: toNano('0.1') + NFT_PRICE,
        },
        "Mint"
    );

    await provider.waitForDeploy(nftCollection.address);

    console.log('NFT Collection deployed');
}
