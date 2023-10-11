package e2e

import (
	"context"
	"fmt"
	"math/big"
	"strings"
	"testing"
	"time"

	transfertypes "github.com/cosmos/ibc-go/v7/modules/apps/transfer/types"
	ibcchanneltypes "github.com/cosmos/ibc-go/v7/modules/core/04-channel/types"
	"github.com/ethereum/go-ethereum/common"
	"github.com/hyperledger-labs/yui-ibc-solidity/pkg/client"
	"github.com/hyperledger-labs/yui-ibc-solidity/pkg/contract/ibcmockapp"
	channeltypes "github.com/hyperledger-labs/yui-ibc-solidity/pkg/ibc/core/channel"
	clienttypes "github.com/hyperledger-labs/yui-ibc-solidity/pkg/ibc/core/client"
	ibctesting "github.com/hyperledger-labs/yui-ibc-solidity/pkg/testing"
	"github.com/stretchr/testify/suite"
)

const (
	relayer          = ibctesting.RelayerKeyIndex // the key-index of relayer on both chains
	deployerA        = ibctesting.RelayerKeyIndex // the key-index of contract deployer on chain A
	deployerB        = ibctesting.RelayerKeyIndex // the key-index of contract deployer on chain B
	aliceA    uint32 = 1                          // the key-index of alice on chain A
	bobB      uint32 = 2                          // the key-index of alice on chain B

	delayPeriodExtensionA = 5
	delayPeriodExtensionB = 10
)

type ChainTestSuite struct {
	suite.Suite
}

func (suite *ChainTestSuite) SetupTest() {}

