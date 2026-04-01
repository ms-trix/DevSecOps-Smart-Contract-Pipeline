// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Test2Vulnerable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function withdraw() public {
        selfdestruct(payable(msg.sender));
    }
}