// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract TxOriginWallet {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable{
    }


    function transfer(address destination, uint256 amount) public {
        require(msg.sender == owner, "Not the owner");
        (bool success, ) = destination.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function setOwner(address newOwner) public {
        require(msg.sender == owner, "Not the owner");
        owner = newOwner;
    }

}
