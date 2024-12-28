// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Escrow {
    address public buyer;
    address public seller;
    address public arbiter;
    bool public releaseFunds;
    uint256 public depositAmount;

    event FundsDeposited(address indexed buyer, uint256 amount);
    event FundsReleased(address indexed seller, uint256 amount);
    event FundsRefunded(address indexed buyer, uint256 amount);

    modifier onlyBuyerOrArbiter() {
        require(msg.sender == buyer || msg.sender == arbiter, "Not Authorized!");
        _;
    }

    modifier onlySellerOrArbiter() {
        require(msg.sender == seller || msg.sender == arbiter, "Not Authorized!");
        _;
    }

    modifier onlyWhenDeposited() {
        require(depositAmount > 0, "No funds to release or refund!");
        _;
    }

    constructor(address _seller, address _arbiter) {
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
    }

    function depositFunds() external payable {
        require(msg.sender == buyer, "Only buyer can deposit funds!");
        require(msg.value > 0, "Deposit must be greater than zero!");
        require(depositAmount == 0, "Funds already deposited!");
        
        depositAmount = msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    function releaseAmount() external onlyBuyerOrArbiter onlyWhenDeposited {
        releaseFunds = true;
        payable(seller).transfer(depositAmount);
        emit FundsReleased(seller, depositAmount);
        depositAmount = 0;
    }

    function refundAmount() external onlySellerOrArbiter onlyWhenDeposited {
        releaseFunds = false;
        payable(buyer).transfer(depositAmount);
        emit FundsRefunded(buyer, depositAmount);
        depositAmount = 0;
    }
}
