import { expect } from "chai";
import hre from "hardhat";

describe("TxOriginWallet - tx.origin Attack", function () {
  let ethers;
  let wallet, walletVulnerable, malicious;
  let owner, attacker;

  before(async function () {
    const connection = await hre.network.connect();
    ethers = connection.ethers;
  });

  beforeEach(async function () {
    [owner, attacker] = await ethers.getSigners();

    const TxOriginWallet = await ethers.getContractFactory("TxOriginWallet");
    wallet = await TxOriginWallet.deploy();
    await owner.sendTransaction({
      to: await wallet.getAddress(),
      value: ethers.parseEther("5"),
    });

    const TxOriginVulnerable = await ethers.getContractFactory("TxOriginVulnerable");
    walletVulnerable = await TxOriginVulnerable.deploy();
    await owner.sendTransaction({
      to: await walletVulnerable.getAddress(),
      value: ethers.parseEther("5"),
    });

    const TxOriginAttacker = await ethers.getContractFactory("TxOriginAttacker");
    malicious = await TxOriginAttacker.deploy(
        await walletVulnerable.getAddress(),
        attacker.address
    );
  });

  it("EXPLOIT: tx.origin attack drains TxOriginVulnerable", async function () {
    const balanceBefore = await ethers.provider.getBalance(
        await walletVulnerable.getAddress()
    );
    expect(balanceBefore).to.equal(ethers.parseEther("5"));

    await malicious.connect(owner).attack();

    const balanceAfter = await ethers.provider.getBalance(
        await walletVulnerable.getAddress()
    );
    expect(balanceAfter).to.equal(0n);
  });

  it("FIXED: TxOriginWallet blocks tx.origin attack", async function () {
    const TxOriginAttacker = await ethers.getContractFactory("TxOriginAttacker");
    const maliciousFixed = await TxOriginAttacker.deploy(
        await wallet.getAddress(),
        attacker.address
    );

    await expect(maliciousFixed.connect(owner).attack()).to.be.revert(ethers);
  });
});