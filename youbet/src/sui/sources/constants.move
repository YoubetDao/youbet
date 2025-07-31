module distributor::constants {
    // Error codes
    #[allow(unused_const)]
    const EInvalidLength: u64 = 0;
    #[allow(unused_const)]
    const ERedPacketExists: u64 = 1;
    #[allow(unused_const)]
    const ERedPacketNotFound: u64 = 2;
    #[allow(unused_const)]
    const ERedPacketNotActive: u64 = 3;
    #[allow(unused_const)]
    const ENotCreator: u64 = 4;
    #[allow(unused_const)]
    const EAlreadyClaimed: u64 = 5;
    #[allow(unused_const)]
    const EInvalidSignature: u64 = 6;
    #[allow(unused_const)]
    const EInvalidSigner: u64 = 7;

    // Status of the red packet
    #[allow(unused_const)]
    const STATUS_ACTIVE: u8 = 0;
    #[allow(unused_const)]
    const STATUS_REFUNDED: u8 = 1;

    // Public functions to access constants
    public fun invalid_length(): u64 { EInvalidLength }
    public fun red_packet_exists(): u64 { ERedPacketExists }
    public fun red_packet_not_found(): u64 { ERedPacketNotFound }
    public fun red_packet_not_active(): u64 { ERedPacketNotActive }
    public fun not_creator(): u64 { ENotCreator }
    public fun already_claimed(): u64 { EAlreadyClaimed }
    public fun invalid_signature(): u64 { EInvalidSignature }
    public fun invalid_signer(): u64 { EInvalidSigner }
    public fun status_active(): u8 { STATUS_ACTIVE }
    public fun status_refunded(): u8 { STATUS_REFUNDED }
} 