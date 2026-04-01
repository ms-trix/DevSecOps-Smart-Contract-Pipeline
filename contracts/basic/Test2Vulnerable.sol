// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Test2Vulnerable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // HIGH: anyone can call this and destroy the contract (SWC-106)
    function withdraw() public {
        selfdestruct(payable(msg.sender));
    }
}
