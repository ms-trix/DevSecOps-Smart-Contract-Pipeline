// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// VULNERABLE: This contract intentionally contains a tx.origin authentication vulnerability
// for educational purposes. DO NOT deploy to mainnet.
// Vulnerability: withdraw() uses tx.origin for authentication instead of msg.sender
// Fix: Replace tx.origin with msg.sender in the require check

contract TxOriginVulnerable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
    }

    // VULNERABILITY: tx.origin can be spoofed by a malicious intermediate contract
    function transfer(address destination, uint256 amount) public {
        require(tx.origin == owner, "Not the owner");
        (bool success, ) = destination.call{value: amount}("");
        require(success, "Transfer failed");
    }
}