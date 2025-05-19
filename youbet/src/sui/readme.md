# YouBet Red Packet System on Sui Network

## Overview / 概述

The YouBet Red Packet System is a Sui blockchain-based digital red packet (hongbao) distribution system that enables creators to distribute SUI tokens or other Sui-based tokens to specific GitHub users in a secure and verifiable manner.

YouBet红包系统是一个基于Sui区块链的数字红包分发系统，允许创建者以安全和可验证的方式向特定GitHub用户分发SUI代币或其他基于Sui的代币。

## Core Features / 核心功能

1. **Red Packet Creation / 红包创建**
   - Create red packets with specified amounts for different GitHub IDs
   - Transfer Sui tokens from creator to smart contract
   - Support both SUI and custom Sui tokens
   - 创建者可以为不同的GitHub ID创建指定金额的红包
   - 将Sui代币从创建者转移到智能合约
   - 支持SUI和自定义Sui代币

2. **Secure Claiming / 安全领取**
   - Sui signature-based verification system
   - One-time claiming mechanism with object capabilities
   - GitHub ID binding with Sui addresses
   - 基于Sui签名的验证系统
   - 基于对象能力的一次性领取机制
   - GitHub ID与Sui地址绑定

3. **Refund Mechanism / 退款机制**
   - Creators can refund unclaimed amounts
   - Status tracking using Sui object model
   - 创建者可以退回未领取的金额
   - 使用Sui对象模型进行状态跟踪

## Technical Architecture / 技术架构

### Move Contract Components / Move合约组件

1. **Object Model / 对象模型**
   ```move
   /// Main RedPacket object storing the core information
   struct RedPacket has key {
       id: UID,
       creator: address,
       total_amount: u64,
       remaining_amount: u64,
       status: u8,  // 0: Active, 1: Refunded
       token_type: TypeName,
   }

   /// Claim object storing individual claim information
   struct Claim has key {
       id: UID,
       red_packet_id: ID,
       github_id: String,
       amount: u64,
       claimed: bool,
   }

   /// Events emitted by the contract
   struct RedPacketCreatedEvent has copy, drop {
       uuid: vector<u8>,
       creator: address,
       total_amount: u64,
       github_ids: vector<String>,
       amounts: vector<u64>,
   }

   struct RedPacketClaimedEvent has copy, drop {
       uuid: vector<u8>,
       github_id: String,
       claimer: address,
       amount: u64,
   }

   struct RedPacketRefundedEvent has copy, drop {
       uuid: vector<u8>,
       creator: address,
       amount: u64,
   }
   ```

2. **Core Functions / 核心函数**
   ```move
   public fun create_red_packet<T: Coin>(
       creator: &signer,
       uuid: vector<u8>,
       github_ids: vector<String>,
       amounts: vector<u64>,
       ctx: &mut TxContext
   ) {
       // Validate inputs
       assert!(vector::length(&github_ids) == vector::length(&amounts), 0);
       assert!(vector::length(&github_ids) > 0, 0);
       
       // Calculate total
       let total = 0;
       let i = 0;
       while (i < vector::length(&amounts)) {
           total = total + *vector::borrow(&amounts, i);
           i = i + 1;
       };

       // Create RedPacket object
       // Transfer tokens
       // Emit event
   }

   public fun claim_red_packet<T: Coin>(
       red_packet: &mut RedPacket,
       github_id: String,
       signature: vector<u8>,
       ctx: &mut TxContext
   ) {
       // Verify active status
       assert!(red_packet.status == 0, 0);
       
       // Verify signature using Sui's native ed25519 verification
       // Transfer tokens
       // Emit event
   }

   public fun refund_red_packet<T: Coin>(
       red_packet: &mut RedPacket,
       ctx: &mut TxContext
   ) {
       // Verify creator
       // Update status
       // Transfer remaining tokens
       // Emit event
   }
   ```

### Sui Features Utilization / Sui特性使用

1. **Object Capabilities / 对象能力**
   - `key` ability for global storage
   - `store` ability for struct fields
   - Custom abilities for token types
   - `key`能力用于全局存储
   - `store`能力用于结构体字段
   - 代币类型的自定义能力

2. **Access Control / 访问控制**
   - Sui signature verification
   - Creator-owned objects
   - Dynamic field-based storage
   - Sui签名验证
   - 创建者拥有的对象
   - 基于动态字段的存储

3. **Safety Features / 安全特性**
   - Move's type safety
   - Resource-oriented programming
   - Object-centric security model
   - Move的类型安全
   - 面向资源的编程
   - 以对象为中心的安全模型

