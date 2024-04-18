# Baba Marta Audit Report

Prepared by: Oldguard (AlgorinthLabs)
Lead Auditors:

- Oldguard

Assisting Auditors:

- None

# Table of contents

<details>

<summary>See table</summary>

- [Baba Marta Audit Report](#passwordstore-audit-report)
- [Table of contents](#table-of-contents)
- [About Oldguard and Disclaimer](#about-oldguard-and-disclaimer)
- [Disclaimer](#disclaimer)
- [Risk Classification](#risk-classification)
- [Audit Details](#audit-details)
  - [Scope](#scope)
- [Protocol Summary](#protocol-summary)
  - [Roles](#roles)
- [Executive Summary](#executive-summary)
  - [Issues found](#issues-found)
- [Findings](#findings)
  - [High](#high)
    - [\[H-1\] Anyone can get health tokens without buying martenitsa tokens or win the voting contest(producers)](#h-1-health-tokens-can-be-acquired-so-easily-by-anyone)
    - [\[H-2\] `voteForMartenitsa::MartenitsaVoting` will result in a denial of service attack](#h-2-voteformartenitsamartenitsavoting-will-result-in-a-denial-of-service-attack)
- [Low Risk Findings](#low-risk-findings)
  - [L-01. Initialization Timeframe Vulnerability](#l-01-initialization-timeframe-vulnerability)
    - [Relevant GitHub Links](#relevant-github-links)
  - [Summary](#summary)
  - [Vulnerability Details](#vulnerability-details)
  - [Impact](#impact)
  - [Tools Used](#tools-used)
  - [Recommendations](#recommendations) - [\[I-1\] The `PasswordStore::getPassword` natspec indicates a parameter that doesn't exist, causing the natspec to be incorrect](#i-1-the-passwordstoregetpassword-natspec-indicates-a-parameter-that-doesnt-exist-causing-the-natspec-to-be-incorrect)
  </details>
  </br>

# About Oldguard and Disclaimer

OldGuard, representing the team at Algorinth Labs LLC, conducted this audit as a personal endeavor within a contest. The team invested significant efforts to uncover potential vulnerabilities within the code within the allocated time frame. However, it's important to clarify that while this document presents our findings, OldGuard and Algorinth Labs LLC assume no liability for the results. Additionally, it's crucial to understand that our audit does not constitute an endorsement of the underlying business or product. This audit was time-constrained and focused specifically on evaluating the security aspects of the Solidity implementation within the contracts.

# Risk Classification

|            |        | Impact |        |     |
| ---------- | ------ | ------ | ------ | --- |
|            |        | High   | Medium | Low |
|            | High   | H      | H/M    | M   |
| Likelihood | Medium | H/M    | M      | M/L |
|            | Low    | M      | M/L    | L   |

## Scope

```
src/
--- MartenitsaToken.sol
--- MartenitsaMarketplace.sol
--- MartenitsaVoting.sol
--- HealthToken.sol
--- MartenitsaEvent.sol
```

# Protocol Summary

The "Baba Marta" protocol allows you to buy `MartenitsaToken` and to give it away to friends. Also, if you want, you can be a producer. The producer creates `MartenitsaTokens` and sells them. There is also a voting for the best `MartenitsaToken`. Only producers can participate with their own `MartenitsaTokens`. The other users can only vote. The winner wins 1 `HealthToken`. If you are not a producer and you want a `HealthToken`, you can receive one if you have 3 different `MartenitsaTokens`. More `MartenitsaTokens` more `HealthTokens`. The `HealthToken` is a ticket to a special event (producers are not able to participate). During this event each participant has producer role and can create and sell own `MartenitsaTokens`.

## Roles

- Owner: Is the only one who should be able to set and access the password.

For this contract, only the owner should be able to interact with the contract.

# Executive Summary

## Issues found

| Severity          | Number of issues found |
| ----------------- | ---------------------- |
| High              | 2                      |
| Medium            | 0                      |
| Low               | 1                      |
| Info              | 1                      |
| Gas Optimizations | 0                      |
| Total             | 0                      |

# Findings

## High

### [H-1] Health Tokens can be acquired so easily by anyone

**Description:** This report identifies a critical vulnerability within the system that allows users to claim health tokens without the prerequisite of purchasing a Martenitsa token. This oversight not only undermines the intended access control mechanism but also poses a significant risk to the integrity of the platform's event participation and producer roles.

Overview: The vulnerability is rooted in the `updateCountMartenitsaTokensOwner` function, which lacks adequate checks to ensure that users have legitimately acquired Martenitsa tokens before being eligible to claim health tokens. This flaw enables users to manipulate the system to gain access to health tokens when they call the `collectReward` function, which are utilized as tickets for events. Participants, leveraging these tokens, can erroneously assume the role of a producer during the event duration, potentially disrupting the intended flow of activities and compromising the platform's security and user trust.

**Impact:** This vulnerability can lead to unauthorized access to health tokens, potentially allowing users to participate in events as producers without the necessary qualifications. This could disrupt event schedules, compromise the integrity of the platform, and undermine user trust.

**Proof of Concept:** Unrestricted Claim of Health Tokens Without Martenitsa Token Purchase

1. Start the Test Environment:
   Initialize the Foundry virtual machine (VM) and set the test environment to simulate the conditions of the vulnerability :

   ```javascript
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
    //token value represented in wei
    uint weiEq = 10 ** 18;
    assertEq(healthToken.balanceOf(bob) / weiEq, 30);
   }
   ```

2.Simulate User Actions:
Use the `vm.startPrank(bob)` function to simulate actions as the user "Bob".
Execute the `updateCountMartenitsaTokensOwner` function 90 times for Bob, incrementing his token count without the need to purchase Martenitsa tokens:

```javascript
        for (uint64 i = 0; i < 90; i++) {
    @>        martenitsaToken.updateCountMartenitsaTokensOwner(bob, "add");
      }

```

3. Verify Token Count:
   Call getCountMartenitsaTokensOwner(bob) to verify that Bob's token count has been increased to 90.
   Assert that Bob does not have Martenitsa tokens (isProducer(bob) should return false) and that his Martenitsa token balance is 0:

   ```javascript
   assertEq(martenitsaToken.isProducer(bob), false);
   assertEq(martenitsaToken.balanceOf(bob), 0);
   ```

4. Attempt to Claim Health Tokens:
   Call `marketplace.collectReward()` to simulate Bob attempting to claim health tokens.
   Assert that Bob's health token balance is increased by 30 tokens, despite not having purchased Martenitsa tokens:

   ```javascript
    marketplace.collectReward();
    //token value represented in wei
    uint weiEq = 10 ** 18;
    assertEq(healthToken.balanceOf(bob) / weiEq, 30);
   ```

   run `forge test --match-test testAnyoneCanGetHealthTokensUsingCollectReward -vv` and you'll be able to see these tests passed.

**Recommended Mitigation:** To address this vulnerability, it is recommended that the updateCountMartenitsaTokensOwner function be modified to include checks that verify the user's ownership of Martenitsa tokens before allowing the increment of their health token count below is one way to do that:

```javascript
function updateCountMartenitsaTokensOwner(
        address owner,
        uint tokenId,
        string memory operation
    ) external {
      require(ownerOf(tokenId)== owner,"Sorry you are not the token's owner")
        if (
            keccak256(abi.encodePacked(operation)) ==
            keccak256(abi.encodePacked("add"))
        ) {
            countMartenitsaTokensOwner[owner] += 1;
        } else if (
            keccak256(abi.encodePacked(operation)) ==
            keccak256(abi.encodePacked("sub"))
        ) {
            countMartenitsaTokensOwner[owner] -= 1;
        } else {
            revert("Wrong operation");
        }
    }
```

### [H-2] `voteForMartenitsa::MartenitsaVoting` will result in a denial of service attack

**Description:** The `voteForMartenitsa::MartenitsaVoting` function could result in a denial of service attack due to lack of checks for duplicates on the `_tokenIds` array an attacker could call this function numerous times to inflate the array hereby rendering the announce winner function impossible to call here's a test showcasing the intentional overpopulation of the `_tokenIds` Array and the gasleft after the population, since `announceWinner` loops through `_tokenIds` this will result in a revert due to the function running out of gas

```javascript
   function voteForMartenitsa(uint256 tokenId) external {
        require(!hasVoted[msg.sender], "You have already voted");
        require(
            block.timestamp < startVoteTime + duration,
            "The voting is no longer active"
        );
        list = _martenitsaMarketplace.getListing(tokenId);
        require(list.forSale, "You are unable to vote for this martenitsa");

        hasVoted[msg.sender] = true;
        voteCounts[tokenId] += 1;
@>        _tokenIds.push(tokenId);
    }
```

**Impact:** `announceWinner` can't be called due to insufficient gas

**Proof of Concept:**

Add the following to the `PasswordStore.t.sol` test suite.

```javascript
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
```

this showcases the gas consumption of 1 million items in the `_tokenIds` quite massive considering it's only a million.

**Recommended Mitigation:** create an array `listedTokens` inside of `MartenitsaMarket.sol` that contains all listed tokens and loop through that instead, much safer and no duplicates

# Low Risk Findings

## <a id='L-01'></a>L-01 No checks for duplicates producers in the `setProducers::MartenitsaToken.sol` function

## Summary

The `setProducers` function, which is responsible for registering producers, currently allows for the registration of the same producer multiple times. While this does not appear to have a massive impact on the protocol's functionality, it is advisable to address this issue to ensure the integrity and efficiency of the system.

## Recommendations

One effective solution is to implement a check using a mapping that verifies if a producer is already registered before allowing a new registration. This approach not only prevents the registration of duplicate producers but also enhances the overall robustness of the protocol

## Impact

producers array gets clogged up with the same address multiple times

## Tools Used

No tools used. It was discovered through manual inspection of the contract.

### [I-1]
