// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// SECURE: Uses EIP-1967 standard storage slots to prevent storage collision
// Implementation slot: keccak256("eip1967.proxy.implementation") - 1
// Admin slot: keccak256("eip1967.proxy.admin") - 1
// These high entropy slots are extremely unlikely to collide with
// implementation contract variables stored in sequential slots 0, 1, 2...

contract SecureProxy {
    bytes32 private constant IMPLEMENTATION_SLOT =
    0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    bytes32 private constant ADMIN_SLOT =
    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    constructor(address _implementation) {
        bytes32 implSlot = IMPLEMENTATION_SLOT;
        bytes32 adminSlot = ADMIN_SLOT;
        assembly {
            sstore(implSlot, _implementation)
            sstore(adminSlot, caller())
        }
    }

    function getImplementation() public view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    function getAdmin() public view returns (address admin) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            admin := sload(slot)
        }
    }

    function upgradeTo(address newImplementation) public {
        bytes32 adminSlot = ADMIN_SLOT;
        bytes32 implSlot = IMPLEMENTATION_SLOT;
        assembly {
            if iszero(eq(caller(), sload(adminSlot))) {
                revert(0, 0)
            }
            sstore(implSlot, newImplementation)
        }
    }

    receive() external payable {}

    fallback() external payable {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            let impl := sload(slot)
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}