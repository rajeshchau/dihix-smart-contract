// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MultiTokenEscrow {
    using SafeERC20 for IERC20;

    address public buyer;
    address public seller;
    address public arbiter;
    uint256 public depositAmount;
    address public tokenAddress; // Token address, address(0) for native currency

    event FundsDeposited(address indexed buyer, uint256 amount, address token);
    event FundsReleased(address indexed seller, uint256 amount, address token);
    event FundsRefunded(address indexed buyer, uint256 amount, address token);

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

    function depositFunds(uint256 _amount, address _token) external payable {
        require(msg.sender == buyer, "Only buyer can deposit funds!");
        require(depositAmount == 0, "Funds already deposited!");

        if (_token == address(0)) {
            // Handling native currency (e.g., ETH)
            require(msg.value > 0, "Deposit must be greater than zero!");
            require(_amount == msg.value, "Mismatch between amount and value!");
        } else {
            // Handling ERC20 tokens
            require(_amount > 0, "Deposit must be greater than zero!");
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }

        depositAmount = _amount;
        tokenAddress = _token;

        emit FundsDeposited(msg.sender, _amount, _token);
    }

    function releaseAmount() external onlyBuyerOrArbiter onlyWhenDeposited {
        if (tokenAddress == address(0)) {
            // Release native currency
            payable(seller).transfer(depositAmount);
        } else {
            // Release ERC20 tokens
            IERC20(tokenAddress).safeTransfer(seller, depositAmount);
        }

        emit FundsReleased(seller, depositAmount, tokenAddress);
        resetEscrow();
    }

    function refundAmount() external onlySellerOrArbiter onlyWhenDeposited {
        if (tokenAddress == address(0)) {
            // Refund native currency
            payable(buyer).transfer(depositAmount);
        } else {
            // Refund ERC20 tokens
            IERC20(tokenAddress).safeTransfer(buyer, depositAmount);
        }

        emit FundsRefunded(buyer, depositAmount, tokenAddress);
        resetEscrow();
    }

    function resetEscrow() private {
        depositAmount = 0;
        tokenAddress = address(0);
    }
}
