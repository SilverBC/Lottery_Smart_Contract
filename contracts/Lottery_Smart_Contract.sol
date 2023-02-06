// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";


contract Lottery_Smart_Contract is VRFV2WrapperConsumerBase, ConfirmedOwner {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords, uint256 payment);

    struct RequestStatus {
        uint256 paid;
        bool fulfilled;
        uint256[] randomWords;
    }

    mapping(uint256 => RequestStatus) public s_requests;
    mapping(uint256 => address payable) public winnersByLottery;

    uint256[] public requestIds;
    uint256 public lastRequestId;
    uint256 public lotteryID;

    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    address linkAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address wrapperAddress = 0x708701a1DfF4f478de54383E49a627eD4852C816;
    address payable[] public players;


    constructor() ConfirmedOwner(msg.sender) VRFV2WrapperConsumerBase(linkAddress, wrapperAddress){
        lotteryID = 0;
    }


    receive() external payable {

    }

    fallback() external payable{

    }

    function requestRandomWords() external onlyOwner returns (uint256 requestId){
        requestId = requestRandomness( callbackGasLimit, requestConfirmations, numWords);

        s_requests[requestId] = RequestStatus({ paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
                                                randomWords: new uint256[](0),
                                                fulfilled: false
                                                });

        requestIds.push(requestId);     
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);

        return requestId;                                   
    }

    function getRequestStatus(uint256 _requestId) external view returns (uint256 paid, bool fulfilled, uint256[] memory _randomWords){
        require(s_requests[_requestId].paid > 0, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.paid, request.fulfilled, request.randomWords);

    }

    function enter() public payable{
        require(msg.value > 0.001 ether);
        players.push(payable(msg.sender));

    }

    function getPlayers() public view returns(address payable[] memory ){
        return players;
    }
    
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    function getWinnerByLottery(uint lottery) public view returns(address payable){
        return winnersByLottery[lottery];
    }

    function pickWinner() public onlyOwner(){
        uint256 index = lastRequestId % players.length;
        players[index].transfer(address(this).balance);

        winnersByLottery[lotteryID++] = players[index];
        //lotteryID++;

        players = new address payable[](0);
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "unable to transfer");

    }


    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override{
        require(s_requests[_requestId].paid > 0, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;

        emit RequestFulfilled(_requestId, _randomWords, s_requests[_requestId].paid);

    }


}

