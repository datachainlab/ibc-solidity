package testing

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/avast/retry-go"
	channeltypes "github.com/hyperledger-labs/yui-ibc-solidity/pkg/ibc/core/channel"
	clienttypes "github.com/hyperledger-labs/yui-ibc-solidity/pkg/ibc/core/client"
	"github.com/stretchr/testify/require"
)

type Coordinator struct {
	t      *testing.T
	chains []*Chain
}

func NewCoordinator(t *testing.T, chains ...*Chain) Coordinator {
	// initialize the input data for the light clients
	for _, chain := range chains {
		chain.UpdateLCInputData()
	}
	return Coordinator{t: t, chains: chains}
}

func (c Coordinator) GetChain(idx int) *Chain {
	return c.chains[idx]
}

// SetupClients is a helper function to create clients on both chains. It assumes the
// caller does not anticipate any errors.
func (coord *Coordinator) SetupClients(
	ctx context.Context,
	chainA, chainB *Chain,
	clientType string,
) (string, string) {

	clientA, err := coord.CreateClient(ctx, chainA, chainB, clientType)
	require.NoError(coord.t, err)

	clientB, err := coord.CreateClient(ctx, chainB, chainA, clientType)
	require.NoError(coord.t, err)

	return clientA, clientB
}

// SetupClientConnections is a helper function to create clients and the appropriate
// connections on both the source and counterparty chain. It assumes the caller does not
// anticipate any errors.
func (coord *Coordinator) SetupClientConnections(
	ctx context.Context,
	chainA, chainB *Chain,
	clientType string,
) (string, string, *TestConnection, *TestConnection) {

	clientA, clientB := coord.SetupClients(ctx, chainA, chainB, clientType)

	connA, connB := coord.CreateConnection(ctx, chainA, chainB, clientA, clientB)

	return clientA, clientB, connA, connB
}

func (coord *Coordinator) UpdateLCInputData() {
	for _, c := range coord.chains {
		c.UpdateLCInputData()
	}
}

func (c Coordinator) CreateClient(
	ctx context.Context,
	source, counterparty *Chain,
	clientType string,
) (clientID string, err error) {
	switch clientType {
	case clienttypes.BesuIBFT2Client:
		clientID, err = source.CreateIBFT2Client(ctx, counterparty)
	case clienttypes.MockClient:
		clientID, err = source.CreateMockClient(ctx, counterparty)
	default:
		err = fmt.Errorf("client type %s is not supported", clientType)
	}

	if err != nil {
		return "", err
	}

	return clientID, nil
}

func (c Coordinator) UpdateClient(
	ctx context.Context,
	source, counterparty *Chain,
	clientID string,
) error {
	counterparty.UpdateLCInputData()
	var err error
	switch counterparty.ClientType() {
	case clienttypes.BesuIBFT2Client:
		err = source.UpdateIBFT2Client(ctx, counterparty, clientID)
	case clienttypes.MockClient:
		err = source.UpdateMockClient(ctx, counterparty, clientID)
	default:
		err = fmt.Errorf("client type %s is not supported", counterparty.ClientType())
	}
	if err != nil {
		return err
	}
	return nil
}

// CreateConnection constructs and executes connection handshake messages in order to create
// OPEN channels on chainA and chainB. The connection information of for chainA and chainB
// are returned within a TestConnection struct. The function expects the connections to be
// successfully opened otherwise testing will fail.
func (c *Coordinator) CreateConnection(
	ctx context.Context,
	chainA, chainB *Chain,
	clientA, clientB string,
) (*TestConnection, *TestConnection) {

	connA, connB, err := c.ConnOpenInit(ctx, chainA, chainB, clientA, clientB)
	require.NoError(c.t, err)

	require.NoError(c.t, c.ConnOpenTry(ctx, chainB, chainA, connB, connA))
	require.NoError(c.t, c.ConnOpenAck(ctx, chainA, chainB, connA, connB))
	require.NoError(c.t, c.ConnOpenConfirm(ctx, chainB, chainA, connB, connA))

	return connA, connB
}

