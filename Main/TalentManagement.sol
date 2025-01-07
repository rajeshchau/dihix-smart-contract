// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract ProjectManagement {
    struct Project {
        uint256 id;
        address owner; 
        string details; 
        uint256 applications; 
        bool isActive; 
    }

    struct Application {
        address applicant;
        uint256 amount;
    }

    struct Interviewer {
        address interviewerAddress;
        uint256 fee;
    }

    address public owner;
    uint256 public projectCounter; 
    uint256 public applicationCounter; 
    mapping(uint256 => Project) public projects; 
    mapping(uint256 => Application[]) public projectApplications;
    mapping(address => bool) public registeredInterviewers; 
    mapping(uint256 => Interviewer) public interviewers; 

    event ProjectCreated(uint256 projectId, address owner, string details);
    event ProjectApplied(uint256 projectId, address applicant, uint256 amount);
    event InterviewerRegistered(address interviewer, uint256 fee);
    event TalentPosted(uint256 projectId, address business);
    event ProjectsRetrieved(uint256[] activeProjects);
    event ProjectClosed(uint projextid,address senderaddress);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
        projectCounter = 0;
    }

    //here there is an issue that what id should be given by frontend or we can provide it with a variable and increment operation.
    
    function createProject(string calldata details) external {
        projects[projectCounter] = Project({
            id: projectCounter,
            owner: msg.sender,
            details: details,
            applications: 0,
            isActive: true
        });

        emit ProjectCreated(projectCounter, msg.sender, details);
        projectCounter++;
    }
    
    //here the function is using the struct to know that the owner is the msg.sender and this function is used to close the application
    // also should we charge the money for closing the post in smart contract.

    function closeApplication(uint256 _projectId) external {
        require(projects[_projectId].owner == msg.sender, "Not the project owner");
        require(projects[_projectId].isActive, "Project already closed");

        projects[_projectId].isActive = false;

        emit ProjectClosed(_projectId, msg.sender);
    }

    //here we are applying a application for the freelancer.

    function applyForProject(uint256 projectId, uint256 amount) external {
        require(projects[projectId].isActive, "Project is not active");

        projectApplications[projectId].push(
            Application({applicant: msg.sender, amount: amount})
        );

        projects[projectId].applications++;
        emit ProjectApplied(projectId, msg.sender, amount);
    }

    //this function is used to register the user for the interviewer.

    function registerInterviewer(uint256 fee) external {
        require(!registeredInterviewers[msg.sender], "Already registered");

        registeredInterviewers[msg.sender] = true;
        interviewers[applicationCounter] = Interviewer({
            interviewerAddress: msg.sender,
            fee: fee
        });

        emit InterviewerRegistered(msg.sender, fee);
        applicationCounter++;
    }

    //it uses for loop for getting the list of active projects in dehix. 

    function getProjects() external view returns (uint256[] memory) {
        uint256 activeCount = 0;

        for (uint256 i = 0; i < projectCounter; i++) {
            if (projects[i].isActive) {
                activeCount++;
            }
        }

        uint256[] memory activeProjects = new uint256[](activeCount);
        uint256 index = 0;

        for (uint256 i = 0; i < projectCounter; i++) {
            if (projects[i].isActive) {
                activeProjects[index] = i;
                index++;
            }
        }

        return activeProjects;
    }
}
