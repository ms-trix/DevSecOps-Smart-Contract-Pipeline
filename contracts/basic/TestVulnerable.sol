// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract TestVulnerable {
    function kill() public {
        selfdestruct(payable(msg.sender));
    }
}