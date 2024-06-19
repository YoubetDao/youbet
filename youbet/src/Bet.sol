// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// support different settle ways
// support different task count
// TODO: support cycle goal

contract Bet {
    struct Goal {
        uint id;
        string name;
        string description;
        uint requiredStake;
        address creator;
        bool completed;
        address[] participants;
        uint taskCount;
        mapping(address => bool) isParticipant;
        mapping(address => bool) isConfirmed;
    }

    struct GoalInfo {
        uint id;
        string name;
        string description;
        uint requiredStake;
        address creator;
        bool completed;
        address[] participants;
    }

    Goal[] private goals;
    mapping(address => uint[]) private userGoals;
    address public contractOwner;

    event GoalCreated(
        uint id,
        string name,
        string description,
        uint requiredStake,
        uint taskCount,
        address creator
    );
    event GoalUnlocked(uint id, address user, uint stakeAmount);
    event GoalConfirmed(uint id, address user);
    event StakeClaimed(uint id, address user, uint stakeAmount);

    constructor() {
        contractOwner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Not the contract owner");
        _;
    }

    function createGoal(
        string memory _name,
        string memory _description,
        uint _requiredStake
    ) public {
        uint defaultTaskCount = 1;
        createGoal(_name, _description, _requiredStake, defaultTaskCount);
    }

    function createGoal(
        string memory _name,
        string memory _description,
        uint _requiredStake,
        uint _taskCount
    ) public {
        uint goalId = goals.length;
        Goal storage newGoal = goals.push();
        newGoal.id = goalId;
        newGoal.name = _name;
        newGoal.description = _description;
        newGoal.requiredStake = _requiredStake;
        newGoal.creator = msg.sender;
        newGoal.taskCount = _taskCount;
        newGoal.completed = false;

        emit GoalCreated(
            goalId,
            _name,
            _description,
            _requiredStake,
            _taskCount,
            msg.sender
        );
    }

    // show stake amount in wei for debugging
    event DebugLog(uint msgValue, uint requiredStake);
    function stakeAndUnlockGoal(uint _goalId) public payable {
        require(_goalId < goals.length, "Goal does not exist.");
        Goal storage goal = goals[_goalId];
        emit DebugLog(msg.value, goal.requiredStake);

        require(msg.value == goal.requiredStake, "Incorrect stake amount.");
        require(
            !goal.isParticipant[msg.sender],
            "Already participated in this goal."
        );

        goal.participants.push(msg.sender);
        goal.isParticipant[msg.sender] = true;
        userGoals[msg.sender].push(_goalId);

        emit GoalUnlocked(_goalId, msg.sender, msg.value);
    }

    function confirmCompletion(uint _goalId, address _user) public {
        require(_goalId < goals.length, "Goal does not exist.");
        Goal storage goal = goals[_goalId];
        require(
            msg.sender == goal.creator,
            "Only goal creator can confirm completion."
        );
        require(
            goal.isParticipant[_user],
            "User is not a participant of this goal."
        );
        require(!goal.isConfirmed[_user], "User already confirmed.");

        goal.isConfirmed[_user] = true;

        emit GoalConfirmed(_goalId, _user);
    }

    function claimStake(uint _goalId) public {
        require(_goalId < goals.length, "Goal does not exist.");
        Goal storage goal = goals[_goalId];
        require(
            goal.isParticipant[msg.sender],
            "Not a participant of this goal."
        );
        require(goal.isConfirmed[msg.sender], "Goal not finished yet.");

        uint stakeAmount = goal.requiredStake;
        goal.isParticipant[msg.sender] = false;
        goal.isConfirmed[msg.sender] = false;

        payable(msg.sender).transfer(stakeAmount);

        emit StakeClaimed(_goalId, msg.sender, stakeAmount);
    }

    function getAllGoals() public view returns (GoalInfo[] memory) {
        GoalInfo[] memory goalInfos = new GoalInfo[](goals.length);
        for (uint i = 0; i < goals.length; i++) {
            Goal storage goal = goals[i];
            goalInfos[i] = GoalInfo(
                goal.id,
                goal.name,
                goal.description,
                goal.requiredStake,
                goal.creator,
                goal.completed,
                goal.participants
            );
        }
        return goalInfos;
    }

    function getUserGoals(address _user) public view returns (uint[] memory) {
        return userGoals[_user];
    }

    function getGoalDetails(
        uint _goalId
    ) public view returns (GoalInfo memory) {
        require(_goalId < goals.length, "Goal does not exist.");
        Goal storage goal = goals[_goalId];
        return
            GoalInfo(
                goal.id,
                goal.name,
                goal.description,
                goal.requiredStake,
                goal.creator,
                goal.completed,
                goal.participants
            );
    }
}
