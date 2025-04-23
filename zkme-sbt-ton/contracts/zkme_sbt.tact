import "./message.tact";
const minTonsForStorage: Int = ton("0.04");
const gasConsumption: Int = ton("0.04");

contract ZkmeSbt {
    next_item_index: Int as uint32 = 1;
    owner_address: Address;                   
    collection_content: Cell;   
    nft_price: Int;
    authority_address: Address;
    token_map: map<Address, Int>;
    owner_map: map<Int, Address>;
    approve_token_map: map<Int, Address>;
    kyc_map: map<Int, UserData>;

    question_map: map<Address,QuestionValue>;


    cooperator_sbt_map: map<Address,Address>;

    cooperator_verify_map: map<Address,Address>;

    cooperator_conf_map: map<Address,Address>;



    init(owner_address: Address, collection_content: Cell, nft_price: Int, cooperator_address:Address){
        self.owner_address = owner_address;
        self.collection_content = collection_content;
        self.nft_price = nft_price;  
        self.authority_address = owner_address;
        self.cooperator_sbt_map.set(owner_address,owner_address);
        self.cooperator_conf_map.set(owner_address,owner_address);
        self.cooperator_verify_map.set(owner_address,owner_address);
        self.cooperator_sbt_map.set(cooperator_address,cooperator_address);
        self.cooperator_conf_map.set(cooperator_address,cooperator_address);
        self.cooperator_verify_map.set(cooperator_address,cooperator_address);
    }

    receive(msg:MintData){
        let ctx: Context = context();
        let msgValue: Int = ctx.value;
        require(self.cooperator_sbt_map.get(ctx.sender) != null,"no auth");
        require(self.token_map.get(msg.data.to) == null, "minted already");
        let totalCost: Int = self.get_nft_mint_total_cost();
        require(msgValue >= totalCost, "Insufficient funds for minting");
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        msgValue = msgValue - (storageFee + gasConsumption + self.nft_price);

        // Send NFT price to owner
        let current_index: Int = self.next_item_index;

        self.mint(msg.data.to, msgValue);
        self.kyc_map.set(current_index, msg.data);
        self.owner_map.set(current_index, msg.data.to);
        self.token_map.set(msg.data.to, current_index);

        emit(LogEventMintRecord{ minter: sender(), item_id: self.next_item_index, generate_number: nativeRandom() }.toCell());
    }




    receive("Withdraw") {
        require(self.cooperator_sbt_map.get(sender()) != null,"no auth");
        let withdrawAmount: Int = myBalance() - context().value - minTonsForStorage;
        require(withdrawAmount > 0, "No TON to withdraw");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: withdrawAmount,
            mode: SendRemainingValue + SendIgnoreErrors
        });
    }

    // ===== Private Methods ===== //
    fun mint(sender: Address, msgValue: Int) {
        require(self.next_item_index >= 0, "Non-sequential NFTs");
        let nft_init: StateInit = self.getNftItemInit(self.next_item_index);
        send(SendParameters{
                to: contractAddress(nft_init), 
                value: msgValue, 
                bounce: false,
                mode: SendIgnoreErrors,
                body: Transfer {
                    query_id: 0,
                    new_owner: sender,
                    response_destination: self.owner_address,
                    custom_payload: self.collection_content,
                    forward_amount: 0,
                    forward_payload: emptySlice()
                }.toCell(),
                code: nft_init.code,
                data: nft_init.data
            });
        self.next_item_index = self.next_item_index + 1;
    }

    // --------- Get Collection Metadata Function --------- //


    get fun get_zkme_content_v2(index: Int ): UserData? {
        return  self.kyc_map.get(index);
    }

    get fun get_zkme_token_id_by_address(address: Address ): Int? {
        return self.token_map.get(address);
    }


    get fun get_owner_of(index: Int): Address?{
        return self.owner_map.get(index);
    }


    receive(msg: SetQuestion){
        let ctx: Context = context();
        require(self.cooperator_conf_map.get(ctx.sender) != null,"no auth");
        let q:QuestionValue = QuestionValue{
        questions: msg.questions,
        };
        self.question_map.set(msg.cooperator, q);
    }


    get fun get_questions(address: Address): String? {
        if(self.question_map.get(address) == null){
            return null;
        }
        let value: QuestionValue =  self.question_map.get(address)!!;
        return value.questions;
    }

    get fun get_init_owner(): Address? {
        return self.owner_address;
    }

    receive(msg: Approve){
        let ctx: Context = context();
        require(self.cooperator_verify_map.get(ctx.sender) != null,"no auth");
        if(self.kyc_map.get(msg.tokenId) == null){
            return;
        }
        if(self.owner_map.get(msg.tokenId) == null){
            return;
        }

        let ownerAddress:Address = self.owner_map.get(msg.tokenId)!!;
        let userData: UserData = self.kyc_map.get(msg.tokenId)!!;
        userData.key = msg.cooperatorThresholdKey;
        self.kyc_map.set(msg.tokenId,userData);

        let b: StringBuilder = beginString();
        b.append(msg.cooperator.toString());
        b.append(msg.tokenId.toString());
        dump(b.toString());
        dump(b.toSlice());
        dump(b.toSlice().hash());


        self.approve_token_map.set(b.toCell().hash(), ownerAddress);

        emit(ApproveRecord{cooperator: msg.cooperator, tokenId:msg.tokenId}.toCell());
    }

    get fun get_has_approved(cooperator: Address, user: Address):Bool{

        if(self.token_map.get(user) == null){
            return false;
        }
        let tokenId:Int = self.token_map.get(user)!!;
        dump(tokenId);
        let b: StringBuilder = beginString();
        b.append(cooperator.toString());
        b.append(tokenId.toString());
        dump(b.toString());
        dump(b.toSlice());
        dump(b.toSlice().hash());
        if(self.approve_token_map.get(b.toCell().hash()) == null){
            return false;
        }
        return true;
    }

    get fun get_user_data(user:Address):UserData?{
        require(self.token_map.get(user) != null, "not exist");
        let tokenId:Int = self.token_map.get(user)!!;
        return self.kyc_map.get(tokenId);
    }

    receive(msg:GrandCoopeator){
        let ctx: Context = context();
        if(msg.category == 1){
            require(self.cooperator_sbt_map.get(ctx.sender)!=null, "no auth");
            self.cooperator_sbt_map.set(msg.cooperator ,msg.cooperator);
        }
        if(msg.category == 2){
            require(self.cooperator_verify_map.get(ctx.sender)!=null, "no auth");
            self.cooperator_verify_map.set(msg.cooperator ,msg.cooperator);
        }
        if(msg.category == 3){
            require(self.cooperator_conf_map.get(ctx.sender)!=null, "no auth");
            self.cooperator_conf_map.set(msg.cooperator ,msg.cooperator);
        }
    }


    get fun get_is_cooperator(coop:Address):Bool{
        return self.cooperator_verify_map.get(coop) != null;
    }

    get fun get_user_token_for_operator(cooperator: Address, user: Address): Int?{
        let tokenId:Int = self.token_map.get(user)!!;
        let b: StringBuilder = beginString();
        b.append(cooperator.toString());
        b.append(tokenId.toString());
        if(self.approve_token_map.get(b.toCell().hash())  !=null){
            return tokenId;
        }
        return null;
    }

    get fun get_collection_data(): CollectionData {     
        let b: StringBuilder = beginString();
        let collectionDataString: String = self.collection_content.asSlice().asString();
        b.append(collectionDataString);
        b.append("meta.json");
        return CollectionData{
            next_item_index: self.next_item_index, 
            collection_content: b.toCell(), 
            owner_address: self.owner_address
        };
    }

    get fun get_nft_mint_total_cost(): Int {
        return (minTonsForStorage + gasConsumption + self.nft_price);
    }

    get fun get_nft_address_by_index(item_index: Int): Address?{      
        let initCode: StateInit = self.getNftItemInit(item_index);
        return contractAddress(initCode);
    }

    get fun getNftItemInit(item_index: Int): StateInit {
        return initOf SbtItem(myAddress(), item_index, self.authority_address);
    }
    
    get fun get_nft_content(index: Int, individual_content: Cell): Cell { 
        let b: StringBuilder = beginString();
        let ic: String = individual_content.asSlice().asString();
        b.append(ic);
        return b.toCell();
    }
}

