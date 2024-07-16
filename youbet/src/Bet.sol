// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./Goal.sol";
import "./GoalType.sol";

contract Bet {
    Goal[] private goals;
    Task[] private tasks;
    mapping(address => uint[]) private userGoals;
    mapping(address => string) private walletToGithub;
    mapping(string => address) private githubToWallet;
    mapping(address => uint) private userPoints;
    mapping(address => uint[]) private userCompletedTasks;
    mapping(string => uint) private subToTaskId;
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
    event TaskCreated(uint id, string sub);
    event GoalUnlocked(uint id, address user, uint stakeAmount);
    event TaskConfirmed(uint id, address user, uint taskIndex);
    event StakeClaimed(uint id, address user, uint stakeAmount);
    event GoalSettled(uint id);
    event WalletLinked(address wallet, string githubId);

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
        // TODO: make sure the minimum fee can cover our cost.
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
            uint userCompletedTaskCount = goal.completedTaskCount[participant];
            if (userCompletedTaskCount > 0) {
                uint reward = (totalStake * userCompletedTaskCount) /
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

    function getAllTasks() public view returns (Task[] memory) {
        return tasks;
    }

    function getUnconfirmedTasks() public view returns (Task[] memory) {
        uint count = 0;
        for (uint i = 0; i < tasks.length; i++) {
            if (!tasks[i].completed) {
                count++;
            }
        }

        Task[] memory unconfirmedTasks = new Task[](count);
        uint index = 0;
        for (uint i = 0; i < tasks.length; i++) {
            if (!tasks[i].completed) {
                unconfirmedTasks[index] = tasks[i];
                index++;
            }
        }

        return unconfirmedTasks;
    }

    function createTask(string memory _sub) public {
        if (subToTaskId[_sub] != 0) {
            revert("Task already exists.");
        }

        uint taskId = tasks.length;
        Task storage newTask = tasks.push();
        newTask.id = taskId;
        newTask.sub = _sub;
        newTask.completed = false;
        subToTaskId[_sub] = taskId + 1;
        emit TaskCreated(taskId, _sub);
    }

    function linkWallet(string memory github) public {
        require(
            keccak256(abi.encodePacked(walletToGithub[msg.sender])) ==
                keccak256(abi.encodePacked("")),
            "Wallet already linked to a Github account."
        );

        walletToGithub[msg.sender] = github;
        githubToWallet[github] = msg.sender;

        emit WalletLinked(msg.sender, github);
    }

    function confirmTask(uint _taskId, string memory github) public {
        require(_taskId < tasks.length, "Task does not exist.");
        Task storage task = tasks[_taskId];
        require(
            keccak256(abi.encodePacked(walletToGithub[msg.sender])) ==
                keccak256(abi.encodePacked(github)),
            "Github account not linked to wallet."
        );
        require(!task.completed, "Task already confirmed.");

        task.completed = true;
        userCompletedTasks[msg.sender].push(_taskId);

        // TODO: should decide points based on task difficulty
        userPoints[msg.sender] += 10;
    }

    function getUserPoints(address _user) public view returns (uint) {
        return userPoints[_user];
    }

    function getUserCompletedTasks(
        address _user
    ) public view returns (uint[] memory) {
        return userCompletedTasks[_user];
    }

    function getGithubByWallet(
        address _wallet
    ) public view returns (string memory) {
        return walletToGithub[_wallet];
    }

    function getWalletByGithub(
        string memory github
    ) public view returns (address) {
        return githubToWallet[github];
    }
}
