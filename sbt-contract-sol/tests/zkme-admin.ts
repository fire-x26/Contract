// import * as anchor from "@coral-xyz/anchor";
// import {Program, web3} from "@coral-xyz/anchor";
// import { ZkmeSol } from "../target/types/zkme_sol";
// import {it} from "mocha";
// import {TOKEN_PROGRAM_ID} from "@coral-xyz/anchor/dist/cjs/utils/token";
// import {
//     createAccount,
//     createAssociatedTokenAccount, createAssociatedTokenAccountInstruction,
//     createInitializeMintInstruction,
//     createInitializeNonTransferableMintInstruction, getAssociatedTokenAddress,
//     mintTo,
//     TOKEN_2022_PROGRAM_ID,
// } from "@solana/spl-token";
// import {createMint} from '@solana/spl-token';
// import {
//     Keypair,
//     Transaction,
//     SystemProgram,
//     Connection,
//     sendAndConfirmTransaction,
//     PublicKey,
//     LAMPORTS_PER_SOL,
//     type Signer, type ConfirmOptions
// } from "@solana/web3.js";
//
//
//
//
// async function sleep(ms: number) {
//     return new Promise(resolve => setTimeout(resolve, ms));
// }
//
//
//
// //anchor test
// describe("zkme_admin", async () => {
//     // Configure the client to use the local cluster.
//     anchor.setProvider(anchor.AnchorProvider.env());
//
//     const program = anchor.workspace.ZkmeSol as Program<ZkmeSol>;
//     const zkmeSeed = anchor.utils.bytes.utf8.encode("zkme_admin");
//
//     let adminPubKey;
//
//     let tokenAccount;
//
//     const mintAuthority = web3.Keypair.generate();
//
//     let mintAuthorityPubKey
//
//
//     before(async () => {
//         [adminPubKey] = await anchor.web3.PublicKey.findProgramAddress(
//             [zkmeSeed, anchor.AnchorProvider.env().wallet.publicKey.toBytes()],
//             program.programId
//         );
//
//     });
//
//
//     before(async () => {
//         [mintAuthorityPubKey] = await anchor.web3.PublicKey.findProgramAddress(
//             [zkmeSeed, mintAuthority.publicKey.toBytes()],
//             program.programId
//         );
//
//     });
//
//
//
//
//
//     it("Is createAdmin", async () => {
//
//         const connection = new Connection('http://127.0.0.1:8899', 'confirmed');
//
//
//         console.log("mintAuthority",mintAuthority)
//         console.log("admin:", adminPubKey)
//         console.log("anchor.AnchorProvider.env().wallet:",anchor.AnchorProvider.env().wallet.publicKey)
//
//         // 创建一个新的Mint
//
//         const fromWallet = web3.Keypair.generate();
//         const createMintPair = web3.Keypair.generate();
//         // async function createToken() {
//             // 确保钱包有足够的SOL来支付交易费用
//             const airdropSignature = await connection.requestAirdrop(
//                 fromWallet.publicKey,
//                 web3.LAMPORTS_PER_SOL, // 获取1 SOL
//             );
//             await connection.confirmTransaction(airdropSignature);
//             const balanceA = await connection.getBalance(fromWallet.publicKey)
//             console.log("airdropSignature success",balanceA)
//
//
//             const airdropSignatureB = await connection.requestAirdrop(
//                 createMintPair.publicKey,
//                 web3.LAMPORTS_PER_SOL, // 获取1 SOL
//             );
//             await connection.confirmTransaction(airdropSignatureB);
//             const balanceB = await connection.getBalance(createMintPair.publicKey)
//             console.log("airdropSignatureB success",balanceB)
//
//
//             const airdropSignatureC = await connection.requestAirdrop(
//                 mintAuthority.publicKey,
//                 web3.LAMPORTS_PER_SOL, // 获取1 SOL
//             );
//             await connection.confirmTransaction(airdropSignatureC);
//             const balanceC = await connection.getBalance(mintAuthority.publicKey)
//             console.log("airdropSignatureC success",balanceC)
//
//
//             const airdropSignatureD = await connection.requestAirdrop(
//                 mintAuthorityPubKey,
//                 web3.LAMPORTS_PER_SOL, // 获取1 SOL
//             );
//             await connection.confirmTransaction(airdropSignatureD);
//             const balanceD = await connection.getBalance(mintAuthorityPubKey)
//             console.log("airdropSignatureD success",balanceD)
//
//
//
//         // let anchorSigner  = anchor.AnchorProvider.env().wallet
//         // 创建代币
//
//         //     const mint = await createMint(
//         //         connection,
//         //         mintAuthority, // 用作minting authority的账户，一般需要为admin owner
//         //         mintAuthority.publicKey, // 通常mint authority和freeze authority是同一个
//         //         null, // freeze authority，可以设置为null
//         //         9, // 小数点位数
//         //         undefined,
//         //         {},
//         //         TOKEN_2022_PROGRAM_ID,// token程序的公钥
//         //     );
//         //
//         //     console.log(`Mint Address: ${mint.toString()}`);
//         //     return mint;
//         // }
//         //
//         // async function mintTokens(mintT, amount) {
//         //     console.log("start mintTokens")
//         //     // 创建一个新的代币账户
//         //     tokenAccount = await createAccount(
//         //         connection, // rpc
//         //         fromWallet, // payer付费钱包
//         //         mintT, // 代币地址
//         //         fromWallet.publicKey, //付费钱包公钥
//         //         undefined, // 自动生成
//         //         {},
//         //         TOKEN_2022_PROGRAM_ID,
//         //     )
//         //     console.log("end createAccount")
//         //     // 铸造代币到这个新账户
//         //     const txn = await mintTo(
//         //         connection,
//         //         fromWallet,
//         //         mintT,  //代币的地址
//         //         tokenAccount, //token的地址
//         //         mintAuthority, // mint 代币的持有人地址
//         //         100,
//         //         undefined,
//         //         {},
//         //         TOKEN_2022_PROGRAM_ID,
//         //     );
//         //
//         //     console.log(`Token Account: ${tokenAccount.toString()}`);
//         //     console.log(`Minted ${amount} tokens to ${tokenAccount.toString()}`);
//         //     console.log("txn mint to:",txn)
//         // }
//         //
//         // // createToken().then((mint) => {
//         // //     mintTokens(mint, 100); // 铸造100个代币
//         // // });
//         //
//         // const mint = await createToken()
//         // console.log("after mid mint",mint)
//         // tokenAccount = await createAccount( //为付费钱包创建账户
//         //     connection,
//         //     fromWallet,
//         //     mint,
//         //     fromWallet.publicKey, //owner 可以不一致
//         //     undefined,
//         //     {},
//         //     TOKEN_2022_PROGRAM_ID,
//         // )
//         // console.log("end createAccount")
//         // // await mintTokens(mint, 100);
//         // console.log("after mint",mint)
//         //
//         // console.log("admin:", mintAuthority.publicKey)
//         //
//         //
//         //
//         //
//         const createAccountInstruction = SystemProgram.createAccount({
//             fromPubkey: fromWallet.publicKey, // Account that will transfer lamports to created account
//             newAccountPubkey: createMintPair.publicKey, // Address of the account to create
//             space: 9, // Amount of bytes to allocate to the created account
//             lamports: web3.LAMPORTS_PER_SOL, // Amount of lamports transferred to created account
//             programId: TOKEN_2022_PROGRAM_ID, // Program assigned as owner of created account
//         });
//         console.log("createAccountInstruction",createAccountInstruction)
//
//         const initializeNonTransferableMintInstruction =
//             createInitializeNonTransferableMintInstruction(
//                 createMintPair.publicKey, // Mint Account address
//                 TOKEN_2022_PROGRAM_ID, // Token Extension Program ID
//             );
//         console.log("initializeNonTransferableMintInstruction",initializeNonTransferableMintInstruction)
//
//         const initializeMintInstruction = createInitializeMintInstruction(
//             createMintPair.publicKey, // Mint Account Address
//             9, // Decimals of Mint
//             mintAuthority.publicKey, // Designated Mint Authority
//             null, // Optional Freeze Authority
//             TOKEN_2022_PROGRAM_ID, // Token Extension Program ID
//         );
//         console.log("initializeMintInstruction",initializeMintInstruction)
//
//
//         const transaction = new Transaction().add(
//             createAccountInstruction,
//             initializeNonTransferableMintInstruction,
//             initializeMintInstruction,
//         );
//         //mint铸造
//         let transactionSignature = await sendAndConfirmTransaction(
//             connection,
//             transaction,
//             [fromWallet, createMintPair], // Signers
//         );
//         console.log("transactionSignature",transactionSignature)
//
//         //  transactionSignature = await mintTo(
//         //     connection,
//         //     payer, // Transaction fee payer
//         //     mint, // Mint Account address
//         //     sourceTokenAccount, // Mint to
//         //     mintAuthority, // Mint Authority address
//         //     100, // Amount
//         //     undefined, // Additional signers
//         //     undefined, // Confirmation options
//         //     TOKEN_2022_PROGRAM_ID, // Token Extension Program ID
//         // );
//
//         console.log(
//             "\nMint Tokens:",
//             `https://solana.fm/tx/${transactionSignature}?cluster=devnet-solana`,
//         );
//
//
//         // tokenAccount = await createAccount(
//         //     connection, // rpc
//         //     fromWallet, // payer付费钱包
//         //     mintT, // 代币地址
//         //     fromWallet.publicKey, //付费钱包公钥
//         //     undefined, // 自动生成
//         //     {},
//         //     TOKEN_2022_PROGRAM_ID,
//         // )
//
//         //     const mint = await createMint(
//         //         connection,
//         //         mintAuthority, // 用作minting authority的账户，一般需要为admin owner
//         //         mintAuthority.publicKey, // 通常mint authority和freeze authority是同一个
//         //         null, // freeze authority，可以设置为null
//         //         9, // 小数点位数
//         //         undefined,
//         //         {},
//         //         TOKEN_2022_PROGRAM_ID,// token程序的公钥
//         //     );
//
//
//         // Mint tokens to sourceTokenAccount
//         // let mintPubkey = await createMint(
//         //     connection, // conneciton
//         //     fromWallet, // fee payer
//         //     mintAuthority.publicKey, // mint authority
//         //     null, // freeze authority (you can use `null` to disable it. when you disable it, you can't turn it on again)
//         //     8, // decimals
//         //     undefined,
//         //     {},
//         //     TOKEN_2022_PROGRAM_ID,// token程序的公钥
//         // );
//         // console.log(`mint: ${mintPubkey.toBase58()}`);
//         //
//         // //创建关联tokenAccount
//         // let ata = await createAssociatedTokenAccount(
//         //     connection, // connection
//         //     fromWallet, // fee payer
//         //     mintPubkey, // mint
//         //     createMintPair.publicKey, // owner,
//         //     {},
//         //     TOKEN_2022_PROGRAM_ID,
//         // );
//         // console.log(`ATA: ${ata.toBase58()}`);
//
//
//
//
// // Send transaction
//
//
//         // const tx = await program.methods.createAdmin().accounts({
//         //     admin: adminPubKey,
//         //     authority: anchor.AnchorProvider.env().wallet.publicKey,
//         //     systemProgram: anchor.web3.SystemProgram.programId,
//         // }).rpc();
//         // console.log("Your create Admin transcation signature", tx);
//         //
//         //
//         // // const tx2 = await program.methods.approveOperator().accounts({
//         // //     admin:adminPubKey,
//         // //     authority:anchor.AnchorProvider.env().wallet.publicKey,
//         // //     newOperator: adminPubKey,
//         // // }).rpc();
//         // // console.log("Your transcation signature",tx2);
//         //
//         // console.log("admin:", adminPubKey.key)
//         // console.log("anchor pubkey:", anchor.AnchorProvider.env().wallet.publicKey)
//         // console.log("programId:", TOKEN_PROGRAM_ID)
//         // const tx3 = await program.methods.mintSbt().accounts({
//         //     admin: adminPubKey,
//         //     authority: anchor.AnchorProvider.env().wallet.publicKey,
//         //     user: mintAuthority.publicKey,
//         //     mint: createMintPair.publicKey,
//         //     tokenAccount: web3.Keypair.generate().publicKey, //关联地址的作用？
//         //     tokenProgram: TOKEN_2022_PROGRAM_ID,
//         //     systemProgram: anchor.web3.SystemProgram.programId,
//         //
//         // }).rpc();
//         // console.log("Your transcation signature", tx3);
//
//         // console.log("burn sbt");
//         // const tx4 = await program.methods.burnSbt().accounts({
//         //     authority: anchor.AnchorProvider.env().wallet.publicKey,
//         //     tokenAccount: tokenAccount,
//         //     mint: mint,
//         //     tokenProgram:TOKEN_2022_PROGRAM_ID
//         // }).rpc()
//         // console.log("burn sbt",tx4);
//
//     })
//
//
//     // it( "Is createAdmin", async () =>{
//     //     const tx = await program.methods.createAdmin().accounts({
//     //         admin:adminPubKey,
//     //         authority:anchor.AnchorProvider.env().wallet.publicKey,
//     //         systemProgram: anchor.web3.SystemProgram.programId,
//     //     }).rpc();
//     //     console.log("Your transcation signature",tx);
//     // })
//     //
//     //
//     // it( "Is add_operator", async () =>{
//     //     const tx = await program.methods.approveOperator().accounts({
//     //         admin:adminPubKey,
//     //         authority:anchor.AnchorProvider.env().wallet.publicKey,
//     //         newOperator: adminPubKey,
//     //     }).rpc();
//     //     console.log("Your transcation signature",tx);
//     // })
//     //
//     // it( "Is mint sbt", async () =>{
//     //     console.log("admin:",adminPubKey.key)
//     //     console.log("anchor pubkey:",anchor.AnchorProvider.env().wallet.publicKey)
//     //     console.log("programId:",TOKEN_PROGRAM_ID)
//     //     const tx = await program.methods.mintSbt().accounts({
//     //         admin: adminPubKey,
//     //         user: anchor.AnchorProvider.env().wallet.publicKey,
//     //         mint: anchor.AnchorProvider.env().wallet.publicKey,
//     //         tokenAccount: "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb",
//     //         tokenProgram: "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb",
//     //     }).rpc();
//     //     console.log("Your transcation signature",tx);
//     // })
//     // let s = "data";
//     // let valiq = ["validQ"];
//     // it( "Is create conf", async () =>{
//     //     const tx = await program.methods.createConf(s,valiq).accounts({
//     //         admin: adminPubKey,
//     //         authority:anchor.AnchorProvider.env().wallet.publicKey,
//     //         coConf: anchor.AnchorProvider.env().wallet.publicKey,
//     //     }).rpc();
//     //     console.log("Your transcation signature",tx);
//     // })
//     //
//     // it( "Is update conf", async () =>{
//     //     const tx = await program.methods.updateConf(s,valiq).accounts({
//     //         admin: adminPubKey,
//     //         authority:anchor.AnchorProvider.env().wallet.publicKey,
//     //         coConf: anchor.AnchorProvider.env().wallet.publicKey,
//     //     }).rpc();
//     //     console.log("Your transcation signature",tx);
//     // })
//     //
//     //
//     // let thresholdKey = "thresholdKey";
//     // let expirationDate: BigInt = 20250101n;
//     //
//     //
//     // it( "Is create Kyc", async () =>{
//     //     // @ts-ignore
//     //     const tx = await program.methods.createKyc(thresholdKey,expirationDate,s,valiq).accounts({
//     //         admin: adminPubKey,
//     //         authority:anchor.AnchorProvider.env().wallet.publicKey,
//     //         kyc: "11111",
//     //     }).rpc();
//     //     console.log("Your transcation signature",tx);
//     // })
//     //
//     // it( "Is update Kyc", async () =>{
//     //     // @ts-ignore
//     //     const tx = await program.methods.updateKyc(thresholdKey,expirationDate,s,valiq).accounts({
//     //         admin: adminPubKey,
//     //         authority:anchor.AnchorProvider.env().wallet.publicKey,
//     //         kyc: "22222",
//     //     }).rpc();
//     //     console.log("Your transcation signature",tx);
//     // })
//
//
//     // it( "Is approve sbt", async () =>{
//     //     const tx = await program.methods.approveSbt(thresholdKey).accounts({
//     //         authority:anchor.AnchorProvider.env().wallet.publicKey,
//     //         coConf:,
//     //         kycFull:,
//     //     }).rpc();
//     //     console.log("Your transcation signature",tx);
//     // })
//     //
//     // it( "Is revoke sbt", async () =>{
//     //     const tx = await program.methods.revokeSbt().accounts({
//     //         authority:anchor.AnchorProvider.env().wallet.publicKey,
//     //         coConf:,
//     //         kycFull:,
//     //     }).rpc();
//     //     console.log("Your transcation signature",tx);
//     // })
//     // it( "Is burn sbt", async () =>{
//     //     const tx = await program.methods.burnSbt().accounts({
//     //         authority:anchor.AnchorProvider.env().wallet.publicKey,
//     //     }).rpc();
//     //     console.log("Your transcation signature",tx);
//     // })
//
//
//     // it("Is initialized!", async () => {
//     //   // Add your test here.
//     //   const tx = await program.methods.initialize().rpc();
//     //   console.log("Your transaction signature", tx);
//     // });
//
//     // it( "Is createConf", async () =>{
//     //     const tx = await program.methods.createAdmin().accounts({
//     //         admin:adminPubKey,
//     //         authority:anchor.AnchorProvider.env().wallet.publicKey,
//     //         systemProgram: anchor.web3.SystemProgram.programId,
//     //     }).rpc();
//     //     console.log("Your transcation signature",tx);
//     // })
// });