pragma solidity ^0.8.0;

contract Musei{
   uint256 public balance;
   address private owner;

   constructor() public{   
        owner=msg.sender;
    }
  
   function paytosmart(uint256 value) public payable{

   }
   
      function getBalance( address target) public view returns(uint256){
        return target.balance;
    }
    function getOwner(
    ) public view returns (address) {    
        return owner;
    }
}