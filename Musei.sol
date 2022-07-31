// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    constructor() ERC20("TESTTOKEN", "TTTTTT") {
        _mint(msg.sender, 1000000000 );
    }
}

contract GameItems is ERC1155 {
    uint256 public constant GOLD = 0;
    uint256 public constant SILVER = 1;
    uint256 public constant THORS_HAMMER = 2;
    uint256 public constant SWORD = 3;
    uint256 public constant SHIELD = 4;

    constructor() ERC1155("https://game.example/api/item/{id}.json") {
        _mint(msg.sender, GOLD, 10**18, "");
        _mint(msg.sender, SILVER, 10**27, "");
        _mint(msg.sender, THORS_HAMMER, 1, "");
        _mint(msg.sender, SWORD, 10**9, "");
        _mint(msg.sender, SHIELD, 10**9, "");
    }
}

contract staking is Ownable {

    IERC20 public token;
    IERC1155 public nft;
    AggregatorV3Interface internal priceFeed;

    uint public votingCount = 1;
    uint public fee;
    uint public voteNeed = 100;

    event DepositedNFT(address who, address nftAddr, uint id, uint amount, uint time);
    event WithdrawNFT(address to, address nftAddr, uint id, uint amount, uint time);
    event TransferOwnership(address from, address to, address nftAddr, uint id, uint amount, uint time);

    constructor (IERC20 _address){
        token = _address;
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e); //Поменять на нужный оракул
    }

    struct Voting {
        address owner;
        address nftAddr;
        uint id;
        uint amount;
        uint time;
        uint vote;
        uint comission;
        uint pool;
    }

    mapping(address => mapping (uint => uint)) public lockedTokens; //who -> number of voting -> amount of locked

    function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }

    mapping(uint => Voting) public numberToVote; //number of voting -> voting
    mapping(uint => address) public numberToOwner; //number of voting to owner

    //Перед стейком пользователь должен сделать Approve
    function createVoting (address _nftAddr, uint _id, uint _amount, uint _time) external payable{
        require(msg.value >= fee); 
        require(msg.sender != address(0) && _time > 0  && _amount > 0);
        nft = IERC1155(_nftAddr);
        nft.safeTransferFrom(msg.sender, address(this), _id, _amount, "");
        numberToVote[votingCount] = Voting(msg.sender, _nftAddr, _id, _amount, block.timestamp+_time, 0, (msg.value/100*95), 0);
        numberToOwner[votingCount] = msg.sender;
        votingCount++;
        emit DepositedNFT(msg.sender, _nftAddr, _id, _amount, block.timestamp);
    }

    function voteForNFT(uint number, uint amount, bool _for) external {
        require(token.balanceOf(msg.sender) > 0);
        require(block.timestamp < numberToVote[number].time);
        require(lockedTokens[msg.sender][number] == 0);
        token.transferFrom(msg.sender, address(this), amount);
        lockedTokens[msg.sender][number] = amount;
        numberToVote[number].pool += amount;
        if (_for) {
            numberToVote[number].vote++;
        } else {
            numberToVote[number].vote--;
        }
    }

    function withdrawToken(uint number) external {
        require(block.timestamp > numberToVote[number].time);
        require(lockedTokens[msg.sender][number] > 0);
        uint balance = lockedTokens[msg.sender][number];
        uint reward = calcReward(number);
        lockedTokens[msg.sender][number] = 0;
        token.transfer(msg.sender, balance);
        payable(msg.sender).transfer(reward);
    }

    function calcReward(uint number) internal view returns(uint reward) {
        uint perc = lockedTokens[msg.sender][number] / numberToVote[number].pool * 100;
        reward = numberToVote[number].comission/100*perc;
    }
 
    function withdrawNFT(uint _number) external {
        require(numberToVote[_number].owner == msg.sender, "Not an owner!");
        require(numberToVote[_number].time > block.timestamp, "Still locked");
        nft.safeTransferFrom (address(this), msg.sender, numberToVote[_number].id, numberToVote[_number].amount, "");
        emit WithdrawNFT(msg.sender, numberToVote[_number].nftAddr, numberToVote[_number].id, numberToVote[_number].amount, block.timestamp);
    }

    function transferOwner(address _newOwner, uint _number) external {
        require(numberToVote[_number].owner == msg.sender, "Not an owner!");
        require(numberToVote[_number].time > block.timestamp, "Still locked");
        numberToVote[_number].owner = _newOwner;
        emit TransferOwnership(msg.sender, _newOwner, numberToVote[_number].nftAddr, numberToVote[_number].id, numberToVote[_number].amount, block.timestamp);
    }

    function changeFee(uint _newFee) external onlyOwner {
        require(_newFee <= 1 ether, "incorrect fee");
        fee = _newFee;
    }

    function changeVoteNeed(uint _voteNeed) external onlyOwner {
        require(_voteNeed > 1, "incorrect vote amount");
        fee = _voteNeed;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }




}