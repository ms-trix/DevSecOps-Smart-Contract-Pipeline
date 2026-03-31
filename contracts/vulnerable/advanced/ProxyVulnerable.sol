// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// VULNERABLE: This contract intentionally contains a storage collision vulnerability
// for educational purposes. DO NOT deploy to mainnet.
// Vulnerability: Both proxy and implementation have 'owner' in storage slot 0
// When initialize() is called via delegatecall, the implementation code runs
// in the proxy's storage context and overwrites the proxy's owner with msg.sender
// An attacker can call initialize() to take ownership of the proxy
// Fix: Use EIP-1967 standard storage slots for proxy admin and implementation address
// EIP-1967 stores these in high entropy slots far from normal variable slots

contract ProxyVulnerable {
    // SLOT 0: proxy owner - will be overwritten by delegatecall to initialize()
    address public owner;
    // SLOT 1: implementation address
    address public implementation;

    constructor(address _implementation) {
        implementation = _implementation;
        owner = msg.sender;
    }

    // VULNERABILITY: any caller can invoke initialize() on the implementation
    // via this fallback, which writes to slot 0 in THIS proxy's storage
    // overwriting the owner with the attacker's address
    fallback() external payable {
        address impl = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}