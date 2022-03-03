// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";

contract FChecker {
    using Counters for Counters.Counter;
    address private addressOfAdmin;
    address private addressOfJournalist;
    address private addressOfFactChecker;
    Counters.Counter private requestIdCounter;

    enum RequestStatus {
        RECEIVED,
        ANSWERED,
        VERIFIED,
        REJECTED
    }

    struct Request {
        string requestMessage;
        string responseMessage;
        RequestStatus status;
        address assignedJournalist;
        address assignedFactChecker;
    }

    mapping(uint256 => Request) private requestIdToRequestMapping;
    uint256[] private receivedRequests;
    uint256[] private answeredRequests;

    constructor() {
        addressOfAdmin = msg.sender;
    }

    modifier isAdmin() {
        require(msg.sender == addressOfAdmin, "Entity not an Admin");
        _;
    }

    modifier isJournalist() {
        require(msg.sender == addressOfJournalist, "Entity not a Jounalist");
        _;
    }

    modifier isFactChecker() {
        require(msg.sender == addressOfFactChecker, "Entity not a FactChecker");
        _;
    }

    function addJournalist(address _addressOfJournalist) external isAdmin {
        addressOfJournalist = _addressOfJournalist;
    }

    function addFactChecker(address _addressOfFactChecker) external isAdmin {
        addressOfFactChecker = _addressOfFactChecker;
    }

    function newRequest(string calldata requestMessage)
        private
        pure
        returns (Request memory)
    {
        Request memory _request;
        _request.requestMessage = requestMessage;
        _request.status = RequestStatus.RECEIVED;
        return _request;
    }

    function request(string calldata requestString)
        external
        returns (uint256 requestId)
    {
        requestId = requestIdCounter.current();
        requestIdCounter.increment();
        Request memory _request = newRequest(requestString);
        requestIdToRequestMapping[requestId] = _request;
        receivedRequests.push(requestId);
    }

    function checkRequestStatus(uint256 requestId)
        external
        view
        returns (Request memory _request)
    {
        _request = requestIdToRequestMapping[requestId];
    }

    function pickByJounalist()
        external
        isJournalist
        returns (uint256 requestId, Request memory _request)
    {
        requestId = receivedRequests.length - 1;
        receivedRequests.pop();
        requestIdToRequestMapping[requestId].assignedJournalist = msg.sender;
        _request = requestIdToRequestMapping[requestId];
    }

    function submitByJournalist(
        uint256 requestId,
        string calldata responseMessage
    ) external isJournalist {
        require(
            msg.sender ==
                requestIdToRequestMapping[requestId].assignedJournalist,
            "Not Authorized to respond"
        );
        requestIdToRequestMapping[requestId].status = RequestStatus.ANSWERED;
        requestIdToRequestMapping[requestId].responseMessage = responseMessage;
        answeredRequests.push(requestId);
    }

    function pickByFactChecker()
        external
        isFactChecker
        returns (uint256 requestId, Request memory _request)
    {
        requestId = answeredRequests.length - 1;
        answeredRequests.pop();
        requestIdToRequestMapping[requestId].assignedFactChecker = msg.sender;
        _request = requestIdToRequestMapping[requestId];
    }

    function submitByFactChecker(uint256 requestId, bool isResponseCorrect)
        external
        isFactChecker
    {
        require(
            msg.sender ==
                requestIdToRequestMapping[requestId].assignedFactChecker,
            "Not Authorized to respond"
        );
        requestIdToRequestMapping[requestId].status = isResponseCorrect
            ? RequestStatus.VERIFIED
            : RequestStatus.REJECTED;
    }
}
