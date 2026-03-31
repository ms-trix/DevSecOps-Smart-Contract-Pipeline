#!/usr/bin/env python3
"""
Custom Slither detector for unprotected initializer functions.
Detects initialize() functions that write to owner/admin state
but have no access control protection.
"""
import sys
import json
from slither.slither import Slither


def detect_unprotected_initializers(target: str) -> list:
    sl = Slither(target)
    findings = []
    sensitive_names = ["owner", "admin", "operator", "governance"]

    for contract in sl.contracts:
        for func in contract.functions_declared:
            if func.is_constructor:
                continue
            if func.visibility not in ["public", "external"]:
                continue

            name = func.name.lower()
            if not (name == "initialize" or name.startswith("init")):
                continue

            vars_written = [v.name for v in func.all_state_variables_written()]
            writes_sensitive = any(
                v.lower() in sensitive_names for v in vars_written
            )
            if not writes_sensitive:
                continue

            if func.is_protected():
                continue

            source = func.source_mapping
            findings.append({
                "contract": contract.name,
                "function": func.name,
                "file": source.filename.relative if source else "unknown",
                "lines": list(source.lines) if source else [],
                "impact": "High",
                "confidence": "High",
                "description": (
                    f"{contract.name}.{func.name}() is an unprotected initializer "
                    f"that writes to {vars_written}. "
                    f"Anyone can call this and take ownership."
                ),
                "recommendation": (
                    "Add access control. Use OpenZeppelin Initializable "
                    "with the initializer modifier, or add a require check "
                    "ensuring the function can only be called once."
                )
            })

    return findings


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 run_detector.py <target>")
        sys.exit(1)

    target = sys.argv[1]
    findings = detect_unprotected_initializers(target)

    if findings:
        print(f"\n[UNPROTECTED-INITIALIZER] Found {len(findings)} issue(s):\n")
        for f in findings:
            print(f"  Contract : {f['contract']}")
            print(f"  Function : {f['function']}")
            print(f"  File     : {f['file']} (lines {f['lines']})")
            print(f"  Impact   : {f['impact']}")
            print(f"  Issue    : {f['description']}")
            print(f"  Fix      : {f['recommendation']}")
            print()
        sys.exit(1)
    else:
        print("[UNPROTECTED-INITIALIZER] No issues found.")
        sys.exit(0)