4. **Event System / 事件系统**
   - Custom event structs with `copy` and `drop` abilities
   - Event emission using Sui's native event system
   - Event indexing and querying capabilities
   - 自定义事件结构体具有`copy`和`drop`能力
   - 使用Sui原生事件系统发送事件
   - 事件索引和查询功能

5. **Signature Verification / 签名验证**
   ```move
   /// Verify signature using Sui's ed25519 verification
   fun verify_signature(
       message: vector<u8>,
       signature: vector<u8>,
       public_key: vector<u8>,
   ): bool {
       ed25519::verify(&signature, &public_key, &message)
   }
   ```

## Implementation Details / 实现细节

### Token Handling / 代币处理
```move
/// Generic coin transfer function
fun transfer_coins<T: Coin>(
    from: &signer,
    to: address,
    amount: u64,
    ctx: &mut TxContext
) {
    let coin = coin::withdraw<T>(from, amount);
    transfer::transfer(coin, to);
}

/// Split coins for multiple recipients
fun split_coins<T: Coin>(
    coin: Coin<T>,
    amounts: vector<u64>,
    ctx: &mut TxContext
): vector<Coin<T>> {
    let result = vector::empty();
    let i = 0;
    while (i < vector::length(&amounts)) {
        let amount = *vector::borrow(&amounts, i);
        let split = coin::split(&mut coin, amount, ctx);
        vector::push_back(&mut result, split);
        i = i + 1;
    };
    result
}
```

### Error Handling / 错误处理
```move
const ERR_INVALID_SIGNATURE: u64 = 1;
const ERR_ALREADY_CLAIMED: u64 = 2;
const ERR_INVALID_STATUS: u64 = 3;
const ERR_UNAUTHORIZED: u64 = 4;
const ERR_INVALID_AMOUNT: u64 = 5;
```

## Testing / 测试

1. **Unit Tests / 单元测试**
   ```move
   #[test]
   fun test_create_red_packet() {
       // Setup test coins and accounts
       let admin = create_test_account();
       let coins = create_test_coins(1000);
       
       // Create red packet
       let github_ids = vector["user1", "user2"];
       let amounts = vector[500, 500];
       create_red_packet(admin, b"test_uuid", github_ids, amounts, test_context());
       
       // Verify creation
       let packet = get_red_packet(b"test_uuid");
       assert!(packet.total_amount == 1000, 0);
       assert!(packet.status == 0, 0);
   }

   #[test]
   fun test_claim_red_packet() {
       // Setup test environment
       let (admin, packet) = setup_test_red_packet();
       let user = create_test_account();
       
       // Generate valid signature
       let signature = generate_test_signature(b"test_uuid", "user1");
       
       // Claim red packet
       claim_red_packet(packet, "user1", signature, test_context());
       
       // Verify claim
       assert!(is_claimed(packet, "user1"), 0);
   }

   #[test]
   fun test_refund_red_packet() {
       // Test implementation
   }
   ```

2. **Integration Tests / 集成测试**
   ```move
   #[test_only]
   module youbet::integration_tests {
       use youbet::red_packet;
       use sui::test_scenario;

       #[test]
       fun test_full_flow() {
           let scenario = test_scenario::begin();
           // Test complete flow from creation to claim/refund
           // ...
           test_scenario::end(scenario);
       }
   }
   ```

## Integration Guide / 集成指南

### Prerequisites / 前置条件
1. Sui Network connection
2. Sui wallet for transaction signing
3. Move package publishing permissions
4. Sui网络连接
5. 用于交易签名的Sui钱包
6. Move包发布权限

### Contract Deployment / 合约部署
```bash
sui move publish --gas-budget 10000000
```

### Event Monitoring / 事件监控
- Sui events system
- Object change monitoring
- Transaction effects tracking
- Sui事件系统
- 对象变更监控
- 交易效果跟踪

## Security Considerations / 安全考虑

1. **Move Type Safety / Move类型安全**
   - Resource-oriented design
   - Linear type system
   - 面向资源的设计
   - 线性类型系统

2. **Object Security / 对象安全**
   - Object capability model
   - Dynamic field protection
   - 对象能力模型
   - 动态字段保护

3. **State Management / 状态管理**
   - Atomic operations
   - Consistent object states
   - 原子操作
   - 一致的对象状态

## Best Practices / 最佳实践

1. **For Creators / 对于创建者**
   - Use appropriate gas budget
   - Verify token type parameters
   - 使用适当的gas预算
   - 验证代币类型参数

2. **For Claimers / 对于领取者**
   - Check object existence
   - Verify transaction effects
   - 检查对象存在性
   - 验证交易效果

3. **For Integrators / 对于集成者**
   - Monitor object changes
   - Handle type parameters correctly
   - 监控对象变更
   - 正确处理类型参数