// CreateChannel constructs and executes channel handshake messages in order to create
// OPEN channels on chainA and chainB. The function expects the channels to be successfully
// opened otherwise testing will fail.
func (c *Coordinator) CreateChannel(
	ctx context.Context,
	chainA, chainB *Chain,
	connA, connB *TestConnection,
	sourcePortID, counterpartyPortID string,
	order channeltypes.Channel_Order,
) (TestChannel, TestChannel) {

	channelA, channelB, err := c.ChanOpenInit(ctx, chainA, chainB, connA, connB, sourcePortID, counterpartyPortID, order)
	require.NoError(c.t, err)

	err = c.ChanOpenTry(ctx, chainB, chainA, &channelB, &channelA, connB, order)
	require.NoError(c.t, err)

	err = c.ChanOpenAck(ctx, chainA, chainB, channelA, channelB)
	require.NoError(c.t, err)

	err = c.ChanOpenConfirm(ctx, chainB, chainA, channelB, channelA)
	require.NoError(c.t, err)

	return channelA, channelB
}

// CloseChannel constructs and executes channel closing messages in order to transition
// the channel to the CLOSED state on chainA and chainB.
// The function expects the channels to be successfully closed otherwise testing will fail.
func (c *Coordinator) CloseChannel(
	ctx context.Context,
	chainA, chainB *Chain,
	chanA, chanB TestChannel,
) {
	err := c.ChanCloseInit(ctx, chainA, chainB, chanA)
	require.NoError(c.t, err)
	require.NoError(c.t, chainA.EnsureChannelState(ctx, chanA.PortID, chanA.ID, channeltypes.CLOSED))

	err = c.ChanCloseConfirm(ctx, chainB, chainA, chanB, chanA)
	require.NoError(c.t, err)
	require.NoError(c.t, chainB.EnsureChannelState(ctx, chanB.PortID, chanB.ID, channeltypes.CLOSED))
}

// ConnOpenInit initializes a connection on the source chain with the state INIT
// using the OpenInit handshake call.
//
// NOTE: The counterparty testing connection will be created even if it is not created in the
// application state.
func (c Coordinator) ConnOpenInit(
	ctx context.Context,
	source, counterparty *Chain,
	clientID, counterpartyClientID string,
) (*TestConnection, *TestConnection, error) {

	sourceConnection := source.AddTestConnection(clientID, counterpartyClientID)
	counterpartyConnection := counterparty.AddTestConnection(counterpartyClientID, clientID)

	// initialize connection on source
	if connID, err := source.ConnectionOpenInit(ctx, counterparty, sourceConnection, counterpartyConnection); err != nil {
		fmt.Println("ConnectionOpenInit failed", err)
		return sourceConnection, counterpartyConnection, err
	} else {
		sourceConnection.ID = connID
	}

	// update source client on counterparty connection
	if err := c.UpdateClient(
		ctx,
		counterparty, source,
		counterpartyClientID,
	); err != nil {
		return sourceConnection, counterpartyConnection, err
	}

	return sourceConnection, counterpartyConnection, nil
}

// ConnOpenTry initializes a connection on the source chain with the state TRYOPEN
// using the OpenTry handshake call.
func (c *Coordinator) ConnOpenTry(
	ctx context.Context,
	source, counterparty *Chain,
	sourceConnection, counterpartyConnection *TestConnection,
) error {

	if connID, err := source.ConnectionOpenTry(ctx, counterparty, sourceConnection, counterpartyConnection); err != nil {
		return err
	} else {
		sourceConnection.ID = connID
	}

	return c.UpdateClient(
		ctx,
		counterparty, source,
		counterpartyConnection.ClientID,
	)
}

// ConnOpenAck initializes a connection on the source chain with the state OPEN
// using the OpenAck handshake call.
func (c *Coordinator) ConnOpenAck(
	ctx context.Context,
	source, counterparty *Chain,
	sourceConnection, counterpartyConnection *TestConnection,
) error {
	// set OPEN connection on source using OpenAck
	if err := source.ConnectionOpenAck(ctx, counterparty, sourceConnection, counterpartyConnection); err != nil {
		return err
	}

	// update source client on counterparty connection
	return c.UpdateClient(
		ctx,
		counterparty, source,
		counterpartyConnection.ClientID,
	)
}

// ConnOpenConfirm initializes a connection on the source chain with the state OPEN
// using the OpenConfirm handshake call.
func (c *Coordinator) ConnOpenConfirm(
	ctx context.Context,
	source, counterparty *Chain,
	sourceConnection, counterpartyConnection *TestConnection,
) error {
	if err := source.ConnectionOpenConfirm(ctx, counterparty, sourceConnection, counterpartyConnection); err != nil {
		return err
	}

	// update source client on counterparty connection
	return c.UpdateClient(
		ctx,
		counterparty, source,
		counterpartyConnection.ClientID,
	)
}

