pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

contract Musei{
   IERC1155 public parentNFT;
   mapping(address => uint256) public stakingTime;    
   mapping(address => Stake) public stakes;

    struct Stake {
        uint256 tokenId;
        uint256 amount;
        uint256 timestamp;
    }
   constructor() public{   
        owner=msg.sender;
        parentNFT = IERC1155()
    }
  
   function paytosmart(uint256 value) public payable{
      
   }
       
       
     
    function stake(uint256 _tokenId, uint256 _amount) public {
        stakes[msg.sender] = Stake(_tokenId, _amount, block.timestamp); 
        parentNFT.safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "0x00");
    } 

    function unstake() public {
        parentNFT.safeTransferFrom(address(this), msg.sender, stakes[msg.sender].tokenId, stakes[msg.sender].amount, "0x00");
        stakingTime[msg.sender] += (block.timestamp - stakes[msg.sender].timestamp);
        delete stakes[msg.sender];
    }      
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

   function getBalance( address target) public view returns(uint256){
        return target.balance;
    }
    function getOwner(
    ) public view returns (address) {    
        return owner;
    }
}