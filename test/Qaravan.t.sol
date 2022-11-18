// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Qaravan.sol";

contract QaravanTest is Test {
    Qaravan public qaravan;

    function setUp() public {
        qaravan = new Qaravan();
        qaravan.addSellerAccount("Test","","","",address(0));
    }

    function testSellerAccount() public {
        Qaravan.SellerAccount memory sa = qaravan.getSellerAccount(address(this));
        assertEq(sa.name, "Test");
    }
}
