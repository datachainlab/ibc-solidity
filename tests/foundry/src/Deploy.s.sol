// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {Options} from "openzeppelin-foundry-upgrades/Options.sol";
import {OwnableUpgradeableIBCHandler} from "../../../contracts/core/25-handler/OwnableUpgradeableIBCHandler.sol";
import {IBCClient} from "../../../contracts/core/02-client/IBCClient.sol";
import {IBCConnectionSelfStateNoValidation} from
    "../../../contracts/core/03-connection/IBCConnectionSelfStateNoValidation.sol";
import {IBCChannelHandshake} from "../../../contracts/core/04-channel/IBCChannelHandshake.sol";
import {IBCChannelPacketSendRecv} from "../../../contracts/core/04-channel/IBCChannelPacketSendRecv.sol";
import {IBCChannelPacketTimeout} from "../../../contracts/core/04-channel/IBCChannelPacketTimeout.sol";
import {
    IBCChannelUpgradeInitTryAck,
    IBCChannelUpgradeConfirmOpenTimeoutCancel
} from "../../../contracts/core/04-channel/IBCChannelUpgrade.sol";
import {IIBCHandler} from "../../../contracts/core/25-handler/IIBCHandler.sol";
import {OwnableIBCHandler} from "../../../contracts/core/25-handler/OwnableIBCHandler.sol";
import {MockClient} from "../../../contracts/clients/mock/MockClient.sol";
import {QBFTClient} from "../../../contracts/clients/qbft/QBFTClient.sol";
import {ICS20Transfer} from "../../../contracts/apps/20-transfer/ICS20Transfer.sol";
import {ERC20Token} from "../../../contracts/apps/20-transfer/ERC20Token.sol";
import {IBCMockApp} from "../../../contracts/apps/mock/IBCMockApp.sol";

contract DeployScript is Script {
    string private constant MOCK_CLIENT_TYPE = "mock-client";
    string private constant QBFT_CLIENT_TYPE = "hb-qbft";
    string private constant ICS20_TRANSFER_PORT = "transfer";
    string private constant MOCK_PORT = "mock";

    function run() external {
        uint256 privateKey =
            vm.deriveKey(vm.envString("TEST_MNEMONIC"), uint32(vm.envOr("TEST_MNEMONIC_INDEX", uint32(0))));
        vm.startBroadcast(privateKey);

        IIBCHandler handler;
        if (vm.envOr("TEST_UPGRADEABLE", false)) {
            Options memory opts;
            opts.constructorData = abi.encode(
                new IBCClient(),
                new IBCConnectionSelfStateNoValidation(),
                new IBCChannelHandshake(),
                new IBCChannelPacketSendRecv(),
                new IBCChannelPacketTimeout(),
                new IBCChannelUpgradeInitTryAck(),
                new IBCChannelUpgradeConfirmOpenTimeoutCancel()
            );
            address proxy = Upgrades.deployUUPSProxy(
                "OwnableUpgradeableIBCHandler.sol",
                abi.encodePacked(OwnableUpgradeableIBCHandler.initialize.selector),
                opts
            );
            handler = IIBCHandler(proxy);
        } else {
            handler = IIBCHandler(
                new OwnableIBCHandler(
                    new IBCClient(),
                    new IBCConnectionSelfStateNoValidation(),
                    new IBCChannelHandshake(),
                    new IBCChannelPacketSendRecv(),
                    new IBCChannelPacketTimeout(),
                    new IBCChannelUpgradeInitTryAck(),
                    new IBCChannelUpgradeConfirmOpenTimeoutCancel()
                )
            );
        }

        // deploy ics20 contract
        ICS20Transfer transfer = new ICS20Transfer(handler, ICS20_TRANSFER_PORT);
        handler.bindPort(ICS20_TRANSFER_PORT, transfer);

        // deploy mock app contract
        IBCMockApp mockApp = new IBCMockApp(handler);
        handler.bindPort(MOCK_PORT, mockApp);

        // deploy client contracts
        MockClient mockClient = new MockClient(address(handler));
        QBFTClient qbftClient = new QBFTClient(address(handler));
        handler.registerClient(MOCK_CLIENT_TYPE, mockClient);
        handler.registerClient(QBFT_CLIENT_TYPE, qbftClient);

        // deploy test helpers
        new ERC20Token("test", "test", 1000000);

        vm.stopBroadcast();
    }
}