// ChanOpenInit initializes a channel on the source chain with the state INIT
// using the OpenInit handshake call.
//
// NOTE: The counterparty testing channel will be created even if it is not created in the
// application state.
func (c *Coordinator) ChanOpenInit(
	ctx context.Context,
	source, counterparty *Chain,
	connection, counterpartyConnection *TestConnection,
	sourcePortID, counterpartyPortID string,
	order channeltypes.Channel_Order,
) (TestChannel, TestChannel, error) {
	sourceChannel := source.AddTestChannel(connection, sourcePortID)
	counterpartyChannel := counterparty.AddTestChannel(counterpartyConnection, counterpartyPortID)

	if channelID, err := source.ChannelOpenInit(ctx, sourceChannel, counterpartyChannel, order, connection.ID); err != nil {
		return sourceChannel, counterpartyChannel, err
	} else {
		sourceChannel.ID = channelID
	}

	// update source client on counterparty connection
	err := c.UpdateClient(
		ctx,
		counterparty, source,
		counterpartyConnection.ClientID,
	)
	return sourceChannel, counterpartyChannel, err
}

// ChanOpenTry relays notice of a channel open attempt on chain A to chain B (this
// code is executed on chain B).
func (c *Coordinator) ChanOpenTry(
	ctx context.Context,
	source, counterparty *Chain,
	sourceChannel, counterpartyChannel *TestChannel,
	connection *TestConnection,
	order channeltypes.Channel_Order,
) error {
	// initialize channel on source
	if channelID, err := source.ChannelOpenTry(ctx, counterparty, *sourceChannel, *counterpartyChannel, order, connection.ID); err != nil {
		return err
	} else {
		sourceChannel.ID = channelID
	}

	// update source client on counterparty connection
	return c.UpdateClient(
		ctx,
		counterparty, source,
		connection.CounterpartyClientID,
	)
}

// ChanOpenAck relays acceptance of a channel open attempt from chain B back
// to chain A (this code is executed on chain A).
func (c *Coordinator) ChanOpenAck(
	ctx context.Context,
	source, counterparty *Chain,
	sourceChannel, counterpartyChannel TestChannel,
) error {
	if err := source.ChannelOpenAck(ctx, counterparty, sourceChannel, counterpartyChannel); err != nil {
		return err
	}

	// update source client on counterparty connection
	return c.UpdateClient(
		ctx,
		counterparty, source,
		sourceChannel.CounterpartyClientID,
	)
}

// ChanOpenConfirm confirms opening of a channel on chain A to chain B, after
// which the channel is open on both chains (this code is executed on chain B).
func (c *Coordinator) ChanOpenConfirm(
	ctx context.Context,
	source, counterparty *Chain,
	sourceChannel, counterpartyChannel TestChannel,
) error {
	if err := source.ChannelOpenConfirm(ctx, counterparty, sourceChannel, counterpartyChannel); err != nil {
		return err
	}

	return c.UpdateClient(
		ctx,
		counterparty, source,
		sourceChannel.CounterpartyClientID,
	)
}

// ChanCloseInit closes a channel on chain A to chain B (this code is executed on chain A).
func (c *Coordinator) ChanCloseInit(
	ctx context.Context,
	source, counterparty *Chain,
	sourceChannel TestChannel,
) error {
	if err := source.ChannelCloseInit(ctx, sourceChannel); err != nil {
		return err
	}

	return c.UpdateClient(
		ctx,
		counterparty, source,
		sourceChannel.CounterpartyClientID,
	)
}

// ChanCloseConfirm confirms closing of a channel on chain A to chain B, after
// which the channel is closed on both chains (this code is executed on chain B).
func (c *Coordinator) ChanCloseConfirm(
	ctx context.Context,
	source, counterparty *Chain,
	sourceChannel, counterpartyChannel TestChannel,
) error {
	if err := source.ChannelCloseConfirm(ctx, counterparty, sourceChannel, counterpartyChannel); err != nil {
		return err
	}

	return c.UpdateClient(
		ctx,
		counterparty, source,
		sourceChannel.CounterpartyClientID,
	)
}

// SendPacket sends a packet through the channel keeper on the source chain and updates the
// counterparty client for the source chain.
func (c *Coordinator) SendPacket(
	ctx context.Context,
	source, counterparty *Chain,
	packet channeltypes.Packet,
	counterpartyClientID string,
) error {
	if err := source.SendPacket(ctx, packet); err != nil {
		return err
	}

	// update source client on counterparty connection
	return c.UpdateClient(
		ctx,
		counterparty, source,
		counterpartyClientID,
	)
}