func (suite *ChainTestSuite) TestICS20() {
	ctx := context.Background()

	ethClA, err := client.NewETHClient("http://127.0.0.1:8645")
	suite.Require().NoError(err)
	ethClB, err := client.NewETHClient("http://127.0.0.1:8745")
	suite.Require().NoError(err)

	chainA := ibctesting.NewChain(suite.T(), ethClA, ibctesting.NewLightClient(ethClA, clienttypes.BesuIBFT2Client), true)
	chainB := ibctesting.NewChain(suite.T(), ethClB, ibctesting.NewLightClient(ethClB, clienttypes.BesuIBFT2Client), true)
	coordinator := ibctesting.NewCoordinator(suite.T(), chainA, chainB)

	clientA, clientB := coordinator.SetupClients(ctx, chainA, chainB, clienttypes.BesuIBFT2Client)
	connA, connB := coordinator.CreateConnection(ctx, chainA, chainB, clientA, clientB)
	chanA, chanB := coordinator.CreateChannel(ctx, chainA, chainB, connA, connB, ibctesting.TransferPort, ibctesting.TransferPort, channeltypes.UNORDERED)

	/// Tests for Transfer module ///

	beforeBalanceA, err := chainA.ERC20.BalanceOf(chainA.CallOpts(ctx, relayer), chainA.CallOpts(ctx, deployerA).From)
	suite.Require().NoError(err)
	suite.Require().NoError(
		coordinator.ApproveAndDepositToken(ctx, chainA, deployerA, 100, aliceA),
	)

	baseDenom := strings.ToLower(chainA.ContractConfig.ERC20TokenAddress.String())

	// try to transfer the token to chainB
	suite.Require().NoError(chainA.WaitIfNoError(ctx)(
		chainA.ICS20Transfer.SendTransfer(
			chainA.TxOpts(ctx, aliceA),
			baseDenom,
			big.NewInt(100),
			addressToHexString(chainB.CallOpts(ctx, bobB).From),
			chanA.PortID, chanA.ID,
			uint64(chainB.LastHeader().Number.Int64())+1000,
		),
	))
	// ensure that escrow has correct balance
	escrowBalance, err := chainA.ICS20Bank.BalanceOf(chainA.CallOpts(ctx, relayer), chainA.ContractConfig.ICS20TransferBankAddress, baseDenom)
	suite.Require().NoError(err)
	suite.Require().GreaterOrEqual(escrowBalance.Int64(), int64(100))

	suite.Require().NoError(coordinator.UpdateClient(ctx, chainB, chainA, clientB))

	// relay the packet
	coordinator.RelayLastSentPacket(ctx, chainA, chainB, chanA, chanB, func(b []byte) {
		var data transfertypes.FungibleTokenPacketData
		suite.Require().NoError(transfertypes.ModuleCdc.UnmarshalJSON(b, &data))
		suite.Require().NoError(data.ValidateBasic())
		suite.Require().Equal(baseDenom, data.Denom)
		suite.Require().Equal("100", data.Amount)
		suite.Require().Equal(addressToHexString(chainA.CallOpts(ctx, aliceA).From), data.Sender)
		suite.Require().Equal(addressToHexString(chainB.CallOpts(ctx, bobB).From), data.Receiver)
		suite.Require().Equal("", data.Memo)
		suite.Require().Equal(data.GetBytes(), b)
	}, func(b []byte) {
		var ack ibcchanneltypes.Acknowledgement
		suite.Require().NoError(transfertypes.ModuleCdc.UnmarshalJSON(b, &ack))
		suite.Require().NoError(ack.ValidateBasic())
		suite.Require().True(ack.Success())
		suite.Require().Equal(ibcchanneltypes.NewResultAcknowledgement([]byte{byte(1)}).Acknowledgement(), b)
	})

	// ensure that chainB has correct balance
	expectedDenom := fmt.Sprintf("%v/%v/%v", chanB.PortID, chanB.ID, baseDenom)
	balance, err := chainB.ICS20Bank.BalanceOf(chainB.CallOpts(ctx, relayer), chainB.CallOpts(ctx, bobB).From, expectedDenom)
	suite.Require().NoError(err)
	suite.Require().Equal(int64(100), balance.Int64())

	// try to transfer the token to chainA
	suite.Require().NoError(chainB.WaitIfNoError(ctx)(
		chainB.ICS20Transfer.SendTransfer(
			chainB.TxOpts(ctx, bobB),
			expectedDenom,
			big.NewInt(100),
			addressToHexString(chainA.CallOpts(ctx, aliceA).From),
			chanB.PortID,
			chanB.ID,
			uint64(chainA.LastHeader().Number.Int64())+1000,
		),
	))
	suite.Require().NoError(coordinator.UpdateClient(ctx, chainA, chainB, clientA))

	// relay the packet
	coordinator.RelayLastSentPacket(ctx, chainB, chainA, chanB, chanA, func(b []byte) {
		var data transfertypes.FungibleTokenPacketData
		suite.Require().NoError(transfertypes.ModuleCdc.UnmarshalJSON(b, &data))
		suite.Require().NoError(data.ValidateBasic())
		suite.Require().Equal(expectedDenom, data.Denom)
		suite.Require().Equal("100", data.Amount)
		suite.Require().Equal(addressToHexString(chainB.CallOpts(ctx, bobB).From), data.Sender)
		suite.Require().Equal(addressToHexString(chainA.CallOpts(ctx, aliceA).From), data.Receiver)
		suite.Require().Equal("", data.Memo)
		suite.Require().Equal(data.GetBytes(), b)
	}, func(b []byte) {
		var ack ibcchanneltypes.Acknowledgement
		suite.Require().NoError(transfertypes.ModuleCdc.UnmarshalJSON(b, &ack))
		suite.Require().NoError(ack.ValidateBasic())
		suite.Require().True(ack.Success())
		suite.Require().Equal(ibcchanneltypes.NewResultAcknowledgement([]byte{byte(1)}).Acknowledgement(), b)
	})

	{
		suite.Require().NoError(chainA.WaitIfNoError(ctx)(
			chainA.ICS20Transfer.SendTransfer(
				chainA.TxOpts(ctx, aliceA),
				baseDenom,
				big.NewInt(50),
				addressToHexString(chainB.CallOpts(ctx, bobB).From),
				chanA.PortID, chanA.ID,
				uint64(chainB.LastHeader().Number.Int64())+1,
			),
		))
		transferPacket, err := chainA.GetLastSentPacket(ctx, chanA.PortID, chanA.ID)
		suite.Require().NoError(err)
		// should fail to timeout packet because the timeout height is not reached
		suite.Require().Error(chainA.TimeoutPacket(ctx, *transferPacket, chainB, chanA, chanB))
		suite.Require().NoError(chainB.AdvanceBlockNumber(ctx, uint64(chainB.LastHeader().Number.Int64())+1))
		// then, update the client to reach the timeout height
		suite.Require().NoError(coordinator.UpdateClient(ctx, chainA, chainB, clientA))

		suite.Require().NoError(chainA.EnsurePacketCommitmentExistence(ctx, true, transferPacket.SourcePort, transferPacket.SourceChannel, transferPacket.Sequence))
		suite.Require().NoError(chainA.TimeoutPacket(ctx, *transferPacket, chainB, chanA, chanB))
		// confirm that the packet commitment is deleted
		suite.Require().NoError(chainA.EnsurePacketCommitmentExistence(ctx, false, transferPacket.SourcePort, transferPacket.SourceChannel, transferPacket.Sequence))
		suite.Require().NoError(chainA.EnsureChannelState(ctx, chanA.PortID, chanA.ID, channeltypes.OPEN))
	}

	// withdraw tokens from the bank
	suite.Require().NoError(chainA.WaitIfNoError(ctx)(
		chainA.ICS20Bank.Withdraw(
			chainA.TxOpts(ctx, aliceA),
			chainA.ContractConfig.ERC20TokenAddress,
			big.NewInt(100),
			chainA.CallOpts(ctx, deployerA).From,
		)))

	// ensure that token balance equals original value
	afterBalanceA, err := chainA.ERC20.BalanceOf(chainA.CallOpts(ctx, relayer), chainA.CallOpts(ctx, deployerA).From)
	suite.Require().NoError(err)
	suite.Require().Equal(beforeBalanceA.Int64(), afterBalanceA.Int64())
}

