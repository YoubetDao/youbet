// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Bet} from "../src/Bet.sol";

contract BetTest is Test {
    Bet public bet;

    function setUp() public {
        bet = new Bet();
    }

    function testCreateGoal() public {
        bet.createGoal("Test Goal", "This is a test goal", 1 ether, 5);
    }
}
