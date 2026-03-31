// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// VULNERABLE: This contract intentionally contains unchecked ERC20 return value vulnerability
// for educational purposes. DO NOT deploy to mainnet.
// Vulnerability: transfer() and transferFrom() return values are never checked
// A non-standard token like USDT can return false silently and the contract
// will update internal balances as if the transfer succeeded
// Fix: Use OpenZeppelin SafeERC20 safeTransfer() and safeTransferFrom()

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract ERC20PaymentVulnerable {
    IERC20 public token;
    mapping(address => uint256) public balances;

    constructor(address tokenAddress) {
        token = IERC20(tokenAddress);
    }

    function deposit(uint256 amount) public {
        // VULNERABILITY: return value of transferFrom is never checked
        // if token returns false silently the transfer failed but we still
        // credit the user's balance as if it succeeded
        token.transferFrom(msg.sender, address(this), amount);
        balances[msg.sender] += amount;
    }

    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;

        // VULNERABILITY: return value of transfer is never checked
        // tokens may not actually move but the balance is already deducted
        token.transfer(msg.sender, amount);
    }
}