func (suite *ChainTestSuite) TestTimeoutAndClose() {
	ctx := context.Background()

	ethClA, err := client.NewETHClient("http://127.0.0.1:8645")
	suite.Require().NoError(err)
	ethClB, err := client.NewETHClient("http://127.0.0.1:8745")
	suite.Require().NoError(err)

	chainA := ibctesting.NewChain(suite.T(), ethClA, ibctesting.NewLightClient(ethClA, clienttypes.BesuIBFT2Client), true)
	chainB := ibctesting.NewChain(suite.T(), ethClB, ibctesting.NewLightClient(ethClB, clienttypes.BesuIBFT2Client), true)
	coordinator := ibctesting.NewCoordinator(suite.T(), chainA, chainB)

	clientA, clientB := coordinator.SetupClients(ctx, chainA, chainB, clienttypes.BesuIBFT2Client)
	connA, connB := coordinator.CreateConnection(ctx, chainA, chainB, clientA, clientB)

	// Case: timeoutOnClose on ordered channel
	{
		chanA, chanB := coordinator.CreateChannel(ctx, chainA, chainB, connA, connB, ibctesting.MockPort, ibctesting.MockPort, channeltypes.ORDERED)
		suite.Require().NoError(coordinator.UpdateClient(ctx, chainA, chainB, clientA))
		suite.Require().NoError(coordinator.UpdateClient(ctx, chainB, chainA, clientB))
		suite.Require().NoError(chainA.WaitIfNoError(ctx)(chainA.IBCMockApp.SendPacket(
			chainA.TxOpts(ctx, aliceA),
			ibctesting.MockPacketData,
			chanA.PortID, chanA.ID,
			ibcmockapp.HeightData{RevisionNumber: 0, RevisionHeight: uint64(chainB.LastHeader().Number.Int64()) + 1000},
			0,
		)))
		packet, err := chainA.GetLastSentPacket(ctx, chanA.PortID, chanA.ID)
		suite.Require().NoError(err)
		suite.Require().NoError(coordinator.ChanCloseInit(ctx, chainB, chainA, chanB))
		suite.Require().NoError(chainA.TimeoutOnClose(ctx, *packet, chainB, chanA, chanB))
		chainA.EnsureChannelState(ctx, chanA.PortID, chanA.ID, channeltypes.CLOSED)
	}

	// Case: timeoutOnClose on unordered channel
	{
		chanA, chanB := coordinator.CreateChannel(ctx, chainA, chainB, connA, connB, ibctesting.MockPort, ibctesting.MockPort, channeltypes.UNORDERED)
		suite.Require().NoError(chainA.WaitIfNoError(ctx)(chainA.IBCMockApp.SendPacket(
			chainA.TxOpts(ctx, aliceA),
			ibctesting.MockPacketData,
			chanA.PortID, chanA.ID,
			ibcmockapp.HeightData{RevisionNumber: 0, RevisionHeight: uint64(chainB.LastHeader().Number.Int64()) + 1000},
			0,
		)))
		packet, err := chainA.GetLastSentPacket(ctx, chanA.PortID, chanA.ID)
		suite.Require().NoError(err)
		suite.Require().NoError(coordinator.ChanCloseInit(ctx, chainB, chainA, chanB))
		suite.Require().NoError(chainA.TimeoutOnClose(ctx, *packet, chainB, chanA, chanB))
		chainA.EnsureChannelState(ctx, chanA.PortID, chanA.ID, channeltypes.CLOSED)
	}

	// Case: timeout packet on ordered channel
	{
		chanA, chanB := coordinator.CreateChannel(ctx, chainA, chainB, connA, connB, ibctesting.MockPort, ibctesting.MockPort, channeltypes.ORDERED)
		suite.Require().NoError(chainA.WaitIfNoError(ctx)(chainA.IBCMockApp.SendPacket(
			chainA.TxOpts(ctx, aliceA),
			ibctesting.MockPacketData,
			chanA.PortID, chanA.ID,
			ibcmockapp.HeightData{RevisionNumber: 0, RevisionHeight: uint64(chainB.LastHeader().Number.Int64()) + 1},
			0,
		)))
		packet, err := chainA.GetLastSentPacket(ctx, chanA.PortID, chanA.ID)
		suite.Require().NoError(err)

		// should fail to timeout packet because the timeout height is not reached
		suite.Require().Error(chainA.TimeoutPacket(ctx, *packet, chainB, chanA, chanB))

		suite.Require().NoError(chainB.AdvanceBlockNumber(ctx, uint64(chainB.LastHeader().Number.Int64())+1))

		// then, update the client to reach the timeout height
		suite.Require().NoError(coordinator.UpdateClient(ctx, chainA, chainB, clientA))

		suite.Require().NoError(chainA.EnsurePacketCommitmentExistence(ctx, true, packet.SourcePort, packet.SourceChannel, packet.Sequence))
		suite.Require().NoError(chainA.TimeoutPacket(ctx, *packet, chainB, chanA, chanB))
		// confirm that the packet commitment is deleted
		suite.Require().NoError(chainA.EnsurePacketCommitmentExistence(ctx, false, packet.SourcePort, packet.SourceChannel, packet.Sequence))
		chainA.EnsureChannelState(ctx, chanA.PortID, chanA.ID, channeltypes.CLOSED)
	}

	// Case: timeout packet on unordered channel
	{
		chanA, chanB := coordinator.CreateChannel(ctx, chainA, chainB, connA, connB, ibctesting.MockPort, ibctesting.MockPort, channeltypes.UNORDERED)
		suite.Require().NoError(chainA.WaitIfNoError(ctx)(chainA.IBCMockApp.SendPacket(
			chainA.TxOpts(ctx, aliceA),
			ibctesting.MockPacketData,
			chanA.PortID, chanA.ID,
			ibcmockapp.HeightData{RevisionNumber: 0, RevisionHeight: uint64(chainB.LastHeader().Number.Int64()) + 1},
			0,
		)))
		packet, err := chainA.GetLastSentPacket(ctx, chanA.PortID, chanA.ID)
		suite.Require().NoError(err)

		// should fail to timeout packet because the timeout height is not reached
		suite.Require().Error(chainA.TimeoutPacket(ctx, *packet, chainB, chanA, chanB))

		suite.Require().NoError(chainB.AdvanceBlockNumber(ctx, uint64(chainB.LastHeader().Number.Int64())+1))

		// then, update the client to reach the timeout height
		suite.Require().NoError(coordinator.UpdateClient(ctx, chainA, chainB, clientA))

		suite.Require().NoError(chainA.EnsurePacketCommitmentExistence(ctx, true, packet.SourcePort, packet.SourceChannel, packet.Sequence))
		suite.Require().NoError(chainA.TimeoutPacket(ctx, *packet, chainB, chanA, chanB))
		// confirm that the packet commitment is deleted
		suite.Require().NoError(chainA.EnsurePacketCommitmentExistence(ctx, false, packet.SourcePort, packet.SourceChannel, packet.Sequence))
		chainA.EnsureChannelState(ctx, chanA.PortID, chanA.ID, channeltypes.OPEN)
	}

	// Case: close channel on ordered channel
	{
		chanA, chanB := coordinator.CreateChannel(ctx, chainA, chainB, connA, connB, ibctesting.MockPort, ibctesting.MockPort, channeltypes.ORDERED)
		coordinator.CloseChannel(ctx, chainA, chainB, chanA, chanB)
	}

	// Case: close channel on unordered channel
	{
		chanA, chanB := coordinator.CreateChannel(ctx, chainA, chainB, connA, connB, ibctesting.MockPort, ibctesting.MockPort, channeltypes.UNORDERED)
		coordinator.CloseChannel(ctx, chainA, chainB, chanA, chanB)
	}
}

