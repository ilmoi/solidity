- [Solidity Cheatsheet and Best practices](#solidity-cheatsheet-and-best-practices)
  * [General gotchas](#Gotchas)
  * [Units](#Units)
  * [Version pragma](#version-pragma)
  * [Import files](#import-files)
  * [Types](#types)
    + [Boolean](#boolean)
    + [Integer](#integer)
    + [Decimals](#decimal)
    + [Address](#address)
      - [balance](#balance)
      - [transfer and send](#transfer-and-send)
      - [call](#call)
      - [delegatecall](#delegatecall)
      - [callcode](#callcode)
    + [Array](#array)
    + [Fixed byte arrays](#fixed-byte-arrays)
    + [Dynamic byte arrays](#dynamic-byte-arrays)
    + [Enum](#enum)
    + [Struct](#struct)
    + [Mapping](#mapping)
  * [Control Structures](#control-structures)
  * [Functions](#functions)
    + [Structure](#structure)
    + [Access modifiers](#access-modifiers)
    + [Parameters](#parameters)
      - [Input parameters](#input-parameters)
      - [Output parameters](#output-parameters)
    + [Constructor](#constructor)
    + [Function Calls](#function-calls)
      - [Internal Function Calls](#internal-function-calls)
      - [External Function Calls](#external-function-calls)
      - [Named Calls](#named-calls)
      - [Unnamed function parameters](#unnamed-function-parameters)
    + [Function type](#function-type)
    + [Function Modifier](#function-modifier)
    + [View or Constant Functions](#view-or-constant-functions)
    + [Pure Functions](#pure-functions)
    + [Payable Functions](#payable-functions)
    + [Fallback Function](#fallback-function)
    + [Virtual/override](#virtual-override)
  * [Contracts](#contracts)
    + [Creating contracts using `new`](#creating-contracts-using--new-)
    + [Contract Inheritance](#contract-inheritance)
      - [Multiple inheritance](#multiple-inheritance)
      - [Constructor of base class](#constructor-of-base-class)
    + [Abstract Contracts](#abstract-contracts)
  * [Interface](#interface)
  * [Events](#events)
  * [Library](#library)
  * [Using - For](#using---for)
  * [Error Handling](#error-handling)
  * [Global variables](#global-variables)
    + [Block variables](#block-variables)
    + [Transaction variables](#transaction-variables)
    + [Mathematical and Cryptographic Functions](#mathematical-and-cryptographic-functions)
    + [Contract Related](#contract-related)


## Gotchas
- there is no null / everything intialized with a 0
- abi = json file that exposes the methods of your contract. It's what's used to actually interact with it
  - each fn gets a signature
    - first 4 bytes of the [keccak256](https://emn178.github.io/online-tools/keccak_256.html) hash of the function signature = `bytes4(keccak256(fn_sig))`
    - fn_sig = just the name for fn w/o args, eg `fnName()` 
    - otherwise also types of args eg `fnName(int256, addr  ess)`
  - for setters we also pad the fn_sig until 32bytes and add the actual arguments
  - web3.js does all this for you

## Gas
gas amount
- execution cost (in gas) = simply the sum of gas costs of each of the OPCODEs, as defined in [ethereum yellowpaper](https://www.luno.com/blog/en/post/understanding-ethereum-fees-how-gas-works)
- transaction cost = execution cost + pay for tx itself, SC creation, and the size of data field
- loops use a lot of gas, so you should avoid using them as much as possible

## Units

### Ether units
- wei (1 wei == 1)
- gwei (1 gwei == 1e9)
- finney [REMOVED in .7]
- szabo [REMOVED in .7]
- ether (1 ether == 1e18)

### Time units
- 1 == 1 seconds
- 1 minutes == 60 seconds
- 1 hours == 60 minutes
- 1 days == 24 hours
- 1 weeks == 7 days
- 1 years == 365 days


## Version pragma

`pragma solidity ^0.5.2;`  will compile with a compiler version  >= 0.5.2 and < 0.6.0.


## Import files

`import "filename";`

`import * as symbolName from "filename";` or `import "filename" as symbolName;`

`import {symbol1 as alias, symbol2} from "filename";`


## Types

### Boolean

`bool` : `true` or `false`

Operators:

- Logical : `!` (logical negation), `&&` (AND), `||` (OR)
- Comparisons : `==` (equality), `!=` (inequality)

### Integer

Unsigned : `uint8 | uint16 | uint32 | uint64 | uint128 | uint256(uint)`

Signed   : `int8  | int16  | int32  | int64  | int128  | int256(int) `

Operators:

- Comparisons: `<=`, `<`, `==`, `!=`, `>=` and `>`
- Bit operators: `&`, `|`, `^` (bitwise exclusive or) and `~` (bitwise negation)
- Arithmetic operators: `+`, `-`, unary `-`, unary `+`, `*`, `/`, `%`, `**` (exponentiation), `<<` (left shift) and `>>` (right shift)

Since solidity .8 underflows/overflows are not allowed by the compiler. If you actually wanted variables to under/overflow you would use `unchecked` like [here](https://ethereum-blockchain-developer.com/010-solidity-basics/03-integer-overflow-underflow/).

Playing with integers:
```solidity
uint8 public three = 3;

uint8 public neg_three = ~three; //252 NOTE: !three doesn't work in solidity on non-bools
uint8 public xor_three = three ^ 1; //2
uint8 public and_three = three & 1; //1
uint8 public or_three = three | 1; //3

uint8 public masked_three = three & 0xf0; //0

uint8 public rshifted_three = three >> 1; //1
uint8 public lshifted_three = three << 2; //12
```

### Decimals

- there are no decimals in solidity, instead you simply define everything in wei
    - ie there are no fixed point number nor floating point numbers
    - in case you’re curious [here’s how fixed point works](https://www.youtube.com/watch?v=QFlbvSeBkwY)


### Address

`address`: Holds an Ethereum address (20 byte value).

`address payable` : Same as address, but includes additional methods `transfer` and `send`
- to convert to payable we might have to `payable(x)` - [more](https://ethereum-blockchain-developer.com/020-escrow-smart-contract/04-withdraw-to-specific-account/)

Operators:

- Comparisons: `<=`, `<`, `==`, `!=`, `>=` and `>`

Methods:

#### balance

- `<address>.balance (uint256)`: balance of the Address in Wei
- NOTE: when calling `.balance` on `this` we first need to do: `address(this).balance` - [more](https://ethereum-blockchain-developer.com/020-escrow-smart-contract/04-withdraw-to-specific-account/)

#### transfer and send

- `<address>.transfer(uint256 amount)`: send given amount of Wei to Address, **throws** on failure
- `<address>.send(uint256 amount) returns (bool)`: send given amount of Wei to Address, **returns false** on failure

#### call
- `<address>.call(...) returns (bool)`: issue low-level CALL, returns false on failure
- can be used to:
  1. Call existing fn
  2. Call non-existing fn and thus trigger fallback
- syntax: `(bool success, bytes memory data) = addr.call.value(msg.value).gas(12345)(abi.encodeWithSignature("foo(string, uin256)"))` [explainer](https://www.youtube.com/watch?v=mz10sUmEdsM)
- NOTE: it is NOT the recommended way to call fns in other contracts, since it's easy to mess up the signature

#### delegatecall
- `<address>.delegatecall(...) returns (bool)`: issue low-level DELEGATECALL, returns false on failure
- when contract A calls contract B using delegatecall, it's basically running B's code inside of its own (A's) context (msg.sender, msg.value, etc)
- 2 things to remember when using delegatecall to prevent attack:
  - it preserves context [eg](https://www.youtube.com/watch?v=bqn-HzRclps)
  - in order for delegate call to work, storage layout must be the same for both A and B (ie both must declare same variables in same order) [eg](https://www.youtube.com/watch?v=oinniLm5gAM&list=PLO5VPQH6OWdWsCgXJT9UuzgbC8SPvTRi5&index=15)

```solidity
contract A {
  uint value;
  address public sender;
  address a = address(0); // address of contract B
  function makeDelegateCall(uint _value) public {
    a.delegatecall(
        abi.encodePacked(bytes4(keccak256("setValue(uint)")), _value)
    ); // Value of A is modified
  }
}

contract B {
  uint value;
  address public sender;
  function setValue(uint _value) public {
    value = _value;
    sender = msg.sender; // msg.sender is preserved in delegatecall. It was not available in callcode.
  }
}
```

> gas() option is available for call, callcode and delegatecall. value() option is not supported for delegatecall.

#### callcode
- `<address>.callcode(...) returns (bool)`: issue low-level CALLCODE, returns false on failure

> Prior to homestead, only a limited variant called `callcode` was available that did not provide access to the original `msg.sender` and `msg.value` values.

### Array

Arrays can be dynamic or have a fixed size.
- better use mappings instead of arrays due to gas consumption

```solidity
uint[] dynamicSizeArray;
uint[7] fixedSizeArray up to 32;
uint[][5] //5 dynamically sized arrays (reversed notation, be careful)
```

### Fixed byte arrays

`bytes1(byte)`, `bytes2`, `bytes3`, ..., `bytes32`.

Operators:

- Comparisons: `<=`, `<`, `==`, `!=`, `>=`, `>` (evaluate to bool)
- Bit operators: `&`, `|`, `^` (bitwise exclusive or), `~` (bitwise negation), `<<` (left shift), `>>` (right shift)
- Index access: If x is of type bytesI, then `x[k]` for 0 <= k < I returns the k th byte (read-only).

Members

- `.length` : read-only
- `.push`

### Dynamic byte arrays

`bytes`: Dynamically-sized `byte` array. It is similar to `byte[]`, but it is packed tightly in calldata. Not a value-type!

`string`: 
- Not a value-type!!!!!
- Dynamically-sized UTF-8-encoded string. It is equal to `bytes` but does not allow LENGTH or INDEX access. 
- When using need to define location "memory" or "storage" - see [this](https://ethereum-blockchain-developer.com/010-solidity-basics/05-string-types/)
- We should try to AVOID using strings in solidity if possible - EXPENSIVE and CUMBERSOME

### Enum

Enum works just like in every other language.

```solidity
enum ActionChoices { 
  GoLeft, 
  GoRight, 
  GoStraight, 
  SitStill 
}

ActionChoices choice = ActionChoices.GoStraight;
```

### Struct

New types can be declared using a struct.
- NOT recursive (can't have a member of struct be of same type as struct itself)
- Structs are more gas-efficient than objects: instead of creating a new contract with public variables/methods and then referencing it - just use a struct.
- can have a mapping inside the struct

```solidity
struct Funder {
    address addr;
    uint amount;
    mapping(address => bool) whitelist;
}

Funder funders;
```

### Mapping

Declared as `mapping(_KeyType => _ValueType)`

Mappings 
- can be seen as **hash tables / dicts**
- are initialized with 0s/false/etc 
- dont have a length (so if you need it, you have to calculate/store manually) 

**key** can be almost any type except for 1)mapping, 2)dynamically sized array, 3)contract, 4)enum, 5)struct. **value** can actually be any type, including mappings.


## Control Structures

Most of the control structures from JavaScript are available in Solidity except for `switch` and `goto`. 

- `if` `else`
- `while`
- `do`
- `for`
- `break`
- `continue`
- `return`
- `? :`

## Functions

- functions DO NOT RETURN A VALUE to the tx sender (it shows with JS VM but not on real blockchain)

Can be read-only (`call`) or read-write (`transaction`).
- calls are instant, free, and done against your local copy of the bc
- calls don't need to be mined, and so don't consume gas (it does but you pay yourself)
- calls are done when a function is marked as `view` or `pure`

### Structure

`function (<parameter types>) {internal|external|public|private} [pure|constant|view|payable] [virtual|override] [returns (<return types>)]`

### Access modifiers

- ```public``` - Accessible from this contract, inherited contracts and externally
- ```private``` - Accessible only from this contract
- ```internal``` - Accessible only from this contract and contracts inheriting from it
- ```external``` - Cannot be accessed internally, only externally. MORE EXPENSIVE THAN INTERNAL TO CALL FROM WITHIN THE CTR. Access internally with `this.f`.

### Parameters

#### Input parameters

Parameters are declared just like variables and are `memory` variables.

```solidity
function f(uint _a, uint _b) {}
```

#### Output parameters

Output parameters are declared after the `returns` keyword

```solidity
function f(uint _a, uint _b) returns (uint _sum) {
   _sum = _a + _b;
}
```

Output can also be specified using `return` statement. In that case, we can omit parameter name `returns (uint)`.

Multiple return types are possible with `return (v0, v1, ..., vn)`.


### Constructor

Function that is executed during contract deployment. Defined using the `constructor` keyword.

```solidity
contract C {
   address owner;
   uint status;
   constructor(uint _status) {
       owner = msg.sender;
       status = _status;
   }
}
```

### Function Calls

#### Internal Function Calls

Functions of the current contract can be called directly (internally - via jumps) and also recursively

```solidity
contract C {
    function funA() returns (uint) { 
       return 5; 
    }
    
    function FunB(uint _a) returns (uint ret) { 
       return funA() + _a; 
    }
}
```

#### External Function Calls

`this.g(8);` and `c.g(2);` (where c is a contract instance) are also valid function calls, but, the function will be called “externally”, via a message call.

> `.gas()` and `.value()` can also be used with external function calls.

#### Named Calls

Function call arguments can also be given by name in any order as below.

```solidity
function f(uint a, uint b) {  }

function g() {
    f({b: 1, a: 2});
}
```

#### Unnamed function parameters

Parameters will be present on the stack, but are not accessible.

```solidity
function f(uint a, uint) returns (uint) {
    return a;
}
```

### Function type

Pass function as a parameter to another function. Similar to `callbacks` and `delegates`

```solidity
pragma solidity ^0.4.18;

contract Oracle {
  struct Request {
    bytes data;
    function(bytes memory) external callback;
  }
  Request[] requests;
  event NewRequest(uint);
  function query(bytes data, function(bytes memory) external callback) {
    requests.push(Request(data, callback));
    NewRequest(requests.length - 1);
  }
  function reply(uint requestID, bytes response) {
    // Here goes the check that the reply comes from a trusted source
    requests[requestID].callback(response);
  }
}

contract OracleUser {
  Oracle constant oracle = Oracle(0x1234567); // known contract
  function buySomething() {
    oracle.query("USD", this.oracleResponse);
  }
  function oracleResponse(bytes response) {
    require(msg.sender == address(oracle));
  }
}
```


### Function Modifier

Modifiers can automatically check a condition prior to executing the function.

```solidity
modifier onlyOwner {
    require(msg.sender == owner);
    _;
}

function close() onlyOwner {
    selfdestruct(owner);
}
```

### View or Constant Functions

Functions can be declared `view` or `constant`:
- reads the state but doens't modify it
- doesn't need to be mined
- is free of charge and instant
- can call other pure or view fns, not writing fns
- "constant" is the old name, it has since been replaced with "view" and "pure"

```solidity
function f(uint a) view returns (uint) {
    return a * b; // where b is a storage variable
}
```

> The compiler does not enforce yet that a `view` method is not modifying state.

### Pure Functions

Functions can be declared `pure`:
- doesn't read OR modify the state
- think functional programming
- can only call other view fns, not pure or writing fns

```solidity
function f(uint a) pure returns (uint) {
    return a * 42;
}
```

### Payable Functions

Functions that receive `Ether` are marked as `payable` function.

### Fallback Function

Unnamed functions don't exist anymore - they have been replaced with 2 fns:
1. `receive` fn - called when no other fn matches AND money sent along
2. `fallback` fn - called when no other fn matches AND NO money sent along

These functions 
- cannot have arguments / cannot return anything
- if these are absent and the caller sends ether w/o specifying a fn to call, the tx will fail
- however, you can't completely prevent your contract from receiving ether. 3 ways you can't stop:
  - if you call `selfdestruct` on another contract and pass this contract's address as `owner`
  - if you are mining
  - if the address you're deploying the contract to already had some ether before you deployed

```solidity
receive() external payable {
  // Do something
}

fallback() external payable {
  // Do something
}
```

### Virtual Override
`virtual` = function in parent we want to override
- if absent, then the function CANT be overriden
- `private` fns can't be `virtual`
- fns w/o implementation have to be marked `virtual` outside of interfaces
- in interfaces all fns automatically considered `virtual`

`override` = function that does the overriding
- for multiple inheritance, if fn present in each parent, we MUST override at child level

```solidity
contract Base1 {
    function foo() virtual public {}
}

contract Base2 {
    function foo() virtual public {}
}

contract Inherited is Base1, Base2 {
    // Derives from multiple bases defining foo(), so we must explicitly override it
    function foo() public override(Base1, Base2) {}
}
```

## Contracts

### Creating contracts using `new`

Contracts can be created from another contract using `new` keyword. The source of the contract has to be known in advance.

```solidity
contract A {
    function add(uint _a, uint _b) returns (uint) {
        return _a + _b;
    }
}

contract C {
    address a;
    function f(uint _a) {
        a = new A(); //since we're spawning a new contract, use an interface where possible (cheaper)
    }
}
```

### Contract Inheritance

Solidity supports multiple inheritance and polymorphism.

```solidity
contract owned {
    function owned() { owner = msg.sender; }
    address owner;
}

contract mortal is owned {
    function kill() {
        if (msg.sender == owner) selfdestruct(owner);
    }
}

contract final is mortal {
    function kill() { 
        super.kill(); // Calls kill() of mortal.
    }
}
```

#### Multiple inheritance

functions from B would overwrite function from A (so last parent is most important)

```solidity
contract A {}
contract B {}
contract C is A, B {}
```

#### Constructor of base class

```solidity
contract A {
    uint a;
    constructor(uint _a) { a = _a; }
}

contract B is A(1) {
    constructor(uint _b) A(_b) {
    }
}
```


### Abstract Contracts

`abstract` contracts 
- has only 1 req: that at least 1 fn that is defined is not implemented
- they are typically used as base for inhereting

```solidity
pragma solidity ^0.4.0;

abstract contract A {
    function C() returns (bytes32);
}

contract B is A {
    function C() returns (bytes32) { return "c"; }
}
```

## Interface

`Interfaces` are similar to abstract contracts, but have more restrictions:

- Cannot have any functions implemented, only show their declarations.
- Cannot inherit other contracts / but can inherit from other interfaces.
- Cannot define constructor.
- Cannot define variables.
- Cannot define structs.
- Cannot define enums.

In terms of abstractions, from most specific to least: contract > abstract contract > interfeace


```solidity
pragma solidity ^0.4.11;

interface Token {
    function transfer(address recipient, uint amount);
}
```

## Events

Events are stored on a "logging" sidechain.
- can be used as **trigger** for off-chain activity (Eg your wallet might do smthn when an event happens)
- can be used for **data storage** - much cheaper than storing data on main chain
    - use ipfs for more complex data types, but use events for strings
- you can "index" up to 3 params, which will make them searchable later on
- note that you CAN access events FROM OUTSIDE but NOT FROM INSIDE
- inheritable (kids get it)

> All non-indexed arguments will be stored in the data part of the log.

```solidity
pragma solidity ^0.4.0;

contract ClientReceipt {
    event Deposit(
        address indexed _from,
        bytes32 indexed _id,
        uint _value
    );

    function deposit(bytes32 _id) payable {
        emit Deposit(msg.sender, _id, msg.value);
    }
}
```

## Library

Libraries:
- are similar to contracts (can have variables, functions), but start with keyword `library`
- are defined exactly once and can be re-used by multiple contracts
- can't inherit or be inherited
- can't receive ether
- under the hood, their code is used with [`delegatecall`](#delegatecall) (`callcode`)

There are [2 types of libraries](https://www.youtube.com/watch?v=25MLAnIzXRw):
1. Deployed - standard one, where one lib can service multiple SC
2. Embedded - where all fns inside the lib are `internal` and so its deployed at the same address as the SC

Simple example:
```solidity
// SPDX-License-Identifier: MIT
library MyLib {
    function add10(uint a) public pure returns(uint) {
        return a+10;
    }
}

contract A {
    function TenTen() public pure returns(uint) {
        return MyLib.add10(10);
    }
}
```

More sophisticated example, where we're using a type which itself is defined in the lib:
```solidity
library MyLib {
    //note how we define the struct inside the library
    struct Player {
        uint score;    
    }
    
    function incrScore(Player storage _player, uint _points) public {
        _player.score += _points;
    }
}

contract A {
    mapping(uint => MyLib.Player) public players;
    
    function incrFirstPlayerScore() public {
        MyLib.incrScore(players[0], 10);
    }
}
```


## Using - For

can be used to attach a library to any type, including one defined in the library itself. Eg extending the above example we can rewrite contract A as follows:

```solidity
contract A {
    using MyLib for MyLib.Player; //add this line
    
    mapping(uint => MyLib.Player) public players;
    
    function incrFirstPlayerScore() public {
        players[0].incrScore(10); //notice how this changed
    }
}
```

## Error Handling

- `assert(bool condition)`: throws if the condition is not met - to be used for internal errors.
  - at bytecode level throws `0xfe`
  - CONSUMES ALL GAS
  - should only be triggered by a genuine SC error - this is not a routine check
  - does not let you return an error string
  - cases when triggered:
    - mnanually by the user    
    - by all standard internal errors (Eg div by 0)
- `require(bool condition)`: throws if the condition is not met - to be used for errors in inputs or external components.
  - at bytecode level throws `0xfd`
  - RETURNS REMAINING GAS
  - use this for routine checks on user inputs
  - lets you return an error string
  - cases when triggered:
    - manually by the user
    - function call via message call that doesn't finish properly
    - external function call to a SC not containing code
    - your contract receives ether w/o a payable modifier
    - your contract received ether as a getter/view fn
    - address.transfer() fails
- `revert()`: abort execution and revert state changes 
  - works exactly like `require` that evals to `false`
  - solidity docs are indifferent to using revert or require
- NOTE: `throw` is now deprecated. Don't use it.
- Catching exceptions is not possible in solidity.
- Errors cascade except for low-level functions - `address.send`, `address.call`, `address.delegatecall`, `address.staticcall`

```solidity
 function sendHalf(address addr) payable returns (uint balance) {
    require(msg.value % 2 == 0); // Only allow even numbers
    uint balanceBeforeTransfer = this.balance;
    addr.transfer(msg.value / 2);
    assert(this.balance == balanceBeforeTransfer - msg.value / 2);
    return this.balance;
}
```



## Global variables

### Block variables

- `block.blockhash(uint blockNumber) returns (bytes32)`: hash of the given block - only works for the 256 most recent blocks excluding current
- `block.coinbase (address)`: current block miner’s address
- `block.difficulty (uint)`: current block difficulty
- `block.gaslimit (uint)`: current block gaslimit
- `block.number (uint)`: current block number
- `block.timestamp (uint)`: current block timestamp as seconds since unix epoch
- `now (uint)`: current block timestamp (alias for `block.timestamp`)

### Transaction variables

- `msg.data (bytes)`: complete calldata
- `msg.gas (uint)`: remaining gas
- `msg.sender (address)`: sender of the message (current call)
- `msg.sig (bytes4)`: first four bytes of the calldata (i.e. function identifier)
- `msg.value (uint)`: number of wei sent with the message
- `tx.gasprice (uint)`: gas price of the transaction
- `tx.origin (address)`: sender of the transaction (full call chain)

### Mathematical and Cryptographic Functions

- `addmod(uint x, uint y, uint k) returns (uint)`:
   compute (x + y) % k where the addition is performed with arbitrary precision and does not wrap around at 2**256.
- `mulmod(uint x, uint y, uint k) returns (uint)`:
   compute (x * y) % k where the multiplication is performed with arbitrary precision and does not wrap around at 2**256.
- `keccak256(...) returns (bytes32)`:
   compute the Ethereum-SHA-3 (Keccak-256) hash of the (tightly packed) arguments
- `sha256(...) returns (bytes32)`:
   compute the SHA-256 hash of the (tightly packed) arguments
- `sha3(...) returns (bytes32)`:
   alias to keccak256
- `ripemd160(...) returns (bytes20)`:
   compute RIPEMD-160 hash of the (tightly packed) arguments
- `ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) returns (address)`:
   recover the address associated with the public key from elliptic curve signature or return zero on error (example usage)
   
### Contract Related
- `this (current contract’s type)`: the current contract, explicitly convertible to Address
- `selfdestruct(address recipient)`: destroy the current contract, sending its funds to the given Address
  - might go away in the future - [link](https://hackmd.io/@vbuterin/selfdestruct)
  - there's a new opcode `CREATE2` that lets you deploy a new contract to a specific address, including one you just called `selfdestruct` on [link](https://eips.ethereum.org/EIPS/eip-1014)
- `suicide(address recipient)`: alias to selfdestruct. Soon to be deprecated.

