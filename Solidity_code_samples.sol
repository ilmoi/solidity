pragma solidity ^0.8.1;

// -----------------------------------------------------------------------------
// moving around funds

contract ReceiveAndSendMoney {
    
    // artificial variable that we created
    uint public balanceReceived;
    
    uint public lockedUntil;
    
    function receiveMoney() public payable {
        balanceReceived += msg.value; //easy to forget to update elsewhere in the code
        lockedUntil = block.timestamp + 1 minutes; //note how we add minutes
    }
    
    function getBalance() public view returns(uint) {
        // note how we have to cast "this" into an address for it to have address methods
        return address(this).balance;
    }
    
    function withdrawMoney() public {
        // same with msg.sender - we have to cast it to be able to pay out to it
        address payable to = payable(msg.sender);
        to.transfer(getBalance());
    }
    
    function withdrawMoneyToAddress(address payable _to) public {
        _to.transfer(getBalance());
    }
    
    function withdrawMoneyAfter1Min(address payable _to) public {
        //check if 1 min passed since deposit, and only then continue
        if(lockedUntil < block.timestamp) {
            _to.transfer(getBalance());
        }
    }
}

// -----------------------------------------------------------------------------
// ownership, pausing, selfdestruct

contract OwnerControlled {
    
    address public owner;
    
    bool public paused;
    
    constructor() {
        owner = msg.sender;
    }
    
    // receives money into the contract
    function addFunds() public payable {
    }
    
    // pays money out from the contract to desired address
    function withdrawFunds(address payable _to) public {
        require(msg.sender == owner, "you are not the owner!");
        require(!paused, "contract is paused!");
        _to.transfer(address(this).balance);
    }
    
    // can change the pause setting, which pauses the contract
    function setPause(bool _paused) public {
        require(msg.sender == owner, "you are not the owner!");
        paused = _paused;
    }
    
    function destroyContract(address payable _to) public {
        require(msg.sender == owner, "you are not the owner!");
        selfdestruct(_to);
    }
    
}

// -----------------------------------------------------------------------------
// mappings and structs

contract MappingsAndStructs {
    
    struct Payment {
        uint amount;
        uint timestamp;
    }
    
    struct Balance {
        uint totalBalance;
        uint numPayments; // for now this records payments in, but not payments out
        mapping(uint => Payment) payments;
    }
    
    mapping(address => Balance) deposits;
    
    function sendMoney() public payable {
        // add total balance
        deposits[msg.sender].totalBalance += msg.value;
        // add a new payment to the array
        Payment memory new_payment = Payment(msg.value, block.timestamp);
        deposits[msg.sender].payments[deposits[msg.sender].numPayments] = new_payment;
        // increment total payment count (important to do AFTER adding the payment)
        deposits[msg.sender].numPayments++;
    }
    
    function getTotalBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function withdrawAllMoney() public {
        //checks effects intraction pattern - https://fravoll.github.io/solidity-patterns/checks_effects_interactions.html
        uint balanceToSend = deposits[msg.sender].totalBalance;
        deposits[msg.sender].totalBalance = 0;
        payable(msg.sender).transfer(balanceToSend);
    }
    
    function withdrawSomeMoney(uint _amount) public {
        require(_amount <= deposits[msg.sender].totalBalance, "not enough funds");
        deposits[msg.sender].totalBalance -= _amount;
        payable(msg.sender).transfer(_amount);
    }
    
}

// -----------------------------------------------------------------------------
// exception handling - assert and require

pragma solidity ^0.5.1;

contract ExceptionExample {
    
    mapping(address => uint64) public deposits;
    
    function receiveMoney() public payable {
        // check that after receiving money we dont end up with less than we started with
        assert(deposits[msg.sender] + uint64(msg.value) >= deposits[msg.sender]);
        
        deposits[msg.sender] += uint64(msg.value);
    }
    
    function withdrawMoney(uint _amount) public {
        // note how an "if" statement wouldn't do here - it wouldn't throw an error and give user no feedback
        require(_amount <= deposits[msg.sender], "not enough balance");
        
        // check that we don't send more than we can
        assert(deposits[msg.sender] >= deposits[msg.sender] - _amount);
        
        deposits[msg.sender] -= uint64(_amount);
        msg.sender.transfer(_amount);
    }
    
}

// -----------------------------------------------------------------------------
// events

contract EventExample {
    
    address owner;
    
    // here we define the event
    event TokensMoved(address _from, address _to, uint _amo);
    
    mapping(address => uint) public tokenBalance;
    
    constructor() {
        owner = msg.sender;
        tokenBalance[owner] = 100;
    }
    
    function sendToken(address _to, uint _amount) public returns(bool) {
        require(tokenBalance[owner] >= _amount, "not enough balance");
        assert(tokenBalance[_to] + _amount >= tokenBalance[_to]);
        assert(tokenBalance[owner] - _amount <= tokenBalance[owner]);
        
        tokenBalance[owner] -= _amount;
        tokenBalance[_to] += _amount;
        
        // here we emit the event - which will now appear in trx logs
        emit TokensMoved(owner, _to, _amount);
        
        // this in turn will not appear or be available externally in any way
        return true;
    }
}

// -----------------------------------------------------------------------------
// libraries

pragma solidity ^0.4.23;

//import the lib - remix lets us do via url
import "https://github.com/ConsenSysMesh/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol";

contract LibrariesExample {
    
    //we're automatically giving all the methods available in SafeMath to uint as a datatype
    using SafeMath for uint;
    
    mapping(address => uint) public tokenBalance;
    
    constructor() public {
        tokenBalance[msg.sender] = tokenBalance[msg.sender].add(1); //safemath to add 1
    }
    
    function sendToken(address _to, uint _amount) public returns(bool) {
        tokenBalance[msg.sender] = tokenBalance[msg.sender].sub(_amount); //safemath
        tokenBalance[_to] = tokenBalance[_to].add(_amount); //safemath
        
        return true;
    }
}

//we can also write our own library with keyword "library" instead of "contract" as per docs example here - https://docs.soliditylang.org/en/v0.5.13/contracts.html#libraries

// -----------------------------------------------------------------------------
// practice - shared wallet contracts

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Allowance is Ownable {
    
    event AllowanceChange(address indexed _forWhom, address indexed _byWhom, uint _oldAmount, uint _newAmount);
    
    mapping(address => uint) allowances;
    
    function isOwner() internal view returns(bool) {
        return owner() == msg.sender;
    }
    
    modifier hasPermission(uint _amount) {
        require(isOwner() || _amount <= allowances[msg.sender], "NOT ALLOWED!");
        _;
    }
    
    function changeAllowance(address _user, uint _newAmount) public onlyOwner {
        emit AllowanceChange(_user, msg.sender, allowances[_user], _newAmount);
        allowances[_user] = _newAmount;
    }
}

contract SharedWallet is Allowance {
    
    event MoneySent(address indexed _where, uint _amount);
    event MoneyReceived(address indexed _fromWhere, uint _amount);
    
    receive() external payable {
        emit MoneyReceived(msg.sender, msg.value);
    }
    
    function getTotalBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function withdrawMoney(uint _amount) public hasPermission(_amount) {
        require(_amount <= address(this).balance, "not enough money!");
        payable(msg.sender).transfer(_amount);
        emit MoneySent(msg.sender, _amount);
    }
    
    //overwrite renounceOwnership function
    function renounceOwnership() public override onlyOwner view {
        revert('this functionality has been removed from the contract!');
    }
    
}

// -----------------------------------------------------------------------------