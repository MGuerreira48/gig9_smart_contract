pragma solidity ^0.4.11;

import "./I_ERC223.sol";
import "./I_ERC223ReceivingContract.sol";
import "./L_SafeMath.sol";
import "./L_ReceiverInterface.sol";

contract Token is ERC223 {
	
	string  tokenName;
    string public tokenSymbol;
	uint8 public tokenDecimals;
	
	address admin;
	uint public totalSupply;
	
    using SafeMath for uint;
	
	mapping (address => uint256) public balances;
	mapping (address => bool) public frozenAccount;
	
	event Transfer(address indexed from, address indexed to, uint value, bytes data);
	
    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }
	
	function Token(string _tokenName, string _tokenSymbol, uint8 _tokenDecimals, uint8 _totalSupply) public {
	
		tokenName = _tokenName;
		tokenSymbol = _tokenSymbol;
		tokenDecimals = _tokenDecimals;
		
		totalSupply = _totalSupply;
		
		admin = msg.sender;
		balances[admin] = _totalSupply;
		totalSupply = _totalSupply;	
	}
	
	function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
      
		if(isContract(_to)) {
			if (balanceOf(msg.sender) < _value) revert();
			balances[msg.sender] = SafeMath.sub(balanceOf(msg.sender), _value);
			balances[_to] = SafeMath.add(balanceOf(_to), _value);
			assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
			Transfer(msg.sender, _to, _value, _data);
			return true;
		}
		else {
			return transferToAddress(_to, _value, _data);
		}
	}
  
	function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
		  
		if(isContract(_to)) {
			return transferToContract(_to, _value, _data);
		}
		else {
			return transferToAddress(_to, _value, _data);
		}
	}
  
	function transfer(address _to, uint _value) public returns (bool success) {
      
		bytes memory empty;

		if(isContract(_to)) {
			return transferToContract(_to, _value, empty);
		}
		else {
			return transferToAddress(_to, _value, empty);
		}
	}

	function isContract(address _addr) private view returns (bool is_contract) {
		
		uint length;
		
		assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
		}
      
		return (length>0);
    }

	function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
	
		if (balanceOf(msg.sender) < _value) revert();
		
		balances[msg.sender] = SafeMath.sub(balanceOf(msg.sender), _value);
		balances[_to] = SafeMath.add(balanceOf(_to), _value);
		
		Transfer(msg.sender, _to, _value, _data);
		
		return true;
	}
  
	function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
		if (balanceOf(msg.sender) < _value) revert();
		balances[msg.sender] = SafeMath.sub(balanceOf(msg.sender), _value);
		balances[_to] = SafeMath.add(balanceOf(_to), _value);
		ContractReceiver receiver = ContractReceiver(_to);
		receiver.tokenFallback(msg.sender, _value, _data);
		Transfer(msg.sender, _to, _value, _data);
		return true;
	}
}