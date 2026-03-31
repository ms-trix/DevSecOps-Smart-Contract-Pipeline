import { ethers } from "ethers";
import hre from "hardhat";

async function main() {
    const url = process.env.SEPOLIA_RPC_URL ?? "http://127.0.0.1:8545";
    const provider = new ethers.JsonRpcProvider(url);

    let deployer;
    if (process.env.METAMASK_API) {
        deployer = new ethers.Wallet(process.env.METAMASK_API, provider);
    } else {
        deployer = await provider.getSigner(0);
    }

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
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});