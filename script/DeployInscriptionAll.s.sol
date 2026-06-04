// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {InscriptionFactory} from "../src/InscriptionFactory.sol";
import {InscriptionToken} from "../src/InscriptionToken.sol";

/// @notice 一键部署工厂并创建首个 inscription token（适合 Anvil / 本地联调）
/// @dev 可选环境变量：
///   INSCRIPTION_SYMBOL       - 默认 "MEME"
///   INSCRIPTION_TOTAL_SUPPLY - 默认 21_000_000
///   INSCRIPTION_PER_MINT     - 默认 1_000
///   INSCRIPTION_MINT         - 设为 1 则在部署后自动 mint 一次
contract DeployInscriptionAllScript is Script {
    InscriptionFactory public factory;
    address public tokenAddr;

    function setUp() public {}

    function run() public {
        string memory symbol = vm.envOr("INSCRIPTION_SYMBOL", string("MEME"));
        uint256 totalSupply = vm.envOr("INSCRIPTION_TOTAL_SUPPLY", uint256(21_000_000));
        uint256 perMint = vm.envOr("INSCRIPTION_PER_MINT", uint256(1_000));
        bool doMint = vm.envOr("INSCRIPTION_MINT", uint256(0)) == 1;

        vm.startBroadcast();

        factory = new InscriptionFactory();
        tokenAddr = factory.deployInscription(symbol, totalSupply, perMint);

        if (doMint) {
            factory.mintInscription(tokenAddr);
        }

        vm.stopBroadcast();

        console2.log("InscriptionFactory", address(factory));
        console2.log("Implementation", factory.implementation());
        console2.log("InscriptionToken", tokenAddr);
        console2.log("Symbol", symbol);
        console2.log("Total supply cap", totalSupply);
        console2.log("Per mint", perMint);
        if (doMint) {
            console2.log("Minter balance", InscriptionToken(tokenAddr).balanceOf(msg.sender));
        }
    }
}
