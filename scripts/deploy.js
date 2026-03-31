import { ethers } from "ethers";
import hre from "hardhat";

const contracts = [
    { artifact: "contracts/basic/Bank.sol:Bank", name: "Bank" },
    { artifact: "contracts/basic/Vault.sol:Vault", name: "Vault" },
    { artifact: "contracts/basic/TxOriginWallet.sol:TxOriginWallet", name: "TxOriginWallet" },
    { artifact: "contracts/advanced/SignatureReplay.sol:SignatureReplay", name: "SignatureReplay" },
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

    // Deploy MockERC20 first — no constructor arguments needed
    const mockArtifact = await hre.artifacts.readArtifact("contracts/exploits/MockERC20.sol:MockERC20");
    const mockFactory = new ethers.ContractFactory(
        mockArtifact.abi,
        mockArtifact.bytecode,
        deployer
    );
    const mockToken = await mockFactory.deploy();
    await mockToken.waitForDeployment();
    const mockTokenAddress = await mockToken.getAddress();
    console.log("MockERC20 deployed to:", mockTokenAddress);

    // Deploy ERC20Payment passing MockERC20 address as constructor argument
    const erc20Artifact = await hre.artifacts.readArtifact("contracts/advanced/ERC20Payment.sol:ERC20Payment");
    const erc20Factory = new ethers.ContractFactory(
        erc20Artifact.abi,
        erc20Artifact.bytecode,
        deployer
    );
    const erc20Payment = await erc20Factory.deploy(mockTokenAddress);
    await erc20Payment.waitForDeployment();
    const erc20PaymentAddress = await erc20Payment.getAddress();
    console.log("ERC20Payment deployed to:", erc20PaymentAddress);

    // Deploy ProxyImplementation first — no constructor arguments needed
    const implArtifact = await hre.artifacts.readArtifact("contracts/exploits/ProxyImplementation.sol:ProxyImplementation");
    const implFactory = new ethers.ContractFactory(
        implArtifact.abi,
        implArtifact.bytecode,
        deployer
    );
    const proxyImpl = await implFactory.deploy();
    await proxyImpl.waitForDeployment();
    const proxyImplAddress = await proxyImpl.getAddress();
    console.log("ProxyImplementation deployed to:", proxyImplAddress);

    // Deploy SecureProxy passing ProxyImplementation address as constructor argument
    const secureProxyArtifact = await hre.artifacts.readArtifact("contracts/advanced/SecureProxy.sol:SecureProxy");
    const secureProxyFactory = new ethers.ContractFactory(
        secureProxyArtifact.abi,
        secureProxyArtifact.bytecode,
        deployer
    );
    const secureProxy = await secureProxyFactory.deploy(proxyImplAddress);
    await secureProxy.waitForDeployment();
    const secureProxyAddress = await secureProxy.getAddress();
    console.log("SecureProxy deployed to:", secureProxyAddress);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});