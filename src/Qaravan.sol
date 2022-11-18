// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@chainlink/contracts/src/v0.8/ChainlinkClient.sol';
import '@chainlink/contracts/src/v0.8/ConfirmedOwner.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./IQaravan.sol";

/// @title Decentralized marketplace Qaravan
/// @author Alex Baker

contract Qaravan is IQaravan, Context, ChainlinkClient, ConfirmedOwner, ERC1155Holder {

    using Chainlink for Chainlink.Request;

    bytes32 private jobId;
    uint256 private fee;

    constructor() ConfirmedOwner(msg.sender) {
        // setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        // setChainlinkOracle(0x40193c8518BB267228Fc409a613bDbD8eC5a97b3);
        // jobId = 'ca98366cc7314957b8c012c72f05aeeb';
        // fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        setChainlinkOracle(0xCC79157eb46F5624204f47AB42b3906cAA40eaB7);
        jobId = 'ca98366cc7314957b8c012c72f05aeeb';
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
    }

    uint256 orderId;
    mapping(uint256 => Order) orders;
    mapping(bytes32 => uint256) requestIdOrderId;

    uint256 deliveryServiceId;
    mapping(uint256 => DeliveryService) deliveryService;

    mapping(address => BuyerAccount) buyerAccount;

    mapping(address => SellerAccount) sellerAccount;

    uint256 goodsId;
    mapping(uint256 => address) goods;

    mapping(address => uint256) userOrderId;
    mapping(address => mapping(uint256 => uint256)) userOrders;  // user => userOrderId => orderId

    mapping(uint256 => uint256) messageId; // orderId => messageId
    mapping(uint256 => mapping(uint256 => Message)) messages; // orderId => messageId =>  Message

     // ----------------------------------------------------------
     // DeliveryService
     // ----------------------------------------------------------

    /**
    * @dev Adding a new delivery service to the blockchain.
    * @param name_ The name of the delivery service.
    * @param image_ The image of the delivery service.
    * @param description_ The description of the delivery service.
    * @param getRequest_ The URL of the Chainlink API.
    * @param pathResult_ The path of the Chainlink API.
    * @param jobId_ The JobID of the Chainlink external adapter.
    * @return _ deliveryServiceId
    */
    function addDeliveryService(
        string memory name_,
        string memory image_,
        string memory description_,
        string memory getRequest_,
        string memory pathResult_,
        bytes32 jobId_
    ) public returns(uint256) {
        deliveryServiceId++;
        deliveryService[deliveryServiceId] = DeliveryService({
            owner: _msgSender(),
            name: name_,
            image: image_,
            description: description_,
            getRequest: getRequest_,
            pathResult: pathResult_,
            jobId: jobId_,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });

        return deliveryServiceId;
    }

    // function updDeliveryService(
    //     uint256 deliveryServiceId_,
    //     string memory name_,
    //     string memory image_,
    //     string memory description_,
    //     string memory getRequest_,
    //     string memory pathResult_,
    //     bytes32 jobId_
    // ) public returns(bool) {
    //     DeliveryService storage ds = deliveryService[deliveryServiceId_];

    //     require(_msgSender() == ds.owner, "Only owner");

    //     ds.name = name_;
    //     ds.image = image_;
    //     ds.description = description_;
    //     ds.getRequest = getRequest_;
    //     ds.pathResult = pathResult_;
    //     ds.jobId = jobId_;
    //     ds.updatedAt = block.timestamp;

    //     return true;
    // }

    /**
    * @dev Getting information about the delivery service.
    * @param deliveryServiceId_ The ID of the delivery service.
    * @return _ DeliveryService
    */
    function getDeliveryService(
        uint256 deliveryServiceId_
    ) public view returns(DeliveryService memory) {
        return deliveryService[deliveryServiceId_];
    }

    // ----------------------------------------------------------
    // SellerAccount
    // ----------------------------------------------------------

    /**
    * @dev Adding a new seller to the blockchain.
    * @param name_ The name of the seller.
    * @param image_ The image of the seller.
    * @param description_ The description of the seller.
    * @param publicKey_ Sellers public key to decrypt the delivery address.
    * @param erc1155_ Address of the contract with a list of goods.
    * @return _ goodsId
    */
    function addSellerAccount(
        string memory name_,
        string memory image_,
        string memory description_,
        string memory publicKey_,
        address erc1155_
    ) public returns(uint256) {
        SellerAccount storage sa = sellerAccount[_msgSender()];

        require(sa.createdAt <= 0, "Seller exists");

        sellerAccount[_msgSender()] = SellerAccount({
            name: name_,
            image: image_,
            description: description_,
            publicKey: publicKey_,
            erc1155: erc1155_,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });

        goodsId++;
        goods[goodsId] = _msgSender();

        return goodsId;
    }

    // function updSellerAccount(
    //     string memory name_,
    //     string memory image_,
    //     string memory description_,
    //     string memory publicKey_
    // ) public returns(bool) {
    //     SellerAccount storage sa = sellerAccount[_msgSender()];

    //     require(sa.createdAt > 0, "Only owner");

    //     sa.name = name_;
    //     sa.image = image_;
    //     sa.description = description_;
    //     sa.publicKey = publicKey_;
    //     sa.updatedAt = block.timestamp;

    //     return true;
    // }

    /**
    * @dev Getting information about the seller.
    * @param seller_ The address of the seller.
    * @return _ SellerAccount
    */
    function getSellerAccount(
        address seller_
    ) public view returns(SellerAccount memory) {
        return sellerAccount[seller_];
    }

    /**
    * @dev Getting information about the goods.
    * @param goodsId_ The ID of the goods.
    * @return _ seller, SellerAccount
    */
    function getGoods(
        uint256 goodsId_
    ) public view returns(address, SellerAccount memory) {
        return (goods[goodsId_], getSellerAccount(goods[goodsId_]));
    }

    // ----------------------------------------------------------
    // Message
    // ----------------------------------------------------------

    // function addMessage(
    //     uint256 orderId_,
    //     string calldata message_
    // ) private returns(uint256) {
    //     messageId[orderId_]++;
    //     messages[orderId_][messageId[orderId_]] = Message({
    //         author: _msgSender(),
    //         message: message_,
    //         createdAt: block.timestamp,
    //         updatedAt: block.timestamp
    //     });

    //     return messageId[orderId_];
    // }

    // function getMessage(
    //     uint256 orderId_,
    //     uint256 messageId_
    // ) public view returns(Message memory) {
    //     return messages[orderId_][messageId_];
    // }

    // ----------------------------------------------------------
    // Order
    // ----------------------------------------------------------

    /**
    * @dev Adding a new order to the blockchain.
    * @param swapToken_ Payment token (ERC20) and purchase token (ERC1155).
    * @param serviceId_ Delivery service ID.
    * @param seller_ The address of the seller of goods.
    * @param deliveryAddress_ Goods delivery address.
    * @return _ orderId
    */
    function addOrder(
        SwapToken calldata swapToken_,
        uint256 serviceId_,
        address seller_,
        string calldata deliveryAddress_
    ) public returns(uint256) {
        SellerAccount storage sa = sellerAccount[seller_];

        require(sa.erc1155 == swapToken_.erc1155.token, "ERC1155 not found");

        // BuyerAccount storage ba = buyerAccount[_msgSender()];

        // if (ba.createdAt <= 0) {
        //     ba.publicKey = publicKey_;
        //     ba.createdAt = block.timestamp;
        //     ba.updatedAt = block.timestamp;
        // }

        // addMessage(orderId, deliveryAddress_);

        orderId++;
        orders[orderId] = Order({
            status: Status.PENDING,
            swap: swapToken_,
            delivery: DeliveryOrder(
                serviceId_, 
                deliveryAddress_, 
                ""
            ),
            buyer: _msgSender(),
            seller: seller_,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });

        userOrderId[_msgSender()]++;
        userOrders[_msgSender()][userOrderId[_msgSender()]] = orderId;

        userOrderId[seller_]++;
        userOrders[seller_][userOrderId[seller_]] = orderId;

        transferFrom(
            _msgSender(),
            seller_,
            swapToken_
        );

        return orderId;
    }

    /**
    * @dev Adding a parcel tracking number.
    * @param orderId_ Order ID.
    * @param trackNumber_ Parcel tracking number.
    * @return _ true
    */
    function addTrackNumberToOrder(
        uint256 orderId_,
        string calldata trackNumber_
    ) public returns(bool) {
        Order storage o = orders[orderId_];

        require(_msgSender() == o.seller, "Only seller");

        o.status = Status.SHIPPED;
        o.delivery.trackNumber = trackNumber_;
        o.updatedAt = block.timestamp;

        return true;
    }

    /**
    * @dev Checking the delivery of order.
    * @param orderId_ Order ID.
    * @return requestId_ Chainlink requestId.
    */
    function checkDeliveryOrder(
        uint256 orderId_
    ) public returns(bytes32 requestId_) {
        Order storage o = orders[orderId_];

        require(o.status == Status.SHIPPED, "Track Number Not Found");

        DeliveryService storage ds = deliveryService[o.delivery.serviceId];

        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        req.add('get', string(abi.encodePacked(ds.getRequest, o.delivery.trackNumber)));
        req.add('path', ds.pathResult);
        req.addInt('times', 1);
        requestId_ = sendChainlinkRequest(req, fee);

        requestIdOrderId[requestId_] = orderId_;
    }

    function fulfill(bytes32 requestId_, uint256 volume_) public recordChainlinkFulfillment(requestId_) {
        orders[requestIdOrderId[requestId_]].status = Status(volume_);
    }

    /**
    * @dev Completion of the order, the seller receives ERC20, and the buyer receives ERC1155.
    * @param orderId_ Order ID.
    * @return _ Status
    */
    function completeOrder(
        uint256 orderId_
    ) public returns(Status) {
        Order storage o = orders[orderId_];
        
        if (
            o.status == Status.DELIVERED
        ) {
            o.status = Status.COMPLETED;
            transfer(
                o.seller,
                o.buyer,
                o.swap
            );
        } else if (
            (o.status == Status.CANCELED) ||
            (
                (
                    o.status == Status.PENDING || o.status == Status.SHIPPED
                ) && 
                    block.timestamp > o.createdAt + (60 * 60 * 24 * 30)
            )
        ) {
            o.status = Status.RETURNED;
            transfer(
                o.buyer,
                o.seller,
                o.swap
            );
        }

        return o.status;
    }

    function transfer(
        address erc20to,
        address erc1155to,
        SwapToken memory swap
    ) private {
        IERC20(swap.erc20.token).transfer(
            erc20to,
            swap.erc20.amount
        );
        IERC1155(swap.erc1155.token).safeBatchTransferFrom(
            address(this),
            erc1155to,
            swap.erc1155.ids,
            swap.erc1155.amounts,
            ""
        );
    }

    function transferFrom(
        address erc20from,
        address erc1155from,
        SwapToken memory swap
    ) private {
        IERC20(swap.erc20.token).transferFrom(
            erc20from,
            address(this),
            swap.erc20.amount
        );
        IERC1155(swap.erc1155.token).safeBatchTransferFrom(
            erc1155from,
            address(this),
            swap.erc1155.ids,
            swap.erc1155.amounts,
            ""
        );
    }

    /**
    * @dev Get order information.
    * @param orderId_ Order ID.
    * @return _ Order
    */
    function getOrder(
        uint256 orderId_
    ) public view returns(Order memory) {
        return orders[orderId_];
    }

    // ----------------------------------------------------------
    // Chainlink
    // ----------------------------------------------------------

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), 'Unable to transfer');
    }

    // ----------------------------------------------------------
}