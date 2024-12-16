// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Bet is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    Task[] private tasks;
    mapping(string => uint) private taskIndices;

    mapping(address => string) private walletToGithub;
    mapping(string => address) private githubToWallet;
    mapping(address => uint) private userPoints;
    mapping(address => uint[]) private userCompletedTasks;
    mapping(string => uint) private subToTaskId;

    // reward related
    mapping(string => Project) private projects;
    string[] private projectIds;
    mapping(address => uint) private totalRewards; // Tracks total rewards accumulated by each user
    mapping(address => uint) private claimedRewards; // Tracks rewards already claimed by each user

    struct Task {
        string id; // g_issue#githubid -> issue
        string name;
        bool completed;
        string projectId;
        address taskCompleter;
    }

    struct Project {
        string id; // g_repo#githubid -> repo
        mapping(address => uint) userPoints;
        address[] participants; // List of participants who have earned points
    }

    event TaskCreated(string id, string sub);
    event TaskConfirmed(string id, address user, string taskName);
    event StakeClaimed(uint id, address user, uint stakeAmount);
    event WalletLinked(address wallet, string githubId);
    event ProjectCreated(string projectId, string name);
    event RewardClaimed(address user, uint reward);

    modifier taskExist(string memory _taskId) {
        require(taskIndices[_taskId] != 0, "Task does not exist.");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    event DebugLog(uint msgValue, uint requiredStake);

    // TODO: 分页
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

    function createProject(
        string memory _projectId,
        string memory _name
    ) public onlyOwner {
        require(bytes(_projectId).length > 0, "Project ID cannot be empty.");
        require(
            bytes(projects[_projectId].id).length == 0,
            "Project already exists."
        );

        Project storage newProject = projects[_projectId];
        newProject.id = _projectId;
        projectIds.push(_projectId);

        emit ProjectCreated(_projectId, _name);
    }

    function createTask(
        string memory _id,
        string memory _name,
        string memory projectId
    ) public {
        require(bytes(_id).length > 0, "Task ID cannot be empty.");

        // Check if the project exists, if not, create it
        if (bytes(projects[projectId].id).length == 0) {
            createProject(projectId, projectId);
        }

        // Ensure the task doesn't already exist
        if (taskIndices[_id] != 0) {
            revert("Task already exists.");
        }

        // Add the task to the array and map its ID to the index
        tasks.push(
            Task({
                id: _id,
                name: _name,
                completed: false,
                projectId: projectId,
                taskCompleter: address(0)
            })
        );

        // Store the index (length - 1) + 1 to avoid using index 0 as a valid task index
        taskIndices[_id] = tasks.length;

        emit TaskCreated(_id, _name);
    }

    function linkWallet(address wallet, string memory github) public onlyOwner {
        require(
            keccak256(abi.encodePacked(walletToGithub[wallet])) ==
                keccak256(abi.encodePacked("")),
            "Wallet already linked to a Github account."
        );

        walletToGithub[wallet] = github;
        githubToWallet[github] = wallet;

        emit WalletLinked(wallet, github);
    }

    function confirmTask(
        string memory _taskId,
        string memory github,
        uint taskPoints
    ) public taskExist(_taskId) onlyOwner {
        uint taskIndex = taskIndices[_taskId];

        Task storage task = tasks[taskIndex - 1]; // Adjust index to match array (1-based to 0-based)
        address userAddress = githubToWallet[github];
        require(
            userAddress != address(0),
            "GitHub account not linked to a wallet."
        );
        require(!task.completed, "Task already confirmed.");

        task.completed = true;
        task.taskCompleter = userAddress;
        userCompletedTasks[userAddress].push(taskIndex);

        // Update user points for both global and project-specific records
        userPoints[userAddress] += taskPoints;
        Project storage project = projects[task.projectId];

        // Check if the user is already a participant in the project
        bool isParticipant = false;
        if (project.userPoints[userAddress] > 0) {
            isParticipant = true;
        }
        // Add to participants if not already included
        if (!isParticipant) {
            project.participants.push(userAddress);
        }

        project.userPoints[userAddress] += taskPoints;

        emit TaskConfirmed(_taskId, userAddress, task.name);
    }

    function donateToProject(string memory projectId) public payable {
        Project storage project = projects[projectId];
        require(bytes(project.id).length != 0, "Project does not exist.");

        uint totalProjectPoints = 0;

        // Calculate total points
        for (uint i = 0; i < project.participants.length; i++) {
            address participant = project.participants[i];
            totalProjectPoints += project.userPoints[participant];
        }

        // If no contribution at all, just donate to YouBet Wallet.
        if (totalProjectPoints > 0) {
            // Distribute donation based on userPoints
            for (uint i = 0; i < project.participants.length; i++) {
                address participant = project.participants[i];
                uint userShare = (project.userPoints[participant] * msg.value) /
                    totalProjectPoints;
                totalRewards[participant] += userShare;
            }
        }
    }

    function getAllProjectIds() public view returns (string[] memory) {
        return projectIds;
    }

    function getProjectParticipants(
        string memory projectId
    ) public view returns (address[] memory) {
        return projects[projectId].participants;
    }

    function getProjectUserPoints(
        string memory projectId,
        address user
    ) public view returns (uint) {
        return projects[projectId].userPoints[user];
    }

    function claimReward() public {
        uint reward = totalRewards[msg.sender] - claimedRewards[msg.sender];
        require(reward > 0, "No rewards to claim.");

        claimedRewards[msg.sender] += reward;

        // Transfer the reward to the user
        payable(msg.sender).transfer(reward);

        emit RewardClaimed(msg.sender, reward);
    }

    function getTotalRewards(address user) public view returns (uint) {
        return totalRewards[user];
    }

    function getClaimedRewards(address user) public view returns (uint) {
        return claimedRewards[user];
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

    function getTask(
        string memory _taskId
    ) public view taskExist(_taskId) returns (Task memory) {
        uint taskIndex = taskIndices[_taskId];
        return tasks[taskIndex - 1];
    }

    /**
     * @dev Batch transfer of Ether
     * @param recipients Array of recipient addresses
     * @param amounts Array of amounts to transfer in wei
     */
    function batchTransferETH(
        address payable[] calldata recipients,
        uint256[] calldata amounts
    ) external payable {
        require(
            recipients.length == amounts.length,
            "Arrays must have the same length"
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            recipients[i].transfer(amounts[i]);
        }
    }
}
