// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

contract NomadBase {
    uint32 domain = 1000;
    uint32 garbage = 1000;
    address public immutable milkomedaReplica;

    constructor(address _milkomedaReplica) {
        milkomedaReplica = _milkomedaReplica;
    }

    function getMessage(bytes32 oldRoot, bytes32 newRoot)
        public
        view
        returns (bytes memory)
    {
        bytes memory message = new bytes(68);
        assembly {
            let dom := sload(domain.slot)
            mstore(add(message, 32), dom)
            // mstore(add(message, 32), shl(224, dom))
            mstore(add(message, 36), oldRoot)
            mstore(add(message, 68), newRoot)
        }
        return message;
    }

    function replicaToDomain(address replica) external view returns (uint32) {
        if (replica == milkomedaReplica) {
            return 25393;
        } else {
            return 0;
        }
    }
}

interface XAppConnectionManager {
    function localDomain() external view returns (uint32);

    function replicaToDomain(address replica) external returns (uint32);

    function domainToReplica(uint32 domain) external returns (address);
}
