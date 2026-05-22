// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {MyToken} from "../src/MyToken.sol";
import {MyNFT} from "../src/MyNFT.sol";
import {NFTMarket} from "../src/NFTMarket.sol";

/// @notice 一次性部署 MyToken、MyNFT、NFTMarket
contract DeployAllScript is Script {
    MyToken public token;
    MyNFT public nft;
    NFTMarket public market;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        token = new MyToken(1_000_000);
        nft = new MyNFT("MyNFT", "MNFT", msg.sender);
        market = new NFTMarket(address(nft), address(token));

        vm.stopBroadcast();
    }
}
