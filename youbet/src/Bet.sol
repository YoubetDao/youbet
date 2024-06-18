// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Bet {
    struct Project {
        uint id;
        string name;
        string description;
        uint requiredStake;
        address creator;
        bool completed;
        address[] participants;
        mapping(address => bool) isParticipant;
        mapping(address => bool) isConfirmed;
    }

    struct ProjectInfo {
        uint id;
        string name;
        string description;
        uint requiredStake;
        address creator;
        bool completed;
        address[] participants;
    }

    Project[] private projects;
    mapping(address => uint[]) private userProjects;
    address public contractOwner;

    event ProjectCreated(
        uint id,
        string name,
        string description,
        uint requiredStake,
        address creator
    );
    event ProjectUnlocked(uint id, address user, uint stakeAmount);
    event ProjectConfirmed(uint id, address user);
    event StakeClaimed(uint id, address user, uint stakeAmount);

    constructor() {
        contractOwner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Not the contract owner");
        _;
    }

    function createProject(
        string memory _name,
        string memory _description,
        uint _requiredStake
    ) public {
        uint projectId = projects.length;
        Project storage newProject = projects.push();
        newProject.id = projectId;
        newProject.name = _name;
        newProject.description = _description;
        newProject.requiredStake = _requiredStake;
        newProject.creator = msg.sender;
        newProject.completed = false;

        emit ProjectCreated(
            projectId,
            _name,
            _description,
            _requiredStake,
            msg.sender
        );
    }

    // show stake amount in wei for debugging
    event DebugLog(uint msgValue, uint requiredStake);
    function stakeAndUnlockProject(uint _projectId) public payable {
        require(_projectId < projects.length, "Project does not exist.");
        Project storage project = projects[_projectId];
        emit DebugLog(msg.value, project.requiredStake);

        require(msg.value == project.requiredStake, "Incorrect stake amount.");
        require(
            !project.isParticipant[msg.sender],
            "Already participated in this project."
        );

        project.participants.push(msg.sender);
        project.isParticipant[msg.sender] = true;
        userProjects[msg.sender].push(_projectId);

        emit ProjectUnlocked(_projectId, msg.sender, msg.value);
    }

    function confirmCompletion(uint _projectId, address _user) public {
        require(_projectId < projects.length, "Project does not exist.");
        Project storage project = projects[_projectId];
        require(
            msg.sender == project.creator,
            "Only project creator can confirm completion."
        );
        require(
            project.isParticipant[_user],
            "User is not a participant of this project."
        );
        require(!project.isConfirmed[_user], "User already confirmed.");

        project.isConfirmed[_user] = true;

        emit ProjectConfirmed(_projectId, _user);
    }

    function claimStake(uint _projectId) public {
        require(_projectId < projects.length, "Project does not exist.");
        Project storage project = projects[_projectId];
        require(
            project.isParticipant[msg.sender],
            "Not a participant of this project."
        );
        require(project.isConfirmed[msg.sender], "Project not finished yet.");

        uint stakeAmount = project.requiredStake;
        project.isParticipant[msg.sender] = false;
        project.isConfirmed[msg.sender] = false;

        payable(msg.sender).transfer(stakeAmount);

        emit StakeClaimed(_projectId, msg.sender, stakeAmount);
    }

    function getAllProjects() public view returns (ProjectInfo[] memory) {
        ProjectInfo[] memory projectInfos = new ProjectInfo[](projects.length);
        for (uint i = 0; i < projects.length; i++) {
            Project storage project = projects[i];
            projectInfos[i] = ProjectInfo(
                project.id,
                project.name,
                project.description,
                project.requiredStake,
                project.creator,
                project.completed,
                project.participants
            );
        }
        return projectInfos;
    }

    function getUserProjects(
        address _user
    ) public view returns (uint[] memory) {
        return userProjects[_user];
    }

    function getProjectDetails(
        uint _projectId
    ) public view returns (ProjectInfo memory) {
        require(_projectId < projects.length, "Project does not exist.");
        Project storage project = projects[_projectId];
        return
            ProjectInfo(
                project.id,
                project.name,
                project.description,
                project.requiredStake,
                project.creator,
                project.completed,
                project.participants
            );
    }
}
