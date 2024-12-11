// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Distributor is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    // State variables
    enum RedPacketStatus {
        Active,
        Refunded
    }

    struct RedPacket {
        address creator;
        uint256 totalAmount;
        RedPacketStatus status;
        mapping(string => uint256) amounts;
        mapping(string => bool) claimed;
    }

    mapping(string => RedPacket) public redPackets;
    address public signer;

    // Events
    event RedPacketRefunded(
        string indexed uuid,
        address indexed creator,
        uint256 amount
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _signer, address _owner) public initializer {
        __Ownable_init(_owner);
        __UUPSUpgradeable_init();
        signer = _signer;
    }

    // Required by UUPSUpgradeable
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    // Update signer address in case of private key compromise
    function updateSigner(address newSigner) external onlyOwner {
        require(newSigner != address(0), "Invalid signer address");
        signer = newSigner;
    }

    // Create a red packet
    function createRedPacket(
        string calldata uuid,
        string[] calldata githubIds,
        uint256[] calldata amounts
    ) external payable {
        require(githubIds.length == amounts.length, "Invalid input lengths");
        require(
            redPackets[uuid].creator == address(0),
            "RedPacket already exists"
        );

        uint256 total = 0;
        for (uint i = 0; i < amounts.length; i++) {
            total += amounts[i];
        }
        require(msg.value == total, "Invalid amount sent");

        RedPacket storage packet = redPackets[uuid];
        packet.creator = msg.sender;
        packet.totalAmount = total;
        packet.status = RedPacketStatus.Active; // Set initial status

        for (uint i = 0; i < githubIds.length; i++) {
            packet.amounts[githubIds[i]] = amounts[i];
        }
    }

    // Claim a red packet
    function claimRedPacket(
        string calldata uuid,
        string calldata githubId,
        bytes calldata signature
    ) external {
        RedPacket storage packet = redPackets[uuid];
        require(packet.creator != address(0), "RedPacket does not exist");
        require(
            packet.status == RedPacketStatus.Active,
            "Red packet not active"
        );
        require(!packet.claimed[githubId], "Already claimed");
        require(packet.amounts[githubId] > 0, "No amount for this github ID");

        // Verify signature
        bytes32 messageHash = keccak256(abi.encodePacked(uuid, githubId));
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
        require(
            recoverSigner(ethSignedMessageHash, signature) == signer,
            "Invalid signature"
        );

        // Mark as claimed and transfer to msg.sender
        packet.claimed[githubId] = true;
        (bool success, ) = msg.sender.call{value: packet.amounts[githubId]}("");
        require(success, "Transfer failed");
    }

    // Signature recovery function
    function recoverSigner(
        bytes32 ethSignedMessageHash,
        bytes memory signature
    ) internal pure returns (address) {
        require(signature.length == 65, "Invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    // Allow creator to refund unclaimed amounts
    function refundRedPacket(string calldata uuid) external {
        RedPacket storage packet = redPackets[uuid];
        require(packet.creator != address(0), "RedPacket does not exist");
        require(packet.status == RedPacketStatus.Active, "Already refunded");
        require(msg.sender == packet.creator, "Only creator can refund");

        // Mark as refunded before transfer
        packet.status = RedPacketStatus.Refunded;

        // Transfer total amount back to creator
        (bool success, ) = msg.sender.call{value: packet.totalAmount}("");
        require(success, "Transfer failed");

        emit RedPacketRefunded(uuid, msg.sender, packet.totalAmount);
    }
}
