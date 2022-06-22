// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./NTTEvent.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Factory {
    using Counters for Counters.Counter;
    Counters.Counter private _contractIds;

    address private owner;

    event NTTContractCreated(
        uint256 contractId,
        address contractAddress,
        address creatorAddress,
        string title,
        string description,
        string[] links,
        string imageHash,
        string associatedCommunity,
        uint256 startDate,
        uint256 endDate
    );

    constructor() {
        owner = msg.sender;
    }

    function deployNTT(
        string memory _title,
        string memory _description,
        string[] memory _links,
        string memory _imageHash,
        string memory _associatedCommunity,
        uint256 _startDate,
        uint256 _endDate,
        address[] memory _list
    ) public returns (address) {
        _contractIds.increment();
        uint256 _id = _contractIds.current();

        NTTEvent nttEvent = new NTTEvent(
            msg.sender,
            _title,
            _description,
            _links,
            _imageHash,
            _associatedCommunity,
            _startDate,
            _endDate,
            _id,
            address(this)
        );

        nttEvent.addToWhitelist(_list);
        emit NTTContractCreated(
            _id,
            address(nttEvent),
            msg.sender,
            _title,
            _description,
            _links,
            _imageHash,
            _associatedCommunity,
            _startDate,
            _endDate
        );

        return address(nttEvent);
    }
}