func (suite *ChainTestSuite) TestPacketRelayWithDelay() {
	ctx := context.Background()

	ethClA, err := client.NewETHClient("http://127.0.0.1:8645")
	suite.Require().NoError(err)
	ethClB, err := client.NewETHClient("http://127.0.0.1:8745")
	suite.Require().NoError(err)

	chainA := ibctesting.NewChain(suite.T(), ethClA, ibctesting.NewLightClient(ethClA, clienttypes.BesuIBFT2Client), true)
	chainA.SetDelayPeriod(3 * ibctesting.BlockTime)
	chainB := ibctesting.NewChain(suite.T(), ethClB, ibctesting.NewLightClient(ethClB, clienttypes.BesuIBFT2Client), true)
	chainB.SetDelayPeriod(3 * ibctesting.BlockTime)
	coordinator := ibctesting.NewCoordinator(suite.T(), chainA, chainB)

	clientA, clientB := coordinator.SetupClients(ctx, chainA, chainB, clienttypes.BesuIBFT2Client)
	connA, connB := coordinator.CreateConnection(ctx, chainA, chainB, clientA, clientB)
	chanA, chanB := coordinator.CreateChannel(ctx, chainA, chainB, connA, connB, ibctesting.TransferPort, ibctesting.TransferPort, channeltypes.UNORDERED)

	/// Tests for Transfer module ///

	suite.Require().NoError(
		coordinator.ApproveAndDepositToken(ctx, chainA, deployerA, 100, aliceA),
	)

	baseDenom := strings.ToLower(chainA.ContractConfig.ERC20TokenAddress.String())

	// set expectedTimePerBlock = block time on chainA
	suite.Require().NoError(chainA.SetExpectedTimePerBlock(ctx, deployerA, ibctesting.BlockTime))
	// set expectedTimePerBlock = 0 on chainB
	suite.Require().NoError(chainB.SetExpectedTimePerBlock(ctx, deployerB, 0))

	// try to transfer the token to chainB
	suite.Require().NoError(chainA.WaitIfNoError(ctx)(
		chainA.ICS20Transfer.SendTransfer(
			chainA.TxOpts(ctx, aliceA),
			baseDenom,
			big.NewInt(100),
			addressToHexString(chainB.CallOpts(ctx, bobB).From),
			chanA.PortID, chanA.ID,
			uint64(chainB.LastHeader().Number.Int64())+1000,
		),
	))
	delayStartTimeForRecv := time.Now()
	suite.Require().NoError(coordinator.UpdateClient(ctx, chainB, chainA, clientB))

	// ensure that escrow has correct balance
	escrowBalance, err := chainA.ICS20Bank.BalanceOf(chainA.CallOpts(ctx, relayer), chainA.ContractConfig.ICS20TransferBankAddress, baseDenom)
	suite.Require().NoError(err)
	suite.Require().GreaterOrEqual(escrowBalance.Int64(), int64(100))

	// relay the packet
	coordinator.RelayLastSentPacketWithDelay(ctx, chainA, chainB, chanA, chanB, 1, 1, delayStartTimeForRecv)

	// ensure that chainB has correct balance
	expectedDenom := fmt.Sprintf("%v/%v/%v", chanB.PortID, chanB.ID, baseDenom)
	balance, err := chainB.ICS20Bank.BalanceOf(chainB.CallOpts(ctx, relayer), chainB.CallOpts(ctx, bobB).From, expectedDenom)
	suite.Require().NoError(err)
	suite.Require().Equal(int64(100), balance.Int64())

	// make delay period 10 times longer on chainA
	suite.Require().NoError(
		chainA.SetExpectedTimePerBlock(ctx, deployerA, ibctesting.BlockTime/delayPeriodExtensionA),
	)

	// make delay period 20 times longer on chainB
	suite.Require().NoError(
		chainB.SetExpectedTimePerBlock(ctx, deployerB, ibctesting.BlockTime/delayPeriodExtensionB),
	)

	// try to transfer the token to chainA
	suite.Require().NoError(chainB.WaitIfNoError(ctx)(
		chainB.ICS20Transfer.SendTransfer(
			chainB.TxOpts(ctx, bobB),
			expectedDenom,
			big.NewInt(100),
			addressToHexString(chainA.CallOpts(ctx, aliceA).From),
			chanB.PortID,
			chanB.ID,
			uint64(chainA.LastHeader().Number.Int64())+1000,
		),
	))
	delayStartTimeForRecv = time.Now()

	suite.Require().NoError(coordinator.UpdateClient(ctx, chainA, chainB, clientA))

	// relay the packet
	coordinator.RelayLastSentPacketWithDelay(ctx, chainB, chainA, chanB, chanA, delayPeriodExtensionB, delayPeriodExtensionA, delayStartTimeForRecv)
}

func addressToHexString(addr common.Address) string {
	return strings.ToLower(addr.String())
}

func TestChainTestSuite(t *testing.T) {
	suite.Run(t, new(ChainTestSuite))
}
