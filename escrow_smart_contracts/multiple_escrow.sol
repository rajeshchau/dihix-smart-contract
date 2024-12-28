// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MultiArbiterEscrow {
    using SafeERC20 for IERC20;

    address public buyer;
    address public seller;
    IERC20 public token;
    uint256 public depositAmount;

    address[] public arbiters;
    mapping(address => bool) public isArbiter;

    event FundsDeposited(address indexed buyer, uint256 amount);
    event FundsReleased(address indexed seller, uint256 amount);
    event FundsRefunded(address indexed buyer, uint256 amount);

    modifier onlyBuyerOrArbiter() {
        require(msg.sender == buyer || isArbiter[msg.sender], "Not Authorized!");
        _;
    }

    modifier onlySellerOrArbiter() {
        require(msg.sender == seller || isArbiter[msg.sender], "Not Authorized!");
        _;
    }

    modifier onlyWhenDeposited() {
        require(depositAmount > 0, "No funds to release or refund!");
        _;
    }

    constructor(
        address _seller,
        address[] memory _arbiters,
        address _token
    ) {
        require(
            _arbiters.length == 1 || _arbiters.length == 3 || _arbiters.length == 5,
            "Number of arbiters must be 1, 3, or 5"
        );
        buyer = msg.sender;
        seller = _seller;
        token = IERC20(_token);

        for (uint256 i = 0; i < _arbiters.length; i++) {
            require(_arbiters[i] != address(0), "Arbiter address cannot be zero");
            arbiters.push(_arbiters[i]);
            isArbiter[_arbiters[i]] = true;
        }
    }

    function depositFunds(uint256 _amount) external {
        require(msg.sender == buyer, "Only buyer can deposit funds!");
        require(_amount > 0, "Deposit must be greater than zero!");
        require(depositAmount == 0, "Funds already deposited!");

        // Transfer tokens from buyer to this contract securely
        token.safeTransferFrom(msg.sender, address(this), _amount);

        depositAmount = _amount;
        emit FundsDeposited(msg.sender, _amount);
    }

    function releaseFunds() external onlyBuyerOrArbiter onlyWhenDeposited {
        require(_majorityVote(true), "Majority vote required to release funds!");

        // Transfer tokens to seller securely
        token.safeTransfer(seller, depositAmount);

        emit FundsReleased(seller, depositAmount);
        depositAmount = 0;
    }

    function refundFunds() external onlySellerOrArbiter onlyWhenDeposited {
        require(_majorityVote(false), "Majority vote required to refund funds!");

        // Transfer tokens back to buyer securely
        token.safeTransfer(buyer, depositAmount);

        emit FundsRefunded(buyer, depositAmount);
        depositAmount = 0;
    }

    function _majorityVote(bool release) private view returns (bool) {
        uint256 votes = 0;
        for (uint256 i = 0; i < arbiters.length; i++) {
            if (_arbiterVoted(arbiters[i], release)) {
                votes++;
            }
        }
        // Majority is half the arbiters plus one
        return votes > arbiters.length / 2;
    }

    mapping(address => mapping(bool => bool)) public arbiterVotes;

    function vote(bool release) external {
        require(isArbiter[msg.sender], "Only arbiters can vote!");
        arbiterVotes[msg.sender][release] = true;
    }

    function _arbiterVoted(address arbiter, bool release) private view returns (bool) {
        return arbiterVotes[arbiter][release];
    }
}
