// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Height} from "../../proto/Client.sol";
import {IIBCClient} from "../02-client/IIBCClient.sol";
import {IIBCConnection} from "../03-connection/IIBCConnection.sol";
import {
    IIBCChannelHandshake, IIBCChannelPacketSendRecv, IIBCChannelPacketTimeout
} from "../04-channel/IIBCChannel.sol";
import {
    IIBCChannelUpgrade,
    IIBCChannelUpgradeInitTryAck,
    IIBCChannelUpgradeConfirmOpenTimeoutCancel
} from "../04-channel/IIBCChannelUpgrade.sol";

interface IBCHandlerViewFunctionWrapper {
    function wrappedRouteUpdateClient(IIBCClient.MsgUpdateClient calldata msg_)
        external
        view
        returns (address, bytes4, bytes memory);
}

/**
 * @dev IBCClientConnectionChannelHandler is a handler implements ICS-02, ICS-03, and ICS-04
 */
abstract contract IBCClientConnectionChannelHandler is
    IIBCClient,
    IIBCConnection,
    IIBCChannelHandshake,
    IIBCChannelPacketSendRecv,
    IIBCChannelPacketTimeout,
    IIBCChannelUpgrade
{
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address internal immutable ibcClient;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address internal immutable ibcConnection;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address internal immutable ibcChannelHandshake;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address internal immutable ibcChannelPacketSendRecv;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address internal immutable ibcChannelPacketTimeout;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address internal immutable ibcChannelUpgradeInitTryAck;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address internal immutable ibcChannelUpgradeConfirmOpenTimeoutCancel;

    /**
     * @dev The arguments of constructor must satisfy the followings:
     * @param ibcClient_ is the address of a contract that implements `IIBCClient`.
     * @param ibcConnection_ is the address of a contract that implements `IIBCConnection`.
     * @param ibcChannelHandshake_ is the address of a contract that implements `IIBCChannelHandshake`.
     * @param ibcChannelPacketSendRecv_ is the address of a contract that implements `IICS04Wrapper + IIBCChannelPacketReceiver`.
     * @param ibcChannelPacketTimeout_ is the address of a contract that implements `IIBCChannelPacketTimeout`.
     * @param ibcChannelUpgradeInitTryAck_ is the address of a contract that implements `IIBCChannelUpgradeInitTryAck`.
     * @param ibcChannelUpgradeConfirmOpenTimeoutCancel_ is the address of a contract that implements `IIBCChannelUpgradeConfirmOpenTimeoutCancel`.
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor(
        IIBCClient ibcClient_,
        IIBCConnection ibcConnection_,
        IIBCChannelHandshake ibcChannelHandshake_,
        IIBCChannelPacketSendRecv ibcChannelPacketSendRecv_,
        IIBCChannelPacketTimeout ibcChannelPacketTimeout_,
        IIBCChannelUpgradeInitTryAck ibcChannelUpgradeInitTryAck_,
        IIBCChannelUpgradeConfirmOpenTimeoutCancel ibcChannelUpgradeConfirmOpenTimeoutCancel_
    ) {
        ibcClient = address(ibcClient_);
        ibcConnection = address(ibcConnection_);
        ibcChannelHandshake = address(ibcChannelHandshake_);
        ibcChannelPacketSendRecv = address(ibcChannelPacketSendRecv_);
        ibcChannelPacketTimeout = address(ibcChannelPacketTimeout_);
        ibcChannelUpgradeInitTryAck = address(ibcChannelUpgradeInitTryAck_);
        ibcChannelUpgradeConfirmOpenTimeoutCancel = address(ibcChannelUpgradeConfirmOpenTimeoutCancel_);
    }

    function createClient(MsgCreateClient calldata) external returns (string memory) {
        doFallback(ibcClient);
    }

    function updateClient(MsgUpdateClient calldata) external {
        doFallback(ibcClient);
    }

    function updateClientCommitments(string calldata, Height.Data[] calldata) external {
        doFallback(ibcClient);
    }

    function routeUpdateClient(MsgUpdateClient calldata msg_) external view returns (address, bytes4, bytes memory) {
        return IBCHandlerViewFunctionWrapper(address(this)).wrappedRouteUpdateClient(msg_);
    }

    function wrappedRouteUpdateClient(MsgUpdateClient calldata msg_) public returns (address, bytes4, bytes memory) {
        /// @custom:oz-upgrades-unsafe-allow delegatecall
        (bool success, bytes memory returndata) =
            address(ibcClient).delegatecall(abi.encodeWithSelector(IIBCClient.routeUpdateClient.selector, msg_));
        if (!success) {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("routeUpdateClient failed");
            }
        }
        return abi.decode(returndata, (address, bytes4, bytes));
    }

    function connectionOpenInit(IIBCConnection.MsgConnectionOpenInit calldata) external returns (string memory) {
        doFallback(ibcConnection);
    }

    function connectionOpenTry(IIBCConnection.MsgConnectionOpenTry calldata) external returns (string memory) {
        doFallback(ibcConnection);
    }

    function connectionOpenAck(IIBCConnection.MsgConnectionOpenAck calldata) external {
        doFallback(ibcConnection);
    }

    function connectionOpenConfirm(IIBCConnection.MsgConnectionOpenConfirm calldata) external {
        doFallback(ibcConnection);
    }

    function channelOpenInit(IIBCChannelHandshake.MsgChannelOpenInit calldata)
        external
        returns (string memory, string memory)
    {
        doFallback(ibcChannelHandshake);
    }

    function channelOpenTry(IIBCChannelHandshake.MsgChannelOpenTry calldata)
        external
        returns (string memory, string memory)
    {
        doFallback(ibcChannelHandshake);
    }

    function channelOpenAck(IIBCChannelHandshake.MsgChannelOpenAck calldata) external {
        doFallback(ibcChannelHandshake);
    }

    function channelOpenConfirm(IIBCChannelHandshake.MsgChannelOpenConfirm calldata) external {
        doFallback(ibcChannelHandshake);
    }

    function channelCloseInit(IIBCChannelHandshake.MsgChannelCloseInit calldata) external {
        doFallback(ibcChannelHandshake);
    }

    function channelCloseConfirm(IIBCChannelHandshake.MsgChannelCloseConfirm calldata) external {
        doFallback(ibcChannelHandshake);
    }

    function sendPacket(string calldata, string calldata, Height.Data calldata, uint64, bytes calldata)
        external
        returns (uint64)
    {
        doFallback(ibcChannelPacketSendRecv);
    }

    function writeAcknowledgement(string calldata, string calldata, uint64, bytes calldata) external {
        doFallback(ibcChannelPacketSendRecv);
    }

    function recvPacket(MsgPacketRecv calldata) external {
        doFallback(ibcChannelPacketSendRecv);
    }

    function acknowledgePacket(MsgPacketAcknowledgement calldata) external {
        doFallback(ibcChannelPacketSendRecv);
    }

    function timeoutPacket(MsgTimeoutPacket calldata) external {
        doFallback(ibcChannelPacketTimeout);
    }

    function timeoutOnClose(MsgTimeoutOnClose calldata) external {
        doFallback(ibcChannelPacketTimeout);
    }

    function channelUpgradeInit(MsgChannelUpgradeInit calldata) external returns (uint64) {
        doFallback(ibcChannelUpgradeInitTryAck);
    }

    function channelUpgradeTry(MsgChannelUpgradeTry calldata) external returns (bool, uint64) {
        doFallback(ibcChannelUpgradeInitTryAck);
    }

    function channelUpgradeAck(MsgChannelUpgradeAck calldata) external returns (bool) {
        doFallback(ibcChannelUpgradeInitTryAck);
    }

    function channelUpgradeConfirm(MsgChannelUpgradeConfirm calldata) external returns (bool) {
        doFallback(ibcChannelUpgradeConfirmOpenTimeoutCancel);
    }

    function channelUpgradeOpen(MsgChannelUpgradeOpen calldata) external {
        doFallback(ibcChannelUpgradeConfirmOpenTimeoutCancel);
    }

    function cancelChannelUpgrade(MsgCancelChannelUpgrade calldata) external {
        doFallback(ibcChannelUpgradeConfirmOpenTimeoutCancel);
    }

    function timeoutChannelUpgrade(MsgTimeoutChannelUpgrade calldata) external {
        doFallback(ibcChannelUpgradeConfirmOpenTimeoutCancel);
    }

    function doFallback(address impl) internal virtual {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
