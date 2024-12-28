// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MultiCurrencyEscrow {
    using SafeERC20 for IERC20;

    address public buyer;
    address public seller;

    address[] public arbiters;
    mapping(address => bool) public isArbiter;

    mapping(address => uint256) public tokenDeposits; // ERC-20 Token deposits
    uint256 public ethDeposit; // ETH deposit

    event FundsDeposited(address indexed buyer, address indexed token, uint256 amount);
    event FundsReleased(address indexed seller, address indexed token, uint256 amount);
    event FundsRefunded(address indexed buyer, address indexed token, uint256 amount);

    modifier onlyBuyerOrArbiter() {
        require(msg.sender == buyer || isArbiter[msg.sender], "Not Authorized!");
        _;
    }

    modifier onlySellerOrArbiter() {
        require(msg.sender == seller || isArbiter[msg.sender], "Not Authorized!");
        _;
    }

    modifier onlyWhenDeposited(address token) {
        if (token == address(0)) {
            require(ethDeposit > 0, "No ETH to release or refund!");
        } else {
            require(tokenDeposits[token] > 0, "No tokens to release or refund!");
        }
        _;
    }

    constructor(
        address _seller,
        address[] memory _arbiters
    ) {
        require(
            _arbiters.length == 1 || _arbiters.length == 3 || _arbiters.length == 5,
            "Number of arbiters must be 1, 3, or 5"
        );
        buyer = msg.sender;
        seller = _seller;

        for (uint256 i = 0; i < _arbiters.length; i++) {
            require(_arbiters[i] != address(0), "Arbiter address cannot be zero");
            arbiters.push(_arbiters[i]);
            isArbiter[_arbiters[i]] = true;
        }
    }

    // Deposit ETH
    function depositETH() external payable {
        require(msg.sender == buyer, "Only buyer can deposit funds!");
        require(msg.value > 0, "Deposit must be greater than zero!");
        require(ethDeposit == 0, "ETH already deposited!");

        ethDeposit = msg.value;
        emit FundsDeposited(msg.sender, address(0), msg.value); // address(0) indicates ETH
    }

    // Deposit ERC-20 Tokens
    function depositToken(address token, uint256 amount) external {
        require(msg.sender == buyer, "Only buyer can deposit funds!");
        require(amount > 0, "Deposit must be greater than zero!");
        require(tokenDeposits[token] == 0, "Funds already deposited for this token!");

        // Transfer tokens from buyer to this contract securely
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        tokenDeposits[token] = amount;
        emit FundsDeposited(msg.sender, token, amount);
    }

    // Release funds to seller
    function releaseFunds(address token) external onlyBuyerOrArbiter onlyWhenDeposited(token) {
        if (token == address(0)) {
            // Release ETH
            uint256 amount = ethDeposit;
            ethDeposit = 0;
            payable(seller).transfer(amount);
            emit FundsReleased(seller, address(0), amount);
        } else {
            // Release ERC-20 tokens
            uint256 amount = tokenDeposits[token];
            tokenDeposits[token] = 0;
            IERC20(token).safeTransfer(seller, amount);
            emit FundsReleased(seller, token, amount);
        }
    }

    // Refund funds to buyer
    function refundFunds(address token) external onlySellerOrArbiter onlyWhenDeposited(token) {
        if (token == address(0)) {
            // Refund ETH
            uint256 amount = ethDeposit;
            ethDeposit = 0;
            payable(buyer).transfer(amount);
            emit FundsRefunded(buyer, address(0), amount);
        } else {
            // Refund ERC-20 tokens
            uint256 amount = tokenDeposits[token];
            tokenDeposits[token] = 0;
            IERC20(token).safeTransfer(buyer, amount);
            emit FundsRefunded(buyer, token, amount);
        }
    }
}
