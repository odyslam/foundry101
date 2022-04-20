// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {NomadBase, XAppConnectionManager} from "../NomadBase.sol";

contract NomadBaseTest is Test {
    NomadBase nomadBase;
    XAppConnectionManager xAppConMngr;

    function setUp() public {
        nomadBase = new NomadBase(0xEf989866b66a491e7B6c7473D73b589450D0f766);
        // use cast interface to easily print the interface of any deployed smart contract
        xAppConMngr = XAppConnectionManager(
            0xFe8874778f946Ac2990A29eba3CFd50760593B2F
        );
    }

    function test_getMessage() public {
        bytes32 oldRoot = "Solidity";
        bytes32 newRoot = " Summit";
        uint32 domain = 1000;
        bytes memory testMessage = abi.encodePacked(domain, oldRoot, newRoot);
        bytes memory message = nomadBase.getMessage(oldRoot, newRoot);
        assertEq(keccak256(testMessage), keccak256(message));
    }

    function test_getLocalDomain() public {
        uint32 localDomain = xAppConMngr.localDomain();
        assertEq(6648936, localDomain);
    }

    function test_replicaToDomain() public {
        uint32 localMilkomedaDomain = nomadBase.replicaToDomain(
            nomadBase.milkomedaReplica()
        );
        uint32 remoteMilkomedaDomain = xAppConMngr.replicaToDomain(
            nomadBase.milkomedaReplica()
        );
        assertEq(localMilkomedaDomain, 25393);
        assertEq(remoteMilkomedaDomain, 25393);
    }

    function test_fuzz_replicaToDomain(address replica) public {
        uint32 domain = nomadBase.replicaToDomain(replica);
        assertEq(0, domain);
    }
}
