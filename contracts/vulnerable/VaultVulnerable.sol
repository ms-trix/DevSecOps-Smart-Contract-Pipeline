// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// VULNERABLE: This contract intentionally contains an access control vulnerability
// for educational purposes. DO NOT deploy to mainnet.
// Vulnerability: withdrawAll() has no access control - any address can drain the vault
// Fix: Add require(msg.sender == owner, "Not the owner") to withdrawAll()


contract VaultVulnerable {
    mapping(address => uint256 ) public balances;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    //VULNERABILITY: Anyone can call this and take all the money!
    function withdrawAll() public {
        payable(msg.sender).transfer(address(this).balance);
    }
}
