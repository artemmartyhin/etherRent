pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract EtherRent is ERC20{
    using SafeMath for uint;

    event AppartmentAdded(address indexed owner, uint price);

    address public owner;

    uint public buyPrice;

    struct Appartment{
        uint8 rooms;
        uint8 floor;
        bool hasBalcony;
        bool isPayed;
        bool isRented;
        uint distFromCenter;
        uint price;
        string addr;
    }

    Appartment[] appartments;

    mapping(uint=>address) appToOwner;
    mapping(uint=>address) appToRenter;

    constructor() ERC20("RentToken", "RTT"){
        owner=msg.sender;
        buyPrice=100 wei;
        _mint(owner, 10000000);
    } 

    function BuyTokens() public payable{
        uint tokens = msg.value.mul(buyPrice);
        require(balanceOf(owner)>=tokens, "There are not so many tokens in supply");
        uint comission = msg.value.div(100);
        require(payable(address(this)).send(comission));
        _transfer(owner, msg.sender, tokens);
    }

    function AddAppartment(uint8 _rooms, uint8 _floor, bool _hasBalcony, uint _distFromCenter, uint _price, string memory _addr) external {
        appartments.push(Appartment(_rooms, _floor, _hasBalcony, false, false, _distFromCenter, _price, _addr));
        appToOwner[appartments.length-1]=msg.sender;
    }

    function ListAppartments() public view returns(Appartment[] memory) {
        return(appartments);
    }

    function RentAppatment(uint _index) external{
        require(!appartments[_index].isRented, "The appartemnt is not free");
        require(balanceOf(msg.sender)>=appartments[_index].price, "Not enough tokens");
        _transfer(msg.sender, appToOwner[_index], appartments[_index].price);
        appartments[_index].isPayed=true;
        appartments[_index].isRented=true;

    }

    function FreeAppartment(uint _index) external{
        require(appToOwner[_index]==msg.sender, "Only owner");
        require(!appartments[_index].isPayed, "Mustn't be payed");
        require(appartments[_index].isRented, "Must be rented");
        delete appToRenter[_index];
        appartments[_index].isRented=false;
    }

    function PayRent(uint _index) external{
        require(appToRenter[_index]==msg.sender, "You dont't rent this appartment");
        require(!appartments[_index].isPayed, "Mustn't be payed");
        require(balanceOf(msg.sender)>=appartments[_index].price, "Not enough tokens");
        _transfer(msg.sender, appToOwner[_index], appartments[_index].price);
        appartments[_index].isPayed=true;
    }

    function EndMonth() external{
        require(owner==msg.sender, "Only for administration");
        for(uint i=0; i<appartments.length; i++){
            if(appartments[i].isPayed){
                appartments[i].isPayed=false;
            }
        }
    }








}

