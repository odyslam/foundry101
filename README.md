# Foundry 101

A short practical introduction Foundry

## Me

![](https://user-images.githubusercontent.com/13405632/164205664-f5593ed9-8539-4d0e-aec1-647595c97a07.png)

## Agenda

- Forge, 10 minutes
- Cast, 2 minutes
- Q&A, 3 minutes

## Goals

- Not just a simple showcase of all functionality. Read the docs!
- TL;DR some best practices and mental models that will get you productive immediately
- Cover as much as possible , but leave time for discussion


## Forge

- Directory structure
- Tests structure -- fixture
- Traces
- Cheatcodes
- Mainnet Forking
- Fuzzing
- Debugger
- Deploy
- Hardhat --> Foundry

### Forge setup

- Install Foundry
    - https://getfoundry.sh/
- Init a directory with a good template
    - It has ds-test, written by dapphub and offers some helper functions

### Default setup

```
├── foundry.toml
├── lib
│   └── ds-test
│       ├── default.nix
│       ├── demo
│       ├── LICENSE
│       ├── Makefile
│       └── src
└── src
    ├── Contract.sol
    └── test
        └── Contract.t.sol
```

```
foundry init --template https://github.com/abigger87/femplate
```

## Forge basics

- Every test is a `public` or `external` function that starts with `test`
- We break up tests logically in different contracts
- Every contract has a single `setUp` function that is called before every `testFunction`.
- It's best to logically divide our fixtures into different contracts that form an inheritance chain:
    - Pattern: https://github.com/gakonst/v3-periphery-foundry/blob/main/contracts/foundry-tests/utils/Deploy.sol
    - Anti-Pattern: https://github.com/pentagonxyz/gov-of-venice/blob/master/src/test/utils/gov2Test.sol
    - It's best because we can easily inspect the fixtures. We could do the same in a single `setUp` function.
    - We can either use the same `setUp()` function by having it virtual and every fixture calling the `setUp()`, or we can use different functions.
- gas-report is an estimate by forge on how much gas it thinks that each function of your smart contract will consume.
- gas-snapshot is a good tool to easily start gas optimizing your contracts. The more fine-grained tests you have, the more accurate the gas report will be. Ideally, each unit-test should test a single thing either-way, so that's another forcing function for keeping good testing hygiene. It's best to add gas-snapshot to the CI and inspect the diff in git-versioning. You can easily see if some change to the underline code resulted in change to the gas cost of test function, as it will show in the diff of the new commit/PR.port.
- Mocks: Create smart contracts that mock the behaviour of external smart contracts or actors. For example, a mockERC20 that is like ERC-20, but where you can mint `freely`
- Suggested libraries:
    - forge-std: https://github.com/foundry-rs/forge-std
        - DSTest
        - console.log
        - stdCheats
        - helper functions to write to files 🔜
    - solmate: https://github.com/Rari-Capital/solmate
        - Opinionated and gas-optized smart contracts. Alternative to Open-Zeppelin (although it doesn't cover all implementations)

### Forge Mainnet Forking
- You can `fork` at current block or specified. If specified, it's cached.
- Now, call traces will show the functions that are executed in remote contracts as well. Before it would just show contract and signature, but we download source code from etherscan and you can see what contract executed what function.
- Example with test_localDomain().
- You can use `cast interface` to easily get the interface signature of some contract on etherscan

### Cheatcodes

```
interface CheatCodes {
    // Set block.timestamp
    function warp(uint256) external;

    // Set block.number
    function roll(uint256) external;

    // Set block.basefee
    function fee(uint256) external;

    // Loads a storage slot from an address
    function load(address account, bytes32 slot) external returns (bytes32);

    // Stores a value to an address' storage slot
    function store(address account, bytes32 slot, bytes32 value) external;

    // Signs data
    // example: NomadBase.t.sol
    function sign(uint256 privateKey, bytes32 digest) external returns (uint8 v, bytes32 r, bytes32 s);

    // Computes address for a given private key
    // example: NomadBase.t.sol
    function addr(uint256 privateKey) external returns (address);

    // Gets the nonce of an account, aka how many transactions the account has sent
    function getNonce(address account) external returns (uint64);

    // Sets the nonce of an account
    // The new nonce must be higher than the current nonce of the account
    function setNonce(address account, uint256 nonce) external;

    // Performs a foreign function call via terminal.
    // example: https://github.com/libevm/subway/blob/master/contracts/src/test/Sandwich.t.sol
    // Nomad: cross-chain communication. Run subsequent tests with different --rpc-url and use file-based read/writes to emulate off-chain agents, all without leaving solidity (except for the bash script that executes subsequent forge test with different --rpc-url)
    function ffi(string[] calldata) external returns (bytes memory);

    // Sets the *next* call's msg.sender to be the input address
    // example: see startPrank
    function prank(address) external;

    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called
    // example: https://github.com/gakonst/v3-periphery-foundry/blob/67d6f43d8151531e6351d766343cc92daaa7dae4/contracts/foundry-tests/SwapRouter.t.sol#L56
    function startPrank(address) external;

    // Sets the *next* call's msg.sender to be the input address, and the tx.origin to be the second input
    function prank(address, address) external;

    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called, and the tx.origin to be the second input
    function startPrank(address, address) external;

    // Resets subsequent calls' msg.sender to be `address(this)`
    function stopPrank() external;

    // Sets an address' balance
    function deal(address who, uint256 newBalance) external;

    // Sets an address' code
    function etch(address who, bytes calldata code) external;

    // Expects an error on next TOP-LEVEL call. If an underlying call reverts but the top-level doesn't (due to some try/catch), then it won't fire.
    function expectRevert() external;
    function expectRevert(bytes calldata) external;
    function expectRevert(bytes4) external;

    // Record all storage reads and writes
    function record() external;

    // Gets all accessed reads and write slot from a recording session, for a given address
    function accesses(address) external returns (bytes32[] memory reads, bytes32[] memory writes);

    // Prepare an expected log with (bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData).
    // Call this function, then emit an event, then call a function. Internally after the call, we check if
    // logs were emitted in the expected order with the expected topics and data (as specified by the booleans)
    function expectEmit(bool, bool, bool, bool) external;

    // Mocks a call to an address, returning specified data.
    // Calldata can either be strict or a partial match, e.g. if you only
    // pass a Solidity selector to the expected calldata, then the entire Solidity
    // function will be mocked.
    function mockCall(address, bytes calldata, bytes calldata) external;

    // Clears all mocked calls
    function clearMockedCalls() external;

    // Expect a call to an address with the specified calldata.
    // Calldata can either be strict or a partial match
    function expectCall(address, bytes calldata) external;

    // Gets the bytecode for a contract in the project given the path to the contract.
    function getCode(string calldata) external returns (bytes memory);

    // Label an address in test traces
    // Example: NomadBase.t.sol
    function label(address addr, string calldata label) external;

    // When fuzzing, generate new inputs if conditional not met
    // Useful for limiting the range of the fuzzer
    function assume(bool) external;
}
```

### Forge debugger

- Top left we have the PC, which shows us what OPCODE will be executed by the EVM
- OPCODES: https://www.evm.codes/
- Everything highlighted: is not tied to a function, it's setup for the contract
- Example: `forge test --debug test_getMessage`
-
### Hardhat --> Foundry

- You can still use Hardhat for complex deployments and test using Foundry
- describe -> contract
- `beforeEach`-> `setUp`
- To install testing libraries that don't live in a `npm` package, you can still use `forge  install` and `/lib` for ease of use.
- There are two partners for creating actors that interact with the smart contracts:
    - Before we had `vm.prank`, we would create a smart contract that called the smart contract under test. The `user` smart contract would be a simple wrapper. This is now mostly an anti-pattern.
        - Example: https://github.com/pentagonxyz/gov-of-venice/blob/master/src/test/utils/gov2Test.sol
    - Use `vm.prank()` and call all the functions we want to call, using some addressed that we have generated with `vm.addr()`. It reduces the boilerplate considerably.
    - In essence, instead of creating complex actors, we just create addresses. No more boilerplate code.
- Example structure
```
/── contracts
/── node_modules
/── forge-tests
    /── Contract.t.sol
```
- Example migration:
    - Hardhat: https://github.com/nomad-xyz/nomad-monorepo/blob/main/typescript/nomad-tests/test/common.test.ts
    - Foundry: https://github.com/odyslam/monorepo/tree/feat/foundry-tests/packages/contracts-core/contracts/test

### Fuzzer

- It's as simple as adding an input to the test function
- The fuzzer will pick random inputs that are of the same input type
- You can limit the inputs with `vm.assume()`
- The fuzzer dictionary will also be enriched with any state changes that happens in your smart contract. It will also be enriched with non-random extreme values (e.g UINT256.max)
- It's good
-
## Deploy

- To deploy our smart contracts, we use forge create and then forge verify-contract to verify the contracts on etherscan
- This command will be deprecated in the coming months, as we will support the ability to deploy through solidity scripts. That means that we can replace existing deployment pipelines with Solidity.

```
ETH_RPC_URL=https://eth-rinkeby.alchemyapi.io/v2/pmyDZ_qaFpuamRt-daJztGtgZUv6eowD && forge create --rpc-url $ETH_RPC_URL "0xD9f3c9CC99548bF3b44a43E0A2D07399EB918ADc" --etherscan-api-key $ETHERSCAN_API_KEY src/NomadBase.sol:NomadBase --private-key $PRIVATE_KEY

forge verify-contract --compiler-version $CMPLR $CONTRACT src/NomadBase.sol:NomadBase $ETHERSCAN_API_KEY --chain-id 4

```
## Cast

- swiss-army knife tool to interact with the chain
- cast call & cast send are the main commands to easily send arbitrary transactions or read the state of the chain
- cast was very useful to script deployment and configuration pipelines. With the upcoming release of `foundry deploy`, when we will write our deployment scripts in solidity, that use-case shouldn't be needed
- That being said, configuration scripting could still be useful, example: https://github.com/pentagonxyz/gov-of-venice/blob/master/scripts/deploy-guild.sh

## Next

- Forge node (Anvil)
- Forge deploy
- Forge fmt
- Forge docs

## CTA

- Install Foundry: https://getfoundry.sh/
- Read the book: https://book.getfoundry.sh/
- Join our Telegram groups: https://github.com/foundry-rs/foundry
- Use Foundry in your project and let us know: https://github.com/crisgarner/awesome-foundry
- Open GH issues with any bugs you find (please share a reproduction repo of the bug)
- Open issues with UX improvements and new features (+ usecase)
- Contribute!
    - Rust beginners: cast is easy to understand and simple features can bring huge UX improvements. Search for `good first issues` tag on GH
    - Dive into Forge! Look for bugs and comment that you want to work on fixing it.
    - Ask in the telegram group for what's in the pipeline and let us know you wan to work on something

## kudos
- Georgios Konstantopoulos
- Matt Seitz
- Oliver Nordbjerg
- Brock Elmore
- Lucas Manuel
