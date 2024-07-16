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
}
