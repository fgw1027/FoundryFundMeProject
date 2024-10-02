// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

// import {Script} from "forge-std/Script.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant BALANCE = 10 ether;
    uint256 Gas_PRICE = 1;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, BALANCE);
    }

    function testMinuimDollar() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgsender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceVersion() public view {
        console.log(fundMe.getVersion());
        assertEq(fundMe.getVersion(), 4);
    }

    function testFundFail() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedStructure() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testFunderIsCorrect() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address fundAddress = fundMe.getFunder(0);
        assertEq(fundAddress, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _; // 这是 modifier 中的特殊符号,表示被修饰函数的原始代码执行位置
    }

    function testOnlyOwnerWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawsingleOwner() public funded {
        //Arrange
        uint256 startOwnerBalance = fundMe.getOwner().balance;
        uint256 startFundMeBalance = address(fundMe).balance;

        //Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //Assert
        uint256 endOwnerBalance = fundMe.getOwner().balance;
        uint256 endFundMeBalance = address(fundMe).balance;
        assertEq(endFundMeBalance, 0);
        assertEq(startOwnerBalance + startFundMeBalance, endOwnerBalance);
    }

    function testWithdrawMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startFunder = 1;
        for (uint160 i = startFunder; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE); // hoax=prank+deal
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    function testCheaperWithdrawMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startFunder = 1;
        for (uint160 i = startFunder; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE); // hoax=prank+deal
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}
