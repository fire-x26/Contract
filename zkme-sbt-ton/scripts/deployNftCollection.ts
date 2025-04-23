import { Address, beginCell, fromNano, toNano } from '@ton/core';
import {MintData, ZkmeSbt, UserData} from '../wrappers/ZkmeSbt';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const OFFCHAIN_CONTENT_PREFIX = 0x01;
    const CONTENT_URL = "https://ipfs.zk.me/ipns/sbt.zk.me/"; // Change to your content URL
    const NFT_PRICE = toNano('0');
    
    const contentCell = beginCell().storeInt(OFFCHAIN_CONTENT_PREFIX, 8).storeStringRefTail(CONTENT_URL).endCell();

    // Use the sender's address as the owner
    const owner = provider.sender().address;

    const cooperator = Address.parse("EQCmJQxMJWYCR70lqiHKVWEJmf4gQWVlEeEh4G4B46zxfCsn")

    if (!owner) {
        console.log("Owner address is undefined");
        return;
    }

    const nftCollection = provider.open(await ZkmeSbt.fromInit(owner, contentCell, NFT_PRICE,cooperator));

    console.log('NFT collection will be deployed at:', nftCollection.address);


    const addressA :Address = Address.parse("UQBy2wQ_EYIcVGWQ95Tj1Fws1EggBE5gfweB3hFd5MvolC09")


    let coopAdd= Address.parse("EQDND6yHEzKB82ZGRn58aY9Tt_69Ie_uz73e2VuuJ3fVVXfV")
    const questionsStr = "1691682026736473830156028739131309201251"+
        "2913280489581153939655864562128061523446"+
        "4413291953880700751284676293630174255314"+
        "6168752826443568356578851982882135008485"+
        "7646790225151838910224288229503243662977"+
        "7721528705884867793143365084876737116315"+
        "7998441164053548419020527146741878982601";
    const addressB: Address = Address.parse("0QCY2-TB2TfLFjOi-zC_fexU2syLkmyex3CqODUviRVWUaW5")
    const addressC: Address = Address.parse("kQDwceu1_JEKY4n3_26CucXC6nZPjf46xxwVG-0tpNtqtqIi")
    const now = new Date().getTime();
    const data = "{\"country\":\"China\",\"gender\":\"F\"}";
    const userThresholdKey = "{\"c1\":{\"x\":\"0xfe7f0030ddef868bc55e2b9c48f78a5b408b126ba43083334234e7451179af4e\",\"y\":\"0x85cd7f77e5202476d4d75df51110d696685e34bb4f4c14317957cca4fc53b150\"},\"c2\":\"0x941f7969df367a4197cba1e56a8706830bfa4b0093bbabe02e058ea204bc8795\",\"c3\":\"0x2b05f8c95fc2668322fd0b01d25fceb46682111de06e430a8b6b0dfc948e9ee4\",\"c4\":\"0x24ff67d993a8cdd2ddc250fc0e4f13b54da42f54e0a1f776685a2a147dc321d0\"}";

    const dataA:UserData = {
        $$type: 'UserData',
        to: addressA,
        key:userThresholdKey,
        data: data,
        validity: BigInt(now),
        questions:questionsStr,
    }
    const mintDataA:MintData = {
        data:dataA,
        $$type:'MintData',
    }

    // Deploy the contract and mint the first NFT
    await nftCollection.send(
        provider.sender(),
        {
            value: toNano('0.1') + NFT_PRICE,
        },
        mintDataA
    );

    await provider.waitForDeploy(nftCollection.address);

    console.log('NFT Collection deployed');
}