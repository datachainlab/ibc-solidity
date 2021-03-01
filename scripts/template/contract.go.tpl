package consts

import (
	"github.com/ethereum/go-ethereum/common"
)

const (
	IBCHostAddress = "<%= IBCHostAddress; %>"
	IBCHandlerAddress = "<%= IBCHandlerAddress; %>"
	IBCIdentifierAddress = "<%= IBCIdentifierAddress; %>"
	IBFT2ClientAddress = "<%= IBFT2ClientAddress; %>"
	SimpleTokenModuleAddress = "<%= SimpleTokenModuleAddress; %>"
	SimpleTokenAddress = "<%= SimpleTokenAddress; %>"
	ICS20TransferAddress = "<%= ICS20TransferAddress; %>"
	ICS20VouchersAddress = "<%= ICS20VouchersAddress; %>"
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

func (contractConfig) GetSimpleTokenModuleAddress() common.Address {
	return common.HexToAddress(SimpleTokenModuleAddress)
}

func (contractConfig) GetSimpleTokenAddress() common.Address {
	return common.HexToAddress(SimpleTokenAddresss)
}

func (contractConfig) GetICS20TransferAddress() common.Address {
	return common.HexToAddress(ICS20TransferAddress)
}

func (contractConfig) GetICS20VouchersAddress() common.Address {
	return common.HexToAddress(ICS20VouchersAddress)
}
