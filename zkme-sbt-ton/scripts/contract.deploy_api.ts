import {
    Address,
    beginCell,
    contractAddress,
    toNano,
    TonClient4,
    internal,
    fromNano,
    WalletContractV4,
    TonClient, Cell,
} from "@ton/ton";

import { getHttpEndpoint } from "@orbs-network/ton-access";

import { mnemonicToPrivateKey } from "@ton/crypto";
import * as dotenv from "dotenv";
dotenv.config();
// ================================================================= //
import {Approve, GrandCoopeator, MintData, SetQuestion, UserData} from "../build/ZkmeSbt/tact_ZkmeSbt";

// ================================================================= //

(async () => {
    // Create client for testnet sandboxv4 API - alternative endpoint
    const client4 = new TonClient4({
        endpoint: "https://sandbox-v4.tonhubapi.com", // Test-net
    });

    const endpoint = await getHttpEndpoint({ network: "testnet" });
    console.log("endpoint:",endpoint)
    const client = new TonClient({endpoint})

    // Parameters for NFTs
    const OFFCHAIN_CONTENT_PREFIX = 0x01;
    const string_first = "https://ipfs.zk.me/ipns/sbt.zk.me/"; // Change to the content URL you prepared
    let newContent = beginCell().storeInt(OFFCHAIN_CONTENT_PREFIX, 8).storeStringRefTail(string_first).endCell();
    let mnemonics = ("rally remove cinnamon polar attack usage section police pottery report " +
        "conduct laundry submit evoke wasp slow umbrella wire repair garden table myself kitten caution"); // 🔴 Change to your own, by creating .env file!

    // let mnemonics2 = (" game " +
    //     " among " +
    //     " puzzle " +
    //     " relax " +
    //     " echo " +
    //     " prison " +
    //     " guide " +
    //     " misery " +
    //     " trouble " +
    //     " kingdom " +
    //     " next " +
    //     " girl " +
    //     " payment " +
    //     " knee " +
    //     " seminar " +
    //     " ship" +
    //     " vanish " +
    //     " film " +
    //     " vast " +
    //     " almost " +
    //     " spot " +
    //     " away " +
    //     " boost" +
    //     " business")

    let s = mnemonics.split(" ")
    console.log("s:" ,s)
    let keyPair = await mnemonicToPrivateKey(s);
    let secretKey = keyPair.secretKey;
    let workchain = 0;
    let wallet = WalletContractV4.create({ workchain, publicKey: keyPair.publicKey });
    console.log("publicKey", wallet.address);
    let wallet_contract = client4.open(wallet);
    console.log("Wallet address: ", wallet_contract.address);

    // Replace owner with your address
    let owner = wallet.address;

    // Prepare the initial code and data for the contract
    // let init = await ZkmeSbt.init(owner, newContent, {
    //     $$type: "RoyaltyParams",
    //     numerator: 0n, // 350n = 35%
    //     denominator: 10n,
    //     destination: owner,
    // });
    // // let deployContract = contractAddress(0, init);
    //EQD8fYF4W03b6Atcw8uNmSr3_NPN26lSJdueUFF-JEY0pX4v
    //EQAdMt3zKEnj_kInQOwUPY4vB9wsX0eNGtjtfl4rE5N7VDJx
    let deployContract = Address.parse("EQAvuCAd5t4MP6XdLDAxsN_yMYbuuVVfnW_r2PHiOszNM44z")
    // ========================================
    // let packed = beginCell().storeUint(0, 32).storeStringTail("Mint").endCell();
    // // ========================================
    console.log("before")
    let balance: bigint = await wallet_contract.getBalance();

    console.log("kk",balance)
    // let deployAmount = toNano("0.5");
    // let seqno: number = await wallet_contract.getSeqno();
    // // ========================================
    // console.log("Current deployment wallet balance: ", fromNano(balance).toString(), "💎TON");
    // printSeparator();
    // console.log("Deploying contract to address: ", deployContract);
    //

    let zkmeSbt = client4.open(ZkmeSbt.fromAddress(deployContract))



    const now = new Date().getTime();
    const userThresholdKey = "{\"c1\":{\"x\":\"0xfe7f0030ddef868bc55e2b9c48f78a5b408b126ba43083334234e7451179af4e\",\"y\":\"0x85cd7f77e5202476d4d75df51110d696685e34bb4f4c14317957cca4fc53b150\"},\"c2\":\"0x941f7969df367a4197cba1e56a8706830bfa4b0093bbabe02e058ea204bc8795\",\"c3\":\"0x2b05f8c95fc2668322fd0b01d25fceb46682111de06e430a8b6b0dfc948e9ee4\",\"c4\":\"0x24ff67d993a8cdd2ddc250fc0e4f13b54da42f54e0a1f776685a2a147dc321d0\"}";
    const data = "{\"country\":\"China\",\"gender\":\"F\"}";
    const questions = ["1691682026736473830156028739131309201251",
        "2913280489581153939655864562128061523446",
        "4413291953880700751284676293630174255314",
        "6168752826443568356578851982882135008485",
        "7646790225151838910224288229503243662977",
        "7721528705884867793143365084876737116315",
        "7998441164053548419020527146741878982601"];

    const questionsStr = "1691682026736473830156028739131309201251"+
        "2913280489581153939655864562128061523446"+
        "4413291953880700751284676293630174255314"+
        "6168752826443568356578851982882135008485"+
        "7646790225151838910224288229503243662977"+
        "7721528705884867793143365084876737116315"+
        "7998441164053548419020527146741878982601";


    const setQuestionsListStr =
        "6168752826443568356578851982882135008485"+
        "7646790225151838910224288229503243662977"+
        "7721528705884867793143365084876737116315"+
        "1691682026736473830156028739131309201251"+
        "2913280489581153939655864562128061523446"+
        "4413291953880700751284676293630174255314";
    function stringArrayToCell(strings: string[]): Cell {
        const builder = beginCell();

        strings.forEach((str) => {
            // const buffer = Buffer.from(str, 'utf-8'); // 将每个字符串编码为 Buffer
            // builder.storeBuffer(buffer); // 将 Buffer 存储到 cell 中
            builder.storeStringTail(str);
        });

        return builder.endCell();
    }
    let coopAdd= Address.parse("EQDND6yHEzKB82ZGRn58aY9Tt_69Ie_uz73e2VuuJ3fVVXfV")
    const questionCell = stringArrayToCell(questions);
    const addressA :Address = Address.parse("UQBy2wQ_EYIcVGWQ95Tj1Fws1EggBE5gfweB3hFd5MvolC09")
    const addressB: Address = Address.parse("0QCY2-TB2TfLFjOi-zC_fexU2syLkmyex3CqODUviRVWUaW5")
    const addressC: Address = Address.parse("kQDwceu1_JEKY4n3_26CucXC6nZPjf46xxwVG-0tpNtqtqIi")

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

    const sender = wallet_contract.sender(secretKey)



    const setQuestionsList = [
        "1691682026736473830156028739131309201251",
        "2913280489581153939655864562128061523446",
        "4413291953880700751284676293630174255314"];


    const setQuestionsListCell = stringArrayToCell(setQuestionsList);

    const coopQ: SetQuestion ={
        $$type: 'SetQuestion',
        cooperator:coopAdd,
        questions: setQuestionsListStr,
    }

    //mint

    // const res = await zkmeSbt.send(sender,  { value: toNano(0.06) }, "Mint")
    // const res = await zkmeSbt.send(sender,  { value: toNano(0.15) }, mintDataA)
    //  console.log("after send")

    // const tokenId :bigint = 0n
    // console.log("before get")
      const ans1 = await  zkmeSbt.getGetZkmeContentV2(1n)
    // console.log("before get")
    // const ans1 = await  zkmeSbt.getGetUserData(addressA)
    console.log("ans:",ans1)
    //
    // //
    // const ans2 = await  zkmeSbt.getGetZkmeTokenIdByAddress(addressA)
    //
    // console.log("ans:",ans2)

    //approve
    // const app :Approve = {
    //     $$type: 'Approve',
    //     cooperator: coopAdd,
    //     tokenId: 2n,
    //     cooperatorThresholdKey: "kscscsdwdwksnfckw",
    // }
    //
    // const approveRes = await zkmeSbt.send(sender,  { value: toNano(0.1) }, app)
    // const hasApp = await zkmeSbt.getGetHasApproved(coopAdd,wallet.address)
    // console.log("hasApp:",hasApp)

    //setQuestion

    const g:GrandCoopeator = {
        $$type: 'GrandCoopeator',
        cooperator: coopAdd,
        category: 2n //1表示sbt合约 2表示verify 3表示 conf express这里永远都穿2
    }

    // const grant = await  zkmeSbt.send(sender,{value: toNano(0.1)}, g)

    // const q = await zkmeSbt.send(sender,{value: toNano(0.1)}, coopQ)
    // console.log("q:",q)

    // const qs = await zkmeSbt.getGetQuestions(coopAdd)
    // console.log("qs:",qs)





    //
    // let collection_client = client4.open(ZkmeItem.fromAddress(deployContract));
    // let latest_indexId = (await collection_client.getGetZkmeData());
    // console.log("Latest indexID:[", latest_indexId, "]");
    // let item_address = await collection_client.getGetNftAddressByIndex(latest_indexId);
    // console.log("Minting NFT Item: ", item_address);
})();
