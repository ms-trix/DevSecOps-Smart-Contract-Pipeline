// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract SignatureReplay {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public nonces;

    bytes32 public immutable DOMAIN_SEPARATOR;

    bytes32 public constant PAYMENT_TYPEHASH = keccak256(
        "Payment(address recipient,uint256 amount,uint256 nonce)"
    );

    constructor() {
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("SignatureReplay")),
            keccak256(bytes("1")),
            block.chainid,
            address(this)
        ));
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() public  {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance");

        balances[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function executePayment(
        address recipient,
        uint256 amount,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 structHash = keccak256(abi.encode(
            PAYMENT_TYPEHASH,
            recipient,
            amount,
            nonce
        ));

        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            structHash
        ));

        address signer = ecrecover(digest, v, r, s);

        require(signer != address(0), "Invalid signature");
        require(nonces[signer] == nonce, "Invalid nonce");
        require(balances[signer] >= amount, "Insufficient balance");

        nonces[signer]++;
        balances[signer] -= amount;
        balances[recipient] += amount;
    }
}