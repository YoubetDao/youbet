// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

abstract contract IDistributor is PausableUpgradeable {
    // change 1. RedPacket -> Ticket
    enum TicketStatus {
        Active,
        Refunded
    }

    struct Ticket {
        address creator;
        ERC20 rewardToken;
        uint256 totalAmount;
        uint256 remainingAmount;
        TicketStatus status;
        // change 2. remove amounts, claim change value to uint256
        // mapping(string => uint256) amounts;
        mapping(string => uint256) claimed;
    }

    mapping(string => Ticket) public tickets;
    address public signer;

    event TicketRefunded(string uuid, address indexed creator, uint256 amount);

    event TicketCreated(
        string uuid,
        address indexed creator,
        uint256 totalAmount,
        // change 3. remove githubIds, no use, for record only?
        // string[] githubIds,
        uint256[] amounts
    );

    event TicketClaimed(
        string uuid,
        string githubId,
        address indexed claimer,
        uint256 amount
    );

    function initialize(
        address _signer,
        address _owner,
        address _token
    ) external virtual;

    function createTicket(
        string memory uuid,
        string[] memory githubIds,
        uint256[] memory amounts
    ) external virtual;

    function claimTicket(
        string memory uuid,
        string memory githubId
    ) external virtual;

    function refundTicket(string memory uuid) external virtual;

    function _verifySignature(
        string memory uuid,
        string memory githubId,
        uint256 amount,
        bytes memory signature
    ) internal view virtual returns (bool);
}
