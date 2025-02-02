// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "./helpers/IBCTestHelper.t.sol";
import {Vm, console2} from "forge-std/Test.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Upgrade, UpgradeFields, Timeout} from "../../../contracts/proto/Channel.sol";
import {LocalhostClientLib} from "../../../contracts/clients/09-localhost/LocalhostClient.sol";
import {LocalhostHelper} from "../../../contracts/clients/09-localhost/LocalhostHelper.sol";
import {IIBCChannelRecvPacket, IIBCChannelAcknowledgePacket} from "../../../contracts/core/04-channel/IIBCChannel.sol";
import {IIBCChannelUpgradeBase} from "../../../contracts/core/04-channel/IIBCChannelUpgrade.sol";
import {IBCChannelUpgradableMockApp} from "../../../contracts/apps/mock/IBCChannelUpgradableMockApp.sol";
import {IIBCHostErrors} from "../../../contracts/core/24-host/IIBCHostErrors.sol";
import {TestIBCChannelUpgradableMockAppInconsistentVersions} from "./helpers/TestIBCChannelUpgradableMockAppInconsistentVersions.t.sol";
import {ICS04UpgradeTestHelper} from "./helpers/ICS04UpgradeTestHelper.t.sol";
import {ICS04PacketEventTestHelper} from "./helpers/ICS04PacketTestHelper.t.sol";
import {
    IIBCChannelUpgradableModule
} from "../../../contracts/apps/commons/IBCChannelUpgradableModule.sol";
import {IBCMockLib} from "../../../contracts/apps/mock/IBCMockLib.sol";
import {IBCMockApp} from "../../../contracts/apps/mock/IBCMockApp.sol";

