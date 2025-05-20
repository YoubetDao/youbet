module distributor::structs {
    // use sui::object;
    use sui::balance::Balance;
    use sui::sui::SUI;
    use sui::table::{Self, Table};
    use std::string::String;
    // use sui::tx_context::TxContext;
    use std::string;
    // use sui::transfer;

    /// Claim record for each GitHub ID
    public struct ClaimInfo has store {
        claimed: bool,
        amount: u64
    }

    /// Red packet object
    public struct RedPacket has key, store {
        id: object::UID,
        creator: address,
        total_amount: u64,
        remaining_amount: u64,
        status: u8,
        claims: Table<String, ClaimInfo>,
        balance: Balance<SUI>
    }

    /// Global state object (Singleton)
    public struct State has key, store {
        id: object::UID,
        signer: vector<u8>,
        owner: address,
        red_packets: Table<string::String, RedPacket>
    }

    // Constructor functions
    public fun new_claim_info(claimed: bool, amount: u64): ClaimInfo {
        ClaimInfo { claimed, amount }
    }

    public fun new_red_packet(
        creator: address,
        total_amount: u64,
        remaining_amount: u64,
        status: u8,
        claims: Table<String, ClaimInfo>,
        balance: Balance<SUI>,
        ctx: &mut TxContext
    ): RedPacket {
        let id = object::new(ctx);
        RedPacket {
            id,
            creator,
            total_amount,
            remaining_amount,
            status,
            claims,
            balance
        }
    }

    public fun new_state(
        signer: vector<u8>,
        owner: address,
        ctx: &mut TxContext
    ): State {
        let id = object::new(ctx);
        let red_packets = table::new(ctx);
        State { id, signer, owner, red_packets }
    }

    // Transfer functions
    public fun share_red_packet(red_packet: RedPacket) {
        transfer::share_object(red_packet);
    }

    public fun share_state(state: State) {
        transfer::share_object(state);
    }

    // Getters and setters for ClaimInfo
    public fun get_claim_info_claimed(info: &ClaimInfo): bool {
        info.claimed
    }

    public fun get_claim_info_amount(info: &ClaimInfo): u64 {
        info.amount
    }

    public fun set_claim_info_claimed(info: &mut ClaimInfo, claimed: bool) {
        info.claimed = claimed;
    }

    // Getters and setters for RedPacket
    public fun get_red_packet_creator(red_packet: &RedPacket): address {
        red_packet.creator
    }

    public fun get_red_packet_total_amount(red_packet: &RedPacket): u64 {
        red_packet.total_amount
    }

    public fun get_red_packet_remaining_amount(red_packet: &RedPacket): u64 {
        red_packet.remaining_amount
    }

    public fun get_red_packet_status(red_packet: &RedPacket): u8 {
        red_packet.status
    }

    public fun get_red_packet_claims(red_packet: &RedPacket): &Table<String, ClaimInfo> {
        &red_packet.claims
    }

    public fun get_red_packet_claims_mut(red_packet: &mut RedPacket): &mut Table<String, ClaimInfo> {
        &mut red_packet.claims
    }

    public fun get_red_packet_balance_mut(red_packet: &mut RedPacket): &mut Balance<SUI> {
        &mut red_packet.balance
    }

    public fun set_red_packet_remaining_amount(red_packet: &mut RedPacket, amount: u64) {
        red_packet.remaining_amount = amount;
    }

    public fun set_red_packet_status(red_packet: &mut RedPacket, status: u8) {
        red_packet.status = status;
    }

    // Getters and setters for State
    public fun get_state_signer(state: &State): vector<u8> {
        state.signer
    }

    public fun get_state_owner(state: &State): address {
        state.owner
    }


    public fun add_red_packet_to_state(state: &mut State, uuid: string::String, red_packet: RedPacket) {

        table::add(&mut state.red_packets, uuid, red_packet);
    }


    public fun get_red_packet_from_state(state: &State, uuid: string::String): &RedPacket {
        // get red packet from state
        table::borrow(&state.red_packets, uuid)
    }

    public fun get_red_packet_from_state_mut(state: &mut State, uuid: string::String): &mut RedPacket {
        // get mutable red packet from state
        table::borrow_mut(&mut state.red_packets, uuid)
    }

    // public fun set_state_signer(state: &mut State, signer: vector<u8>, ctx: &mut TxContext)  {
    //     // TODO: check if signer is owner  
    //     assert!(tx_context::sender(ctx) == state.owner, 0);
    //     state.signer = signer;
    // }

    public fun set_state_owner(state: &mut State, owner: address, ctx: &mut TxContext) {
        // TODO: check if signer is owner  
        assert!(tx_context::sender(ctx) == state.owner, 0);
        state.owner = owner;
    }
} 
