/*
/// Module: distributor
module distributor::distributor;
*/

// For Move coding conventions, see
// https://docs.sui.io/concepts/sui-move-concepts/conventions

module distributor::distributor {
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::balance;
    use sui::sui::SUI;
    use sui::ed25519;
    use sui::table;
    use std::vector;
    use std::string;
    use distributor::structs::{State, RedPacket};
    use distributor::events;
    use distributor::constants;

    #[allow(unused_const)]
    const ESignatureVerificationFailed: u64 = 1;

    /// Create a new red packet
    public entry fun create_red_packet(
        uuid: vector<u8>,
        github_ids: vector<vector<u8>>,
        amounts: vector<u64>,
        payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let github_ids_len = vector::length(&github_ids);
        let amounts_len = vector::length(&amounts);
        assert!(github_ids_len == amounts_len, constants::invalid_length());
        
        let mut total_amount = 0u64;
        let mut i = 0;
        while (i < amounts_len) {
            total_amount = total_amount + *vector::borrow(&amounts, i);
            i = i + 1;
        };

        let mut claims = table::new(ctx);
        i = 0;
        while (i < github_ids_len) {
            let github_id = string::utf8(*vector::borrow(&github_ids, i));
            let amount = *vector::borrow(&amounts, i);
            let claim_info = distributor::structs::new_claim_info(false, amount);
            table::add(&mut claims, github_id, claim_info);
            i = i + 1;
        };

        let red_packet = distributor::structs::new_red_packet(
            tx_context::sender(ctx),
            total_amount,
            total_amount,
            constants::status_active(),
            claims,
            coin::into_balance(payment),
            ctx
        );

        let mut github_id_strings = vector::empty();
        i = 0;
        while (i < github_ids_len) {
            vector::push_back(&mut github_id_strings, string::utf8(*vector::borrow(&github_ids, i)));
            i = i + 1;
        };

        events::emit_red_packet_created(
            string::utf8(uuid),
            tx_context::sender(ctx),
            total_amount,
            github_id_strings,
            amounts
        );

        distributor::structs::share_red_packet(red_packet);
    }

    /// Claim red packet with signature verification
    public entry fun claim_red_packet(
        state: &State,
        red_packet: &mut RedPacket,
        uuid: vector<u8>,
        github_id: vector<u8>,
        public_key: vector<u8>,
        signature: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(distributor::structs::get_red_packet_status(red_packet) == constants::status_active(), constants::red_packet_not_active());
        let amount = {
            let claims = distributor::structs::get_red_packet_claims_mut(red_packet);
            let claim_info = table::borrow_mut(claims, string::utf8(github_id));
            assert!(!distributor::structs::get_claim_info_claimed(claim_info), constants::already_claimed());
            distributor::structs::set_claim_info_claimed(claim_info, true);
            let mut message = vector::empty();
            vector::append(&mut message, uuid);
            vector::append(&mut message, github_id);
            assert!(
                ed25519::ed25519_verify(&signature, &public_key, &message),
                ESignatureVerificationFailed
            );
            distributor::structs::get_claim_info_amount(claim_info)
        };
        let balance = distributor::structs::get_red_packet_balance_mut(red_packet);
        let coin = coin::from_balance(balance::split(balance, amount), ctx);
        transfer::public_transfer(coin, tx_context::sender(ctx));
        let remaining = distributor::structs::get_red_packet_remaining_amount(red_packet);
        distributor::structs::set_red_packet_remaining_amount(red_packet, remaining - amount);
        events::emit_red_packet_claimed(
            string::utf8(uuid),
            string::utf8(github_id),
            tx_context::sender(ctx),
            amount
        );
    }

    /// Refund unclaimed amount
    public entry fun refund_red_packet(
        red_packet: &mut RedPacket,
        uuid: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == distributor::structs::get_red_packet_creator(red_packet), constants::not_creator());
        assert!(distributor::structs::get_red_packet_status(red_packet) == constants::status_active(), constants::red_packet_not_active());
        distributor::structs::set_red_packet_status(red_packet, constants::status_refunded());
        let remaining = distributor::structs::get_red_packet_remaining_amount(red_packet);
        let balance = distributor::structs::get_red_packet_balance_mut(red_packet);
        let coin = coin::from_balance(balance::split(balance, remaining), ctx);
        transfer::public_transfer(coin, distributor::structs::get_red_packet_creator(red_packet));
        events::emit_red_packet_refunded(
            string::utf8(uuid),
            distributor::structs::get_red_packet_creator(red_packet),
            remaining
        );
    }

    /// Update signer address (only owner)
    public entry fun update_signer(
        state: &mut State,
        new_signer: address,
        ctx: &TxContext
    ) {
        assert!(tx_context::sender(ctx) == distributor::structs::get_state_owner(state), constants::not_creator());
        distributor::structs::set_state_signer(state, new_signer);
    }
}


