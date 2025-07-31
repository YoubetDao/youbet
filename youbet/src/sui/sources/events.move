module distributor::events {
    use std::string::String;
    use sui::event;

    /// Event emitted when a red packet is created
    public struct RedPacketCreated has copy, drop {
        uuid: String,
        creator: address,
        total_amount: u64,
        github_ids: vector<String>,
        amounts: vector<u64>
    }

    /// Event emitted when a red packet is claimed
    public struct RedPacketClaimed has copy, drop {
        uuid: String,
        github_id: String,
        claimer: address,
        amount: u64
    }

    /// Event emitted when a red packet is refunded
    public struct RedPacketRefunded has copy, drop {
        uuid: String,
        creator: address,
        refund_amount: u64
    }

    /// Emit red packet created event
    public fun emit_red_packet_created(
        uuid: String,
        creator: address,
        total_amount: u64,
        github_ids: vector<String>,
        amounts: vector<u64>
    ) {
        event::emit(RedPacketCreated {
            uuid,
            creator,
            total_amount,
            github_ids,
            amounts
        });
    }

    /// Emit red packet claimed event
    public fun emit_red_packet_claimed(
        uuid: String,
        github_id: String,
        claimer: address,
        amount: u64
    ) {
        event::emit(RedPacketClaimed {
            uuid,
            github_id,
            claimer,
            amount
        });
    }

    /// Emit red packet refunded event
    public fun emit_red_packet_refunded(
        uuid: String,
        creator: address,
        refund_amount: u64
    ) {
        event::emit(RedPacketRefunded {
            uuid,
            creator,
            refund_amount
        });
    }
} 