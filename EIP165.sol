// tutorial: https://medium.com/coinmonks/ethereum-standard-erc165-explained-63b54ca0d273

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// -----------------------------------------------------------------------------
// store contract with the intefraces it's using

contract StoreInterfaceId {
  bytes4 internal constant STORE_INTERFACE_ID = 0x75b24222;
}

abstract contract StoreInterface is StoreInterfaceId {
  function getValue() external view virtual returns (uint256);
  function setValue(uint256 v) external virtual;
}

interface ERC165 {
  function supportsInterface(bytes4 interfaceID)
    external view returns (bool);
}

contract Store is ERC165, StoreInterface {
  uint256 internal value;
  function getValue() external view override returns (uint256) {
    return value;
  }
  function setValue(uint256 v) external override {
    value = v;
  }
  function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
    return interfaceId == STORE_INTERFACE_ID;
  }
}

// -----------------------------------------------------------------------------
// NOTstore with intentionally wrong interface

// this one doesn't pass the check
contract NotStore is ERC165 {
  uint256 internal value;
  function setValue(uint256 v) external {
    value = v;
  }
  function getNoValue() external view returns (uint256) {
    return value;
  }
  function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
    return interfaceId == 0x01ffc9a7 ||
           interfaceId == 0x01ffc9a7;
  }
}

// -----------------------------------------------------------------------------
// store reader that uses store contract

// interacts with the interface
contract StoreReader {
  function readStoreValue(address store) external view returns (uint256) {
        // we're casting store into an interface of type ERC165
        // this lets us call one of its methods .supportsInterface()
        if (ERC165(store).supportsInterface(0x75b24222)) {
            // we're casting store into an interface of type StoreInterface
            // this lets us call one of its methods .getValue()
            return StoreInterface(store).getValue();
        }
        return 11111; //weird value just to know the if check failed above
    }
}


// -----------------------------------------------------------------------------
// clac the intefaceId value
//how do you get the actual interface Id?
//ERC165 defines that an interface ID can be calculated as the XOR of all function selectors in the interface.

contract Selector {
  function calcStoreInterfaceId() external pure returns (bytes4) {
    StoreInterface i;
    // nice didn't know you could do method.selector
    return i.getValue.selector ^ i.setValue.selector; // returns 0x75b24222
  }
}


// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
//another tutorial - https://www.youtube.com/watch?v=mWOkmmEMHYc

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 2 steps involves:
// 1)calc interface id
// 2)publish it via a specific fn called supportsInterface

contract B {
    mapping(bytes4 => bool) private _interfaces;
    
    constructor() {
        _interfaces[calcInterfaceId()] = true;
        _interfaces[bytes4(keccak256("foo()"))] = true;
        _interfaces[bytes4(keccak256("bar()"))] = true;
        _interfaces[0x01ffc9a7] = true; //this is the interface of the supportsInterface function itself as per https://eips.ethereum.org/EIPS/eip-165
    }
    
    function calcInterfaceId() public pure returns(bytes4) {
        //method 1 - the manual way
        // return bytes4(keccak256("foo()")) ^ bytes4(keccak256("bar()"));
        //method 2 - more automatic
        B b; //instantiate a local copy of the contract
        return b.foo.selector ^ b.bar.selector;
    }
    
    function supportsInterface(bytes4 interfaceId) public view returns(bool) {
        return _interfaces[interfaceId];
    }
    
    function foo() external pure returns(uint) {
        return 1234;
    }
    
    function bar() external pure returns(uint) {
        return 4321;
    }
}

interface IB {
    function calcInterfaceId() external pure returns(bytes4);
    function supportsInterface(bytes4 interfaceId) external view returns(bool);
    function foo() external pure returns(uint);
    function bar() external pure returns(uint);
}

contract A {
    function callFoo(address _addressOfB) public view returns(bool) {
        //for play
        bytes4 interfaceId = bytes4(keccak256("foo()"));
        
        // note the below implementation is simplified
        // the rec'ed way to check if interface is implemented is a 5 step process described here https://eips.ethereum.org/EIPS/eip-165
        
        //notice how we instantiate the contract: ContractName(contractAddress)
        //note that if contract B was in another file we'd first import it, but otherwise we'd instantiate it exactly the same
        //notice that we're using the interface, rather than the contract itself. This is because WE DONT NEED TO IMPORT THE ENTIRE CONTRACT - it consumers too much gas
        //julian explains all of this in detail here - https://www.youtube.com/watch?v=YxU87o4U5iw
        if (IB(_addressOfB).supportsInterface(interfaceId)) {
            IB(_addressOfB).foo();
            return true;
        } else {
            revert('contract B doesnt support fn of interest.');
        }
    }
}

// erc 165 led to erc 1820 which led to erc 777


// -----------------------------------------------------------------------------
// newer versions of solidity

//Using type(T).interfaceId automatically computes ERC165 interface id from the corresponding Interface, removing the need to hardcode it - https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2487