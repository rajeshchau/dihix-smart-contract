// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Oraclecontracts{
    struct Oracle{
        uint oracleid;
        address oracleaddress;
        uint oracleprice;
        uint oraclerewords;
        bool isActive;
    }

    struct Project{
        uint projectid;
        address projectaddress;
        uint projectprice;
        uint projectrewords;
        bool isactive;
        address oracleselected;
        bool grantreward;
    }

    address owner;
    uint public NumOracles;
    constructor(){
        NumOracles = 0;
        owner = msg.sender;
        
    }

    mapping(uint256 => Oracle) public oracle;
    mapping(uint256 => Project) public project;

    event OracleCreated(uint256 oracleid, address oracleaddress, uint256 oracleprice);
    event ProjectCreated(uint projectid,address projectaddress,uint projectprice,uint projectrewords);
    event OracleSelected(uint projectid, address oracleaddress);
    event RewardGranted(uint projectid, address oracleaddress);

    function createproject(uint _projectid,address _projectaddress,uint _projectprice,uint _projectrewords) public {
        project[_projectid].projectid=_projectid;
        project[_projectid].projectaddress=_projectaddress;
        project[_projectid].projectprice=_projectprice;
        project[_projectid].projectrewords=_projectrewords;
        project[_projectid].oracleselected= 0x0000000000000000000000000000000000000000;
        project[_projectid].isactive=true;
        project[_projectid].grantreward=false;
        emit ProjectCreated(_projectid,_projectaddress,_projectprice,_projectrewords);


    }

    function createoracle(uint _oracleid , uint _oracleprice ) public {
        require(oracle[_oracleid].oracleid != _oracleid, "This ID is already taken.");
        oracle[_oracleid] = Oracle({
            oracleid: _oracleid,
            oracleaddress: msg.sender,
            oracleprice: _oracleprice,
            oraclerewords: 0,
            isActive: true
        });

        emit OracleCreated(_oracleid, msg.sender, _oracleprice);
        NumOracles++;
    }

    function randomguess(uint _oracleid,uint _projectid) public {
        require(oracle[_oracleid].oracleid == _oracleid, "This ID is found in contract");
        require(oracle[_oracleid].isActive == true, "Oracle is not active");
        project[_projectid].oracleselected= oracle[_oracleid].oracleaddress;

        emit OracleSelected(_projectid, oracle[_oracleid].oracleaddress);
    }

    function rewardgrant(uint _reward , uint _projectid,uint _oracleid) public {
        require(project[_projectid].projectrewords == _reward, "Reward is not equal");
        require( project[_projectid].grantreward  == true,"owner allowes to grant reward");
        oracle[_oracleid].oraclerewords == _reward;

        emit RewardGranted(_projectid, oracle[_oracleid].oracleaddress);
    }

    function grantreword(uint _projectid)public{
        require( project[_projectid].projectid==_projectid,"this project is not found");
        project[_projectid].grantreward  = true;
    }

    // function penalize(address _user) public  {
    //     require(msg.sender == owner,"owner can call this function");
    //     require(_user != address(0), "User address cannot be zero");
    //     require(_user != address(this), "User address cannot be contract");

    //     //logic will be made after clear ideaa from arpit sir.
    // }

   

    function getOraclesList() external view returns (uint256[] memory) {
        uint256 activeOracle = 0;

        for (uint256 i = 0; i <= NumOracles; i++) {
            if (oracle[i].isActive) {
                activeOracle++;
            }
        }

        uint256[] memory activeOracles = new uint256[](activeOracle);
        uint256 index = 0;

        for (uint256 i = 0; i <= NumOracles; i++) {
            if (oracle[i].isActive) {
                activeOracles[index] = i;
                index++;
            }
        }

        return activeOracles;
    }

}

