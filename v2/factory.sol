// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./NTTEvent.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Factory {
    using Counters for Counters.Counter;
    Counters.Counter private _contractIds;

    address private owner;

    constructor() {
        owner = msg.sender;
    }

    struct NTTEventData {
        uint256 contractId;
        address contractAddress;
        address creatorAddress; //redundant as the value is equal to the key of register. check if it can be eliminated
        string title;
        string associatedCommunity;
        uint256 timestamp;
    }

    struct NTTData {
        address contractAddress;
        uint256 tokenId;
    }

    mapping(address => NTTEventData[]) private issuerRegister;
    mapping(address => NTTData[]) private receiverRegister;

    function deployNTT(
        string memory _title,
        string memory _description,
        string[] memory _links,
        string memory _imageHash,
        string memory _associatedCommunity,
        uint256 _startDate,
        uint256 _endDate,
        address[] memory _list
    ) public {
        address currentContractAddress = address(this);
        NTTEvent nttEvent = new NTTEvent(
            msg.sender,
            _title,
            _description,
            _links,
            _imageHash,
            _associatedCommunity,
            _startDate,
            _endDate,
            currentContractAddress
        );
        address nttEventAddress = address(nttEvent);

        //set whitelist
        nttEvent.addToWhitelist(_list);

        //get contract id
        _contractIds.increment();

        uint256 _id = _contractIds.current();
        //update the creator data
        NTTEventData memory _nttEventData = NTTEventData({
            contractId: _id,
            contractAddress: nttEventAddress,
            creatorAddress: msg.sender,
            title: _title,
            associatedCommunity: _associatedCommunity,
            timestamp: block.timestamp
        });

        issuerRegister[msg.sender].push(_nttEventData);

        //emit event
    }

    function mintFromNTTEvent(address _contractAddress) public {
        NTTEvent nttEvent = NTTEvent(_contractAddress);
        uint256 _tokenId = nttEvent.mint(msg.sender);

        require(_tokenId != 0, "Mint failed!");
        NTTData memory _nttData = NTTData({
            tokenId: _tokenId,
            contractAddress: _contractAddress
        });

        receiverRegister[msg.sender].push(_nttData);
    }

    function getContractDeployedInfo()
        public
        view
        returns (NTTEventData[] memory)
    {
        return issuerRegister[msg.sender];
    }

    //returns data of contract where tokens have been issued
    function getMyNTTContractData() public view returns (NTTData[] memory) {
        return receiverRegister[msg.sender];
    }
}
