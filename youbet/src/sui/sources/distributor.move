/*
/// Module: distributor
module distributor::distributor;
*/

// For Move coding conventions, see
// https://docs.sui.io/concepts/sui-move-concepts/conventions

module distributor::distributor {
    // use sui::transfer;
    // use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::balance;
    use sui::sui::SUI;
    use sui::ecdsa_k1;
    use sui::hash;
    use sui::table::{Self};
    use std::string;
    use distributor::structs::{State, RedPacket};
    use distributor::events;
    use distributor::constants;

    #[allow(unused_const)]
    const ESignatureVerificationFailed: u64 = 1;

    /// One-time witness for the module
    public struct DISTRIBUTOR has drop {}

    /// Initialize the module
    fun init(_witness: DISTRIBUTOR, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        let signer_public_key = vector[26, 59, 248, 15, 36, 21, 95, 58, 153, 40, 50, 86, 237, 94, 201, 180, 252, 24, 137, 9, 211, 128, 218, 82, 124, 121, 186, 41, 149, 25, 172, 185, 21];
        let state = distributor::structs::new_state(signer_public_key, sender, ctx);
        distributor::structs::share_state(state);
    }

    /// Create a new red packet
    public entry fun create_red_packet(
        state: &mut State,
        uuid: string::String,
        github_ids: vector<string::String>,
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
            let github_id = *vector::borrow(&github_ids, i);
            let amount = *vector::borrow(&amounts, i);
            let claim_info = distributor::structs::new_claim_info(false, amount);
            table::add(&mut claims, github_id, claim_info);
            i = i + 1;
        };

        let mut payment_mut = payment;
        let red_packet_coin = coin::split(&mut payment_mut, total_amount, ctx);
        let red_packet = distributor::structs::new_red_packet(
            tx_context::sender(ctx),
            total_amount,
            total_amount,
            constants::status_active(),
            claims,
            coin::into_balance(red_packet_coin),
            ctx
        );
        transfer::public_transfer(payment_mut, tx_context::sender(ctx));

        let mut github_id_strings = vector::empty();
        i = 0;
        while (i < github_ids_len) {
            vector::push_back(&mut github_id_strings, *vector::borrow(&github_ids, i));
            i = i + 1;
        };
        distributor::structs::add_red_packet_to_state(state, uuid, red_packet);
        events::emit_red_packet_created(
            uuid,
            tx_context::sender(ctx),
            total_amount,
            github_id_strings,
            amounts
        );
    }

    //Claim red packet with signature verification
    public entry fun claim_red_packet(
        state: &mut State,
        uuid: string::String,
        github_id: string::String,
        signature: vector<u8>,
        ctx: &mut TxContext
    ) {
        let state_signer = distributor::structs::get_state_signer(state);

        let red_packet = distributor::structs::get_red_packet_from_state_mut(state, uuid);
        assert!(distributor::structs::get_red_packet_status(red_packet) == constants::status_active(), constants::red_packet_not_active());
        let amount = {
            let claims = distributor::structs::get_red_packet_claims_mut(red_packet);
            let claim_info = table::borrow_mut(claims, github_id);
            assert!(!distributor::structs::get_claim_info_claimed(claim_info), constants::already_claimed());
            distributor::structs::set_claim_info_claimed(claim_info, true);
            let mut message = std::string::utf8(b"");
            string::append(&mut message, uuid);
            string::append(&mut message, github_id);

            let message_hash = hash::keccak256(string::as_bytes(&message));
            let prefix = b"\x19Sui Signed Message:\n32";
            let mut eth_message = std::string::utf8(b"");
            string::append(&mut eth_message, string::utf8(prefix));
            string::append(&mut eth_message, string::utf8(message_hash));
            let eth_signed_message_hash = hash::keccak256(string::as_bytes(&eth_message));


            // https://docs-zh.sui-book.com/guides/developer/cryptography/signing/
            let recovered = ecdsa_k1::secp256k1_ecrecover(&signature, &eth_signed_message_hash, 1);
            assert!(recovered == state_signer, ESignatureVerificationFailed);

            distributor::structs::get_claim_info_amount(claim_info)
        };
        let balance = distributor::structs::get_red_packet_balance_mut(red_packet);
        let coin = coin::from_balance(balance::split(balance, amount), ctx);
        transfer::public_transfer(coin, tx_context::sender(ctx));
        let remaining = distributor::structs::get_red_packet_remaining_amount(red_packet);
        distributor::structs::set_red_packet_remaining_amount(red_packet, remaining - amount);
        events::emit_red_packet_claimed(
            uuid,
            github_id,
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
}