contract SbtItem {
    collection_address: Address;
    item_index: Int; 
    is_initialized: Bool;

    owner: Address?;
    individual_content: Cell?;

    authority_address: Address?;
    revoked_at: Int as uint64 = 0;

    init(collection_address: Address, item_index: Int, authority_address: Address){
        require(sender() == collection_address, "Not from collection");
        self.collection_address = collection_address;
        self.item_index = item_index;
        self.is_initialized = false;
        self.authority_address = authority_address;
    }

    receive(msg: Transfer){
        let ctx: Context = context(); 
        let msgValue: Int = self.msgValue(ctx.value);
        
        if (self.is_initialized == false) {  // Initial Transfer, aka the "Minting" of the NFT
            require(ctx.sender == self.collection_address, "Initialized tx need from collection");
            self.is_initialized = true;
            self.owner = msg.new_owner;
            self.individual_content = msg.custom_payload;
            if (msgValue > 0) {
                    send(SendParameters{
                    to: msg.new_owner,
                    value: msgValue,
                    mode: SendPayGasSeparately,
                    body: Excesses { query_id: msg.query_id }.toCell()
                });
            }
        } else {
            require(false, "SBT cannot be transferred");
        }
    }
    
    receive(msg: GetStaticData){ 
        send(SendParameters {
            to: sender(),
            value: 0,
            mode: 64,  // (return msg amount except gas fees) 
            bounce: true,
            body: ReportStaticData{
                query_id: msg.query_id,
                index_id: self.item_index,
                collection: self.collection_address
            }.toCell()
        });
    }

    receive(msg: ProveOwnership) {
        require(sender() == self.owner, "Not owner");
        send(SendParameters{
            to: msg.dest,
            value: 0,
            mode: 64,
            body: OwnershipProof {
                query_id: msg.query_id,
                item_id: self.item_index,
                owner: self.owner!!,
                data: msg.forward_payload,
                revoked_at: self.revoked_at,
                content: msg.with_content ? self.individual_content : null
            }.toCell()
        });
    }

    receive(msg: RequestOwner) {
        send(SendParameters{
            to: msg.dest,
            value: 0,
            mode: 64,
            body: OwnerInfo {
                query_id: msg.query_id,
                item_id: self.item_index,
                initiator: sender(),
                owner: self.owner!!,
                data: msg.forward_payload,
                revoked_at: self.revoked_at,
                content: msg.with_content ? self.individual_content : null
            }.toCell()
        });
    }



    receive(msg: Revoke) {
        require(sender() == self.authority_address, "Not authorized");
        require(self.revoked_at == 0, "Already revoked");
        self.revoked_at = now();
    }

    fun msgValue(value: Int): Int {
        let tonBalanceBeforeMsg: Int = myBalance() - value;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        return value - (storageFee + gasConsumption);
    }

    // --------- Get Item Metadata Function --------- //
    get fun get_nft_data(): GetNftData {
        let b: StringBuilder = beginString();
        let collectionData: String = (self.individual_content!!).asSlice().asString();
        b.append(collectionData);
        b.append("item.json");

        return GetNftData {
            is_initialized: self.is_initialized, 
            index: self.item_index, 
            collection_address: self.collection_address, 
            owner_address: self.owner!!,
            individual_content: b.toCell()
        };
    }

    get fun get_authority_address(): Address? {
        return self.authority_address;
    }

    get fun get_revoked_time(): Int {
        return self.revoked_at;
    }
}