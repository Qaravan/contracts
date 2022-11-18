// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IQaravan {

    event EventDeliveryService(
        address indexed owner,
        string indexed name,
        string image,
        string description,
        string getRequest,
        string pathResult,
        uint256 createdAt,
        uint256 updatedAt
    );

    event EventSellerAccount(
        address indexed owner,
        string indexed name,
        string image,
        string description,
        string publicKey,
        uint256 createdAt,
        uint256 updatedAt
    );

    event EventOrder(
        address indexed buyer,
        address indexed seller,
        uint256 createdAt,
        uint256 updatedAt
    );

    enum Status {
        PENDING,
        SHIPPED,
        DELIVERED,
        CANCELED,
        RETURNED,
        COMPLETED
    }

    struct DeliveryService {
        address owner;
        string name;
        string image; // IPFS
        string description;
        string getRequest;
        string pathResult;
        bytes32 jobId;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct BuyerAccount {
        string publicKey;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct SellerAccount {
        string name;
        string image; // IPFS
        string description;
        string publicKey;
        address erc1155;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct Message {
        address author;
        string message; // IPFS {text: "publicKey(My message)"}
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct ERC20Token {
        address token;
        uint256 amount;
    }

    struct ERC1155Token {
        address token;
        uint256[] ids;
        uint256[] amounts;
    }

    struct SwapToken {
        ERC20Token erc20;
        ERC1155Token erc1155;
    }

    struct DeliveryOrder {
        uint256 serviceId;
        string deliveryAddress;
        string trackNumber;
    }

    struct Order {
        Status status;
        SwapToken swap;
        DeliveryOrder delivery;
        address buyer;
        address seller;
        uint256 createdAt;
        uint256 updatedAt;
    }

}