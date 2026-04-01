// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// VULNERABLE: This contract intentionally contains a signature replay vulnerability
// for educational purposes. DO NOT deploy to mainnet.
// Vulnerability 1: Domain separator missing chainId - signature valid on any EVM chain
// Vulnerability 2: No nonce tracking - same signature can be replayed multiple times
// Fix: Add chainId to domain separator and implement per-address nonce tracking

contract SignatureReplayVulnerable {
    mapping(address => uint256) public balances;

    bytes32 public DOMAIN_SEPARATOR;

    bytes32 public constant PAYMENT_TYPEHASH = keccak256(
        "Payment(address recipient,uint256 amount)"
    );

    constructor() {
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,address verifyingContract)"),
            keccak256(bytes("SignatureReplay")),
            keccak256(bytes("1")),
            address(this)
        // VULNERABILITY: chainId is missing here
        ));
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function executePayment(
        address recipient,
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 structHash = keccak256(abi.encode(
            PAYMENT_TYPEHASH,
            recipient,
            amount
        ));

        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            structHash
        ));

        // VULNERABILITY: no nonce in the struct hash
        // the same signature can be replayed indefinitely
        address signer = ecrecover(digest, v, r, s);

        require(signer != address(0), "Invalid signature");
        require(balances[signer] >= amount, "Insufficient balance");

        balances[signer] -= amount;
        balances[recipient] += amount;
    }
}