func (c *Coordinator) HandlePacketRecv(
	ctx context.Context,
	source, counterparty *Chain,
	sourceChannel, counterpartyChannel TestChannel,
	packet channeltypes.Packet,
) error {
	if err := source.HandlePacketRecv(ctx, counterparty, sourceChannel, counterpartyChannel, packet); err != nil {
		return err
	}

	// update source client on counterparty connection
	return c.UpdateClient(
		ctx,
		counterparty, source,
		counterpartyChannel.ClientID,
	)
}

func (c *Coordinator) HandlePacketAcknowledgement(
	ctx context.Context,
	source, counterparty *Chain,
	sourceChannel, counterpartyChannel TestChannel,
	packet channeltypes.Packet,
	acknowledgement []byte,
) error {
	if err := source.HandlePacketAcknowledgement(ctx, counterparty, sourceChannel, counterpartyChannel, packet, acknowledgement); err != nil {
		return err
	}

	// update source client on counterparty connection
	return c.UpdateClient(
		ctx,
		counterparty, source,
		counterpartyChannel.ClientID,
	)
}

func (c *Coordinator) RelayLastSentPacket(
	ctx context.Context,
	source, counterparty *Chain,
	sourceChannel, counterpartyChannel TestChannel,
	packetCb func([]byte),
	ackCb func([]byte),
) {
	packet, err := source.GetLastSentPacket(ctx, sourceChannel.PortID, sourceChannel.ID)
	require.NoError(c.t, err)
	c.t.Logf("packet found: %v", string(packet.Data))
	if packetCb != nil {
		packetCb(packet.Data)
	}
	require.NoError(c.t, c.HandlePacketRecv(ctx, counterparty, source, counterpartyChannel, sourceChannel, *packet))
	ack, err := counterparty.FindAcknowledgement(ctx, counterpartyChannel.PortID, counterpartyChannel.ID, packet.Sequence)
	require.NoError(c.t, err)
	c.t.Logf("ack found: %v", string(ack))
	if ackCb != nil {
		ackCb(ack)
	}
	require.NoError(c.t, c.HandlePacketAcknowledgement(ctx, source, counterparty, sourceChannel, counterpartyChannel, *packet, ack))
}

func (c *Coordinator) RelayLastSentPacketWithDelay(
	ctx context.Context,
	source, counterparty *Chain,
	sourceChannel, counterpartyChannel TestChannel,
	sourceDelayPeriodExtension, counterpartyDelayPeriodExtension uint64,
	delayStartTimeForRecv time.Time,
) {
	var delayStartTimeForAck time.Time

	packet, err := source.GetLastSentPacket(ctx, sourceChannel.PortID, sourceChannel.ID)
	require.NoError(c.t, err)
	c.t.Logf("packet found: %v", string(packet.Data))
	require.NoError(c.t, retry.Do(
		func() error {
			delayStartTimeForAck = time.Now()
			return c.HandlePacketRecv(ctx, counterparty, source, counterpartyChannel, sourceChannel, *packet)
		},
		retry.Delay(time.Second),
		retry.Attempts(60),
	))
	delayForRecv := time.Since(delayStartTimeForRecv)
	c.t.Logf("delay for recv@%v %s", counterparty.chainID, delayForRecv)
	require.Greater(c.t, delayForRecv, time.Duration(counterpartyDelayPeriodExtension*counterparty.GetDelayPeriod()))
	ack, err := counterparty.FindAcknowledgement(ctx, counterpartyChannel.PortID, counterpartyChannel.ID, packet.Sequence)
	require.NoError(c.t, err)
	c.t.Logf("ack found: %v", string(ack))
	require.NoError(c.t, retry.Do(
		func() error {
			return c.HandlePacketAcknowledgement(ctx, source, counterparty, sourceChannel, counterpartyChannel, *packet, ack)
		},
		retry.Delay(time.Second),
		retry.Attempts(60),
	))
	delayForAck := time.Since(delayStartTimeForAck)
	c.t.Logf("delay for ack@%v %s", source.chainID, delayForAck)
	require.Greater(c.t, delayForAck, time.Duration(sourceDelayPeriodExtension*source.GetDelayPeriod()))
}
