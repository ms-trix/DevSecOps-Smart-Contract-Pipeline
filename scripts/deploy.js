import { ethers } from "ethers";
import hre from "hardhat";

const contracts = [
    { artifact: "contracts/basic/Bank.sol:Bank", name: "Bank" },
    { artifact: "contracts/basic/Vault.sol:Vault", name: "Vault" },
    { artifact: "contracts/basic/TxOriginWallet.sol:TxOriginWallet", name: "TxOriginWallet" },
    {artifact: "contracts/advanced/SignatureReplay.sol:SignatureReplay",name: "SignatureReplay"},
];

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

    for (const contract of contracts) {
        const artifact = await hre.artifacts.readArtifact(contract.artifact);
        const factory = new ethers.ContractFactory(
            artifact.abi,
            artifact.bytecode,
            deployer
        );

        const deployed = await factory.deploy();
        await deployed.waitForDeployment();

        const address = await deployed.getAddress();
        console.log(`${contract.name} deployed to:`, address);
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});