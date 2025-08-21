// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/// @custom:oz-upgrades-from Distributor
contract Distributor is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // State variables
    enum RewardStatus {
        Active,
        Refunded
    }

    struct Reward {
        address creator;
        IERC20 token;
        uint256 totalAmount;
        uint256 remainingAmount;
        RewardStatus status;
        mapping(string => uint256) amounts;
        mapping(string => bool) claimed;
        string creatorId;
        string sourceType;
    }

    struct ClaimRewardBatch {
        string uuid;
        string githubId;
        bytes signature;
    }

    struct CreateRewardBatch {
        string uuid;
        address token;
        string[] githubIds;
        uint256[] amounts;
        string creatorId;
        string sourceType;
    }

    // Events
    event RewardRefunded(
        string indexed uuid,
        address indexed creator,
        address indexed token,
        uint256 amount
    );

    event RewardCreated(
        string indexed uuid,
        address indexed creator,
        address indexed token,
        uint256 totalAmount,
        string[] githubIds,
        uint256[] amounts,
        string creatorId,
        string sourceType
    );

    event RewardClaimed(
        string indexed uuid,
        address indexed claimer,
        address indexed token,
        string githubId,
        uint256 amount,
        string sourceType
    );

    address public signer;

    mapping(string => Reward) public rewards;

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

    // Batch create rewards
    function batchCreateReward(CreateRewardBatch[] calldata batch) public {
        for (uint i = 0; i < batch.length; i++) {
            createReward(
                batch[i].uuid,
                batch[i].token,
                batch[i].githubIds,
                batch[i].amounts,
                batch[i].creatorId,
                batch[i].sourceType
            );
        }
    }

    // Create a reward
    function createReward(
        string calldata uuid,
        address tokenAddress,
        string[] calldata githubIds,
        uint256[] calldata amounts,
        string calldata creatorId,
        string calldata sourceType
    ) public {
        require(githubIds.length == amounts.length, "Invalid input lengths");
        require(rewards[uuid].creator == address(0), "Reward already exists");
        require(tokenAddress != address(0), "Invalid token address");

        uint256 total = 0;
        for (uint i = 0; i < amounts.length; i++) {
            total += amounts[i];
        }

        IERC20 token = IERC20(tokenAddress);
        // transfer token to contract
        token.safeTransferFrom(msg.sender, address(this), total);

        Reward storage reward = rewards[uuid];
        reward.creator = msg.sender;
        reward.token = token;
        reward.totalAmount = total;
        reward.remainingAmount = total;
        reward.status = RewardStatus.Active;
        reward.creatorId = creatorId;
        reward.sourceType = sourceType;

        for (uint i = 0; i < githubIds.length; i++) {
            reward.amounts[githubIds[i]] = amounts[i];
        }

        emit RewardCreated(
            uuid,
            msg.sender,
            tokenAddress,
            total,
            githubIds,
            amounts,
            creatorId,
            sourceType
        );
    }

    // Batch claim rewards
    function batchClaimReward(ClaimRewardBatch[] calldata batch) public {
        for (uint i = 0; i < batch.length; i++) {
            claimReward(batch[i].uuid, batch[i].githubId, batch[i].signature);
        }
    }

    // Claim a reward
    function claimReward(
        string calldata uuid,
        string calldata githubId,
        bytes calldata signature
    ) public {
        Reward storage reward = rewards[uuid];
        require(reward.creator != address(0), "Reward does not exist");
        require(reward.status == RewardStatus.Active, "Reward not active");
        require(!reward.claimed[githubId], "Already claimed");
        require(reward.amounts[githubId] > 0, "No amount for this github ID");

        // Verify signature
        bytes32 messageHash = keccak256(abi.encodePacked(uuid, githubId));

        require(
            messageHash.toEthSignedMessageHash().recover(signature) == signer,
            "Invalid signature"
        );

        // Mark as claimed and transfer tokens to msg.sender
        reward.claimed[githubId] = true;
        reward.remainingAmount -= reward.amounts[githubId];
        reward.token.safeTransfer(msg.sender, reward.amounts[githubId]);

        emit RewardClaimed(
            uuid,
            msg.sender,
            address(reward.token),
            githubId,
            reward.amounts[githubId],
            reward.sourceType
        );
    }

    // Signature recovery function
    function recoverSigner(
        bytes32 ethSignedMessageHash,
        bytes memory signature
    ) internal pure returns (address) {
        return ECDSA.recover(ethSignedMessageHash, signature);
    }

    // Internal function to refund a reward
    function _refundReward(string calldata uuid) internal {
        Reward storage reward = rewards[uuid];
        require(reward.creator != address(0), "Reward does not exist");
        require(reward.status == RewardStatus.Active, "Already refunded");

        reward.status = RewardStatus.Refunded;
        reward.token.safeTransfer(reward.creator, reward.remainingAmount);
        emit RewardRefunded(
            uuid,
            reward.creator,
            address(reward.token),
            reward.remainingAmount
        );
    }

    // Allow owner to refund all unclaimed amounts of all rewards
    function refundAllRewards(string[] calldata uuids) external onlyOwner {
        for (uint i = 0; i < uuids.length; i++) {
            _refundReward(uuids[i]);
        }
    }

    // Allow creator to refund unclaimed amounts
    function refundReward(string calldata uuid) external {
        Reward storage reward = rewards[uuid];
        require(msg.sender == reward.creator, "Only creator can refund");
        _refundReward(uuid);
    }
}
