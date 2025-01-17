// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FreelancerContract {
    using SafeERC20 for IERC20;

    enum State { Paid, Unpaid, Pending }

    struct FreelancerPayment {
        string freelancerId;
        string projectId;
        uint256 totalAmount;
        State state;
    }

    struct Milestone {
        string milestoneId;
        uint256 projectId;
        uint256 milestoneNumber;
        uint256 milestoneCompleted;
        mapping(uint256 => FreelancerPayment) freelancerPayments; // Mapping by payment ID
    }

    struct Project {
        string projectId;
        bool isActive;
        uint256 totalApplications;
        mapping(uint256 => uint256) appliedFreelancers; // Mapping of freelancer IDs to their application status
        mapping(uint256 => Milestone) milestones; // Mapping by milestone ID
    }

    struct Freelancer {
        string freelancerId;
        address freelancerAddress;
        mapping(uint256 => Project) projects; // Mapping by project ID
    }

    struct Business {
        string businessId;
        address businessAddress;
        mapping(uint256 => Project) projects; // Mapping by project ID
    }

    struct Hiring {
        string hiringId;
        mapping(uint256 => Freelancer) freelancers; // Mapping by freelancer ID
        bool feesStatus;
    }

    struct Oracle {
        string oracleId;
        address oracleAddress;
    }

    struct Escrow {
        string escrowid;
        address[] votingoracles;
        address freelanceraddress;
        address bussnessadress;
        uint256 projectid;
        uint256 deposiedamount;
        IERC20 tokenaddress;
    }

    address public owner;

    mapping(uint256 => Freelancer) public freelancers; // Mapping of freelancer ID to Freelancer struct
    mapping(uint256 => Project) public projects;       // Mapping of project ID to Project struct
    mapping(uint256 => Business) public businesses;    // Mapping of business ID to Business struct
    mapping(uint256 => Hiring) public hirings;         // Mapping of hiring ID to Hiring struct
    mapping(uint256 => Oracle) public oracles;         // Mapping of oracle ID to Oracle struct
    mapping(uint256 => Escrow)public escrow;

    mapping(address => bool) public isOracles;
    mapping(address => mapping(bool => bool)) public oracleVotes;

    string private nextFreelancerId;
    string private nextProjectId;
    string private nextBusinessId;
    string private nextMilestoneId;
    string private nextHiringId;
    address[] public Orecles;

    event FreelancerAdded(uint256 indexed freelancerId, address freelancerAddress);
    event ProjectCreated(uint256 indexed projectId, bool isActive);
    event MilestoneAdded(uint256 indexed projectId, uint256 milestoneId);
    event PaymentAdded(uint256 indexed milestoneId, uint256 paymentId);
    event FundsDeposited(address businessaddress, uint256 amount);
    event FundsReleased(address freelanceraddress, uint256 amount);
    event FundsRefunded(address freelanceraddress,uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier onlyBuyerOrOracle(string _escrowid) {
        require(msg.sender == escrow[_escrowid].bussnessadress || isOracles[msg.sender], "Not Authorized!");
        _;
    }

    modifier onlyWhenDeposited(string _escrowid){
        require( escrow[_escrowid].deposiedamount > 0, "No funds to release or refund!");
        _;
    }

    modifier onlySellerOrOrecle(string _escrowid){
        require(msg.sender == escrow[_escrowid].freelanceraddress || isOracles[msg.sender], "Not Authorized!");
        _;
    }

    function addBusinessToDehix(string _bussinessid, address _bussinessaddress) public {
        businesses[_bussinessid].businessId = _bussinessid;
        businesses[_bussinessid].businessAddress=_bussinessaddress;
    }

    function addFreelancerToDehix(string _freelancerid,address _freelancerAddress) external onlyOwner {
        require(_freelancerid != 0, "Freelancer ID cannot be 0");
        require(_freelancerid != freelancers[_freelancerid].freelancerId, "Freelancer ID already exists");
        require(_freelancerAddress != address(0), "Freelancer address cannot be 0");
        
        
        freelancers[_freelancerid].freelancerId = _freelancerid;
        freelancers[_freelancerid].freelancerAddress = _freelancerAddress;
        emit FreelancerAdded(_freelancerid, _freelancerAddress);
    }

    function createProjectToDehix(string _businessId,string _projectid) external onlyOwner returns (string) {
        require(_projectid != 0,"Project id could not be zero.");
        projects[_projectid].projectId = _projectid;
        projects[_projectid].isActive = true;
        
        Project storage project = projects[_projectid];
        businesses[_businessId].projects[_projectid].projectId = project.projectId;
        businesses[_businessId].projects[_projectid].isActive = project.isActive;
        businesses[_businessId].projects[_projectid].totalApplications = project.totalApplications;
        emit ProjectCreated(_projectid, true);
        return _projectid;
    }

    function addMilestoneToDehix(
        string _projectId,
        uint256 _milestoneNumber,
        string _milestoneid
    ) external onlyOwner {
        Project storage project = projects[_projectId];
        require(project.isActive, "Project is not active");

        
        project.milestones[_milestoneid].milestoneId = _milestoneid;
        project.milestones[_milestoneid].projectId = _projectId;
        project.milestones[_milestoneid].milestoneNumber = _milestoneNumber;
        project.milestones[_milestoneid].milestoneCompleted = 0;

        emit MilestoneAdded(_projectId, _milestoneid);
    }

    function addFreelancerPaymentToDehix(
        string _milestoneId,
        string _freelancerId,
        string _projectId,
        uint256 _amount,
        State _state
    ) external onlyOwner {
        Milestone storage milestone = projects[_projectId].milestones[_milestoneId];

        uint256 paymentId = milestone.milestoneCompleted++;
        milestone.freelancerPayments[paymentId] = FreelancerPayment({
            freelancerId: _freelancerId,
            projectId: _projectId,
            totalAmount: _amount,
            state: _state
        });

        emit PaymentAdded(_milestoneId, paymentId);
    }

    function applyToProjectToDehix(string _projectId, string _freelancerId) external {
        Project storage project = projects[_projectId];
        require(project.isActive, "Project is not active");

        project.appliedFreelancers[_freelancerId] = 1; // Mark freelancer as applied
        project.totalApplications++;
    }

    function deactivateProjectToDehix(string _projectId) external onlyOwner {
        projects[_projectId].isActive = false;
    }

    function assignOracleToDehix(string _oracleId, address _oracleAddress) external onlyOwner {
        oracles[_oracleId].oracleId = _oracleId;
        oracles[_oracleId].oracleAddress = _oracleAddress;
    }

    // Additional getters for retrieving nested mapping data
    function getMilestone(string _projectId, string _milestoneId)
        external
        view
        returns (string, string, uint256, uint256)
    {
        Milestone storage milestone = projects[_projectId].milestones[_milestoneId];
        return (
            milestone.milestoneId,
            milestone.projectId,
            milestone.milestoneNumber,
            milestone.milestoneCompleted
        );
    }

    function getFreelancerPayment(uint256 _projectId, uint256 _milestoneId, uint256 _paymentId)
        external
        view
        returns (uint256, uint256, uint256, State)
    {
        FreelancerPayment storage payment = projects[_projectId].milestones[_milestoneId].freelancerPayments[_paymentId];
        return (
            payment.freelancerId,
            payment.projectId,
            payment.totalAmount,
            payment.state
        );
    }

    function createescrow(string _escrowid,address[] memory _votingoracle,address _freelancer,address _bussness,string _projectid,address _tokenaddress)public{
        require(_votingoracle.length == 1 || _votingoracle.length == 3 || _votingoracle.length == 5,"Number of arbiters must be 1, 3, or 5");
        escrow[_escrowid].escrowid=_escrowid;
        escrow[_escrowid].votingoracles=_votingoracle;
        escrow[_escrowid].freelanceraddress=_freelancer;
        escrow[_escrowid].bussnessadress=_bussness;
        escrow[_escrowid].projectid=_projectid;
        escrow[_escrowid].deposiedamount = 0;
        escrow[_escrowid].tokenaddress=IERC20(_tokenaddress);

        for (uint256 i = 0; i < _votingoracle.length; i++) {
            require(_votingoracle[i] != address(0), "Arbiter address cannot be zero");
            Orecles.push(_votingoracle[i]);
            isOracles[_votingoracle[i]] = true;
        }

    }

    function depositFundsToEscrow(uint256 _amount,string _escrowid) external {
        require(msg.sender == escrow[_escrowid].bussnessadress, "Only buyer can deposit funds!");
        require(_amount > 0, "Deposit must be greater than zero!");
        require(escrow[_escrowid].deposiedamount == 0, "Funds already deposited!");

        // Transfer tokens from buyer to this contract securely
        escrow[_escrowid].tokenaddress.safeTransferFrom(msg.sender, address(this), _amount);

        escrow[_escrowid].deposiedamount = _amount;
        emit FundsDeposited(msg.sender, _amount);
    }

    function releaseEscrowFunds(string _escrowid) external onlyBuyerOrOracle(_escrowid) onlyWhenDeposited(_escrowid) {
        require(_majorityVote(true), "Majority vote required to release funds!");

        // Transfer tokens to seller securely
        escrow[_escrowid].tokenaddress.safeTransfer(escrow[_escrowid].freelanceraddress, escrow[_escrowid].deposiedamount);

        emit FundsReleased(escrow[_escrowid].freelanceraddress, escrow[_escrowid].deposiedamount);
        escrow[_escrowid].deposiedamount = 0;
    }

    function _majorityVote(bool release) private view returns (bool) {
        uint256 votes = 0;
        for (uint256 i = 0; i < Orecles.length; i++) {
            if (_orecleVoted(Orecles[i], release)) {
                votes++;
            }
        }
        // Majority is half the arbiters plus one
        return votes > Orecles.length / 2;
    }

    function vote(bool release) external {
        require(isOracles[msg.sender], "Only arbiters can vote!");
        oracleVotes[msg.sender][release] = true;
    }

    function refundFundsOfEscrow(string _escrowid) external onlySellerOrOrecle(_escrowid) onlyWhenDeposited(_escrowid) {
        require(_majorityVote(false), "Majority vote required to refund funds!");

        // Transfer tokens back to buyer securely
        escrow[_escrowid].tokenaddress.safeTransfer(escrow[_escrowid].bussnessadress, escrow[_escrowid].deposiedamount);

        emit FundsRefunded(escrow[_escrowid].bussnessadress, escrow[_escrowid].deposiedamount);
        escrow[_escrowid].deposiedamount = 0;
    }

    function _orecleVoted(address _orecle, bool _release) private view returns (bool) {
        return oracleVotes[_orecle][_release];
    }

}
