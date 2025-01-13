// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Test} from "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/console.sol";
import {Bet} from "../src/Bet.sol";

contract BetTest is Test {
    Bet private bet;

    address private owner = address(0x123);
    address private user = address(0x456);
    address private otherUser = address(0x789);

    function setUp() public {
        Bet _bet = new Bet();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(_bet),
            abi.encodeWithSignature("initialize(address)", owner)
        );

        bet = Bet(address(proxy));
    }

    function testInitialize() public view {
        // check owner
        assertEq(bet.owner(), owner);
    }

    function testConfirmTaskCompletion() public {
        vm.startPrank(owner);

        bet.linkWallet(user, "githubUser");

        bet.createTask("task1", "Task 1", "proj1");
        bet.confirmTask("task1", "githubUser", 100);

        vm.stopPrank();

        uint[] memory completedTasks = bet.getUserCompletedTasks(user);
        assertEq(completedTasks.length, 1);
    }

    function testGetAllTasks() public {
        vm.prank(owner);
        bet.createTask("task1", "Task 1", "proj1");
        bet.createTask("task2", "Task 2", "proj1");

        Bet.Task[] memory tasks = bet.getAllTasks();
        assertEq(tasks[0].name, "Task 1");
        assertEq(tasks[1].name, "Task 2");
    }

    function testGetUnconfirmedTasks() public {
        vm.startPrank(owner);
        bet.createTask("task1", "Task 1", "proj1");
        bet.createTask("task2", "Task 2", "proj1");
        bet.linkWallet(user, "githubUser");
        bet.confirmTask("task1", "githubUser", 10);
        vm.stopPrank();

        vm.prank(user);
        Bet.Task[] memory unconfirmedTasks = bet.getUnconfirmedTasks();
        assertEq(unconfirmedTasks[0].id, "task2");
    }

    function testCreateProject() public {
        vm.prank(owner);
        bet.createProject("proj1", "Project 1");

        string[] memory projectIds = bet.getAllProjectIds();

        assertEq(projectIds[0], "proj1");
    }

    function testCreateTask() public {
        vm.prank(owner);
        bet.createProject("proj1", "Project 1");
        bet.createTask("task1", "Task 1", "proj1");

        Bet.Task[] memory tasks = bet.getAllTasks();
        assertEq(tasks[0].name, "Task 1");
    }

    function testLinkWallet() public {
        vm.prank(owner);
        bet.linkWallet(user, "githubUser");

        string memory github = bet.getGithubByWallet(user);
        assertEq(github, "githubUser");
    }

    function testConfirmTask() public {
        vm.startPrank(owner);
        bet.createProject("proj1", "Project 1");
        bet.createTask("task1", "Task 1", "proj1");
        bet.linkWallet(user, "githubUser");
        bet.confirmTask("task1", "githubUser", 10);
        vm.stopPrank();

        uint points = bet.getUserPoints(user);
        assertEq(points, 10);
    }

    function testDonateToProject() public {
        vm.startPrank(owner);
        bet.createProject("proj1", "Project 1");
        bet.createTask("task1", "Task 1", "proj1");
        bet.linkWallet(user, "githubUser");
        bet.confirmTask("task1", "githubUser", 10);
        vm.stopPrank();

        vm.deal(otherUser, 5 ether);
        vm.prank(otherUser);

        bet.donateToProject{value: 5 ether}("proj1");
        uint totalRewards = bet.getTotalRewards(user);
        assertEq(totalRewards, 5 ether);
    }

    function testClaimReward() public {
        vm.startPrank(owner);
        bet.createProject("proj1", "Project 1");
        bet.createTask("task1", "Task 1", "proj1");
        bet.linkWallet(user, "githubUser");
        bet.confirmTask("task1", "githubUser", 10);
        vm.stopPrank();

        vm.deal(otherUser, 5 ether);
        vm.prank(otherUser);
        bet.donateToProject{value: 5 ether}("proj1");
        vm.prank(user);

        bet.claimReward();

        assertEq(user.balance, 5 ether);
    }

    function testGetTotalRewards() public {
        vm.startPrank(owner);
        bet.createProject("proj1", "Project 1");
        bet.createTask("task1", "Task 1", "proj1");
        bet.linkWallet(user, "githubUser");
        bet.confirmTask("task1", "githubUser", 10);
        vm.stopPrank();

        vm.deal(otherUser, 5 ether);
        vm.prank(otherUser);
        bet.donateToProject{value: 5 ether}("proj1");

        uint totalRewards = bet.getTotalRewards(user);
        assertEq(totalRewards, 5 ether);
    }

    function testGetClaimedRewards() public {
        vm.startPrank(owner);
        bet.createProject("proj1", "Project 1");
        bet.createTask("task1", "Task 1", "proj1");
        bet.linkWallet(user, "githubUser");
        bet.confirmTask("task1", "githubUser", 10);
        vm.stopPrank();

        vm.deal(otherUser, 5 ether);
        vm.prank(otherUser);
        bet.donateToProject{value: 5 ether}("proj1");

        vm.prank(user);
        bet.claimReward();

        uint[] memory completedTasks2 = bet.getUserCompletedTasks(user);
        assertEq(
            completedTasks2.length,
            1,
            "User2 should have 1 completed task"
        );
        uint claimedRewards = bet.getClaimedRewards(user);
        assertEq(claimedRewards, 5 ether);
    }

    function testGetUserPoints() public {
        vm.startPrank(owner);
        bet.createProject("proj1", "Project 1");
        bet.createTask("task1", "Task 1", "proj1");
        bet.linkWallet(user, "githubUser");
        bet.confirmTask("task1", "githubUser", 10);
        vm.stopPrank();

        uint points = bet.getUserPoints(user);
        assertEq(points, 10);
    }

    function testGetGithubByWallet() public {
        vm.prank(owner);
        bet.linkWallet(user, "githubUser");

        string memory github = bet.getGithubByWallet(user);
        assertEq(github, "githubUser");
    }

    function testGetWalletByGithub() public {
        vm.prank(owner);
        bet.linkWallet(user, "githubUser");

        address wallet = bet.getWalletByGithub("githubUser");
        assertEq(wallet, user);
    }
}