contract TestICS04Upgrade is ICS04UpgradeTestHelper, ICS04PacketEventTestHelper {
    using LocalhostHelper for TestableIBCHandler;

    string internal constant MOCK_APP_PORT = "mockapp";
    string internal constant MOCK_APP_VERSION_1 = "mockapp-1";
    string internal constant MOCK_APP_VERSION_2 = "mockapp-2";

    TestableIBCHandler ibcHandler;
    IBCChannelUpgradableMockApp mockApp;
    TestIBCChannelUpgradableMockAppInconsistentVersions maliciousMockApp;

    struct ChannelInfo {
        string connectionId;
        string portId;
        string channelId;
    }

    function setUp() public {
        ibcHandler = defaultIBCHandler();
        mockApp = new IBCChannelUpgradableMockApp(ibcHandler);
        maliciousMockApp = new TestIBCChannelUpgradableMockAppInconsistentVersions(ibcHandler);
        ibcHandler.bindPort(MOCK_APP_PORT, mockApp);
        ibcHandler.registerLocalhostClient();
        ibcHandler.createLocalhostClient();
    }

    // ------------------------------ Test Cases ------------------------------ //

    function testUpgradeInit() public {
        (ChannelInfo memory channel0,) = createMockAppLocalhostChannel(Channel.Order.ORDER_UNORDERED);
        vm.recordLogs();
        uint64 upgradeSequence = 1;
        mockApp.proposeUpgrade(
            channel0.portId,
            channel0.channelId,
            UpgradeFields.Data({
                ordering: Channel.Order.ORDER_UNORDERED,
                connection_hops: IBCChannelLib.buildConnectionHops(channel0.connectionId),
                version: MOCK_APP_VERSION_2
            }),
            Timeout.Data({height: H(10), timestamp: 0})
        );
        {
            // failure because the msg sender is not the upgrade authority
            vm.startPrank(address(0x01));
            IIBCChannelUpgradeBase.MsgChannelUpgradeInit memory msg_ = IIBCChannelUpgradeBase.MsgChannelUpgradeInit({
                portId: channel0.portId,
                channelId: channel0.channelId,
                proposedUpgradeFields: mockApp.getUpgradeProposal(channel0.portId, channel0.channelId).fields
            });
            vm.expectRevert();
            ibcHandler.channelUpgradeInit(msg_);
            vm.stopPrank();
        }
        {
            // success
            assertEq(
                ibcHandler.channelUpgradeInit(
                    IIBCChannelUpgradeBase.MsgChannelUpgradeInit({
                        portId: channel0.portId,
                        channelId: channel0.channelId,
                        proposedUpgradeFields: mockApp.getUpgradeProposal(channel0.portId, channel0.channelId).fields
                    })
                ),
                upgradeSequence
            );
            ensureChannelState(ibcHandler, channel0, Channel.State.STATE_OPEN);
        }
        {
            // success but error receipt of previous upgrade is emitted
            upgradeSequence = 2;
            mockApp.proposeUpgrade(
                channel0.portId,
                channel0.channelId,
                UpgradeFields.Data({
                    ordering: Channel.Order.ORDER_UNORDERED,
                    connection_hops: IBCChannelLib.buildConnectionHops(channel0.connectionId),
                    version: MOCK_APP_VERSION_2
                }),
                Timeout.Data({height: H(10), timestamp: 0})
            );
            assertEq(
                ibcHandler.channelUpgradeInit(
                    IIBCChannelUpgradeBase.MsgChannelUpgradeInit({
                        portId: channel0.portId,
                        channelId: channel0.channelId,
                        proposedUpgradeFields: mockApp.getUpgradeProposal(channel0.portId, channel0.channelId).fields
                    })
                ),
                upgradeSequence,
                "upgrade sequence mismatch"
            );
            ensureChannelState(ibcHandler, channel0, Channel.State.STATE_OPEN);
            ErrorReceipt.Data memory rc = getLastWriteErrorReceiptEvent(ibcHandler, vm.getRecordedLogs());
            assertEq(rc.sequence, 1, "sequence mismatch");
        }
    }

    function testUpgradeNotUpgradableModule() public {
        string memory portId = "not-upgradable";
        IIBCModule notUpgradableApp = new IBCMockApp(ibcHandler);
        ibcHandler.bindPort(portId, notUpgradableApp);
        (ChannelInfo memory channel0,) = createMockAppLocalhostChannel(Channel.Order.ORDER_UNORDERED, portId, portId, MOCK_APP_VERSION_1);
        IIBCChannelUpgradeBase.MsgChannelUpgradeInit memory msg_ = IIBCChannelUpgradeBase.MsgChannelUpgradeInit({
            portId: channel0.portId,
            channelId: channel0.channelId,
            proposedUpgradeFields: mockApp.getUpgradeProposal(channel0.portId, channel0.channelId).fields
        });
        vm.expectRevert(abi.encodeWithSelector(IIBCHostErrors.IBCHostModuleDoesNotSupportIIBCModuleUpgrade.selector, address(notUpgradableApp)));
        ibcHandler.channelUpgradeInit(msg_);
    }

    function testUpgradeOutOfSync() public {
        (ChannelInfo memory channel0, ChannelInfo memory channel1) =
            createMockAppLocalhostChannel(Channel.Order.ORDER_ORDERED);

        assertEq(
            mockApp.proposeAndInitUpgrade(
                channel0.portId,
                channel0.channelId,
                UpgradeFields.Data({
                    ordering: Channel.Order.ORDER_ORDERED,
                    connection_hops: IBCChannelLib.buildConnectionHops(channel0.connectionId),
                    version: MOCK_APP_VERSION_2
                }),
                Timeout.Data({height: H(10), timestamp: 0})
            ),
            1
        );
        assertEq(
            mockApp.proposeAndInitUpgrade(
                channel1.portId,
                channel1.channelId,
                UpgradeFields.Data({
                    ordering: Channel.Order.ORDER_ORDERED,
                    connection_hops: IBCChannelLib.buildConnectionHops(channel1.connectionId),
                    version: MOCK_APP_VERSION_2
                }),
                Timeout.Data({height: H(10), timestamp: 0})
            ),
            1
        );
        // authorize re-proposal for channel1 to advance the upgrade sequence to 2
        assertEq(
            mockApp.proposeAndInitUpgrade(
                channel1.portId,
                channel1.channelId,
                UpgradeFields.Data({
                    ordering: Channel.Order.ORDER_ORDERED,
                    connection_hops: IBCChannelLib.buildConnectionHops(channel1.connectionId),
                    version: MOCK_APP_VERSION_2
                }),
                Timeout.Data({height: H(10), timestamp: 0})
            ),
            2
        );
        {
            // channel0: sequence 1, channel1: sequence 2
            IIBCChannelUpgradeBase.MsgChannelUpgradeTry memory msg_ = IIBCChannelUpgradeBase.MsgChannelUpgradeTry({
                portId: channel0.portId,
                channelId: channel0.channelId,
                counterpartyUpgradeFields: mockApp.getUpgradeProposal(channel1.portId, channel1.channelId).fields,
                counterpartyUpgradeSequence: 2,
                proposedConnectionHops: IBCChannelLib.buildConnectionHops(channel0.connectionId),
                proofs: upgradeLocalhostProofs()
            });
            (bool ok, uint64 seq) = ibcHandler.channelUpgradeTry(msg_);
            assertTrue(ok);
            // channel0 advances to sequence 2
            assertEq(seq, 2);
        }
        {
            // channel0: sequence 2, channel1: sequence 2
            assertTrue(
                ibcHandler.channelUpgradeAck(
                    IIBCChannelUpgradeBase.MsgChannelUpgradeAck({
                        portId: channel1.portId,
                        channelId: channel1.channelId,
                        counterpartyUpgrade: getCounterpartyUpgrade(channel0.portId, channel0.channelId),
                        proofs: upgradeLocalhostProofs()
                    })
                )
            );
        }
    }

    function testUpgradeCrossingHelloIncompatibleProposals() public {
        (ChannelInfo memory channel0, ChannelInfo memory channel1) =
            createMockAppLocalhostChannel(Channel.Order.ORDER_ORDERED);

        // The proposals are incompatible because the ordering is different
        assertEq(
            mockApp.proposeAndInitUpgrade(
                channel0.portId,
                channel0.channelId,
                UpgradeFields.Data({
                    ordering: Channel.Order.ORDER_UNORDERED,
                    connection_hops: IBCChannelLib.buildConnectionHops(channel0.connectionId),
                    version: MOCK_APP_VERSION_2
                }),
                Timeout.Data({height: H(10), timestamp: 0})
            ),
            1
        );
        assertEq(
            mockApp.proposeAndInitUpgrade(
                channel1.portId,
                channel1.channelId,
                UpgradeFields.Data({
                    ordering: Channel.Order.ORDER_ORDERED,
                    connection_hops: IBCChannelLib.buildConnectionHops(channel1.connectionId),
                    version: MOCK_APP_VERSION_2
                }),
                Timeout.Data({height: H(10), timestamp: 0})
            ),
            1
        );

        // Try msg is reverted because the proposals are incompatible
        {
            IIBCChannelUpgradeBase.MsgChannelUpgradeTry memory msg_ = IIBCChannelUpgradeBase.MsgChannelUpgradeTry({
                portId: channel0.portId,
                channelId: channel0.channelId,
                counterpartyUpgradeFields: mockApp.getUpgradeProposal(channel1.portId, channel1.channelId).fields,
                counterpartyUpgradeSequence: 1,
                proposedConnectionHops: IBCChannelLib.buildConnectionHops(channel0.connectionId),
                proofs: upgradeLocalhostProofs()
            });
            vm.expectRevert(IIBCChannelUpgradeErrors.IBCChannelUpgradeIncompatibleProposal.selector);
            ibcHandler.channelUpgradeTry(msg_);
        }
        {
            IIBCChannelUpgradeBase.MsgChannelUpgradeTry memory msg_ = IIBCChannelUpgradeBase.MsgChannelUpgradeTry({
                portId: channel0.portId,
                channelId: channel0.channelId,
                counterpartyUpgradeFields: mockApp.getUpgradeProposal(channel1.portId, channel1.channelId).fields,
                counterpartyUpgradeSequence: 1,
                proposedConnectionHops: IBCChannelLib.buildConnectionHops(channel1.connectionId),
                proofs: upgradeLocalhostProofs()
            });
            vm.expectRevert(IIBCChannelUpgradeErrors.IBCChannelUpgradeTryProposedConnectionHopsMismatch.selector);
            ibcHandler.channelUpgradeTry(msg_);
        }
        {
            IIBCChannelUpgradeBase.MsgChannelUpgradeTry memory msg_ = IIBCChannelUpgradeBase.MsgChannelUpgradeTry({
                portId: channel0.portId,
                channelId: channel0.channelId,
                counterpartyUpgradeFields: mockApp.getUpgradeProposal(channel1.portId, channel1.channelId).fields,
                counterpartyUpgradeSequence: 1,
                proposedConnectionHops: new string[](0),
                proofs: upgradeLocalhostProofs()
            });
            vm.expectRevert(IIBCChannelUpgradeErrors.IBCChannelUpgradeTryProposedConnectionHopsEmpty.selector);
            ibcHandler.channelUpgradeTry(msg_);
        }
        {
            IIBCChannelUpgradeBase.MsgChannelUpgradeTry memory msg_ = IIBCChannelUpgradeBase.MsgChannelUpgradeTry({
                portId: channel1.portId,
                channelId: channel1.channelId,
                counterpartyUpgradeFields: mockApp.getUpgradeProposal(channel0.portId, channel0.channelId).fields,
                counterpartyUpgradeSequence: 1,
                proposedConnectionHops: IBCChannelLib.buildConnectionHops(channel1.connectionId),
                proofs: upgradeLocalhostProofs()
            });
            vm.expectRevert(IIBCChannelUpgradeErrors.IBCChannelUpgradeIncompatibleProposal.selector);
            ibcHandler.channelUpgradeTry(msg_);
        }
        {
            IIBCChannelUpgradeBase.MsgChannelUpgradeTry memory msg_ = IIBCChannelUpgradeBase.MsgChannelUpgradeTry({
                portId: channel1.portId,
                channelId: channel1.channelId,
                counterpartyUpgradeFields: mockApp.getUpgradeProposal(channel0.portId, channel0.channelId).fields,
                counterpartyUpgradeSequence: 1,
                proposedConnectionHops: IBCChannelLib.buildConnectionHops(channel0.connectionId),
                proofs: upgradeLocalhostProofs()
            });
            vm.expectRevert(IIBCChannelUpgradeErrors.IBCChannelUpgradeTryProposedConnectionHopsMismatch.selector);
            ibcHandler.channelUpgradeTry(msg_);
        }
        {
            IIBCChannelUpgradeBase.MsgChannelUpgradeTry memory msg_ = IIBCChannelUpgradeBase.MsgChannelUpgradeTry({
                portId: channel1.portId,
                channelId: channel1.channelId,
                counterpartyUpgradeFields: mockApp.getUpgradeProposal(channel0.portId, channel0.channelId).fields,
                counterpartyUpgradeSequence: 1,
                proposedConnectionHops: new string[](0),
                proofs: upgradeLocalhostProofs()
            });
            vm.expectRevert(IIBCChannelUpgradeErrors.IBCChannelUpgradeTryProposedConnectionHopsEmpty.selector);
            ibcHandler.channelUpgradeTry(msg_);
        }

        // channel0 advances to next upgrade sequence
        assertEq(
            mockApp.proposeAndInitUpgrade(
                channel0.portId,
                channel0.channelId,
                UpgradeFields.Data({
                    ordering: Channel.Order.ORDER_UNORDERED,
                    connection_hops: IBCChannelLib.buildConnectionHops(channel0.connectionId),
                    version: MOCK_APP_VERSION_2
                }),
                Timeout.Data({height: H(10), timestamp: 0})
            ),
            2
        );

        {
            // channel0: sequence 2, channel1: sequence 1
            // The error receipt of sequence 1 is already written for channel0, so the Try msg is reverted
            IIBCChannelUpgradeBase.MsgChannelUpgradeTry memory msg_ = IIBCChannelUpgradeBase.MsgChannelUpgradeTry({
                portId: channel0.portId,
                channelId: channel0.channelId,
                counterpartyUpgradeFields: mockApp.getUpgradeProposal(channel1.portId, channel1.channelId).fields,
                counterpartyUpgradeSequence: 1,
                proposedConnectionHops: IBCChannelLib.buildConnectionHops(channel0.connectionId),
                proofs: upgradeLocalhostProofs()
            });
            vm.expectRevert(
                abi.encodeWithSelector(
                    IIBCChannelUpgradeErrors.IBCChannelUpgradeWriteOldErrorReceiptSequence.selector, 1, 1
                )
            );
            ibcHandler.channelUpgradeTry(msg_);
        }
        {
            // channel0: sequence 2, channel1: sequence 1
            // The upgrade proposal is compatible with the channel1's
            IIBCChannelUpgradeBase.MsgChannelUpgradeTry memory msg_ = IIBCChannelUpgradeBase.MsgChannelUpgradeTry({
                portId: channel1.portId,
                channelId: channel1.channelId,
                counterpartyUpgradeFields: mockApp.getUpgradeProposal(channel0.portId, channel0.channelId).fields,
                counterpartyUpgradeSequence: 2,
                proposedConnectionHops: IBCChannelLib.buildConnectionHops(channel1.connectionId),
                proofs: upgradeLocalhostProofs()
            });
            vm.expectRevert(IIBCChannelUpgradeErrors.IBCChannelUpgradeIncompatibleProposal.selector);
            ibcHandler.channelUpgradeTry(msg_);
        }

        // channel1 advances to next upgrade sequence
        // and the upgrade proposal is compatible with the channel0's
        assertEq(
            mockApp.proposeAndInitUpgrade(
                channel1.portId,
                channel1.channelId,
                UpgradeFields.Data({
                    ordering: Channel.Order.ORDER_UNORDERED,
                    connection_hops: IBCChannelLib.buildConnectionHops(channel1.connectionId),
                    version: MOCK_APP_VERSION_2
                }),
                Timeout.Data({height: H(10), timestamp: 0})
            ),
            2
        );
        // channel0: sequence 2, channel1: sequence 2
        (bool ok,) = ibcHandler.channelUpgradeTry(
            IIBCChannelUpgradeBase.MsgChannelUpgradeTry({
                portId: channel0.portId,
                channelId: channel0.channelId,
                counterpartyUpgradeFields: mockApp.getUpgradeProposal(channel1.portId, channel1.channelId).fields,
                counterpartyUpgradeSequence: 2,
                proposedConnectionHops: IBCChannelLib.buildConnectionHops(channel0.connectionId),
                proofs: upgradeLocalhostProofs()
            })
        );
        assertTrue(ok);
    }

    function testCrossingHelloInconsistentVersions() public {
        string memory maliciousPortId = "mockapp-malicious";
        ibcHandler.bindPort(maliciousPortId, maliciousMockApp);
        (ChannelInfo memory channel0, ChannelInfo memory channel1) = crossingHelloFlushing(MOCK_APP_PORT, maliciousPortId);
        {
            Upgrade.Data memory counterpartyUpgrade = getCounterpartyUpgrade(channel1.portId, channel1.channelId);
            counterpartyUpgrade.fields.version = string(abi.encodePacked(counterpartyUpgrade.fields.version, "-inconsistent"));
            assertFalse(
                ibcHandler.channelUpgradeConfirm(
                    IIBCChannelUpgradeBase.MsgChannelUpgradeConfirm({
                        portId: channel0.portId,
                        channelId: channel0.channelId,
                        counterpartyChannelState: Channel.State.STATE_FLUSHING,
                        counterpartyUpgrade: counterpartyUpgrade,
                        proofs: upgradeLocalhostProofs()
                    })
                )
            );
        }
        (channel0, channel1) = crossingHelloFlushing(MOCK_APP_PORT, maliciousPortId);
        {
            Upgrade.Data memory counterpartyUpgrade = getCounterpartyUpgrade(channel0.portId, channel0.channelId);
            assertFalse(
                ibcHandler.channelUpgradeConfirm(
                    IIBCChannelUpgradeBase.MsgChannelUpgradeConfirm({
                        portId: channel1.portId,
                        channelId: channel1.channelId,
                        counterpartyChannelState: Channel.State.STATE_FLUSHING,
                        counterpartyUpgrade: counterpartyUpgrade,
                        proofs: upgradeLocalhostProofs()
                    })
                )
            );
        }
    }

    function testUpgradeNoChanges() public {
        (ChannelInfo memory channel0,) = createMockAppLocalhostChannel(Channel.Order.ORDER_UNORDERED);
        mockApp.proposeUpgrade(
            channel0.portId,
            channel0.channelId,
            UpgradeFields.Data({
                ordering: Channel.Order.ORDER_UNORDERED,
                connection_hops: IBCChannelLib.buildConnectionHops(channel0.connectionId),
                version: MOCK_APP_VERSION_1
            }),
            Timeout.Data({height: H(10), timestamp: 0})
        );
        IIBCChannelUpgradeBase.MsgChannelUpgradeInit memory msg_ = IIBCChannelUpgradeBase.MsgChannelUpgradeInit({
            portId: channel0.portId,
            channelId: channel0.channelId,
            proposedUpgradeFields: mockApp.getUpgradeProposal(channel0.portId, channel0.channelId).fields
        });
        vm.expectRevert(IIBCChannelUpgradeErrors.IBCChannelUpgradeNoChanges.selector);
        ibcHandler.channelUpgradeInit(msg_);
    }

    function testUpgradeFull() public {
        (ChannelInfo memory channelA, ChannelInfo memory channelB) =
            createMockAppLocalhostChannel(Channel.Order.ORDER_UNORDERED);
        HandshakeFlow[] memory flows = allHandshakeFlows();
        for (uint256 i = 0; i < 4; i++) {
            ChannelInfo memory channel0;
            ChannelInfo memory channel1;
            Channel.Order proposedOrder;
            if (i % 2 == 0) {
                (channel0, channel1) = (channelA, channelB);
                proposedOrder = Channel.Order.ORDER_ORDERED;
            } else {
                (channel0, channel1) = (channelB, channelA);
                proposedOrder = Channel.Order.ORDER_UNORDERED;
            }
            for (uint256 j = 0; j < flows.length; j++) {
                (string memory newConnectionId0, string memory newConnectionId1) =
                    ibcHandler.createLocalhostConnection();
                handshakeUpgrade(
                    channel0,
                    channel1,
                    validProposals(proposedOrder, newConnectionId0, newConnectionId1, mockVersion(i)),
                    flows[j]
                );
                (Channel.Data memory channelData0,) = ibcHandler.getChannel(channel0.portId, channel0.channelId);
                (Channel.Data memory channelData1,) = ibcHandler.getChannel(channel1.portId, channel1.channelId);
                assertEq(channelData0.connection_hops[0], newConnectionId0, "connection hop mismatch");
                assertEq(channelData1.connection_hops[0], newConnectionId1, "connection hop mismatch");
                assertEq(uint8(channelData0.ordering), uint8(proposedOrder), "ordering mismatch");
                assertEq(uint8(channelData1.ordering), uint8(proposedOrder), "ordering mismatch");
                assertEq(channelData0.version, mockVersion(i), "version mismatch");
                assertEq(channelData1.version, mockVersion(i), "version mismatch");
            }
        }
    }

    function testUpgradeAuthorityCancel() public {
        vm.recordLogs();
        HandshakeCallbacks[] memory callbacks = new HandshakeCallbacks[](6);
        for (uint256 i = 0; i < callbacks.length; i++) {
            callbacks[i] = emptyCallbacks();
        }
        callbacks[0].openInitAndOpen.callback = _cancelSuccessOnlySrc;
        callbacks[1].openInitAndFlushing.callback = _cancelSuccess;
        callbacks[1].openInitAndFlushing.reverse = true;
        callbacks[2].flushingAndFlushing.callback = _cancelSuccess;
        callbacks[3].flushingAndComplete.callback = _cancelSuccess;
        callbacks[4].flushingAndComplete.callback = _cancelFail;
        callbacks[4].flushingAndComplete.reverse = true;
        callbacks[5].openSucAndComplete.callback = _cancelFail;

        Channel.Order[2] memory orders = [Channel.Order.ORDER_UNORDERED, Channel.Order.ORDER_ORDERED];
        for (uint256 i = 0; i < orders.length; i++) {
            for (uint256 j = 0; j < callbacks.length; j++) {
                (ChannelInfo memory channel0, ChannelInfo memory channel1) = createMockAppLocalhostChannel(orders[i]);
                handshakeUpgradeWithCallbacks(
                    channel0,
                    channel1,
                    validProposals(orders[i], channel0.connectionId, channel1.connectionId, MOCK_APP_VERSION_2),
                    HandshakeFlow(false, false),
                    callbacks[j]
                );
            }
        }
    }

    function testUpgradeTimeoutAbortAck() public {
        (ChannelInfo memory channelA, ChannelInfo memory channelB) =
            createMockAppLocalhostChannel(Channel.Order.ORDER_ORDERED);

        Timeout.Data[3] memory timeouts = [
            Timeout.Data({height: H(getBlockNumber()), timestamp: 0}),
            Timeout.Data({height: H(0), timestamp: getBlockTimestampNano(0)}),
            Timeout.Data({height: H(getBlockNumber()), timestamp: getBlockTimestampNano()})
        ];
        HandshakeCallbacks memory callbacks = emptyCallbacks();
        callbacks.openInitAndFlushing.callback = _testUpgradeTimeoutAbortAck;
        vm.recordLogs();
        for (uint64 i = 0; i < 4; i++) {
            for (uint64 j = 0; j < timeouts.length; j++) {
                ChannelInfo memory channel0;
                ChannelInfo memory channel1;
                if (i % 2 == 0) {
                    (channel0, channel1) = (channelA, channelB);
                } else {
                    (channel0, channel1) = (channelB, channelA);
                }
                handshakeUpgradeWithCallbacks(
                    channel0,
                    channel1,
                    UpgradeProposals({
                        p0: UpgradeProposal({
                            order: Channel.Order.ORDER_UNORDERED,
                            connectionId: channel0.connectionId,
                            version: MOCK_APP_VERSION_1,
                            timeout: Timeout.Data({height: H(10), timestamp: 0})
                        }),
                        p1: UpgradeProposal({
                            order: Channel.Order.ORDER_UNORDERED,
                            connectionId: channel1.connectionId,
                            version: MOCK_APP_VERSION_1,
                            timeout: timeouts[j]
                        })
                    }),
                    HandshakeFlow(false, false),
                    callbacks
                );
            }
        }
    }

    function testUpgradeTimeoutAbortConfirm() public {
        (ChannelInfo memory channelA, ChannelInfo memory channelB) =
            createMockAppLocalhostChannel(Channel.Order.ORDER_UNORDERED);

        Timeout.Data[3] memory timeouts = [
            Timeout.Data({height: H(getBlockNumber()), timestamp: 0}),
            Timeout.Data({height: H(0), timestamp: getBlockTimestampNano()}),
            Timeout.Data({height: H(getBlockNumber()), timestamp: getBlockTimestampNano()})
        ];
        HandshakeCallbacks memory callbacks = emptyCallbacks();
        callbacks.flushingAndFlushing.callback = _testUpgradeTimeoutAbortConfirm;
        vm.recordLogs();
        for (uint64 i = 0; i < 4; i++) {
            for (uint64 j = 0; j < timeouts.length; j++) {
                ChannelInfo memory channel0;
                ChannelInfo memory channel1;
                if (i % 2 == 0) {
                    (channel0, channel1) = (channelA, channelB);
                } else {
                    (channel0, channel1) = (channelB, channelA);
                }
                handshakeUpgradeWithCallbacks(
                    channel0,
                    channel1,
                    UpgradeProposals({
                        p0: UpgradeProposal({
                            order: Channel.Order.ORDER_UNORDERED,
                            connectionId: channel0.connectionId,
                            version: MOCK_APP_VERSION_2,
                            timeout: timeouts[j]
                        }),
                        p1: UpgradeProposal({
                            order: Channel.Order.ORDER_UNORDERED,
                            connectionId: channel1.connectionId,
                            version: MOCK_APP_VERSION_2,
                            timeout: Timeout.Data({height: H(10), timestamp: 0})
                        })
                    }),
                    HandshakeFlow(false, false),
                    callbacks
                );
            }
        }
    }

    function testUpgradeTimeoutUpgrade() public {
        CallbacksTimeout[] memory cases = new CallbacksTimeout[](16);
        for (uint256 i = 0; i < cases.length; i++) {
            cases[i].callbacks = emptyCallbacks();
        }
        uint256 i = 0;

        // ------------------------------ Success Cases ------------------------------ //

        cases[i].callbacks.flushingAndFlushing.callback = _testUpgradeTimeoutUpgradeSuccess;
        cases[i].t0 = Timeout.Data({height: H(getBlockNumber(1)), timestamp: 0});
        cases[i].t1 = Timeout.Data({height: H(getBlockNumber(1)), timestamp: 0});
        i++;

        cases[i].callbacks.flushingAndFlushing.callback = _testUpgradeTimeoutUpgradeSuccess;
        cases[i].t0 = Timeout.Data({height: H(0), timestamp: getBlockTimestampNano(1)});
        cases[i].t1 = Timeout.Data({height: H(0), timestamp: getBlockTimestampNano(1)});
        i++;

        cases[i].callbacks.openInitAndFlushing.callback = _testUpgradeTimeoutUpgradeSuccess;
        cases[i].callbacks.openInitAndFlushing.reverse = true;
        cases[i].t0 = Timeout.Data({height: H(getBlockNumber(1)), timestamp: 0});
        cases[i].t1 = Timeout.Data({height: H(getBlockNumber(1)), timestamp: 0});
        i++;

        cases[i].callbacks.openInitAndFlushing.callback = _testUpgradeTimeoutUpgradeSuccess;
        cases[i].callbacks.openInitAndFlushing.reverse = true;
        cases[i].t0 = Timeout.Data({height: H(0), timestamp: getBlockTimestampNano(1)});
        cases[i].t1 = Timeout.Data({height: H(0), timestamp: getBlockTimestampNano(1)});
        i++;

        cases[i].callbacks.flushingAndComplete.callback = _testUpgradeTimeoutUpgradeSuccess;
        cases[i].callbacks.flushingAndComplete.reverse = true;
        cases[i].t0 = Timeout.Data({height: H(getBlockNumber(1)), timestamp: 0});
        cases[i].t1 = Timeout.Data({height: H(getBlockNumber(1)), timestamp: 0});
        i++;

        cases[i].callbacks.flushingAndComplete.callback = _testUpgradeTimeoutUpgradeSuccess;
        cases[i].callbacks.flushingAndComplete.reverse = true;
        cases[i].t0 = Timeout.Data({height: H(0), timestamp: getBlockTimestampNano(1)});
        cases[i].t1 = Timeout.Data({height: H(0), timestamp: getBlockTimestampNano(1)});
        i++;

        // ------------------------------ Failure Cases ------------------------------ //

        cases[i].callbacks.flushingAndFlushing.callback = _testUpgradeTimeoutUpgradeFailTimeoutHeightNotReached;
        cases[i].t0 = Timeout.Data({height: H(getBlockNumber(1)), timestamp: 0});
        cases[i].t1 = Timeout.Data({height: H(getBlockNumber(1)), timestamp: 0});
        i++;

        cases[i].callbacks.flushingAndFlushing.callback = _testUpgradeTimeoutUpgradeFailTimeoutTimestampNotReached;
        cases[i].t0 = Timeout.Data({height: H(0), timestamp: getBlockTimestampNano(1)});
        cases[i].t1 = Timeout.Data({height: H(0), timestamp: getBlockTimestampNano(1)});
        i++;

        cases[i].callbacks.flushingAndComplete.callback = _testUpgradeTimeoutUpgradeFailReached;
        cases[i].t0 = Timeout.Data({height: H(getBlockNumber(1)), timestamp: 0});
        cases[i].t1 = Timeout.Data({height: H(getBlockNumber(1)), timestamp: 0});
        i++;

        cases[i].callbacks.flushingAndComplete.callback = _testUpgradeTimeoutUpgradeFailReached;
        cases[i].t0 = Timeout.Data({height: H(0), timestamp: getBlockTimestampNano(1)});
        cases[i].t1 = Timeout.Data({height: H(0), timestamp: getBlockTimestampNano(1)});
        i++;

        cases[i].callbacks.openSucAndComplete.callback = _testUpgradeTimeoutUpgradeFailReachedAlreadyUpgraded;
        cases[i].callbacks.openSucAndComplete.reverse = true;
        cases[i].t0 = Timeout.Data({height: H(getBlockNumber(1)), timestamp: 0});
        cases[i].t1 = Timeout.Data({height: H(getBlockNumber(1)), timestamp: 0});
        i++;

        cases[i].callbacks.openSucAndComplete.callback = _testUpgradeTimeoutUpgradeFailReachedAlreadyUpgraded;
        cases[i].callbacks.openSucAndComplete.reverse = true;
        cases[i].t0 = Timeout.Data({height: H(0), timestamp: getBlockTimestampNano(1)});
        cases[i].t1 = Timeout.Data({height: H(0), timestamp: getBlockTimestampNano(1)});
        i++;

        cases[i].callbacks.completeAndComplete.callback = _testUpgradeTimeoutUpgradeFailReachedAlreadyCompleted;
        cases[i].t0 = Timeout.Data({height: H(getBlockNumber(1)), timestamp: 0});
        cases[i].t1 = Timeout.Data({height: H(getBlockNumber(1)), timestamp: 0});
        i++;

        cases[i].callbacks.completeAndComplete.callback = _testUpgradeTimeoutUpgradeFailReachedAlreadyCompleted;
        cases[i].t0 = Timeout.Data({height: H(0), timestamp: getBlockTimestampNano(1)});
        cases[i].t1 = Timeout.Data({height: H(0), timestamp: getBlockTimestampNano(1)});
        i++;

        cases[i].callbacks.completeAndComplete.callback = _testUpgradeTimeoutUpgradeFailReachedAlreadyCompleted;
        cases[i].callbacks.completeAndComplete.reverse = true;
        cases[i].t0 = Timeout.Data({height: H(getBlockNumber(1)), timestamp: 0});
        cases[i].t1 = Timeout.Data({height: H(getBlockNumber(1)), timestamp: 0});
        i++;

        cases[i].callbacks.completeAndComplete.callback = _testUpgradeTimeoutUpgradeFailReachedAlreadyCompleted;
        cases[i].callbacks.completeAndComplete.reverse = true;
        cases[i].t0 = Timeout.Data({height: H(0), timestamp: getBlockTimestampNano(1)});
        cases[i].t1 = Timeout.Data({height: H(0), timestamp: getBlockTimestampNano(1)});
        i++;

        require(i == cases.length, "invalid number of cases");

        for (uint256 i = 0; i < cases.length; i++) {
            console2.log("case:", i);
            (uint256 height, uint256 timestampSec) = (getBlockNumber(), vm.getBlockTimestamp());
            (ChannelInfo memory channel0, ChannelInfo memory channel1) =
                createMockAppLocalhostChannel(Channel.Order.ORDER_UNORDERED);
            handshakeUpgradeWithCallbacks(
                channel0,
                channel1,
                UpgradeProposals({
                    p0: UpgradeProposal({
                        order: Channel.Order.ORDER_UNORDERED,
                        connectionId: channel0.connectionId,
                        version: mockVersion(i + 2),
                        timeout: cases[i].t0
                    }),
                    p1: UpgradeProposal({
                        order: Channel.Order.ORDER_UNORDERED,
                        connectionId: channel1.connectionId,
                        version: mockVersion(i + 2),
                        timeout: cases[i].t1
                    })
                }),
                HandshakeFlow(false, false),
                cases[i].callbacks
            );
            // restore the block height and timestamp
            vm.roll(height);
            vm.warp(timestampSec);
        }
    }

    function testUpgradeCannotCancelWithOldErrorReceipt() public {
        (ChannelInfo memory channel0, ChannelInfo memory channel1) =
            createMockAppLocalhostChannel(Channel.Order.ORDER_UNORDERED);
        vm.recordLogs();
        mockApp.proposeAndInitUpgrade(
            channel0.portId,
            channel0.channelId,
            UpgradeFields.Data({
                ordering: Channel.Order.ORDER_UNORDERED,
                connection_hops: IBCChannelLib.buildConnectionHops(channel0.connectionId),
                version: MOCK_APP_VERSION_2
            }),
            Timeout.Data({height: H(10), timestamp: 0})
        );
        mockApp.proposeAndInitUpgrade(
            channel1.portId,
            channel1.channelId,
            UpgradeFields.Data({
                ordering: Channel.Order.ORDER_UNORDERED,
                connection_hops: IBCChannelLib.buildConnectionHops(channel1.connectionId),
                version: MOCK_APP_VERSION_2
            }),
            Timeout.Data({height: H(10), timestamp: 0})
        );
        ibcHandler.cancelChannelUpgrade(
            IIBCChannelUpgradeBase.MsgCancelChannelUpgrade({
                portId: channel1.portId,
                channelId: channel1.channelId,
                errorReceipt: emptyErrorReceipt(),
                proofUpgradeError: LocalhostClientLib.sentinelProof(),
                proofHeight: H(getBlockNumber())
            })
        );
        ErrorReceipt.Data memory rc = getLastWriteErrorReceiptEvent(ibcHandler, vm.getRecordedLogs());
        mockApp.proposeAndInitUpgrade(
            channel0.portId,
            channel0.channelId,
            UpgradeFields.Data({
                ordering: Channel.Order.ORDER_UNORDERED,
                connection_hops: IBCChannelLib.buildConnectionHops(channel0.connectionId),
                version: MOCK_APP_VERSION_2
            }),
            Timeout.Data({height: H(10), timestamp: 0})
        );
        vm.startPrank(address(0x01));
        vm.expectRevert(IIBCChannelUpgradeErrors.IBCChannelUpgradeOldErrorReceiptSequence.selector);
        ibcHandler.cancelChannelUpgrade(
            IIBCChannelUpgradeBase.MsgCancelChannelUpgrade({
                portId: channel0.portId,
                channelId: channel0.channelId,
                errorReceipt: rc,
                proofUpgradeError: LocalhostClientLib.sentinelProof(),
                proofHeight: H(getBlockNumber())
            })
        );
        vm.stopPrank();
    }

    function testUpgradeCounterpartyAdvanceNextSequenceBeforeOpen() public {
        HandshakeCallbacks memory callbacks = emptyCallbacks();
        callbacks.openSucAndComplete.callback = _testUpgradeCounterpartyAdvanceNextSequenceBeforeOpen;
        (ChannelInfo memory channel0, ChannelInfo memory channel1) =
            createMockAppLocalhostChannel(Channel.Order.ORDER_UNORDERED);
        handshakeUpgradeWithCallbacks(
            channel0,
            channel1,
            UpgradeProposals({
                p0: UpgradeProposal({
                    order: Channel.Order.ORDER_UNORDERED,
                    connectionId: channel0.connectionId,
                    version: MOCK_APP_VERSION_2,
                    timeout: Timeout.Data({height: H(10), timestamp: 0})
                }),
                p1: UpgradeProposal({
                    order: Channel.Order.ORDER_UNORDERED,
                    connectionId: channel1.connectionId,
                    version: MOCK_APP_VERSION_2,
                    timeout: Timeout.Data({height: H(10), timestamp: 0})
                })
            }),
            HandshakeFlow(false, false),
            callbacks
        );
    }

    function testUpgradeSendPacketFailAtFlushingOrFlushComplete() public {
        HandshakeCallbacks memory callbacks = emptyCallbacks();
        callbacks.flushingAndFlushing.callback = _testUpgradeSendPacketFailAtFlushingOrFlushComplete;
        (ChannelInfo memory channel0, ChannelInfo memory channel1) =
            createMockAppLocalhostChannel(Channel.Order.ORDER_ORDERED);
        handshakeUpgradeWithCallbacks(
            channel0,
            channel1,
            validProposals(
                Channel.Order.ORDER_ORDERED, channel0.connectionId, channel1.connectionId, MOCK_APP_VERSION_2
            ),
            HandshakeFlow(false, false),
            callbacks
        );
    }

    function _testUpgradeSendPacketFailAtFlushingOrFlushComplete(
        IIBCHandler,
        ChannelInfo memory channel0,
        ChannelInfo memory channel1
    ) internal returns (bool) {
        vm.expectRevert(
            abi.encodeWithSelector(
                IIBCChannelErrors.IBCChannelUnexpectedChannelState.selector, uint8(Channel.State.STATE_FLUSHING)
            )
        );
        mockApp.sendPacket(IBCMockLib.MOCK_PACKET_DATA, channel0.portId, channel0.channelId, H(10), 0);
        vm.expectRevert(
            abi.encodeWithSelector(
                IIBCChannelErrors.IBCChannelUnexpectedChannelState.selector, uint8(Channel.State.STATE_FLUSHING)
            )
        );
        mockApp.sendPacket(IBCMockLib.MOCK_PACKET_DATA, channel1.portId, channel1.channelId, H(10), 0);
        return false;
    }

    function testUpgradeRelaySuccessAtFlushing() public {
        vm.recordLogs();
        HandshakeCallbacks memory callbacks = emptyCallbacks();
        callbacks.flushingAndFlushing.callback = _testUpgradeRelaySuccessAtFlushing;
        (ChannelInfo memory channel0, ChannelInfo memory channel1) =
            createMockAppLocalhostChannel(Channel.Order.ORDER_UNORDERED);
        mockApp.sendPacket(IBCMockLib.MOCK_PACKET_DATA, channel0.portId, channel0.channelId, H(uint64(getBlockNumber(1))), 0);
        mockApp.sendPacket(IBCMockLib.MOCK_PACKET_DATA, channel1.portId, channel1.channelId, H(uint64(getBlockNumber(1))), 0);
        handshakeUpgradeWithCallbacks(
            channel0,
            channel1,
            validProposals(
                Channel.Order.ORDER_UNORDERED, channel0.connectionId, channel1.connectionId, MOCK_APP_VERSION_2
            ),
            HandshakeFlow(false, false),
            callbacks
        );
    }

    function _testUpgradeRelaySuccessAtFlushing(
        IIBCHandler handler,
        ChannelInfo memory channel0,
        ChannelInfo memory channel1
    ) internal returns (bool) {
        Vm.Log[] memory logs = vm.getRecordedLogs();
        Packet memory p0 = getLastSentPacket(handler, channel0.portId, channel0.channelId, logs);
        Packet memory p1 = getLastSentPacket(handler, channel1.portId, channel1.channelId, logs);
        ibcHandler.recvPacket(
            IIBCChannelRecvPacket.MsgPacketRecv({
                packet: p0,
                proof: LocalhostClientLib.sentinelProof(),
                proofHeight: H(getBlockNumber())
            })
        );
        ibcHandler.acknowledgePacket(
            IIBCChannelAcknowledgePacket.MsgPacketAcknowledgement({
                packet: p0,
                acknowledgement: getLastWrittenAcknowledgement(handler, vm.getRecordedLogs()).acknowledgement,
                proof: LocalhostClientLib.sentinelProof(),
                proofHeight: H(getBlockNumber())
            })
        );
        ibcHandler.recvPacket(
            IIBCChannelRecvPacket.MsgPacketRecv({
                packet: p1,
                proof: LocalhostClientLib.sentinelProof(),
                proofHeight: H(getBlockNumber())
            })
        );
        ibcHandler.acknowledgePacket(
            IIBCChannelAcknowledgePacket.MsgPacketAcknowledgement({
                packet: p1,
                acknowledgement: getLastWrittenAcknowledgement(handler, vm.getRecordedLogs()).acknowledgement,
                proof: LocalhostClientLib.sentinelProof(),
                proofHeight: H(getBlockNumber())
            })
        );
        return true;
    }

    function testUpgradeRelaySuccessAtCounterpartyFlushComplete() public {
        vm.recordLogs();
        HandshakeCallbacks memory callbacks = emptyCallbacks();
        callbacks.flushingAndComplete.callback = _testUpgradeRelaySuccessAtCounterpartyFlushComplete;
        (ChannelInfo memory channel0, ChannelInfo memory channel1) =
            createMockAppLocalhostChannel(Channel.Order.ORDER_UNORDERED);
        mockApp.sendPacket(IBCMockLib.MOCK_PACKET_DATA, channel0.portId, channel0.channelId, H(uint64(getBlockNumber(1))), 0);
        handshakeUpgradeWithCallbacks(
            channel0,
            channel1,
            validProposals(
                Channel.Order.ORDER_UNORDERED, channel0.connectionId, channel1.connectionId, MOCK_APP_VERSION_2
            ),
            HandshakeFlow(false, false),
            callbacks
        );
    }

    function _testUpgradeRelaySuccessAtCounterpartyFlushComplete(
        IIBCHandler handler,
        ChannelInfo memory channel0,
        ChannelInfo memory
    ) internal returns (bool) {
        Vm.Log[] memory logs = vm.getRecordedLogs();
        Packet memory p0 = getLastSentPacket(handler, channel0.portId, channel0.channelId, logs);
        ibcHandler.recvPacket(
            IIBCChannelRecvPacket.MsgPacketRecv({
                packet: p0,
                proof: LocalhostClientLib.sentinelProof(),
                proofHeight: H(getBlockNumber())
            })
        );
        ibcHandler.acknowledgePacket(
            IIBCChannelAcknowledgePacket.MsgPacketAcknowledgement({
                packet: p0,
                acknowledgement: getLastWrittenAcknowledgement(handler, vm.getRecordedLogs()).acknowledgement,
                proof: LocalhostClientLib.sentinelProof(),
                proofHeight: H(getBlockNumber())
            })
        );
        return true;
    }

    function testUpgradeCannotRecvNextUpgradePacket() public {
        vm.recordLogs();
        HandshakeCallbacks memory callbacks = emptyCallbacks();
        callbacks.openSucAndComplete.callback = _testUpgradeCannotRecvNextUpgradePacket;
        (ChannelInfo memory channel0, ChannelInfo memory channel1) =
            createMockAppLocalhostChannel(Channel.Order.ORDER_UNORDERED);
        handshakeUpgradeWithCallbacks(
            channel0,
            channel1,
            validProposals(
                Channel.Order.ORDER_UNORDERED, channel0.connectionId, channel1.connectionId, MOCK_APP_VERSION_2
            ),
            HandshakeFlow(false, false),
            callbacks
        );
    }

    function _testUpgradeCannotRecvNextUpgradePacket(
        IIBCHandler handler,
        ChannelInfo memory channel0,
        ChannelInfo memory channel1
    ) internal returns (bool) {
        MockAppRelayResult memory result = mockAppRelay(channel0, channel1, IBCMockLib.MOCK_PACKET_DATA, RelayPhase.None);
        vm.expectRevert(
            abi.encodeWithSelector(IIBCChannelErrors.IBCChannelCannotRecvNextUpgradePacket.selector, result.packet.sequence, uint64(1))
        );
        handler.recvPacket(
            IIBCChannelRecvPacket.MsgPacketRecv({
                packet: result.packet,
                proof: LocalhostClientLib.sentinelProof(),
                proofHeight: H(getBlockNumber())
            })
        );
        ibcHandler.channelUpgradeOpen(
            IIBCChannelUpgradeBase.MsgChannelUpgradeOpen({
                portId: channel1.portId,
                channelId: channel1.channelId,
                counterpartyChannelState: Channel.State.STATE_OPEN,
                counterpartyUpgradeSequence: 1,
                proofChannel: LocalhostClientLib.sentinelProof(),
                proofHeight: H(getBlockNumber())
            })
        );
        ensureChannelState(handler, channel1, Channel.State.STATE_OPEN);
        handler.recvPacket(
            IIBCChannelRecvPacket.MsgPacketRecv({
                packet: result.packet,
                proof: LocalhostClientLib.sentinelProof(),
                proofHeight: H(getBlockNumber())
            })
        );
        ibcHandler.acknowledgePacket(
            IIBCChannelAcknowledgePacket.MsgPacketAcknowledgement({
                packet: result.packet,
                acknowledgement: getLastWrittenAcknowledgement(handler, vm.getRecordedLogs()).acknowledgement,
                proof: LocalhostClientLib.sentinelProof(),
                proofHeight: H(getBlockNumber())
            })
        );
        return false;
    }

    function testFlushCompletePacketAcknowledgementOrdered() public {
        vm.recordLogs();
        HandshakeCallbacks memory callbacks = emptyCallbacks();
        callbacks.flushingAndComplete.callback = _breakCallback;
        (ChannelInfo memory channel0, ChannelInfo memory channel1) =
            createMockAppLocalhostChannel(Channel.Order.ORDER_ORDERED);

        MockAppRelayResult memory res1 = mockAppRelay(channel1, channel0, IBCMockLib.MOCK_PACKET_DATA, RelayPhase.RecvPacket);
        handshakeUpgradeWithCallbacks(
            channel0,
            channel1,
            validProposals(
                Channel.Order.ORDER_ORDERED, channel0.connectionId, channel1.connectionId, MOCK_APP_VERSION_2
            ),
            HandshakeFlow(false, false),
            callbacks
        );
        ensureChannelState(ibcHandler, channel1, Channel.State.STATE_FLUSHING);
        ibcHandler.channelUpgradeConfirm(
            IIBCChannelUpgradeBase.MsgChannelUpgradeConfirm({
                portId: channel1.portId,
                channelId: channel1.channelId,
                counterpartyChannelState: Channel.State.STATE_FLUSHCOMPLETE,
                counterpartyUpgrade: getCounterpartyUpgrade(channel0.portId, channel0.channelId),
                proofs: upgradeLocalhostProofs()
            })
        );
        ensureChannelState(ibcHandler, channel1, Channel.State.STATE_FLUSHING);
        ibcHandler.acknowledgePacket(
            IIBCChannelAcknowledgePacket.MsgPacketAcknowledgement({
                packet: res1.packet,
                acknowledgement: res1.ack,
                proof: LocalhostClientLib.sentinelProof(),
                proofHeight: H(getBlockNumber())
            })
        );
        ensureChannelState(ibcHandler, channel1, Channel.State.STATE_FLUSHCOMPLETE);
    }

    function testFlushCompletePacketAcknowledgementUnordered() public {
        vm.recordLogs();
        HandshakeCallbacks memory callbacks = emptyCallbacks();
        callbacks.flushingAndComplete.callback = _breakCallback;
        (ChannelInfo memory channel0, ChannelInfo memory channel1) =
            createMockAppLocalhostChannel(Channel.Order.ORDER_UNORDERED);

        MockAppRelayResult memory res0 = mockAppRelay(channel0, channel1, IBCMockLib.MOCK_PACKET_DATA, RelayPhase.RecvPacket);
        uint64 upgradeSequence = handshakeUpgradeWithCallbacks(
            channel0,
            channel1,
            validProposals(
                Channel.Order.ORDER_UNORDERED, channel0.connectionId, channel1.connectionId, MOCK_APP_VERSION_2
            ),
            HandshakeFlow(false, false),
            callbacks
        );
        ensureChannelState(ibcHandler, channel0, Channel.State.STATE_FLUSHING);
        IIBCChannelUpgradableModule(address(ibcHandler.getIBCModuleByPort(channel0.portId))).allowTransitionToFlushComplete(channel0.portId, channel0.channelId, upgradeSequence);
        ibcHandler.acknowledgePacket(
            IIBCChannelAcknowledgePacket.MsgPacketAcknowledgement({
                packet: res0.packet,
                acknowledgement: res0.ack,
                proof: LocalhostClientLib.sentinelProof(),
                proofHeight: H(getBlockNumber())
            })
        );
        ensureChannelState(ibcHandler, channel0, Channel.State.STATE_FLUSHCOMPLETE);
    }

    function testFlushingClosePacketTimeoutOrdered() public {
        vm.recordLogs();
        HandshakeCallbacks memory callbacks = emptyCallbacks();
        callbacks.flushingAndComplete.callback = _breakCallback;
        (ChannelInfo memory channel0, ChannelInfo memory channel1) =
            createMockAppLocalhostChannel(Channel.Order.ORDER_ORDERED);

        MockAppRelayResult memory res1 = mockAppRelay(channel1, channel0, IBCMockLib.MOCK_PACKET_DATA, RelayPhase.None);
        handshakeUpgradeWithCallbacks(
            channel0,
            channel1,
            validProposals(
                Channel.Order.ORDER_ORDERED, channel0.connectionId, channel1.connectionId, MOCK_APP_VERSION_2,
                Timeout.Data({height: H(10), timestamp: 0}),
                Timeout.Data({height: H(10), timestamp: 0})
            ),
            HandshakeFlow(false, false),
            callbacks
        );
        vm.roll(getBlockNumber() + 1);
        ibcHandler.timeoutPacket(
            IIBCChannelPacketTimeout.MsgTimeoutPacket({
                packet: res1.packet,
                proof: LocalhostClientLib.sentinelProof(),
                proofHeight: H(getBlockNumber()),
                nextSequenceRecv: 1
            })
        );
        ensureChannelState(ibcHandler, channel1, Channel.State.STATE_CLOSED);
        (, bool found) = ibcHandler.getChannelUpgrade(channel1.portId, channel1.channelId);
        assertFalse(found);
        assertEq(ibcHandler.getCommitment(IBCCommitment.channelUpgradeCommitmentKey(channel1.portId, channel1.channelId)), bytes32(0));
    }

    function testFlushCompletePacketTimeoutUnordered() public {
        vm.recordLogs();
        HandshakeCallbacks memory callbacks = emptyCallbacks();
        callbacks.flushingAndComplete.callback = _breakCallback;
        (ChannelInfo memory channel0, ChannelInfo memory channel1) =
            createMockAppLocalhostChannel(Channel.Order.ORDER_UNORDERED);

        MockAppRelayResult memory res0 = mockAppRelay(channel0, channel1, IBCMockLib.MOCK_PACKET_DATA, RelayPhase.None);
        uint64 upgradeSequence = handshakeUpgradeWithCallbacks(
            channel0,
            channel1,
            validProposals(
                Channel.Order.ORDER_UNORDERED, channel0.connectionId, channel1.connectionId, MOCK_APP_VERSION_2,
                Timeout.Data({height: H(10), timestamp: 0}),
                Timeout.Data({height: H(10), timestamp: 0})
            ),
            HandshakeFlow(false, false),
            callbacks
        );
        vm.roll(getBlockNumber() + 1);
        ensureChannelState(ibcHandler, channel0, Channel.State.STATE_FLUSHING);
        IIBCChannelUpgradableModule(address(ibcHandler.getIBCModuleByPort(channel0.portId))).allowTransitionToFlushComplete(channel0.portId, channel0.channelId, upgradeSequence);
        ibcHandler.timeoutPacket(
            IIBCChannelPacketTimeout.MsgTimeoutPacket({
                packet: res0.packet,
                proof: LocalhostClientLib.sentinelProof(),
                proofHeight: H(getBlockNumber()),
                nextSequenceRecv: 0
            })
        );
        ensureChannelState(ibcHandler, channel0, Channel.State.STATE_FLUSHCOMPLETE);
        (, bool found) = ibcHandler.getChannelUpgrade(channel1.portId, channel1.channelId);
        assertTrue(found);
    }

    function testFlushingClosedCounterpartyUpgradeTimeoutOrdered() public {
        vm.recordLogs();
        HandshakeCallbacks memory callbacks = emptyCallbacks();
        callbacks.flushingAndComplete.callback = _breakCallback;
        (ChannelInfo memory channel0, ChannelInfo memory channel1) =
            createMockAppLocalhostChannel(Channel.Order.ORDER_ORDERED);

        MockAppRelayResult memory res1 = mockAppRelay(channel1, channel0, IBCMockLib.MOCK_PACKET_DATA, RelayPhase.None);
        handshakeUpgradeWithCallbacks(
            channel0,
            channel1,
            validProposals(
                Channel.Order.ORDER_ORDERED, channel0.connectionId, channel1.connectionId, MOCK_APP_VERSION_2,
                Timeout.Data({height: H(getBlockNumber(1)), timestamp: 0}),
                Timeout.Data({height: H(getBlockNumber(1)), timestamp: 0})
            ),
            HandshakeFlow(false, false),
            callbacks
        );
        ensureChannelState(ibcHandler, channel1, Channel.State.STATE_FLUSHING);
        vm.roll(getBlockNumber() + 1);
        ibcHandler.timeoutPacket(
            IIBCChannelPacketTimeout.MsgTimeoutPacket({
                packet: res1.packet,
                proof: LocalhostClientLib.sentinelProof(),
                proofHeight: H(getBlockNumber()),
                nextSequenceRecv: 1
            })
        );
        ensureChannelState(ibcHandler, channel1, Channel.State.STATE_CLOSED);
        (, bool found) = ibcHandler.getChannelUpgrade(channel1.portId, channel1.channelId);
        assertFalse(found);
        assertEq(ibcHandler.getCommitment(IBCCommitment.channelUpgradeCommitmentKey(channel1.portId, channel1.channelId)), bytes32(0));
    }

    function testFlushingRestoreCounterpartyUpgradeTimeoutUnordered() public {
        vm.recordLogs();
        HandshakeCallbacks memory callbacks = emptyCallbacks();
        callbacks.flushingAndComplete.callback = _breakCallback;
        (ChannelInfo memory channel0, ChannelInfo memory channel1) =
            createMockAppLocalhostChannel(Channel.Order.ORDER_UNORDERED);

        MockAppRelayResult memory res0 = mockAppRelay(channel0, channel1, IBCMockLib.MOCK_PACKET_DATA, RelayPhase.None);
        handshakeUpgradeWithCallbacks(
            channel0,
            channel1,
            validProposals(
                Channel.Order.ORDER_UNORDERED, channel0.connectionId, channel1.connectionId, MOCK_APP_VERSION_2,
                Timeout.Data({height: H(getBlockNumber(1)), timestamp: 0}),
                Timeout.Data({height: H(getBlockNumber(1)), timestamp: 0})
            ),
            HandshakeFlow(false, false),
            callbacks
        );
        vm.roll(getBlockNumber() + 1);
        ensureChannelState(ibcHandler, channel0, Channel.State.STATE_FLUSHING);
        ibcHandler.timeoutPacket(
            IIBCChannelPacketTimeout.MsgTimeoutPacket({
                packet: res0.packet,
                proof: LocalhostClientLib.sentinelProof(),
                proofHeight: H(getBlockNumber()),
                nextSequenceRecv: 0
            })
        );
        ensureChannelState(ibcHandler, channel0, Channel.State.STATE_OPEN);
        (, bool found) = ibcHandler.getChannelUpgrade(channel0.portId, channel0.channelId);
        assertFalse(found);
        assertEq(ibcHandler.getCommitment(IBCCommitment.channelUpgradeCommitmentKey(channel0.portId, channel0.channelId)), bytes32(0));
    }

    function _breakCallback(
        IIBCHandler,
        ChannelInfo memory,
        ChannelInfo memory
    ) internal returns (bool) {
        return false;
    }

    function testUpgradeToUnordered() public {
        vm.recordLogs();
        Channel.Order[2] memory orders = [Channel.Order.ORDER_ORDERED, Channel.Order.ORDER_UNORDERED];
        for (uint256 i = 0; i < orders.length; i++) {
            {
                (ChannelInfo memory channel0, ChannelInfo memory channel1) = createMockAppLocalhostChannel(orders[i]);
                handshakeUpgrade(
                    channel0,
                    channel1,
                    validProposals(
                        Channel.Order.ORDER_UNORDERED, channel0.connectionId, channel1.connectionId, MOCK_APP_VERSION_2
                    ),
                    HandshakeFlow(false, false)
                );
                ensureNextSequences(channel0, 1, 1, 1);
                ensureNextSequences(channel1, 1, 1, 1);
            }
            {
                (ChannelInfo memory channel0, ChannelInfo memory channel1) = createMockAppLocalhostChannel(orders[i]);
                assertEq(mockAppRelay(channel0, channel1, IBCMockLib.MOCK_PACKET_DATA, RelayPhase.AckPacket).packet.sequence, 1);
                assertEq(mockAppRelay(channel1, channel0, IBCMockLib.MOCK_PACKET_DATA, RelayPhase.AckPacket).packet.sequence, 1);
                assertEq(mockAppRelay(channel0, channel1, IBCMockLib.MOCK_PACKET_DATA, RelayPhase.AckPacket).packet.sequence, 2);
                handshakeUpgrade(
                    channel0,
                    channel1,
                    validProposals(
                        Channel.Order.ORDER_UNORDERED, channel0.connectionId, channel1.connectionId, MOCK_APP_VERSION_2
                    ),
                    HandshakeFlow(false, false)
                );
                ensureNextSequences(channel0, 3, 1, 1);
                ensureNextSequences(channel1, 2, 1, 1);
            }
            {
                (ChannelInfo memory channel0, ChannelInfo memory channel1) = createMockAppLocalhostChannel(orders[i]);
                assertEq(mockAppRelay(channel0, channel1, IBCMockLib.MOCK_PACKET_DATA, RelayPhase.AckPacket).packet.sequence, 1);
                assertEq(mockAppRelay(channel1, channel0, IBCMockLib.MOCK_PACKET_DATA, RelayPhase.AckPacket).packet.sequence, 1);
                assertEq(mockAppRelay(channel0, channel1, IBCMockLib.MOCK_PACKET_DATA, RelayPhase.None).packet.sequence, 2);
                handshakeUpgrade(
                    channel0,
                    channel1,
                    validProposals(
                        Channel.Order.ORDER_UNORDERED, channel0.connectionId, channel1.connectionId, MOCK_APP_VERSION_2
                    ),
                    HandshakeFlow(false, false)
                );
                ensureNextSequences(channel0, 3, 1, 1);
                ensureNextSequences(channel1, 2, 1, 1);
            }
            {
                (ChannelInfo memory channel0, ChannelInfo memory channel1) = createMockAppLocalhostChannel(orders[i]);
                assertEq(mockAppRelay(channel0, channel1, IBCMockLib.MOCK_PACKET_DATA, RelayPhase.AckPacket).packet.sequence, 1);
                assertEq(mockAppRelay(channel1, channel0, IBCMockLib.MOCK_PACKET_DATA, RelayPhase.AckPacket).packet.sequence, 1);
                assertEq(mockAppRelay(channel0, channel1, IBCMockLib.MOCK_PACKET_DATA, RelayPhase.RecvPacket).packet.sequence, 2);
                handshakeUpgrade(
                    channel0,
                    channel1,
                    validProposals(
                        Channel.Order.ORDER_UNORDERED, channel0.connectionId, channel1.connectionId, MOCK_APP_VERSION_2
                    ),
                    HandshakeFlow(false, false)
                );
                ensureNextSequences(channel0, 3, 1, 1);
                ensureNextSequences(channel1, 2, 1, 1);
            }
        }
    }

    function testUpgradeToOrdered() public {
        vm.recordLogs();
        Channel.Order[2] memory orders = [Channel.Order.ORDER_UNORDERED, Channel.Order.ORDER_ORDERED];
        for (uint256 i = 0; i < orders.length; i++) {
            {
                (ChannelInfo memory channel0, ChannelInfo memory channel1) = createMockAppLocalhostChannel(orders[i]);
                handshakeUpgrade(
                    channel0,
                    channel1,
                    validProposals(
                        Channel.Order.ORDER_ORDERED, channel0.connectionId, channel1.connectionId, MOCK_APP_VERSION_2
                    ),
                    HandshakeFlow(false, false)
                );
                ensureNextSequences(channel0, 1, 1, 1);
                ensureNextSequences(channel1, 1, 1, 1);
            }
            {
                (ChannelInfo memory channel0, ChannelInfo memory channel1) = createMockAppLocalhostChannel(orders[i]);
                assertEq(mockAppRelay(channel0, channel1, IBCMockLib.MOCK_PACKET_DATA, RelayPhase.AckPacket).packet.sequence, 1);
                assertEq(mockAppRelay(channel1, channel0, IBCMockLib.MOCK_PACKET_DATA, RelayPhase.AckPacket).packet.sequence, 1);
                handshakeUpgrade(
                    channel0,
                    channel1,
                    validProposals(
                        Channel.Order.ORDER_ORDERED, channel0.connectionId, channel1.connectionId, mockVersion(2)
                    ),
                    HandshakeFlow(false, false)
                );
                ensureNextSequences(channel0, 2, 2, 2);
                ensureNextSequences(channel1, 2, 2, 2);
            }
            {
                (ChannelInfo memory channel0, ChannelInfo memory channel1) = createMockAppLocalhostChannel(orders[i]);
                assertEq(mockAppRelay(channel0, channel1, IBCMockLib.MOCK_PACKET_DATA, RelayPhase.AckPacket).packet.sequence, 1);
                assertEq(mockAppRelay(channel1, channel0, IBCMockLib.MOCK_PACKET_DATA, RelayPhase.AckPacket).packet.sequence, 1);
                assertEq(mockAppRelay(channel0, channel1, IBCMockLib.MOCK_PACKET_DATA, RelayPhase.AckPacket).packet.sequence, 2);
                handshakeUpgrade(
                    channel0,
                    channel1,
                    validProposals(
                        Channel.Order.ORDER_ORDERED, channel0.connectionId, channel1.connectionId, mockVersion(2)
                    ),
                    HandshakeFlow(false, false)
                );
                ensureNextSequences(channel0, 3, 3, 2);
                ensureNextSequences(channel1, 2, 2, 3);
            }
            {
                (ChannelInfo memory channel0, ChannelInfo memory channel1) = createMockAppLocalhostChannel(orders[i]);
                assertEq(mockAppRelay(channel0, channel1, IBCMockLib.MOCK_PACKET_DATA, RelayPhase.AckPacket).packet.sequence, 1);
                assertEq(mockAppRelay(channel1, channel0, IBCMockLib.MOCK_PACKET_DATA, RelayPhase.AckPacket).packet.sequence, 1);
                assertEq(mockAppRelay(channel0, channel1, IBCMockLib.MOCK_PACKET_DATA, RelayPhase.None).packet.sequence, 2);
                handshakeUpgrade(
                    channel0,
                    channel1,
                    validProposals(
                        Channel.Order.ORDER_ORDERED, channel0.connectionId, channel1.connectionId, mockVersion(2)
                    ),
                    HandshakeFlow(false, false)
                );
                ensureNextSequences(channel0, 3, 3, 2);
                ensureNextSequences(channel1, 2, 2, 3);
            }
            {
                (ChannelInfo memory channel0, ChannelInfo memory channel1) = createMockAppLocalhostChannel(orders[i]);
                assertEq(mockAppRelay(channel0, channel1, IBCMockLib.MOCK_PACKET_DATA, RelayPhase.AckPacket).packet.sequence, 1);
                assertEq(mockAppRelay(channel1, channel0, IBCMockLib.MOCK_PACKET_DATA, RelayPhase.AckPacket).packet.sequence, 1);
                assertEq(mockAppRelay(channel0, channel1, IBCMockLib.MOCK_PACKET_DATA, RelayPhase.RecvPacket).packet.sequence, 2);
                handshakeUpgrade(
                    channel0,
                    channel1,
                    validProposals(
                        Channel.Order.ORDER_ORDERED, channel0.connectionId, channel1.connectionId, mockVersion(2)
                    ),
                    HandshakeFlow(false, false)
                );
                ensureNextSequences(channel0, 3, 3, 2);
                ensureNextSequences(channel1, 2, 2, 3);
            }
        }
    }

    // ------------------------------ Internal Functions ------------------------------ //

    struct UpgradeProposals {
        UpgradeProposal p0;
        UpgradeProposal p1;
    }

    struct UpgradeProposal {
        Channel.Order order;
        string connectionId;
        string version;
        Timeout.Data timeout;
    }

    function validProposals(
        Channel.Order order,
        string memory channel0ConnectionId,
        string memory channel1ConnectionId,
        string memory appVersion
    ) internal view returns (UpgradeProposals memory) {
        return UpgradeProposals({
            p0: UpgradeProposal({
                order: order,
                connectionId: channel0ConnectionId,
                version: appVersion,
                timeout: Timeout.Data({height: H(getBlockNumber(1)), timestamp: 0})
            }),
            p1: UpgradeProposal({
                order: order,
                connectionId: channel1ConnectionId,
                version: appVersion,
                timeout: Timeout.Data({height: H(getBlockNumber(1)), timestamp: 0})
            })
        });
    }

    function validProposals(
        Channel.Order order,
        string memory channel0ConnectionId,
        string memory channel1ConnectionId,
        string memory appVersion,
        Timeout.Data memory timeout0,
        Timeout.Data memory timeout1
    ) internal view returns (UpgradeProposals memory) {
        return UpgradeProposals({
            p0: UpgradeProposal({
                order: order,
                connectionId: channel0ConnectionId,
                version: appVersion,
                timeout: timeout0
            }),
            p1: UpgradeProposal({
                order: order,
                connectionId: channel1ConnectionId,
                version: appVersion,
                timeout: timeout1
            })
        });
    }

    struct HandshakeFlow {
        bool crossingHello;
        bool fastPath;
    }

    function allHandshakeFlows() private pure returns (HandshakeFlow[] memory) {
        HandshakeFlow[] memory flows = new HandshakeFlow[](4);
        flows[0] = HandshakeFlow(false, false);
        flows[1] = HandshakeFlow(true, false);
        flows[2] = HandshakeFlow(false, true);
        flows[3] = HandshakeFlow(true, true);
        return flows;
    }

    function handshakeUpgrade(
        ChannelInfo memory channel0,
        ChannelInfo memory channel1,
        UpgradeProposals memory proposals,
        HandshakeFlow memory flow
    ) internal returns (uint64) {
        return handshakeUpgradeWithCallbacks(channel0, channel1, proposals, flow, emptyCallbacks());
    }

    function handshakeUpgradeWithCallbacks(
        ChannelInfo memory channel0,
        ChannelInfo memory channel1,
        UpgradeProposals memory proposals,
        HandshakeFlow memory flow,
        HandshakeCallbacks memory callbacks
    ) internal returns (uint64 upgradeSequence) {
        Channel.Order currentOrder;
        {
            (Channel.Data memory channelData0,) = ibcHandler.getChannel(channel0.portId, channel0.channelId);
            (Channel.Data memory channelData1,) = ibcHandler.getChannel(channel1.portId, channel1.channelId);
            require(channelData0.upgrade_sequence == channelData1.upgrade_sequence, "upgrade sequence mismatch");
            require(channelData0.ordering == channelData1.ordering, "ordering mismatch");
            currentOrder = channelData0.ordering;
            upgradeSequence = channelData0.upgrade_sequence + 1;
        }
        {
            // Init@channel0: OPEN -> OPEN(INIT)
            IIBCChannelUpgradableModule(address(ibcHandler.getIBCModuleByPort(channel0.portId))).proposeUpgrade(
                channel0.portId,
                channel0.channelId,
                UpgradeFields.Data({
                    ordering: proposals.p0.order,
                    connection_hops: IBCChannelLib.buildConnectionHops(proposals.p0.connectionId),
                    version: proposals.p0.version
                }),
                proposals.p0.timeout
            );
            assertEq(
                ibcHandler.channelUpgradeInit(
                    IIBCChannelUpgradeBase.MsgChannelUpgradeInit({
                        portId: channel0.portId,
                        channelId: channel0.channelId,
                        proposedUpgradeFields: IIBCChannelUpgradableModule(address(ibcHandler.getIBCModuleByPort(channel0.portId))).getUpgradeProposal(channel0.portId, channel0.channelId).fields
                    })
                ),
                upgradeSequence
            );
            ensureChannelState(ibcHandler, channel0, Channel.State.STATE_OPEN);
            if (!callbacks.openInitAndOpen.reverse) {
                if (!callbacks.openInitAndOpen.callback(ibcHandler, channel0, channel1)) {
                    return upgradeSequence;
                }
            } else {
                if (!callbacks.openInitAndOpen.callback(ibcHandler, channel1, channel0)) {
                    return upgradeSequence;
                }
            }
        }

        IIBCChannelUpgradableModule(address(ibcHandler.getIBCModuleByPort(channel1.portId))).proposeUpgrade(
            channel1.portId,
            channel1.channelId,
            UpgradeFields.Data({
                ordering: proposals.p1.order,
                connection_hops: IBCChannelLib.buildConnectionHops(proposals.p1.connectionId),
                version: proposals.p1.version
            }),
            proposals.p1.timeout
        );

        if (flow.crossingHello) {
            // Init@channel1: OPEN -> OPEN(INIT)
            assertEq(
                ibcHandler.channelUpgradeInit(
                    IIBCChannelUpgradeBase.MsgChannelUpgradeInit({
                        portId: channel1.portId,
                        channelId: channel1.channelId,
                        proposedUpgradeFields: IIBCChannelUpgradableModule(address(ibcHandler.getIBCModuleByPort(channel1.portId))).getUpgradeProposal(channel1.portId, channel1.channelId).fields
                    })
                ),
                upgradeSequence
            );
        }

        {
            // Try@channel1: OPEN(INIT) -> FLUSHING
            IIBCChannelUpgradeBase.MsgChannelUpgradeTry memory msg_ = IIBCChannelUpgradeBase.MsgChannelUpgradeTry({
                portId: channel1.portId,
                channelId: channel1.channelId,
                counterpartyUpgradeFields: IIBCChannelUpgradableModule(address(ibcHandler.getIBCModuleByPort(channel0.portId))).getUpgradeProposal(channel0.portId, channel0.channelId).fields,
                counterpartyUpgradeSequence: upgradeSequence,
                proposedConnectionHops: IBCChannelLib.buildConnectionHops(proposals.p1.connectionId),
                proofs: upgradeLocalhostProofs()
            });
            (bool ok, uint64 seq) = ibcHandler.channelUpgradeTry(msg_);
            assertTrue(ok);
            assertEq(seq, upgradeSequence);
            ensureChannelState(ibcHandler, channel1, Channel.State.STATE_FLUSHING);
            if (!callbacks.openInitAndFlushing.reverse) {
                if (!callbacks.openInitAndFlushing.callback(ibcHandler, channel0, channel1)) {
                    return upgradeSequence;
                }
            } else {
                if (!callbacks.openInitAndFlushing.callback(ibcHandler, channel1, channel0)) {
                    return upgradeSequence;
                }
            }
        }

        bool skipFlushCompleteAuthorization = false;
        {
            bool channel0SequenceMatch = ibcHandler.getNextSequenceSend(channel0.portId, channel0.channelId)
                == ibcHandler.getNextSequenceAck(channel0.portId, channel0.channelId);
            bool channel1SequenceMatch = ibcHandler.getNextSequenceSend(channel1.portId, channel1.channelId)
                == ibcHandler.getNextSequenceAck(channel1.portId, channel1.channelId);
            // If the channel is ORDERED and the all packets have been acknowledged, we can use the fast path to upgrade
            skipFlushCompleteAuthorization =
                currentOrder == Channel.Order.ORDER_ORDERED && channel0SequenceMatch && channel1SequenceMatch;
        }

        if (flow.fastPath && !skipFlushCompleteAuthorization) {
            // Ack@channel0: OPEN(INIT) -> FLUSHING
            assertTrue(
                ibcHandler.channelUpgradeAck(
                    IIBCChannelUpgradeBase.MsgChannelUpgradeAck({
                        portId: channel0.portId,
                        channelId: channel0.channelId,
                        counterpartyUpgrade: getCounterpartyUpgrade(channel1.portId, channel1.channelId),
                        proofs: upgradeLocalhostProofs()
                    })
                )
            );
            ensureChannelState(ibcHandler, channel0, Channel.State.STATE_FLUSHING);
            assertFalse(ibcHandler.getCanTransitionToFlushComplete(channel0.portId, channel0.channelId));
            assertFalse(ibcHandler.getCanTransitionToFlushComplete(channel1.portId, channel1.channelId));
            IIBCChannelUpgradableModule(address(ibcHandler.getIBCModuleByPort(channel0.portId))).allowTransitionToFlushComplete(channel0.portId, channel0.channelId, upgradeSequence);
            assertTrue(ibcHandler.getCanTransitionToFlushComplete(channel0.portId, channel0.channelId));
            IIBCChannelUpgradableModule(address(ibcHandler.getIBCModuleByPort(channel1.portId))).allowTransitionToFlushComplete(channel1.portId, channel1.channelId, upgradeSequence);
            assertTrue(ibcHandler.getCanTransitionToFlushComplete(channel1.portId, channel1.channelId));
        }
        if (skipFlushCompleteAuthorization || flow.fastPath) {
            // Ack@channel0: OPEN(INIT) or FLUSHING -> FLUSHCOMPLETE
            assertTrue(
                ibcHandler.channelUpgradeAck(
                    IIBCChannelUpgradeBase.MsgChannelUpgradeAck({
                        portId: channel0.portId,
                        channelId: channel0.channelId,
                        counterpartyUpgrade: getCounterpartyUpgrade(channel1.portId, channel1.channelId),
                        proofs: upgradeLocalhostProofs()
                    })
                )
            );
            ensureChannelState(ibcHandler, channel0, Channel.State.STATE_FLUSHCOMPLETE);

            // Confirm@channel1: FLUSHING -> OPEN
            assertTrue(
                ibcHandler.channelUpgradeConfirm(
                    IIBCChannelUpgradeBase.MsgChannelUpgradeConfirm({
                        portId: channel1.portId,
                        channelId: channel1.channelId,
                        counterpartyChannelState: Channel.State.STATE_FLUSHCOMPLETE,
                        counterpartyUpgrade: getCounterpartyUpgrade(channel0.portId, channel0.channelId),
                        proofs: upgradeLocalhostProofs()
                    })
                )
            );
            ensureChannelState(ibcHandler, channel1, Channel.State.STATE_OPEN);

            // Open@channel0: FLUSHCOMPLETE -> OPEN
            ibcHandler.channelUpgradeOpen(
                IIBCChannelUpgradeBase.MsgChannelUpgradeOpen({
                    portId: channel0.portId,
                    channelId: channel0.channelId,
                    counterpartyChannelState: Channel.State.STATE_OPEN,
                    counterpartyUpgradeSequence: upgradeSequence,
                    proofChannel: LocalhostClientLib.sentinelProof(),
                    proofHeight: H(getBlockNumber())
                })
            );
            ensureChannelState(ibcHandler, channel0, Channel.State.STATE_OPEN);
        } else if (
            currentOrder == Channel.Order.ORDER_ORDERED
                && ibcHandler.getNextSequenceSend(channel0.portId, channel0.channelId)
                    != ibcHandler.getNextSequenceAck(channel0.portId, channel0.channelId)
        ) {
            // Ack@channel0: OPEN(INIT) -> FLUSHING
            assertTrue(
                ibcHandler.channelUpgradeAck(
                    IIBCChannelUpgradeBase.MsgChannelUpgradeAck({
                        portId: channel0.portId,
                        channelId: channel0.channelId,
                        counterpartyUpgrade: getCounterpartyUpgrade(channel1.portId, channel1.channelId),
                        proofs: upgradeLocalhostProofs()
                    })
                )
            );
            ensureChannelState(ibcHandler, channel0, Channel.State.STATE_FLUSHING);

            assertFalse(ibcHandler.getCanTransitionToFlushComplete(channel0.portId, channel0.channelId));
            IIBCChannelUpgradableModule(address(ibcHandler.getIBCModuleByPort(channel0.portId))).allowTransitionToFlushComplete(channel0.portId, channel0.channelId, upgradeSequence);
            assertTrue(ibcHandler.getCanTransitionToFlushComplete(channel0.portId, channel0.channelId));
            // Confirm@channel0: FLUSHING -> FLUSHCOMPLETE
            assertTrue(
                ibcHandler.channelUpgradeConfirm(
                    IIBCChannelUpgradeBase.MsgChannelUpgradeConfirm({
                        portId: channel0.portId,
                        channelId: channel0.channelId,
                        counterpartyChannelState: Channel.State.STATE_FLUSHING,
                        counterpartyUpgrade: getCounterpartyUpgrade(channel1.portId, channel1.channelId),
                        proofs: upgradeLocalhostProofs()
                    })
                )
            );
            ensureChannelState(ibcHandler, channel0, Channel.State.STATE_FLUSHCOMPLETE);

            if (!callbacks.flushingAndComplete.reverse) {
                if (!callbacks.flushingAndComplete.callback(ibcHandler, channel1, channel0)) {
                    return upgradeSequence;
                }
            } else {
                if (!callbacks.flushingAndComplete.callback(ibcHandler, channel0, channel1)) {
                    return upgradeSequence;
                }
            }

            // Confirm@channel1: FLUSHING -> OPEN
            assertTrue(
                ibcHandler.channelUpgradeConfirm(
                    IIBCChannelUpgradeBase.MsgChannelUpgradeConfirm({
                        portId: channel1.portId,
                        channelId: channel1.channelId,
                        counterpartyChannelState: Channel.State.STATE_FLUSHCOMPLETE,
                        counterpartyUpgrade: getCounterpartyUpgrade(channel0.portId, channel0.channelId),
                        proofs: upgradeLocalhostProofs()
                    })
                )
            );
            ensureChannelState(ibcHandler, channel1, Channel.State.STATE_OPEN);

            // Open@channel0: FLUSHCOMPLETE -> OPEN
            ibcHandler.channelUpgradeOpen(
                IIBCChannelUpgradeBase.MsgChannelUpgradeOpen({
                    portId: channel0.portId,
                    channelId: channel0.channelId,
                    counterpartyChannelState: Channel.State.STATE_OPEN,
                    counterpartyUpgradeSequence: upgradeSequence,
                    proofChannel: LocalhostClientLib.sentinelProof(),
                    proofHeight: H(getBlockNumber())
                })
            );
            ensureChannelState(ibcHandler, channel0, Channel.State.STATE_OPEN);
        } else if (
            currentOrder == Channel.Order.ORDER_ORDERED
                && ibcHandler.getNextSequenceSend(channel1.portId, channel1.channelId)
                    != ibcHandler.getNextSequenceAck(channel1.portId, channel1.channelId)
        ) {
            // Ack@channel0: OPEN(INIT) -> FLUSHCOMPLETE
            assertTrue(
                ibcHandler.channelUpgradeAck(
                    IIBCChannelUpgradeBase.MsgChannelUpgradeAck({
                        portId: channel0.portId,
                        channelId: channel0.channelId,
                        counterpartyUpgrade: getCounterpartyUpgrade(channel1.portId, channel1.channelId),
                        proofs: upgradeLocalhostProofs()
                    })
                )
            );
            ensureChannelState(ibcHandler, channel0, Channel.State.STATE_FLUSHCOMPLETE);

            if (!callbacks.flushingAndComplete.reverse) {
                if (!callbacks.flushingAndComplete.callback(ibcHandler, channel1, channel0)) {
                    return upgradeSequence;
                }
            } else {
                if (!callbacks.flushingAndComplete.callback(ibcHandler, channel0, channel1)) {
                    return upgradeSequence;
                }
            }

            assertFalse(ibcHandler.getCanTransitionToFlushComplete(channel1.portId, channel1.channelId));
            IIBCChannelUpgradableModule(address(ibcHandler.getIBCModuleByPort(channel1.portId))).allowTransitionToFlushComplete(channel1.portId, channel1.channelId, upgradeSequence);
            assertTrue(ibcHandler.getCanTransitionToFlushComplete(channel1.portId, channel1.channelId));
            // Confirm@channel1: FLUSHING -> OPEN
            assertTrue(
                ibcHandler.channelUpgradeConfirm(
                    IIBCChannelUpgradeBase.MsgChannelUpgradeConfirm({
                        portId: channel1.portId,
                        channelId: channel1.channelId,
                        counterpartyChannelState: Channel.State.STATE_FLUSHCOMPLETE,
                        counterpartyUpgrade: getCounterpartyUpgrade(channel0.portId, channel0.channelId),
                        proofs: upgradeLocalhostProofs()
                    })
                )
            );
            ensureChannelState(ibcHandler, channel1, Channel.State.STATE_OPEN);

            // Open@channel0: FLUSHCOMPLETE -> OPEN
            ibcHandler.channelUpgradeOpen(
                IIBCChannelUpgradeBase.MsgChannelUpgradeOpen({
                    portId: channel0.portId,
                    channelId: channel0.channelId,
                    counterpartyChannelState: Channel.State.STATE_OPEN,
                    counterpartyUpgradeSequence: upgradeSequence,
                    proofChannel: LocalhostClientLib.sentinelProof(),
                    proofHeight: H(getBlockNumber())
                })
            );
            ensureChannelState(ibcHandler, channel0, Channel.State.STATE_OPEN);
        } else {
            // Ack@channel0: OPEN(INIT) -> FLUSHING
            assertTrue(
                ibcHandler.channelUpgradeAck(
                    IIBCChannelUpgradeBase.MsgChannelUpgradeAck({
                        portId: channel0.portId,
                        channelId: channel0.channelId,
                        counterpartyUpgrade: getCounterpartyUpgrade(channel1.portId, channel1.channelId),
                        proofs: upgradeLocalhostProofs()
                    })
                )
            );
            ensureChannelState(ibcHandler, channel0, Channel.State.STATE_FLUSHING);
            if (!callbacks.flushingAndFlushing.reverse) {
                if (!callbacks.flushingAndFlushing.callback(ibcHandler, channel0, channel1)) {
                    return upgradeSequence;
                }
            } else {
                if (!callbacks.flushingAndFlushing.callback(ibcHandler, channel1, channel0)) {
                    return upgradeSequence;
                }
            }

            // Tx will be success but cannot transition to FLUSHCOMPLETE because `canTransitionToFlushComplete` returns false
            // Confirm@channel1: FLUSHING -> FLUSHING
            assertTrue(
                ibcHandler.channelUpgradeConfirm(
                    IIBCChannelUpgradeBase.MsgChannelUpgradeConfirm({
                        portId: channel1.portId,
                        channelId: channel1.channelId,
                        counterpartyChannelState: Channel.State.STATE_FLUSHING,
                        counterpartyUpgrade: getCounterpartyUpgrade(channel0.portId, channel0.channelId),
                        proofs: upgradeLocalhostProofs()
                    })
                )
            );
            ensureChannelState(ibcHandler, channel1, Channel.State.STATE_FLUSHING);

            {
                (Channel.Data memory channel1Data,) = ibcHandler.getChannel(channel1.portId, channel1.channelId);
                // Confirm@channel1: FLUSHING -> FLUSHCOMPLETE
                assertFalse(ibcHandler.getCanTransitionToFlushComplete(channel1.portId, channel1.channelId));
                IIBCChannelUpgradableModule(address(ibcHandler.getIBCModuleByPort(channel1.portId))).allowTransitionToFlushComplete(channel1.portId, channel1.channelId, upgradeSequence);
                assertTrue(ibcHandler.getCanTransitionToFlushComplete(channel1.portId, channel1.channelId));
                assertTrue(
                    ibcHandler.channelUpgradeConfirm(
                        IIBCChannelUpgradeBase.MsgChannelUpgradeConfirm({
                            portId: channel1.portId,
                            channelId: channel1.channelId,
                            counterpartyChannelState: Channel.State.STATE_FLUSHING,
                            counterpartyUpgrade: getCounterpartyUpgrade(channel0.portId, channel0.channelId),
                            proofs: upgradeLocalhostProofs()
                        })
                    )
                );
                ensureChannelState(ibcHandler, channel1, Channel.State.STATE_FLUSHCOMPLETE);
                if (!callbacks.flushingAndComplete.reverse) {
                    if (!callbacks.flushingAndComplete.callback(ibcHandler, channel0, channel1)) {
                        return upgradeSequence;
                    }
                } else {
                    if (!callbacks.flushingAndComplete.callback(ibcHandler, channel1, channel0)) {
                        return upgradeSequence;
                    }
                }

                assertFalse(ibcHandler.getCanTransitionToFlushComplete(channel0.portId, channel0.channelId));
                IIBCChannelUpgradableModule(address(ibcHandler.getIBCModuleByPort(channel0.portId))).allowTransitionToFlushComplete(channel0.portId, channel0.channelId, upgradeSequence);
                assertTrue(ibcHandler.getCanTransitionToFlushComplete(channel0.portId, channel0.channelId));
                mockCallVerifyChannelState(
                    address(LocalhostHelper.getLocalhostClient(ibcHandler)), channel1, channel1Data
                );
                // Confirm@channel0: FLUSHING -> FLUSHCOMPLETE
                ibcHandler.channelUpgradeConfirm(
                    IIBCChannelUpgradeBase.MsgChannelUpgradeConfirm({
                        portId: channel0.portId,
                        channelId: channel0.channelId,
                        counterpartyChannelState: Channel.State.STATE_FLUSHING,
                        counterpartyUpgrade: getCounterpartyUpgrade(channel1.portId, channel1.channelId),
                        proofs: upgradeLocalhostProofs()
                    })
                );
                vm.clearMockedCalls();
            }

            if (!callbacks.completeAndComplete.reverse) {
                if (!callbacks.completeAndComplete.callback(ibcHandler, channel0, channel1)) {
                    return upgradeSequence;
                }
            } else {
                if (!callbacks.completeAndComplete.callback(ibcHandler, channel1, channel0)) {
                    return upgradeSequence;
                }
            }
            // Open@channel0: FLUSHCOMPLETE -> OPEN
            ibcHandler.channelUpgradeOpen(
                IIBCChannelUpgradeBase.MsgChannelUpgradeOpen({
                    portId: channel0.portId,
                    channelId: channel0.channelId,
                    counterpartyChannelState: Channel.State.STATE_FLUSHCOMPLETE,
                    counterpartyUpgradeSequence: upgradeSequence,
                    proofChannel: LocalhostClientLib.sentinelProof(),
                    proofHeight: H(getBlockNumber())
                })
            );
            ensureChannelState(ibcHandler, channel0, Channel.State.STATE_OPEN);
            if (!callbacks.openSucAndComplete.reverse) {
                if (!callbacks.openSucAndComplete.callback(ibcHandler, channel0, channel1)) {
                    return upgradeSequence;
                }
            } else {
                if (!callbacks.openSucAndComplete.callback(ibcHandler, channel1, channel0)) {
                    return upgradeSequence;
                }
            }

            {
                (Channel.Data memory ch0,) = ibcHandler.getChannel(channel0.portId, channel0.channelId);
                // Open@channel1: FLUSHCOMPLETE -> OPEN
                ibcHandler.channelUpgradeOpen(
                    IIBCChannelUpgradeBase.MsgChannelUpgradeOpen({
                        portId: channel1.portId,
                        channelId: channel1.channelId,
                        counterpartyChannelState: ch0.state,
                        counterpartyUpgradeSequence: ch0.upgrade_sequence,
                        proofChannel: LocalhostClientLib.sentinelProof(),
                        proofHeight: H(getBlockNumber())
                    })
                );
            }
            ensureChannelState(ibcHandler, channel1, Channel.State.STATE_OPEN);
            if (!callbacks.openSucAndOpenSuc.reverse) {
                if (!callbacks.openSucAndOpenSuc.callback(ibcHandler, channel0, channel1)) {
                    return upgradeSequence;
                }
            } else {
                if (!callbacks.openSucAndOpenSuc.callback(ibcHandler, channel1, channel0)) {
                    return upgradeSequence;
                }
            }
        }
    }

    function crossingHelloFlushing(string memory portId0, string memory portId1) public returns (ChannelInfo memory channel0, ChannelInfo memory channel1) {
        (ChannelInfo memory channel0, ChannelInfo memory channel1) = createMockAppLocalhostChannel(Channel.Order.ORDER_UNORDERED, portId0, portId1, MOCK_APP_VERSION_1);

        (string memory newConnectionId0, string memory newConnectionId1) =
            ibcHandler.createLocalhostConnection();

        assertEq(
            mockApp.proposeAndInitUpgrade(
                channel0.portId,
                channel0.channelId,
                UpgradeFields.Data({
                    ordering: Channel.Order.ORDER_UNORDERED,
                    connection_hops: IBCChannelLib.buildConnectionHops(newConnectionId0),
                    version: MOCK_APP_VERSION_1
                }),
                Timeout.Data({height: H(10), timestamp: 0})
            ),
            1
        );
        assertEq(
            maliciousMockApp.proposeAndInitUpgrade(
                channel1.portId,
                channel1.channelId,
                UpgradeFields.Data({
                    ordering: Channel.Order.ORDER_UNORDERED,
                    connection_hops: IBCChannelLib.buildConnectionHops(newConnectionId1),
                    version: MOCK_APP_VERSION_1
                }),
                Timeout.Data({height: H(10), timestamp: 0})
            ),
            1
        );

        (Channel.Data memory channel0Data,) = ibcHandler.getChannel(channel0.portId, channel0.channelId);
        (Upgrade.Data memory upgrade0,) = ibcHandler.getChannelUpgrade(channel0.portId, channel0.channelId);
        {
            (bool ok,) = ibcHandler.channelUpgradeTry(
                IIBCChannelUpgradeBase.MsgChannelUpgradeTry({
                    portId: channel0.portId,
                    channelId: channel0.channelId,
                    counterpartyUpgradeFields: maliciousMockApp.getUpgradeProposal(channel1.portId, channel1.channelId).fields,
                    counterpartyUpgradeSequence: 1,
                    proposedConnectionHops: IBCChannelLib.buildConnectionHops(newConnectionId0),
                    proofs: upgradeLocalhostProofs()
                })
            );
            assertTrue(ok);
        }
        {
            mockCallVerifyChannelState(
                address(LocalhostHelper.getLocalhostClient(ibcHandler)), channel0, channel0Data
            );
            mockCallVerifyChannelUpgrade(
                address(LocalhostHelper.getLocalhostClient(ibcHandler)), channel0, upgrade0
            );
            (bool ok,) = ibcHandler.channelUpgradeTry(
                IIBCChannelUpgradeBase.MsgChannelUpgradeTry({
                    portId: channel1.portId,
                    channelId: channel1.channelId,
                    counterpartyUpgradeFields: mockApp.getUpgradeProposal(channel0.portId, channel0.channelId).fields,
                    counterpartyUpgradeSequence: 1,
                    proposedConnectionHops: IBCChannelLib.buildConnectionHops(newConnectionId1),
                    proofs: upgradeLocalhostProofs()
                })
            );
            assertTrue(ok);
            vm.clearMockedCalls();
        }
        return (channel0, channel1);
    }

    function createMockAppLocalhostChannel(Channel.Order ordering)
        internal
        returns (ChannelInfo memory, ChannelInfo memory)
    {
        return createMockAppLocalhostChannel(ordering, MOCK_APP_PORT, MOCK_APP_PORT, MOCK_APP_VERSION_1);
    }

    function createMockAppLocalhostChannel(Channel.Order ordering, string memory portId0, string memory portId1, string memory version)
        internal
        returns (ChannelInfo memory, ChannelInfo memory)
    {
        (string memory connectionId0, string memory connectionId1) = ibcHandler.createLocalhostConnection();
        (string memory channelId0, string memory channelId1) = ibcHandler.createLocalhostChannel(
            LocalhostHelper.MsgCreateChannel({
                connectionId0: connectionId0,
                connectionId1: connectionId1,
                portId0: portId0,
                portId1: portId1,
                ordering: ordering,
                version: version
            })
        );
        return (
            ChannelInfo({connectionId: connectionId0, portId: portId0, channelId: channelId0}),
            ChannelInfo({connectionId: connectionId1, portId: portId1, channelId: channelId1})
        );
    }

    function ensureChannelState(IIBCHandler handler, ChannelInfo memory channel, Channel.State state) internal {
        assertEq(uint8(getChannelState(handler, channel)), uint8(state), "channel state mismatch");
    }

    function getChannelState(IIBCHandler handler, ChannelInfo memory channel) internal view returns (Channel.State) {
        (Channel.Data memory channelData, bool found) = handler.getChannel(channel.portId, channel.channelId);
        require(found, "channel not found");
        return channelData.state;
    }

    function getCounterpartyUpgrade(string memory portId, string memory channelId)
        private
        view
        returns (Upgrade.Data memory)
    {
        IIBCChannelUpgradableModule module = IIBCChannelUpgradableModule(address(ibcHandler.getIBCModuleByPort(portId)));
        return Upgrade.Data({
            fields: module.getUpgradeProposal(portId, channelId).fields,
            timeout: module.getUpgradeProposal(portId, channelId).timeout,
            next_sequence_send: ibcHandler.getNextSequenceSend(portId, channelId)
        });
    }

    function upgradeLocalhostProofs() private view returns (IIBCChannelUpgradeBase.ChannelUpgradeProofs memory) {
        return IIBCChannelUpgradeBase.ChannelUpgradeProofs({
            proofChannel: LocalhostClientLib.sentinelProof(),
            proofUpgrade: LocalhostClientLib.sentinelProof(),
            proofHeight: H(getBlockNumber())
        });
    }

    function mockVersion(uint256 version) private pure returns (string memory) {
        return string(abi.encodePacked("mockapp-", Strings.toString(version)));
    }

    function emptyErrorReceipt() private pure returns (ErrorReceipt.Data memory) {
        return ErrorReceipt.Data({sequence: 0, message: ""});
    }

    function mockCallVerifyChannelState(
        address client,
        ChannelInfo memory counterpartyChannelInfo,
        Channel.Data memory counterpartyChannel
    ) internal {
        vm.mockCall(
            address(client),
            abi.encodeWithSelector(
                ILightClient.verifyMembership.selector,
                LocalhostClientLib.CLIENT_ID,
                H(getBlockNumber()),
                0,
                0,
                LocalhostClientLib.sentinelProof(),
                bytes("ibc"),
                IBCCommitment.channelPath(counterpartyChannelInfo.portId, counterpartyChannelInfo.channelId),
                Channel.encode(counterpartyChannel)
            ),
            abi.encode(true)
        );
    }

    function mockCallVerifyChannelUpgrade(
        address client,
        ChannelInfo memory counterpartyChannelInfo,
        Upgrade.Data memory counterpartyUpgrade
    ) internal {
        vm.mockCall(
            address(client),
            abi.encodeWithSelector(
                ILightClient.verifyMembership.selector,
                LocalhostClientLib.CLIENT_ID,
                H(getBlockNumber()),
                0,
                0,
                LocalhostClientLib.sentinelProof(),
                bytes("ibc"),
                IBCCommitment.channelUpgradePath(counterpartyChannelInfo.portId, counterpartyChannelInfo.channelId),
                Upgrade.encode(counterpartyUpgrade)
            ),
            abi.encode(true)
        );
    }

    function ensureNextSequences(
        ChannelInfo memory ch,
        uint64 nextSequenceSend,
        uint64 nextSequenceAck,
        uint64 nextSequenceRecv
    ) internal {
        assertEq(ibcHandler.getNextSequenceSend(ch.portId, ch.channelId), nextSequenceSend, "nextSequenceSend mismatch");
        assertEq(ibcHandler.getNextSequenceAck(ch.portId, ch.channelId), nextSequenceAck, "nextSequenceAck mismatch");
        assertEq(ibcHandler.getNextSequenceRecv(ch.portId, ch.channelId), nextSequenceRecv, "nextSequenceRecv mismatch");
    }

    enum RelayPhase {
        None,
        RecvPacket,
        AckPacket
    }

    struct MockAppRelayResult {
        Packet packet;
        bytes ack;
    }

    function mockAppRelay(ChannelInfo memory ca, ChannelInfo memory cb, bytes memory packetData, RelayPhase phase)
        private
        returns (MockAppRelayResult memory result)
    {
        return mockAppRelay(ca, cb, packetData, phase, Timeout.Data({height: H(getBlockNumber(1)), timestamp: 0}));
    }

    function mockAppRelay(ChannelInfo memory ca, ChannelInfo memory cb, bytes memory packetData, RelayPhase phase, Timeout.Data memory timeout)
        private
        returns (MockAppRelayResult memory result)
    {
        uint64 sequence = mockApp.sendPacket(packetData, ca.portId, ca.channelId, timeout.height, timeout.timestamp);
        result.packet = getLastSentPacket(ibcHandler, ca.portId, ca.channelId, vm.getRecordedLogs());
        if (phase == RelayPhase.None) {
            return result;
        }
        ibcHandler.recvPacket(
            IIBCChannelRecvPacket.MsgPacketRecv({
                packet: result.packet,
                proof: LocalhostClientLib.sentinelProof(),
                proofHeight: Height.nil()
            })
        );
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(abi.encode(result.packet), abi.encode(getLastRecvPacket(ibcHandler, logs)));
        if (keccak256(packetData) == keccak256(IBCMockLib.MOCK_ASYNC_PACKET_DATA)) {
            mockApp.writeAcknowledgement(cb.portId, cb.channelId, sequence);
            logs = vm.getRecordedLogs();
        }
        WriteAcknolwedgement memory ack = getLastWrittenAcknowledgement(ibcHandler, logs);
        assertEq(ack.sequence, sequence);
        result.ack = ack.acknowledgement;
        if (phase == RelayPhase.RecvPacket) {
            return result;
        }
        ibcHandler.acknowledgePacket(
            IIBCChannelAcknowledgePacket.MsgPacketAcknowledgement({
                packet: result.packet,
                acknowledgement: ack.acknowledgement,
                proof: LocalhostClientLib.sentinelProof(),
                proofHeight: Height.nil()
            })
        );
        assertTrue(ibcHandler.getPacketCommitment(ca.portId, ca.channelId, sequence) == bytes32(0));
        return result;
    }

    // ------------------------------ Handshake Callbacks ------------------------------ //

    struct HandshakeCallbacks {
        HandshakeCallback openInitAndOpen;
        HandshakeCallback openInitAndFlushing;
        HandshakeCallback flushingAndFlushing;
        HandshakeCallback flushingAndComplete;
        HandshakeCallback completeAndComplete;
        HandshakeCallback openSucAndComplete;
        HandshakeCallback openSucAndOpenSuc;
    }

    struct HandshakeCallback {
        function(IIBCHandler, ChannelInfo memory, ChannelInfo memory) returns (bool) callback;
        bool reverse;
    }

    function noopCallback(IIBCHandler, ChannelInfo memory, ChannelInfo memory) internal pure returns (bool) {
        return true;
    }

    function emptyCallbacks() internal pure returns (HandshakeCallbacks memory) {
        return HandshakeCallbacks({
            openInitAndOpen: HandshakeCallback(noopCallback, false),
            openInitAndFlushing: HandshakeCallback(noopCallback, false),
            flushingAndFlushing: HandshakeCallback(noopCallback, false),
            flushingAndComplete: HandshakeCallback(noopCallback, false),
            completeAndComplete: HandshakeCallback(noopCallback, false),
            openSucAndComplete: HandshakeCallback(noopCallback, false),
            openSucAndOpenSuc: HandshakeCallback(noopCallback, false)
        });
    }

    function _cancelSuccessOnlySrc(IIBCHandler handler, ChannelInfo memory src, ChannelInfo memory)
        internal
        returns (bool)
    {
        handler.cancelChannelUpgrade(
            IIBCChannelUpgradeBase.MsgCancelChannelUpgrade({
                portId: src.portId,
                channelId: src.channelId,
                errorReceipt: emptyErrorReceipt(),
                proofUpgradeError: LocalhostClientLib.sentinelProof(),
                proofHeight: H(getBlockNumber())
            })
        );
        return false;
    }

    function _cancelSuccess(IIBCHandler handler, ChannelInfo memory src, ChannelInfo memory dst)
        internal
        returns (bool)
    {
        // flush recordes logs
        vm.getRecordedLogs();
        handler.cancelChannelUpgrade(
            IIBCChannelUpgradeBase.MsgCancelChannelUpgrade({
                portId: src.portId,
                channelId: src.channelId,
                errorReceipt: emptyErrorReceipt(),
                proofUpgradeError: LocalhostClientLib.sentinelProof(),
                proofHeight: H(getBlockNumber())
            })
        );
        ErrorReceipt.Data memory rc = getLastWriteErrorReceiptEvent(handler, vm.getRecordedLogs());
        handler.cancelChannelUpgrade(
            IIBCChannelUpgradeBase.MsgCancelChannelUpgrade({
                portId: dst.portId,
                channelId: dst.channelId,
                errorReceipt: rc,
                proofUpgradeError: LocalhostClientLib.sentinelProof(),
                proofHeight: H(getBlockNumber())
            })
        );
        return false;
    }

    function _cancelFail(IIBCHandler handler, ChannelInfo memory src, ChannelInfo memory) internal returns (bool) {
        vm.expectRevert();
        handler.cancelChannelUpgrade(
            IIBCChannelUpgradeBase.MsgCancelChannelUpgrade({
                portId: src.portId,
                channelId: src.channelId,
                errorReceipt: emptyErrorReceipt(),
                proofUpgradeError: LocalhostClientLib.sentinelProof(),
                proofHeight: H(getBlockNumber())
            })
        );
        return false;
    }

    function _testUpgradeTimeoutAbortAck(IIBCHandler handler, ChannelInfo memory src, ChannelInfo memory dst)
        internal
        returns (bool)
    {
        // channelUpgradeAck returns false because the upgrade timeout is reached
        assertFalse(
            handler.channelUpgradeAck(
                IIBCChannelUpgradeBase.MsgChannelUpgradeAck({
                    portId: src.portId,
                    channelId: src.channelId,
                    counterpartyUpgrade: getCounterpartyUpgrade(dst.portId, dst.channelId),
                    proofs: upgradeLocalhostProofs()
                })
            )
        );
        ensureChannelState(handler, src, Channel.State.STATE_OPEN);
        (, bool found) = handler.getChannelUpgrade(src.portId, src.channelId);
        assertFalse(found);
        vm.startPrank(address(0x01));
        ibcHandler.cancelChannelUpgrade(
            IIBCChannelUpgradeBase.MsgCancelChannelUpgrade({
                portId: dst.portId,
                channelId: dst.channelId,
                errorReceipt: getLastWriteErrorReceiptEvent(ibcHandler, vm.getRecordedLogs()),
                proofUpgradeError: LocalhostClientLib.sentinelProof(),
                proofHeight: H(getBlockNumber())
            })
        );
        vm.stopPrank();
        return false;
    }

    function _testUpgradeTimeoutAbortConfirm(IIBCHandler handler, ChannelInfo memory src, ChannelInfo memory dst)
        internal
        returns (bool)
    {
        // channelUpgradeConfirm returns false because the upgrade timeout is reached
        assertFalse(
            handler.channelUpgradeConfirm(
                IIBCChannelUpgradeBase.MsgChannelUpgradeConfirm({
                    portId: dst.portId,
                    channelId: dst.channelId,
                    counterpartyChannelState: Channel.State.STATE_FLUSHING,
                    counterpartyUpgrade: getCounterpartyUpgrade(src.portId, src.channelId),
                    proofs: upgradeLocalhostProofs()
                })
            )
        );
        ensureChannelState(handler, dst, Channel.State.STATE_OPEN);
        (, bool found) = handler.getChannelUpgrade(dst.portId, dst.channelId);
        assertFalse(found);
        vm.startPrank(address(0x01));
        handler.cancelChannelUpgrade(
            IIBCChannelUpgradeBase.MsgCancelChannelUpgrade({
                portId: src.portId,
                channelId: src.channelId,
                errorReceipt: getLastWriteErrorReceiptEvent(handler, vm.getRecordedLogs()),
                proofUpgradeError: LocalhostClientLib.sentinelProof(),
                proofHeight: H(getBlockNumber())
            })
        );
        vm.stopPrank();
        return false;
    }

    function _testUpgradeTimeoutUpgradeSuccess(
        IIBCHandler handler,
        ChannelInfo memory channel0,
        ChannelInfo memory channel1
    ) internal returns (bool) {
        Timeout.Data memory timeout = mockApp.getUpgradeTimeout(channel1.portId, channel1.channelId);
        if (timeout.height.revision_height != 0) {
            vm.roll(uint256(timeout.height.revision_height));
        }
        if (timeout.timestamp != 0) {
            vm.warp(uint256(timeout.timestamp / 1e9));
        }
        (Channel.Data memory counterpartyChannel,) = handler.getChannel(channel1.portId, channel1.channelId);
        handler.timeoutChannelUpgrade(
            IIBCChannelUpgradeBase.MsgTimeoutChannelUpgrade({
                portId: channel0.portId,
                channelId: channel0.channelId,
                counterpartyChannel: counterpartyChannel,
                proofChannel: LocalhostClientLib.sentinelProof(),
                proofHeight: H(getBlockNumber())
            })
        );
        vm.startPrank(address(0x01));
        handler.cancelChannelUpgrade(
            IIBCChannelUpgradeBase.MsgCancelChannelUpgrade({
                portId: channel1.portId,
                channelId: channel1.channelId,
                errorReceipt: ErrorReceipt.Data({sequence: 1, message: "3"}),
                proofUpgradeError: LocalhostClientLib.sentinelProof(),
                proofHeight: H(getBlockNumber())
            })
        );
        vm.stopPrank();
        return false;
    }

    function _testUpgradeTimeoutUpgradeFailTimeoutHeightNotReached(
        IIBCHandler handler,
        ChannelInfo memory channel0,
        ChannelInfo memory channel1
    ) internal returns (bool) {
        (Channel.Data memory counterpartyChannel,) = handler.getChannel(channel1.portId, channel1.channelId);
        IIBCChannelUpgradeBase.MsgTimeoutChannelUpgrade memory msg_ = IIBCChannelUpgradeBase.MsgTimeoutChannelUpgrade({
            portId: channel0.portId,
            channelId: channel0.channelId,
            counterpartyChannel: counterpartyChannel,
            proofChannel: LocalhostClientLib.sentinelProof(),
            proofHeight: H(getBlockNumber())
        });
        vm.expectRevert(IIBCChannelUpgradeErrors.IBCChannelUpgradeTimeoutHeightNotReached.selector);
        handler.timeoutChannelUpgrade(msg_);
        return true;
    }

    function _testUpgradeTimeoutUpgradeFailTimeoutTimestampNotReached(
        IIBCHandler handler,
        ChannelInfo memory channel0,
        ChannelInfo memory channel1
    ) internal returns (bool) {
        (Channel.Data memory counterpartyChannel,) = handler.getChannel(channel1.portId, channel1.channelId);
        IIBCChannelUpgradeBase.MsgTimeoutChannelUpgrade memory msg_ = IIBCChannelUpgradeBase.MsgTimeoutChannelUpgrade({
            portId: channel0.portId,
            channelId: channel0.channelId,
            counterpartyChannel: counterpartyChannel,
            proofChannel: LocalhostClientLib.sentinelProof(),
            proofHeight: H(getBlockNumber())
        });
        vm.expectRevert(IIBCChannelUpgradeErrors.IBCChannelUpgradeTimeoutTimestampNotReached.selector);
        handler.timeoutChannelUpgrade(msg_);
        return true;
    }

    function _testUpgradeTimeoutUpgradeFailReached(
        IIBCHandler handler,
        ChannelInfo memory channel0,
        ChannelInfo memory channel1
    ) internal returns (bool) {
        Timeout.Data memory timeout = mockApp.getUpgradeTimeout(channel1.portId, channel1.channelId);
        if (timeout.height.revision_height != 0) {
            vm.roll(uint256(timeout.height.revision_height));
        }
        if (timeout.timestamp != 0) {
            vm.warp(uint256(timeout.timestamp / 1e9));
        }
        (Channel.Data memory counterpartyChannel,) = handler.getChannel(channel1.portId, channel1.channelId);
        IIBCChannelUpgradeBase.MsgTimeoutChannelUpgrade memory msg_ = IIBCChannelUpgradeBase.MsgTimeoutChannelUpgrade({
            portId: channel0.portId,
            channelId: channel0.channelId,
            counterpartyChannel: counterpartyChannel,
            proofChannel: LocalhostClientLib.sentinelProof(),
            proofHeight: H(getBlockNumber())
        });
        vm.expectRevert();
        handler.timeoutChannelUpgrade(msg_);
        return false;
    }

    function _testUpgradeTimeoutUpgradeFailReachedAlreadyUpgraded(
        IIBCHandler handler,
        ChannelInfo memory channel0,
        ChannelInfo memory channel1
    ) internal returns (bool) {
        // TODO make timestamp configurable
        vm.roll(100);
        vm.warp(100);
        (Channel.Data memory counterpartyChannel,) = handler.getChannel(channel1.portId, channel1.channelId);
        IIBCChannelUpgradeBase.MsgTimeoutChannelUpgrade memory msg_ = IIBCChannelUpgradeBase.MsgTimeoutChannelUpgrade({
            portId: channel0.portId,
            channelId: channel0.channelId,
            counterpartyChannel: counterpartyChannel,
            proofChannel: LocalhostClientLib.sentinelProof(),
            proofHeight: H(getBlockNumber())
        });
        vm.expectRevert(IIBCChannelUpgradeErrors.IBCChannelUpgradeCounterpartyAlreadyUpgraded.selector);
        handler.timeoutChannelUpgrade(msg_);
        return false;
    }

    function _testUpgradeTimeoutUpgradeFailReachedAlreadyCompleted(
        IIBCHandler handler,
        ChannelInfo memory channel0,
        ChannelInfo memory channel1
    ) internal returns (bool) {
        Timeout.Data memory timeout = mockApp.getUpgradeTimeout(channel1.portId, channel1.channelId);
        if (timeout.height.revision_height != 0) {
            vm.roll(uint256(timeout.height.revision_height));
        }
        if (timeout.timestamp != 0) {
            vm.warp(uint256(timeout.timestamp / 1e9));
        }
        (Channel.Data memory counterpartyChannel,) = handler.getChannel(channel1.portId, channel1.channelId);
        IIBCChannelUpgradeBase.MsgTimeoutChannelUpgrade memory msg_ = IIBCChannelUpgradeBase.MsgTimeoutChannelUpgrade({
            portId: channel0.portId,
            channelId: channel0.channelId,
            counterpartyChannel: counterpartyChannel,
            proofChannel: LocalhostClientLib.sentinelProof(),
            proofHeight: H(getBlockNumber())
        });
        vm.expectRevert(IIBCChannelUpgradeErrors.IBCChannelUpgradeCounterpartyAlreadyFlushCompleted.selector);
        handler.timeoutChannelUpgrade(msg_);
        return false;
    }

    function _testUpgradeCounterpartyAdvanceNextSequenceBeforeOpen(
        IIBCHandler,
        ChannelInfo memory channel0,
        ChannelInfo memory
    ) internal returns (bool) {
        mockApp.proposeAndInitUpgrade(
            channel0.portId,
            channel0.channelId,
            UpgradeFields.Data({
                ordering: Channel.Order.ORDER_UNORDERED,
                connection_hops: IBCChannelLib.buildConnectionHops(channel0.connectionId),
                version: mockVersion(3)
            }),
            Timeout.Data({height: H(10), timestamp: 0})
        );
        return true;
    }

    struct CallbacksTimeout {
        HandshakeCallbacks callbacks;
        Timeout.Data t0;
        Timeout.Data t1;
    }
}