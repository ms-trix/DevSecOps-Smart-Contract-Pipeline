# DevSecOps Smart Contract Security Pipeline

> Automated smart contract security pipeline combining static analysis, symbolic execution, and AI-powered remediation — deployed on Sepolia testnet with full AWS observability.

<img width="576" height="238" alt="Screenshot 2026-04-02 at 13 11 43" src="https://github.com/user-attachments/assets/d2a3a64a-df05-4208-9b7c-17ed669e5f02" />

---

## What This Project Does

Every time code is pushed, an automated security pipeline runs Slither static analysis and a custom vulnerability detector against the Solidity contracts. If a high severity vulnerability is found, the pipeline blocks deployment, triggers Mythril symbolic execution for deep analysis, and calls the Claude AI API to generate a structured remediation report with exact fix instructions. The report is posted as a PR comment, uploaded to S3, and logged to CloudWatch — all without human intervention.

---

## Live Links

- **Grafana Dashboard** — [Live Pipeline Metrics](https://mskrebe.grafana.net/dashboard/snapshot/IHE7Wvq36oTKq4P0PHSD0eiNjbeW3vKB)
- **Sepolia Contracts** — see [Deployed Contracts](#deployed-contracts) below

---

## Architecture

<img width="1408" height="768" alt="Gemini_Generated_Image_bpl1fcbpl1fcbpl1" src="https://github.com/user-attachments/assets/7b85310e-8f96-406b-a731-73e8b18ebfa1" />


---

## Tech Stack

| Layer | Technology |
|---|---|
| Smart Contracts | Solidity 0.8.28, OpenZeppelin v5 |
| Development | Hardhat v3, ethers v6, TypeScript |
| Static Analysis | Slither 0.11.5, Custom Detector Plugin |
| Symbolic Execution | Mythril 0.24.7 |
| AI Remediation | Claude API (claude-sonnet-4-5), Anthropic |
| CI/CD | GitHub Actions |
| Testnet | Sepolia, Infura |
| Infrastructure | AWS S3, CloudWatch, IAM OIDC, Budgets |
| IaC | Terraform v1.14 |
| Observability | Grafana Cloud, CloudWatch Dashboards |
| Runtime | Node.js 22.13.1, Python 3.11 |

---

## Pipeline In Action

### Security Scan — Pipeline Blocks Deployment on High Severity Finding

<img width="549" height="232" alt="Screenshot 2026-04-02 at 13 12 32" src="https://github.com/user-attachments/assets/dd0de206-7ab0-42d9-9ff9-cadba4a63aac" />


### AI Remediation — Automatic PR Comment

<img width="477" height="523" alt="Screenshot 2026-04-02 at 01 44 02" src="https://github.com/user-attachments/assets/c5beff09-13fa-4a36-b8da-7089cd35fac1" />


### AI Remediation Report — Claude Analysis
<img width="1152" height="265" alt="Screenshot 2026-04-02 at 13 13 44" src="https://github.com/user-attachments/assets/107d9743-4de5-42ff-927c-429566d22c2b" />

<img width="615" height="419" alt="Screenshot 2026-04-02 at 13 14 06" src="https://github.com/user-attachments/assets/bc0ffabd-54c8-4c44-acba-bbbbc5de4caf" />

<img width="647" height="622" alt="Screenshot 2026-04-02 at 13 14 33" src="https://github.com/user-attachments/assets/caa09b87-c599-44d7-bb11-d8f4bfb93e9a" />

### Grafana Dashboard — Live Pipeline Metrics

<img width="1195" height="621" alt="Screenshot 2026-04-02 at 13 13 22" src="https://github.com/user-attachments/assets/779b732f-2e83-4307-83b3-c5b164be8e73" />


---

## Vulnerabilities Covered

Six production smart contract vulnerabilities — each has a vulnerable version, a fixed version, an exploit contract, and a Hardhat proof-of-exploit test.

### Basic Vulnerabilities

**Reentrancy (SWC-107)** — `BankVulnerable.sol` updates state after the external call, allowing `Attacker.sol` to recursively drain the contract before the balance is zeroed. Fixed in `Bank.sol` using the Checks-Effects-Interactions pattern.

**Missing Access Control (SWC-105)** — `VaultVulnerable.sol` has no ownership check on `withdrawAll()`, allowing any address to drain the vault. Fixed in `Vault.sol` with `onlyOwner`.

**tx.origin Authentication (SWC-115)** — `TxOriginVulnerable.sol` uses `tx.origin` for authentication, allowing `TxOriginAttacker.sol` to drain the wallet by tricking the owner into calling a malicious contract. Fixed in `TxOriginWallet.sol` using `msg.sender`.

### Advanced Vulnerabilities

**Signature Replay (SWC-121)** — `SignatureReplayVulnerable.sol` lacks nonce tracking and chain ID in the domain separator, allowing signed messages to be replayed. Fixed in `SignatureReplay.sol` with EIP-712 and per-user nonces.

**Unchecked ERC20 Return Values** — `ERC20PaymentVulnerable.sol` ignores return values from token transfers, silently failing on non-standard tokens. Fixed in `ERC20Payment.sol` using OpenZeppelin SafeERC20.

**Proxy Storage Collision (SWC-124)** — `ProxyVulnerable.sol` uses a naive storage layout causing the proxy's admin slot to collide with the implementation. Fixed in `SecureProxy.sol` using EIP-1967 storage slots.

---

## Hardhat Tests — Proof of Exploit

Seven tests across three files proving each vulnerability is real and each fix works. Every test follows the pattern: attack succeeds on the vulnerable contract, attack fails on the fixed contract.
```bash
npx hardhat test mocha
```
```
Bank - Reentrancy
  ✔ EXPLOIT: drains BankVulnerable via reentrancy
  ✔ FIXED: Bank blocks reentrancy with CEI pattern

TxOriginWallet - tx.origin Attack
  ✔ EXPLOIT: tx.origin attack drains TxOriginVulnerable
  ✔ FIXED: TxOriginWallet blocks tx.origin attack

Vault - Access Control
  ✔ EXPLOIT: anyone can withdrawAll from VaultVulnerable
  ✔ FIXED: Vault blocks non-owner withdrawal
  ✔ FIXED: owner can still withdrawAll from Vault

7 passing (350ms)
```

---

## Custom Slither Detector

A custom Slither plugin that detects unprotected initializer functions — a real vulnerability class that has been exploited in production DeFi protocols. If any contract exposes an `initialize()` or `init*()` function that writes to owner/admin state without access control, the pipeline fails.
```bash
python3 slither_detectors/run_detector.py contracts/advanced/SecureProxy.sol
# No issues found

python3 slither_detectors/run_detector.py contracts/exploits/ProxyImplementation.sol
# FOUND: unprotected-initializer in ProxyImplementation.initialize() (lines 8-10)
```

---

## Mythril Deep Audit

Standalone symbolic execution tool that finds vulnerabilities Slither misses. Runs automatically in the AI remediation pipeline on any contract with High severity findings.
```bash
python3 scripts/deep-audit.py contracts/vulnerable/basic/BankVulnerable.sol --timeout 60 --depth 10
# FAILED: 2 Medium findings (state read/write after external call)

python3 scripts/deep-audit.py contracts/basic/Bank.sol --timeout 60 --depth 10
# PASSED: No issues found
```

---

## AWS Infrastructure

All infrastructure managed as code with Terraform. State stored in S3 with versioning.
```
terraform/
├── main.tf          — AWS provider, S3 backend
├── variables.tf     — region, account ID, repo, project name
├── s3.tf            — reports bucket, encryption, versioning, HTTPS-only policy
├── iam.tf           — GitHub Actions OIDC role, least-privilege policy
├── cloudwatch.tf    — log group, metric filters, alarm
├── dashboard.tf     — CloudWatch dashboard
├── budget.tf        — $5/month budget alert, cost anomaly detector
└── outputs.tf       — bucket name, role ARN, dashboard URL
```
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

**Resources created:**
- S3 bucket — AES-256 encrypted, versioned, public access blocked, HTTPS-only
- IAM OIDC role — GitHub Actions authenticates without long-lived keys
- CloudWatch log group — 90 day retention, metric filters for PASSED/FAILED/AIRemediationSuccess
- CloudWatch alarm — triggers on High severity findings
- CloudWatch dashboard — live pipeline metrics
- AWS Budget — $5/month limit, alerts at 80% and 100%
- Cost Anomaly Detector — daily email if any service exceeds $1

---

## Deployed Contracts

All contracts deployed and verified on Sepolia testnet.

| Contract | Address | Etherscan |
|---|---|---|
| Bank | `0xb4b56AF104484C7825d44Ce0fbcf15FFdAFCFCF6` | [View](https://sepolia.etherscan.io/address/0xb4b56AF104484C7825d44Ce0fbcf15FFdAFCFCF6) |
| Vault | `0x9F249ed33683F72d255BaB6e9A770F167415c306` | [View](https://sepolia.etherscan.io/address/0x9F249ed33683F72d255BaB6e9A770F167415c306) |
| TxOriginWallet | `0x445B733E3bD7A9A07Af1134CE377a4D5F62E3E68` | [View](https://sepolia.etherscan.io/address/0x445B733E3bD7A9A07Af1134CE377a4D5F62E3E68) |
| SignatureReplay | `0xE53bDb085a46F426b5e8f1856aE998f64A0d6201` | [View](https://sepolia.etherscan.io/address/0xE53bDb085a46F426b5e8f1856aE998f64A0d6201) |
| ERC20Payment | `0x48CB11A2C520EcCf6fD4117C5d649050EDBEcDBd` | [View](https://sepolia.etherscan.io/address/0x48CB11A2C520EcCf6fD4117C5d649050EDBEcDBd) |
| SecureProxy | `0xf9b11F8ABfFaCb3f7840494F7203F9973B690530` | [View](https://sepolia.etherscan.io/address/0xf9b11F8ABfFaCb3f7840494F7203F9973B690530) |
| MockERC20 | `0x375749681C3BE13D39ECFe717993f0AF554BD0C0` | [View](https://sepolia.etherscan.io/address/0x375749681C3BE13D39ECFe717993f0AF554BD0C0) |
| ProxyImplementation | `0x7FF1BA37D87534BF4a2958b7485a1E4BeB6efb04` | [View](https://sepolia.etherscan.io/address/0x7FF1BA37D87534BF4a2958b7485a1E4BeB6efb04) |

---

## Local Setup

### Prerequisites

- Node.js 22.13.1 (use nvm)
- Python 3.11
- Git

### Install
```bash
git clone https://github.com/ms-trix/DevSecOps-Smart-Contract-Pipeline.git
cd DevSecOps-Smart-Contract-Pipeline
npm ci
pip install slither-analyzer
```

### Run Security Analysis Locally
```bash
# Slither static analysis
slither contracts/basic/ --json slither-basic.json
slither contracts/advanced/ --json slither-advanced.json

# Custom detector
python3 slither_detectors/run_detector.py contracts/advanced/SecureProxy.sol

# Mythril deep audit
pip install mythril==0.24.7 setuptools==69.5.1
python3 scripts/deep-audit.py contracts/basic/Bank.sol --timeout 60 --depth 10
```

### Run Tests
```bash
npx hardhat test mocha
```

### Deploy to Sepolia

Create a `.env` file:
```
SEPOLIA_RPC_URL=your_rpc_url
METAMASK_API=your_private_key
```
```bash
npx hardhat run scripts/deploy.js --network sepolia
```

---

## GitHub Secrets Required

| Secret | Purpose |
|---|---|
| `SEPOLIA_RPC_URL` | Sepolia RPC endpoint |
| `METAMASK_API` | Deployer private key |
| `CLAUDE_API_KEY` | Anthropic API for AI remediation |
| `AWS_ROLE_ARN` | IAM role for OIDC authentication |

---

## Repository Structure
```
├── .github/workflows/
│   ├── security.yml          — Main CI/CD pipeline
│   └── ai-remediation.yml    — AI remediation pipeline
├── contracts/
│   ├── basic/                — Fixed production contracts
│   ├── advanced/             — Fixed advanced contracts
│   ├── exploits/             — Attack/exploit contracts
│   └── vulnerable/           — Vulnerable reference contracts
├── scripts/
│   ├── deploy.js             — Deploys all contracts to Sepolia
│   └── deep-audit.py         — Mythril CLI tool
├── slither_detectors/
│   ├── run_detector.py       — Custom unprotected initializer detector
│   └── unprotected_initializer.py
├── terraform/                — AWS infrastructure as code
├── test/                     — Hardhat proof-of-exploit tests
└── audit-reports/            — Local Mythril JSON reports
```

---

## Screenshots
### AI Remediation Pipeline — Full Run
Once the CI pipeline fails, the AI remediation pipeline triggers automatically via `workflow_run`. It downloads the Slither artifact, runs Mythril symbolic execution, calls the Claude API, uploads the report to S3, and posts a PR comment — all without human intervention.

<img width="321" height="233" alt="Screenshot 2026-04-02 at 13 18 49" src="https://github.com/user-attachments/assets/d0aabb93-9b25-4fa3-b996-ba5054573150" />
<img width="1346" height="784" alt="Screenshot 2026-04-02 at 13 18 25" src="https://github.com/user-attachments/assets/16267a16-0d06-4868-bd22-f254020cd16e" />

<br> 

### AWS S3 — Persistent Report Storage

Every pipeline run uploads its Slither JSON report to S3. AI remediation reports are stored separately. Reports are retained indefinitely with AES-256 encryption and versioning enabled.

<img width="548" height="703" alt="Screenshot 2026-04-02 at 13 25 11" src="https://github.com/user-attachments/assets/3ba7c835-bf38-48ef-8804-8f213b57cfa6" />
<img width="531" height="111" alt="Screenshot 2026-04-02 at 13 25 40" src="https://github.com/user-attachments/assets/f37f48e9-23d3-406f-bbb5-469675e377ed" />

### CloudWatch — Live Pipeline Logs

Every pipeline run pushes a structured log event to CloudWatch with the result, branch name, and run ID. The AI remediation pipeline pushes a separate event confirming the report was generated successfully.

<img width="930" height="378" alt="Screenshot 2026-04-02 at 13 29 00" src="https://github.com/user-attachments/assets/e9f8a525-176c-4c35-b53d-d8338538d5a6" />
<img width="697" height="35" alt="Screenshot 2026-04-02 at 13 28 26" src="https://github.com/user-attachments/assets/44a22f02-5046-4de9-bdb6-47df9c1164fc" />
