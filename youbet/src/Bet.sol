// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// support different settle ways
// support different task count
// TODO: support cycle goal

contract Bet {
    enum GoalType {
        Solo,
        Gambling
    }

    struct Goal {
        uint id;
        string name;
        string description;
        uint requiredStake;
        address creator;
        bool completed;
        address[] participants;
        uint taskCount;
        GoalType goalType;
        mapping(address => bool) isParticipant;
        mapping(address => bool) isClaimed;
        mapping(address => uint) completedTaskCount; // 使用 uint 来记录每个用户完成的任务数量
        mapping(address => uint) rewards; // 记录每个用户应得的奖励
    }

    struct GoalInfo {
        uint id;
        string name;
        string description;
        uint requiredStake;
        address creator;
        bool completed;
        address[] participants;
        GoalType goalType;
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
        GoalType goalType,
        address creator
    );
    event GoalUnlocked(uint id, address user, uint stakeAmount);
    event TaskConfirmed(uint id, address user, uint taskIndex); // 修改为任务确认事件
    event StakeClaimed(uint id, address user, uint stakeAmount);
    event GoalSettled(uint id);

    constructor() {
        contractOwner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Not the contract owner");
        _;
    }

    function createGoalSolo(
        string memory _name,
        string memory _description,
        uint _requiredStake,
        uint _taskCount
    ) public {
        _createGoal(
            _name,
            _description,
            _requiredStake,
            _taskCount,
            GoalType.Solo
        );
    }

    function createGoal(
        string memory _name,
        string memory _description,
        uint _requiredStake,
        uint _taskCount
    ) public {
        _createGoal(
            _name,
            _description,
            _requiredStake,
            _taskCount,
            GoalType.Gambling
        );
    }

    function _createGoal(
        string memory _name,
        string memory _description,
        uint _requiredStake,
        uint _taskCount,
        GoalType _goalType
    ) public {
        uint goalId = goals.length;
        Goal storage newGoal = goals.push();
        newGoal.id = goalId;
        newGoal.name = _name;
        newGoal.description = _description;
        newGoal.requiredStake = _requiredStake;
        newGoal.creator = msg.sender;
        newGoal.taskCount = _taskCount;
        newGoal.goalType = _goalType;
        newGoal.completed = false;

        emit GoalCreated(
            goalId,
            _name,
            _description,
            _requiredStake,
            _taskCount,
            _goalType,
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

    function confirmTaskCompletion(uint _goalId, address _user) public {
        require(_goalId < goals.length, "Goal does not exist.");
        Goal storage goal = goals[_goalId];
        require(
            msg.sender == goal.creator,
            "Only goal creator can confirm task completion."
        );
        require(
            goal.isParticipant[_user],
            "User is not a participant of this goal."
        );
        require(
            goal.completedTaskCount[_user] < goal.taskCount,
            "All tasks already confirmed."
        );

        goal.completedTaskCount[_user] += 1;

        emit TaskConfirmed(_goalId, _user, goal.completedTaskCount[_user]);
    }

    function claimStake(uint _goalId) public {
        require(_goalId < goals.length, "Goal does not exist.");
        Goal storage goal = goals[_goalId];
        require(
            goal.isParticipant[msg.sender],
            "Not a participant of this goal."
        );
        require(!goal.isClaimed[msg.sender], "Stake already claimed.");

        uint reward;
        if (goal.goalType == GoalType.Solo) {
            reward =
                (goal.requiredStake * goal.completedTaskCount[msg.sender]) /
                goal.taskCount;
        } else {
            reward = goal.rewards[msg.sender];
        }

        require(reward > 0, "No reward to claim.");

        payable(msg.sender).transfer(reward);
        goal.isClaimed[msg.sender] = true;

        emit StakeClaimed(_goalId, msg.sender, reward);
    }

    function settleGoal(uint _goalId) public {
        // only goal creator or contract owner can settle the goal
        require(
            msg.sender == goals[_goalId].creator || msg.sender == contractOwner,
            "Only goal creator or contract owner can settle the goal."
        );

        require(_goalId < goals.length, "Goal does not exist.");
        Goal storage goal = goals[_goalId];
        require(goal.goalType == GoalType.Gambling, "Not a gambling goal");

        uint totalStake = 0;
        uint totalCompletedTasks = 0;
        uint totalParticipants = goal.participants.length;
        // TODO: the minimum fee can cover our cost.
        uint fee = (totalParticipants * goal.requiredStake) / 100;

        for (uint i = 0; i < totalParticipants; i++) {
            address participant = goal.participants[i];
            totalStake += goal.requiredStake;
            totalCompletedTasks += goal.completedTaskCount[participant];
        }

        require(
            totalStake > fee,
            "No stakes to distribute after fee deduction"
        );
        totalStake -= fee;

        for (uint i = 0; i < totalParticipants; i++) {
            address participant = goal.participants[i];
            uint userCompletedTasks = goal.completedTaskCount[participant];
            if (userCompletedTasks > 0) {
                uint reward = (totalStake * userCompletedTasks) /
                    totalCompletedTasks;
                goal.rewards[participant] = reward;
            }
        }

        goal.completed = true;
        emit GoalSettled(_goalId);
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
                goal.participants,
                goal.goalType
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
                goal.participants,
                goal.goalType
            );
    }
}
