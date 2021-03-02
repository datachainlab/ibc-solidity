package consts

import (
	"github.com/ethereum/go-ethereum/common"
)

const (
	IBCHostAddress = "<%= IBCHostAddress; %>"
	IBCHandlerAddress = "<%= IBCHandlerAddress; %>"
	IBCIdentifierAddress = "<%= IBCIdentifierAddress; %>"
	IBFT2ClientAddress = "<%= IBFT2ClientAddress; %>"
	SimpleTokenAddress = "<%= SimpleTokenAddress; %>"
	ICS20TransferAddress = "<%= ICS20TransferAddress; %>"
	ICS20BankAddress = "<%= ICS20BankAddress; %>"
)

type contractConfig struct{}

var Contract contractConfig

func (contractConfig) GetIBCHostAddress() common.Address {
	return common.HexToAddress(IBCHostAddress)
}

func (contractConfig) GetIBCHandlerAddress() common.Address {
	return common.HexToAddress(IBCHandlerAddress)
}

func (contractConfig) GetIBCIdentifierAddress() common.Address {
	return common.HexToAddress(IBCIdentifierAddress)
}

func (contractConfig) GetIBFT2ClientAddress() common.Address {
	return common.HexToAddress(IBFT2ClientAddress)
}

func (contractConfig) GetSimpleTokenAddress() common.Address {
	return common.HexToAddress(SimpleTokenAddress)
}

func (contractConfig) GetICS20TransferAddress() common.Address {
	return common.HexToAddress(ICS20TransferAddress)
}

func (contractConfig) GetICS20BankAddress() common.Address {
	return common.HexToAddress(ICS20BankAddress)
}
