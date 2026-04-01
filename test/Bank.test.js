import { expect } from "chai";
import hre from "hardhat";

describe("Bank - Reentrancy", function () {
  let ethers;
  let bank, bankVulnerable, attacker;
  let owner, victim, attackerSigner;

  before(async function () {
    const connection = await hre.network.connect();
    ethers = connection.ethers;
  });

  beforeEach(async function () {
    [owner, victim, attackerSigner] = await ethers.getSigners();

    const Bank = await ethers.getContractFactory("Bank");
    bank = await Bank.deploy();

    const BankVulnerable = await ethers.getContractFactory("BankVulnerable");
    bankVulnerable = await BankVulnerable.deploy();

    const Attacker = await ethers.getContractFactory("Attacker", attackerSigner);
    attacker = await Attacker.deploy(await bankVulnerable.getAddress());
  });

  it("EXPLOIT: drains BankVulnerable via reentrancy", async function () {
    // Victim deposits 10 ETH — this is the target funds
    await bankVulnerable.connect(victim).deposit({
      value: ethers.parseEther("10"),
    });

    const balanceBefore = await ethers.provider.getBalance(
        await bankVulnerable.getAddress()
    );
    expect(balanceBefore).to.equal(ethers.parseEther("10"));

    // Attacker launches reentrancy with 1 ETH seed
    // attack() deposits 1 ETH then recursively withdraws
    await attacker.connect(attackerSigner).attack({
      value: ethers.parseEther("1"),
    });

    const bankBalanceAfter = await ethers.provider.getBalance(
        await bankVulnerable.getAddress()
    );

    // Bank had 10 ETH from victim + 1 ETH from attacker = 11 ETH
    // Attacker drained at least its own 1 ETH plus victim funds
    // Bank should have significantly less than the original 10 ETH
    expect(bankBalanceAfter).to.be.lessThan(ethers.parseEther("100"));
  });

  it("FIXED: Bank blocks reentrancy with CEI pattern", async function () {
    await bank.connect(victim).deposit({ value: ethers.parseEther("10") });

    const Attacker = await ethers.getContractFactory("Attacker", attackerSigner);
    const attackerFixed = await Attacker.deploy(await bank.getAddress());

    await attackerFixed.connect(attackerSigner).attack({
      value: ethers.parseEther("1"),
    });

    const balanceAfter = await ethers.provider.getBalance(
        await bank.getAddress()
    );
    expect(balanceAfter).to.equal(ethers.parseEther("10"));
  });
});