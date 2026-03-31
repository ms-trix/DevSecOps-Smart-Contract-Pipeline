// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// VULNERABLE: This contract intentionally contains a reentrancy vulnerability
// for educational purposes. DO NOT deploy to mainnet.
// Vulnerability: State is updated AFTER the external call (violates CEI pattern)
// Fix: Move balances[msg.sender] -= amount to BEFORE the external call

contract BankVulnerable {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Not enough balance");

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        unchecked {
            balances[msg.sender] -= amount;
        }
    }

    receive() external payable {}
}