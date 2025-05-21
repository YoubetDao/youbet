// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {Distributor} from "../src/Distributor.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DistributorTest is Test {
    Distributor public distributor;
    MockERC20 public token;

    address public owner;
    uint256 signerPrivateKey = 1;
    address public signer;
    address public user1;
    address public user2;

    uint256 public constant INITIAL_BALANCE = 1000 * 10 ** 18;

    function setUp() public {
        owner = makeAddr("owner");
        signer = vm.addr(signerPrivateKey);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        token = new MockERC20("Test Token", "TEST");

        vm.startPrank(owner);
        address proxy = Upgrades.deployUUPSProxy(
            "Distributor.sol:Distributor",
            abi.encodeCall(
                Distributor.initialize,
                (signer, owner, address(token))
            )
        );
        distributor = Distributor(proxy);
        vm.stopPrank();

        token.mint(user1, INITIAL_BALANCE);
    }

    function test_CreateAndClaimAndRefund() public {
        string memory uuid = "test-uuid";
        string[] memory githubIds = new string[](2);
        githubIds[0] = "github-user-1";
        githubIds[1] = "github-user-2";

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 50 * 10 ** 18; // 50 tokens
        amounts[1] = 30 * 10 ** 18; // 30 tokens

        vm.startPrank(user1);
        token.approve(address(distributor), 80 * 10 ** 18);
        distributor.createRedPacket(
            uuid,
            githubIds,
            amounts,
            "test-creator-id",
            "test-source-type"
        );
        vm.stopPrank();

        assertEq(token.balanceOf(address(distributor)), 80 * 10 ** 18);
        assertEq(token.balanceOf(user1), INITIAL_BALANCE - 80 * 10 ** 18);

        bytes32 messageHash = keccak256(abi.encodePacked(uuid, githubIds[0]));
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            uint256(1),
            ethSignedMessageHash
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(user2);
        distributor.claimRedPacket(uuid, githubIds[0], signature);

        assertEq(token.balanceOf(user2), 50 * 10 ** 18);
        assertEq(token.balanceOf(address(distributor)), 30 * 10 ** 18);

        vm.prank(user1);
        distributor.refundRedPacket(uuid);

        assertEq(token.balanceOf(user1), INITIAL_BALANCE - 50 * 10 ** 18);
        assertEq(token.balanceOf(address(distributor)), 0);
    }
}
