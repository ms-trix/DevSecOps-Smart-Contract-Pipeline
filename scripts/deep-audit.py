#!/usr/bin/env python3
"""
Deep audit script using Mythril symbolic execution.
Runs a thorough analysis on a single contract and saves a timestamped report.

Usage:
    python3 scripts/deep-audit.py <contract_path> [--timeout 60] [--depth 10]

Examples:
    python3 scripts/deep-audit.py contracts/basic/Bank.sol
    python3 scripts/deep-audit.py contracts/vulnerable/basic/BankVulnerable.sol --timeout 120 --depth 15
"""

import argparse
import json
import os
import subprocess
import sys
from datetime import datetime


def parse_args():
    parser = argparse.ArgumentParser(
        description="Deep audit a Solidity contract using Mythril symbolic execution"
    )
    parser.add_argument(
        "contract",
        help="Path to the Solidity contract to analyze"
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=60,
        help="Execution timeout in seconds per transaction (default: 60)"
    )
    parser.add_argument(
        "--depth",
        type=int,
        default=10,
        help="Maximum transaction depth for symbolic execution (default: 10)"
    )
    return parser.parse_args()


def run_mythril(contract_path: str, timeout: int, depth: int) -> dict:
    print(f"\n[*] Running Mythril on {contract_path}")
    print(f"    Timeout: {timeout}s | Max depth: {depth}")
    print(f"    This may take several minutes...\n")

    cmd = [
        "myth", "analyze",
        contract_path,
        "--execution-timeout", str(timeout),
        "--max-depth", str(depth),
        "-o", "json"
    ]

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout * 10
        )
        output = result.stdout.strip()
        if output:
            return json.loads(output)
        return {"issues": [], "success": True}
    except subprocess.TimeoutExpired:
        print("[!] Mythril timed out during analysis")
        return {"issues": [], "success": False}
    except json.JSONDecodeError:
        print(f"[!] Could not parse Mythril output")
        return {"issues": [], "success": False}
    except FileNotFoundError:
        print("[!] myth command not found. Install with: pip install mythril")
        sys.exit(1)


def categorize_findings(issues: list) -> dict:
    categories = {
        "High": [],
        "Medium": [],
        "Low": [],
        "Informational": []
    }
    for issue in issues:
        severity = issue.get("severity", "Informational")
        if severity in categories:
            categories[severity].append(issue)
        else:
            categories["Informational"].append(issue)
    return categories


def print_summary(contract_path: str, categories: dict, report_path: str):
    total = sum(len(v) for v in categories.values())

    print("=" * 60)
    print("MYTHRIL DEEP AUDIT REPORT")
    print("=" * 60)
    print(f"Contract  : {contract_path}")
    print(f"Timestamp : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Total     : {total} issue(s) found")
    print("-" * 60)

    for severity in ["High", "Medium", "Low", "Informational"]:
        issues = categories[severity]
        if not issues:
            continue
        print(f"\n[{severity.upper()}] {len(issues)} issue(s):")
        for issue in issues:
            print(f"\n  Title    : {issue.get('title', 'Unknown')}")
            print(f"  SWC ID   : {issue.get('swc-id', 'N/A')}")
            print(f"  Function : {issue.get('function', 'N/A')}")
            print(f"  File     : {issue.get('filename', 'N/A')} "
                  f"(line {issue.get('lineno', 'N/A')})")
            print(f"  Code     : {issue.get('code', 'N/A')}")
            description = issue.get('description', '')
            if description:
                short_desc = description[:150] + "..." if len(description) > 150 else description
                print(f"  Detail   : {short_desc}")

    print("\n" + "-" * 60)
    print(f"Full report saved to: {report_path}")
    print("=" * 60)


def save_report(contract_path: str, categories: dict, raw_output: dict) -> str:
    os.makedirs("audit-reports", exist_ok=True)
    timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    contract_name = os.path.basename(contract_path).replace(".sol", "")
    report_path = f"audit-reports/{timestamp}-{contract_name}-mythril.json"

    report = {
        "timestamp": datetime.now().isoformat(),
        "contract": contract_path,
        "summary": {
            "high": len(categories["High"]),
            "medium": len(categories["Medium"]),
            "low": len(categories["Low"]),
            "informational": len(categories["Informational"]),
            "total": sum(len(v) for v in categories.values())
        },
        "findings": categories,
        "raw": raw_output
    }

    with open(report_path, "w") as f:
        json.dump(report, f, indent=2)

    return report_path


def main():
    args = parse_args()

    if not os.path.exists(args.contract):
        print(f"[!] Contract not found: {args.contract}")
        sys.exit(1)

    raw_output = run_mythril(args.contract, args.timeout, args.depth)
    issues = raw_output.get("issues", [])
    categories = categorize_findings(issues)
    report_path = save_report(args.contract, categories, raw_output)
    print_summary(args.contract, categories, report_path)

    high_and_medium = len(categories["High"]) + len(categories["Medium"])
    if high_and_medium > 0:
        print(f"\n[FAILED] {high_and_medium} High/Medium severity issue(s) found.")
        sys.exit(1)
    else:
        print("\n[PASSED] No High or Medium severity issues found.")
        sys.exit(0)


if __name__ == "__main__":
    main()