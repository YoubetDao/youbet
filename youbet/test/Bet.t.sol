// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Bet} from "../src/Bet.sol";
import "../src/GoalType.sol";
import "../src/Goal.sol";

contract BetTest is Test {
    Bet public bet;

    function setUp() public {
        bet = new Bet();
    }

    function testCreateGoal() public {
        bet.createGoal("Test Goal", "This is a test goal", 1 ether, 5);
        GoalInfo[] memory goals = bet.getAllGoals();

        assertEq(goals.length, 1, "Goal count should be 1");

        GoalInfo memory goal = goals[0];
        assertEq(goal.name, "Test Goal", "Goal name should be 'Test Goal'");
        assertEq(
            goal.description,
            "This is a test goal",
            "Goal description should be 'This is a test goal'"
        );
        assertEq(
            goal.requiredStake,
            1 ether,
            "Required stake should be 1 ether"
        );
        assertEq(
            uint(goal.goalType),
            uint(GoalType.Gambling),
            "Goal type should be Gambling"
        );
    }

    function testCreateTask() public {
        bet.createTask("Test Task 1");
        Task[] memory tasks = bet.getAllTasks();

        assertEq(tasks.length, 1, "Task count should be 1");

        Task memory task = tasks[0];
        assertEq(task.sub, "Test Task 1", "Task sub should be 'Test Task 1'");
        assertEq(task.completed, false, "Task should not be completed");
    }

    function testCreateTaskRevert() public {
        bet.createTask("Test Task 1");
        vm.expectRevert("Task already exists.");
        bet.createTask("Test Task 1");
    }

    function testGetUnconfirmedTasks() public {
        bet.createTask("Test Task 1");
        bet.createTask("Test Task 2");

        Task[] memory unconfirmedTasks = bet.getUnconfirmedTasks();

        assertEq(
            unconfirmedTasks.length,
            2,
            "Unconfirmed task count should be 2"
        );
    }

    function testLinkWallet() public {
        bet.linkWallet("TestGithub");
        string memory github = bet.getGithubByWallet(address(this));

        assertEq(github, "TestGithub", "Github account should be 'TestGithub'");
    }

    function testConfirmTask() public {
        bet.linkWallet("TestGithub");
        bet.createTask("Test Task 1");

        bet.confirmTask(0, "TestGithub");
        Task[] memory tasks = bet.getAllTasks();

        assertEq(tasks[0].completed, true, "Task should be completed");
        uint points = bet.getUserPoints(address(this));
        assertEq(points, 10, "User should have 10 points");

        uint[] memory completedTasks = bet.getUserCompletedTasks(address(this));
        assertEq(completedTasks.length, 1, "User should have 1 completed task");
    }

    function testGetUserPoints() public {
        bet.linkWallet("TestGithub");
        bet.createTask("Test Task 1");

        bet.confirmTask(0, "TestGithub");
        uint points = bet.getUserPoints(address(this));

        assertEq(points, 10, "User should have 10 points");
    }

    function testGetUserCompletedTasks() public {
        bet.linkWallet("TestGithub");
        bet.createTask("Test Task 1");
        bet.createTask("Test Task 2");

        bet.confirmTask(0, "TestGithub");
        uint[] memory completedTasks = bet.getUserCompletedTasks(address(this));

        assertEq(completedTasks.length, 1, "User should have 1 completed task");
        assertEq(completedTasks[0], 0, "Completed task ID should be 0");
    }
}
