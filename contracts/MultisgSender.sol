//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.4;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./EtherRent.sol";

contract MutisigSender is Context, ReentrancyGuard{
    //TODO: add events, more view functions
    using SafeMath for uint;
    //CONSTANTS
    uint constant MAX_SIGNERS=12;
    uint constant REQUIRED_SIGNS=4;

    //STORAGE
    mapping(uint=>Tx) public txes;
    mapping(uint=>mapping(address=>bool)) public confirmations;
    mapping(address=>bool) isSigner;
    address[] public signers;
    uint public txCounter;

    struct Tx{
        string name;
        address to;
        uint amount;
        bool executed;
    }

    //MODIFIERS
    modifier isContract(address _addr){
        uint size;
        assembly{
            size:=extcodesize(_addr)
        }
        require(size>0, "The receiver isn't a contract");
        _;
    }

    modifier MultisigOnly(){
        require(_msgSender()==address(this), "Not multisig");
        _;
    }

    modifier SignerOnly(address _addr){
        require(isSigner[_addr], "Not a signer");
        _;
    }

    modifier isNotSigner(address _addr){
        require(_addr!=address(this), "Zero address provided");
        require(!isSigner[_addr], "Already a signer");
        _;
    }

    modifier TxExists(uint _txId){
        require(txes[_txId].to!=address(0), "The transaction does not exist");
        _;
    }

    modifier TxConfirmed(uint _txId, address _signer){
        require(confirmations[_txId][_signer], "The transaction isn't confirmed");
        _;
    }

    modifier isNotConfirmed(uint _txId, address _signer){
        require(!confirmations[_txId][_signer], "The transaction isn already confirmed");
        _;
    }

    modifier isNotExecuted(uint _txId){
        require(!txes[_txId].executed, "Transaction is already executed");
        _;
    }

    //PUBLIC FUNCTIONS

    //@dev fallback function that allows to deposit

    receive() external payable{}

    //@dev constructor adds initial signers
    constructor(address[] memory _signers){
        require(_signers.length==MAX_SIGNERS, "Incorrect amount of signers provided");
        signers = new address[](MAX_SIGNERS);
        for(uint i=0; i<MAX_SIGNERS; i++){
            require(_signers[i]!=address(0), "Zero address provided");
            require(!isSigner[_signers[i]], "The signer is already registred");
            signers[i]=_signers[i];
            isSigner[signers[i]]=true;
        }
        txCounter=0;
    }
    //@dev functions return deposited ether
    function returnDeposit(address payable _sender, uint _amount) external MultisigOnly SignerOnly(_sender){
        require(address(this).balance>=_amount, "Not enough ether to return");
        _sender.transfer(_amount);
    }
    function submitTx(string memory _name, address _to, uint _amount) external 
    SignerOnly(_msgSender()) isContract(_to)
    returns(uint _txId){
        require(_to!=address(0), "Zero address provided");
        _txId = txCounter;
        txes[_txId]=Tx({
            name: _name,
            to:_to,
            amount: _amount,
            executed: false
        });
        txCounter.add(1);
        confirmTx(_txId);
    }
    function confirmTx(uint _txId) public 
    SignerOnly(_msgSender()) TxExists(_txId) isNotConfirmed(_txId, _msgSender()){
        confirmations[_txId][_msgSender()]=true;
        executeTx(_txId);
    }
    function executeTx(uint _txId) internal isNotExecuted(_txId){
        if(isConfirmed(_txId)){
            if(external_call(_txId)){

            }
        }
        else{

        }
    }
    function external_call(uint _txId) internal nonReentrant() returns (bool result) {
        Tx storage _tx= txes[_txId];
        EtherRent er = EtherRent(_tx.to);
        uint amount = _tx.amount;
        er.BuyTokens{value:amount}();
        return result;
    }
    function isConfirmed(uint _txId) public view returns(bool result){
        if(txes[_txId].executed){
            return true;
        }
        uint counter=0;
        for(uint i=0; i<MAX_SIGNERS; i++){
            if(confirmations[_txId][signers[i]]){
                counter.add(1);
            }
            if(counter==REQUIRED_SIGNS){
                return true;
            }        
        }
        return false;
    }

}