import { expect } from "chai";
import hre from "hardhat";

describe("Vault - Access Control", function () {
  let ethers;
  let vault, vaultVulnerable;
  let owner, attacker;

  before(async function () {
    const connection = await hre.network.connect();
    ethers = connection.ethers;
  });

  beforeEach(async function () {
    [owner, attacker] = await ethers.getSigners();

    const Vault = await ethers.getContractFactory("Vault");
    vault = await Vault.deploy();
    await vault.connect(owner).deposit({ value: ethers.parseEther("5") });

    const VaultVulnerable = await ethers.getContractFactory("VaultVulnerable");
    vaultVulnerable = await VaultVulnerable.deploy();
    await vaultVulnerable.connect(owner).deposit({ value: ethers.parseEther("5") });
  });

  it("EXPLOIT: anyone can withdrawAll from VaultVulnerable", async function () {
    const balanceBefore = await ethers.provider.getBalance(
        await vaultVulnerable.getAddress()
    );
    expect(balanceBefore).to.equal(ethers.parseEther("5"));

    await vaultVulnerable.connect(attacker).withdrawAll();

    const balanceAfter = await ethers.provider.getBalance(
        await vaultVulnerable.getAddress()
    );
    expect(balanceAfter).to.equal(0n);
  });

  it("FIXED: Vault blocks non-owner withdrawal", async function () {
    await expect(
        vault.connect(attacker).withdrawAll()
    ).to.be.revertedWith("Not the owner");
  });

  it("FIXED: owner can still withdrawAll from Vault", async function () {
    await vault.connect(owner).withdrawAll();
    const balanceAfter = await ethers.provider.getBalance(
        await vault.getAddress()
    );
    expect(balanceAfter).to.equal(0n);
  });
});