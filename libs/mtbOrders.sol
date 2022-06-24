// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./mtbCommon.sol";

contract MetaInBoxOrder is MetaInBoxCommon{

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _orderIds;

    struct Order{
        uint256 id;
        uint256 tokenId;
        uint256 collectionId;
        address payable asker;
        address bidder;
        uint256 askprice;
        uint256 bidprice;
        MetaInBoxCommon.Fee askerFee;
        MetaInBoxCommon.Fee serviceFee;
        MetaInBoxCommon.ORDERSTATUS status;
    }
    mapping(uint256 => Order) public Orders;
    mapping(uint256 => bool) public activateSales;
    mapping(uint256 => uint256[]) public OrderKeys;
    uint256 public totalOrders;
/*
    address public marketplace_address = address(0x0);

    modifier isAdmin(bytes32 iRrole) {
        require(hasRole(iRrole, msg.sender), "Administrator Permission denied");
        _;
    }
*/
/*
    function initialize() initializer public {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
*/
    function getOrder(uint256 Id) public view returns(Order memory){
        return Orders[Id];
    }
    function setSaleDeactivate(uint256 tokenId) internal {
        activateSales[tokenId]=false;

    }
    function getActiviate(uint256 tokenId) public view returns(bool){
        return activateSales[tokenId];
    }
    function getOrderStatus(uint256 orderId) public view returns(ORDERSTATUS){
        return Orders[orderId].status;
    }
    function getOrderKeys(uint256 tokenId) public view returns(uint256[] memory){
        return OrderKeys[tokenId];
    }
    function createOrder(address payable asker,
    uint256 price,
    uint256 assetId,
    uint256 collectionId,
    Fee memory sellFee,
    Fee memory payee)
    internal returns(uint256){
        require(assetId!=0,"error on create order by unknow token Id");
        _orderIds.increment();
        uint256 curOrderId = _orderIds.current();
        Fee memory serviceFee=payee;

        Orders[curOrderId]=Order(
            {
                id:curOrderId,
                tokenId:assetId,
                collectionId:collectionId,
                asker:asker,
                bidder:address(0x0),
                askprice:price,
                bidprice:uint256(0),
                askerFee:sellFee,
                serviceFee:serviceFee,
                status:MetaInBoxCommon.ORDERSTATUS.SELLING
            }
        );
        activateSales[assetId]=true;
        OrderKeys[assetId].push(curOrderId);
        totalOrders+=1;
        return curOrderId;

    }
    function modifyOrder(uint256 id,address bidder,uint256 bidprice,MetaInBoxCommon.ORDERSTATUS status) internal returns(uint256)
    {
        //require(marketplace_address != address(0x0),"please set marketplace address first");
        //require(msg.sender == marketplace_address,"only marketplace address can call this action");

        require(existsOrder(id),"can not find order");

        Order memory oldOrder = Orders[id];

        oldOrder.bidder=bidder;
        oldOrder.bidprice=bidprice;
        oldOrder.status=status;
        Orders[id]=oldOrder;

        return id;
    }
    function existsOrder(uint256 id) public view returns(bool){
        return Orders[id].asker != address(0x0) && Orders[id].status == MetaInBoxCommon.ORDERSTATUS.SELLING;
    }
/*
    function setMarketPlace(address newMarket) public isAdmin(DEFAULT_ADMIN_ROLE){
        marketplace_address=newMarket;
    }
*/
}