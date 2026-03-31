// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Vault {
    mapping(address => uint256 ) public balances;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }


    function withdrawAll() public {
        require(msg.sender == owner, "Not the owner");
        payable(msg.sender).transfer(address(this).balance);
    }
}
