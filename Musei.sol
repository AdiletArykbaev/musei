// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

contract Musei{
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event StartAuction();
    event Bid(address indexed sender,uint amount);
    event Withdraw(address indexed bidder,uint amount);
    event End(address highestBidder,uint amount);

   IERC1155 public immutable parentNFT;
   uint public immutable nftId;
   address private _owner;
   address payable public seller;
   uint32 public endAt;
   bool public started; 
   bool public ended;

   address public highestBidder;
   uint public highestBid;

   mapping(address => uint) public bids; 
   mapping(address => uint256) public stakingTime;    
   mapping(address => Stake) public stakes;

    struct Stake {
        uint256 tokenId;
        uint256 amount;
        uint256 timestamp;
    }
  constructor () {
    address msgSender = msg.sender;
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }
  
   function auctionData(address _nft,uint _nftId,uint _startingBid) public payable {
       parentNFT = IERC1155(_nft);
       nftId = _nftId;
       seller = payable(msg.sender);
       highestBid = _startingBid;
   }
   function startAuction() external {
       require(msg.sender == seller, "Not seller");
       require(!started,"Started");

       started = true;
       endAt = uint32(block.timestamp + 1 days);
       parentNFT.transferFrom(seller, address(this), nftId);

       emit StartAuction();
   }
   function endAuction() external {
       require(started,"Not started");
       require(!ended,"Ended");
       require(block.timestamp >=endAt,"Not ended");

       ended = true;
       if(highestBidder != address(0)) {
           parentNFT.transferFrom(address(this),highestBidder,nftId);
           seller.transfer(highestBid);
       } else {
           parentNFT.transferFrom(address(this),seller,nftId);
       }
       emit End(highestBidder,highestBid);
   }

   function bid() external payable {
       require(started,"Not started");
       require(block.timestamp < endAt,"Ended");
       require(msg.value > highestBid,"little bid");

        if(highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        highestBid = msg.value;
        highestBidder = msg.sender;

        emit Bid(msg.sender,msg.value);
   }

    function withdraw() external {
        uint uBid = bids[msg.sender];
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(uBid);

        emit Withdraw(msg.sender,uBid);
    }

   function paytosmart() public payable{
      
   }
       
   function getParentNft(address nft) public{
        parentNFT = IERC1155(nft);
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

}