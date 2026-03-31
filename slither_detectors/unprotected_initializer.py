"""
Module detecting unprotected initializer functions in proxy contracts
An unprotected initializer is a function that sets owner/admin state
but has no access control, allowing anyone to call it and take ownership
"""
from slither.core.declarations.contract import Contract
from slither.core.declarations.function_contract import FunctionContract
from slither.detectors.abstract_detector import (
    AbstractDetector,
    DetectorClassification,
    DETECTOR_INFO,
)
from slither.utils.output import Output


class UnprotectedInitializer(AbstractDetector):
    """
    Unprotected initializer detector
    """

    ARGUMENT = "unprotected-initializer"
    HELP = "Initializer function callable by anyone"
    IMPACT = DetectorClassification.HIGH
    CONFIDENCE = DetectorClassification.HIGH

    WIKI = "https://github.com/crytic/slither/wiki/Detector-Documentation"
    WIKI_TITLE = "Unprotected Initializer"
    WIKI_DESCRIPTION = (
        "An initializer function sets owner or admin state variables "
        "but has no access control. Anyone can call it and take ownership."
    )

    WIKI_EXPLOIT_SCENARIO = """
```solidity
contract Proxy {
    address public owner;

    function initialize() public {
        owner = msg.sender;
    }
}
```
Attacker calls `initialize()` after deployment and becomes the owner."""

    WIKI_RECOMMENDATION = (
        "Add access control to initializer functions. "
        "Use OpenZeppelin's Initializable contract with the `initializer` modifier, "
        "or add a require check ensuring the function can only be called once."
    )

    @staticmethod
    def _is_initializer(func: FunctionContract) -> bool:
        name = func.name.lower()
        return name == "initialize" or name.startswith("init")

    @staticmethod
    def _writes_to_owner_or_admin(func: FunctionContract) -> bool:
        sensitive_names = ["owner", "admin", "operator", "governance"]
        for var in func.all_state_variables_written():
            if var.name.lower() in sensitive_names:
                return True
        return False

    @staticmethod
    def _is_unprotected(func: FunctionContract) -> bool:
        return not func.is_protected()

    def _detect_unprotected_initializer(
            self, contract: Contract
    ) -> list[FunctionContract]:
        results = []
        for func in contract.functions_declared:
            if func.is_constructor:
                continue
            if func.visibility not in ["public", "external"]:
                continue
            if not self._is_initializer(func):
                continue
            if not self._writes_to_owner_or_admin(func):
                continue
            if not self._is_unprotected(func):
                continue
            results.append(func)
        return results

    def _detect(self) -> list[Output]:
        """Detect unprotected initializer functions"""
        results = []
        for contract in self.contracts:
            funcs = self._detect_unprotected_initializer(contract)
            for func in funcs:
                nodes = [n for n in func.nodes if n.source_mapping]
                if not nodes:
                    continue
                info: DETECTOR_INFO = [
                    func,
                    " is an unprotected initializer that sets owner/admin state. "
                    "Anyone can call this function and take ownership.\n",
                    nodes[0],
                    "\n",
                ]
                res = self.generate_result(info)
                results.append(res)
        return results