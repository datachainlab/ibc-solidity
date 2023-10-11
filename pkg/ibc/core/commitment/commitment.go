package commitment

import (
	host "github.com/cosmos/ibc-go/v7/modules/core/24-host"
	"github.com/cosmos/ibc-go/v7/modules/core/exported"
	"github.com/ethereum/go-ethereum/crypto"
)

// This value is determined by IBCHost.sol
var ibcHostCommitmentSlot = [32]byte{} // uint256(0)

// Slot calculator

func ClientStateCommitmentSlot(clientID string) string {
	return CalculateCommitmentSlot(host.FullClientStateKey(clientID))
}

func ConsensusStateCommitmentSlot(clientID string, height exported.Height) string {
	return CalculateCommitmentSlot(host.FullConsensusStateKey(clientID, height))
}

func ConnectionStateCommitmentSlot(connectionID string) string {
	return CalculateCommitmentSlot(host.ConnectionKey(connectionID))
}

func ChannelStateCommitmentSlot(portID, channelID string) string {
	return CalculateCommitmentSlot(host.ChannelKey(portID, channelID))
}

func PacketCommitmentSlot(portID, channelID string, sequence uint64) string {
	return CalculateCommitmentSlot(host.PacketCommitmentKey(portID, channelID, sequence))
}

func PacketAcknowledgementCommitmentSlot(portID, channelID string, sequence uint64) string {
	return CalculateCommitmentSlot(host.PacketAcknowledgementKey(portID, channelID, sequence))
}

func PacketReceiptCommitmentSlot(portID, channelID string, sequence uint64) string {
	return CalculateCommitmentSlot(host.PacketReceiptKey(portID, channelID, sequence))
}

func NextSequenceRecvCommitmentSlot(portID, channelID string) string {
	return CalculateCommitmentSlot(host.NextSequenceRecvKey(portID, channelID))
}

func CalculateCommitmentSlot(path []byte) string {
	return crypto.Keccak256Hash(crypto.Keccak256Hash(path).Bytes(), ibcHostCommitmentSlot[:]).Hex()
}
