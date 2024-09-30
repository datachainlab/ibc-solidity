// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package ics20transferbank

import (
	"errors"
	"math/big"
	"strings"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/event"
)

// Reference imports to suppress errors if they are not otherwise used.
var (
	_ = errors.New
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
	_ = abi.ConvertType
)

// ChannelCounterpartyData is an auto generated low-level Go binding around an user-defined struct.
type ChannelCounterpartyData struct {
	PortId    string
	ChannelId string
}

// HeightData is an auto generated low-level Go binding around an user-defined struct.
type HeightData struct {
	RevisionNumber uint64
	RevisionHeight uint64
}

// IIBCModuleInitializerMsgOnChanOpenInit is an auto generated low-level Go binding around an user-defined struct.
type IIBCModuleInitializerMsgOnChanOpenInit struct {
	Order          uint8
	ConnectionHops []string
	PortId         string
	ChannelId      string
	Counterparty   ChannelCounterpartyData
	Version        string
}

// IIBCModuleInitializerMsgOnChanOpenTry is an auto generated low-level Go binding around an user-defined struct.
type IIBCModuleInitializerMsgOnChanOpenTry struct {
	Order               uint8
	ConnectionHops      []string
	PortId              string
	ChannelId           string
	Counterparty        ChannelCounterpartyData
	CounterpartyVersion string
}

// IIBCModuleMsgOnChanCloseConfirm is an auto generated low-level Go binding around an user-defined struct.
type IIBCModuleMsgOnChanCloseConfirm struct {
	PortId    string
	ChannelId string
}

// IIBCModuleMsgOnChanCloseInit is an auto generated low-level Go binding around an user-defined struct.
type IIBCModuleMsgOnChanCloseInit struct {
	PortId    string
	ChannelId string
}

// IIBCModuleMsgOnChanOpenAck is an auto generated low-level Go binding around an user-defined struct.
type IIBCModuleMsgOnChanOpenAck struct {
	PortId              string
	ChannelId           string
	CounterpartyVersion string
}

// IIBCModuleMsgOnChanOpenConfirm is an auto generated low-level Go binding around an user-defined struct.
type IIBCModuleMsgOnChanOpenConfirm struct {
	PortId    string
	ChannelId string
}

// Packet is an auto generated low-level Go binding around an user-defined struct.
type Packet struct {
	Sequence           uint64
	SourcePort         string
	SourceChannel      string
	DestinationPort    string
	DestinationChannel string
	Data               []byte
	TimeoutHeight      HeightData
	TimeoutTimestamp   uint64
}

// Ics20transferbankMetaData contains all meta data concerning the Ics20transferbank contract.
var Ics20transferbankMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"ibcHandler_\",\"type\":\"address\",\"internalType\":\"contractIIBCHandler\"},{\"name\":\"bank_\",\"type\":\"address\",\"internalType\":\"contractIICS20Bank\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"ICS20_VERSION\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"ibcAddress\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"onAcknowledgementPacket\",\"inputs\":[{\"name\":\"packet\",\"type\":\"tuple\",\"internalType\":\"structPacket\",\"components\":[{\"name\":\"sequence\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"sourcePort\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"sourceChannel\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"destinationPort\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"destinationChannel\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"timeoutHeight\",\"type\":\"tuple\",\"internalType\":\"structHeight.Data\",\"components\":[{\"name\":\"revision_number\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"revision_height\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]},{\"name\":\"timeoutTimestamp\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]},{\"name\":\"acknowledgement\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"onChanCloseConfirm\",\"inputs\":[{\"name\":\"\",\"type\":\"tuple\",\"internalType\":\"structIIBCModule.MsgOnChanCloseConfirm\",\"components\":[{\"name\":\"portId\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"channelId\",\"type\":\"string\",\"internalType\":\"string\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"onChanCloseInit\",\"inputs\":[{\"name\":\"msg_\",\"type\":\"tuple\",\"internalType\":\"structIIBCModule.MsgOnChanCloseInit\",\"components\":[{\"name\":\"portId\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"channelId\",\"type\":\"string\",\"internalType\":\"string\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"onChanOpenAck\",\"inputs\":[{\"name\":\"msg_\",\"type\":\"tuple\",\"internalType\":\"structIIBCModule.MsgOnChanOpenAck\",\"components\":[{\"name\":\"portId\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"channelId\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"counterpartyVersion\",\"type\":\"string\",\"internalType\":\"string\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"onChanOpenConfirm\",\"inputs\":[{\"name\":\"\",\"type\":\"tuple\",\"internalType\":\"structIIBCModule.MsgOnChanOpenConfirm\",\"components\":[{\"name\":\"portId\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"channelId\",\"type\":\"string\",\"internalType\":\"string\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"onChanOpenInit\",\"inputs\":[{\"name\":\"msg_\",\"type\":\"tuple\",\"internalType\":\"structIIBCModuleInitializer.MsgOnChanOpenInit\",\"components\":[{\"name\":\"order\",\"type\":\"uint8\",\"internalType\":\"enumChannel.Order\"},{\"name\":\"connectionHops\",\"type\":\"string[]\",\"internalType\":\"string[]\"},{\"name\":\"portId\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"channelId\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"counterparty\",\"type\":\"tuple\",\"internalType\":\"structChannelCounterparty.Data\",\"components\":[{\"name\":\"port_id\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"channel_id\",\"type\":\"string\",\"internalType\":\"string\"}]},{\"name\":\"version\",\"type\":\"string\",\"internalType\":\"string\"}]}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"onChanOpenTry\",\"inputs\":[{\"name\":\"msg_\",\"type\":\"tuple\",\"internalType\":\"structIIBCModuleInitializer.MsgOnChanOpenTry\",\"components\":[{\"name\":\"order\",\"type\":\"uint8\",\"internalType\":\"enumChannel.Order\"},{\"name\":\"connectionHops\",\"type\":\"string[]\",\"internalType\":\"string[]\"},{\"name\":\"portId\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"channelId\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"counterparty\",\"type\":\"tuple\",\"internalType\":\"structChannelCounterparty.Data\",\"components\":[{\"name\":\"port_id\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"channel_id\",\"type\":\"string\",\"internalType\":\"string\"}]},{\"name\":\"counterpartyVersion\",\"type\":\"string\",\"internalType\":\"string\"}]}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"onRecvPacket\",\"inputs\":[{\"name\":\"packet\",\"type\":\"tuple\",\"internalType\":\"structPacket\",\"components\":[{\"name\":\"sequence\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"sourcePort\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"sourceChannel\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"destinationPort\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"destinationChannel\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"timeoutHeight\",\"type\":\"tuple\",\"internalType\":\"structHeight.Data\",\"components\":[{\"name\":\"revision_number\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"revision_height\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]},{\"name\":\"timeoutTimestamp\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]},{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"acknowledgement\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"onTimeoutPacket\",\"inputs\":[{\"name\":\"packet\",\"type\":\"tuple\",\"internalType\":\"structPacket\",\"components\":[{\"name\":\"sequence\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"sourcePort\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"sourceChannel\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"destinationPort\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"destinationChannel\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"timeoutHeight\",\"type\":\"tuple\",\"internalType\":\"structHeight.Data\",\"components\":[{\"name\":\"revision_number\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"revision_height\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]},{\"name\":\"timeoutTimestamp\",\"type\":\"uint64\",\"internalType\":\"uint64\"}]},{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"sendTransfer\",\"inputs\":[{\"name\":\"denom\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"receiver\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"sourcePort\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"sourceChannel\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"timeoutHeight\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"error\",\"name\":\"IBCModuleChannelCloseNotAllowed\",\"inputs\":[{\"name\":\"portId\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"channelId\",\"type\":\"string\",\"internalType\":\"string\"}]},{\"type\":\"error\",\"name\":\"IBCModuleChannelOrderNotAllowed\",\"inputs\":[{\"name\":\"portId\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"channelId\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"order\",\"type\":\"uint8\",\"internalType\":\"enumChannel.Order\"}]},{\"type\":\"error\",\"name\":\"IBCModuleInvalidSender\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ICS20BankNotAdminRole\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ICS20BankNotBurnRole\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ICS20BankNotMintRole\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ICS20BytesSliceOutOfBounds\",\"inputs\":[{\"name\":\"length\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"start\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"end\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ICS20BytesSliceOverflow\",\"inputs\":[{\"name\":\"length\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ICS20EscrowAddressNotFound\",\"inputs\":[{\"name\":\"channelId\",\"type\":\"string\",\"internalType\":\"string\"}]},{\"type\":\"error\",\"name\":\"ICS20FailedERC20Transfer\",\"inputs\":[{\"name\":\"tokenContract\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"from\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ICS20FailedERC20TransferFrom\",\"inputs\":[{\"name\":\"tokenContract\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"from\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ICS20InsufficientBalance\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"balance\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"needed\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ICS20InvalidReceiver\",\"inputs\":[{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ICS20InvalidReceiverAddress\",\"inputs\":[{\"name\":\"receiver\",\"type\":\"string\",\"internalType\":\"string\"}]},{\"type\":\"error\",\"name\":\"ICS20InvalidSender\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ICS20InvalidSenderAddress\",\"inputs\":[{\"name\":\"sender\",\"type\":\"string\",\"internalType\":\"string\"}]},{\"type\":\"error\",\"name\":\"ICS20InvalidTokenContract\",\"inputs\":[{\"name\":\"tokenContract\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ICS20JSONClosingBraceNotFound\",\"inputs\":[{\"name\":\"position\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"actual\",\"type\":\"bytes1\",\"internalType\":\"bytes1\"}]},{\"type\":\"error\",\"name\":\"ICS20JSONInvalidEscape\",\"inputs\":[{\"name\":\"position\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"actual\",\"type\":\"bytes1\",\"internalType\":\"bytes1\"}]},{\"type\":\"error\",\"name\":\"ICS20JSONStringClosingDoubleQuoteNotFound\",\"inputs\":[{\"name\":\"position\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"actual\",\"type\":\"bytes1\",\"internalType\":\"bytes1\"}]},{\"type\":\"error\",\"name\":\"ICS20JSONStringUnclosed\",\"inputs\":[{\"name\":\"bz\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"position\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ICS20JSONUnexpectedBytes\",\"inputs\":[{\"name\":\"position\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"expected\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"actual\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"ICS20UnexpectedVersion\",\"inputs\":[{\"name\":\"version\",\"type\":\"string\",\"internalType\":\"string\"}]}]",
}

// Ics20transferbankABI is the input ABI used to generate the binding from.
// Deprecated: Use Ics20transferbankMetaData.ABI instead.
var Ics20transferbankABI = Ics20transferbankMetaData.ABI

// Ics20transferbank is an auto generated Go binding around an Ethereum contract.
type Ics20transferbank struct {
	Ics20transferbankCaller     // Read-only binding to the contract
	Ics20transferbankTransactor // Write-only binding to the contract
	Ics20transferbankFilterer   // Log filterer for contract events
}

// Ics20transferbankCaller is an auto generated read-only Go binding around an Ethereum contract.
type Ics20transferbankCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// Ics20transferbankTransactor is an auto generated write-only Go binding around an Ethereum contract.
type Ics20transferbankTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// Ics20transferbankFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type Ics20transferbankFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// Ics20transferbankSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type Ics20transferbankSession struct {
	Contract     *Ics20transferbank // Generic contract binding to set the session for
	CallOpts     bind.CallOpts      // Call options to use throughout this session
	TransactOpts bind.TransactOpts  // Transaction auth options to use throughout this session
}

// Ics20transferbankCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type Ics20transferbankCallerSession struct {
	Contract *Ics20transferbankCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts            // Call options to use throughout this session
}

// Ics20transferbankTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type Ics20transferbankTransactorSession struct {
	Contract     *Ics20transferbankTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts            // Transaction auth options to use throughout this session
}

// Ics20transferbankRaw is an auto generated low-level Go binding around an Ethereum contract.
type Ics20transferbankRaw struct {
	Contract *Ics20transferbank // Generic contract binding to access the raw methods on
}

// Ics20transferbankCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type Ics20transferbankCallerRaw struct {
	Contract *Ics20transferbankCaller // Generic read-only contract binding to access the raw methods on
}

// Ics20transferbankTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type Ics20transferbankTransactorRaw struct {
	Contract *Ics20transferbankTransactor // Generic write-only contract binding to access the raw methods on
}

// NewIcs20transferbank creates a new instance of Ics20transferbank, bound to a specific deployed contract.
func NewIcs20transferbank(address common.Address, backend bind.ContractBackend) (*Ics20transferbank, error) {
	contract, err := bindIcs20transferbank(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &Ics20transferbank{Ics20transferbankCaller: Ics20transferbankCaller{contract: contract}, Ics20transferbankTransactor: Ics20transferbankTransactor{contract: contract}, Ics20transferbankFilterer: Ics20transferbankFilterer{contract: contract}}, nil
}

// NewIcs20transferbankCaller creates a new read-only instance of Ics20transferbank, bound to a specific deployed contract.
func NewIcs20transferbankCaller(address common.Address, caller bind.ContractCaller) (*Ics20transferbankCaller, error) {
	contract, err := bindIcs20transferbank(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &Ics20transferbankCaller{contract: contract}, nil
}

// NewIcs20transferbankTransactor creates a new write-only instance of Ics20transferbank, bound to a specific deployed contract.
func NewIcs20transferbankTransactor(address common.Address, transactor bind.ContractTransactor) (*Ics20transferbankTransactor, error) {
	contract, err := bindIcs20transferbank(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &Ics20transferbankTransactor{contract: contract}, nil
}

// NewIcs20transferbankFilterer creates a new log filterer instance of Ics20transferbank, bound to a specific deployed contract.
func NewIcs20transferbankFilterer(address common.Address, filterer bind.ContractFilterer) (*Ics20transferbankFilterer, error) {
	contract, err := bindIcs20transferbank(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &Ics20transferbankFilterer{contract: contract}, nil
}

// bindIcs20transferbank binds a generic wrapper to an already deployed contract.
func bindIcs20transferbank(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := Ics20transferbankMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Ics20transferbank *Ics20transferbankRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Ics20transferbank.Contract.Ics20transferbankCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Ics20transferbank *Ics20transferbankRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Ics20transferbank.Contract.Ics20transferbankTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Ics20transferbank *Ics20transferbankRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Ics20transferbank.Contract.Ics20transferbankTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Ics20transferbank *Ics20transferbankCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Ics20transferbank.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Ics20transferbank *Ics20transferbankTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Ics20transferbank.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Ics20transferbank *Ics20transferbankTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Ics20transferbank.Contract.contract.Transact(opts, method, params...)
}

// ICS20VERSION is a free data retrieval call binding the contract method 0x025183eb.
//
// Solidity: function ICS20_VERSION() view returns(string)
func (_Ics20transferbank *Ics20transferbankCaller) ICS20VERSION(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _Ics20transferbank.contract.Call(opts, &out, "ICS20_VERSION")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// ICS20VERSION is a free data retrieval call binding the contract method 0x025183eb.
//
// Solidity: function ICS20_VERSION() view returns(string)
func (_Ics20transferbank *Ics20transferbankSession) ICS20VERSION() (string, error) {
	return _Ics20transferbank.Contract.ICS20VERSION(&_Ics20transferbank.CallOpts)
}

// ICS20VERSION is a free data retrieval call binding the contract method 0x025183eb.
//
// Solidity: function ICS20_VERSION() view returns(string)
func (_Ics20transferbank *Ics20transferbankCallerSession) ICS20VERSION() (string, error) {
	return _Ics20transferbank.Contract.ICS20VERSION(&_Ics20transferbank.CallOpts)
}

// IbcAddress is a free data retrieval call binding the contract method 0x696a9bf4.
//
// Solidity: function ibcAddress() view returns(address)
func (_Ics20transferbank *Ics20transferbankCaller) IbcAddress(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _Ics20transferbank.contract.Call(opts, &out, "ibcAddress")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// IbcAddress is a free data retrieval call binding the contract method 0x696a9bf4.
//
// Solidity: function ibcAddress() view returns(address)
func (_Ics20transferbank *Ics20transferbankSession) IbcAddress() (common.Address, error) {
	return _Ics20transferbank.Contract.IbcAddress(&_Ics20transferbank.CallOpts)
}

// IbcAddress is a free data retrieval call binding the contract method 0x696a9bf4.
//
// Solidity: function ibcAddress() view returns(address)
func (_Ics20transferbank *Ics20transferbankCallerSession) IbcAddress() (common.Address, error) {
	return _Ics20transferbank.Contract.IbcAddress(&_Ics20transferbank.CallOpts)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_Ics20transferbank *Ics20transferbankCaller) SupportsInterface(opts *bind.CallOpts, interfaceId [4]byte) (bool, error) {
	var out []interface{}
	err := _Ics20transferbank.contract.Call(opts, &out, "supportsInterface", interfaceId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_Ics20transferbank *Ics20transferbankSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _Ics20transferbank.Contract.SupportsInterface(&_Ics20transferbank.CallOpts, interfaceId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_Ics20transferbank *Ics20transferbankCallerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _Ics20transferbank.Contract.SupportsInterface(&_Ics20transferbank.CallOpts, interfaceId)
}

// OnAcknowledgementPacket is a paid mutator transaction binding the contract method 0xfb8b532e.
//
// Solidity: function onAcknowledgementPacket((uint64,string,string,string,string,bytes,(uint64,uint64),uint64) packet, bytes acknowledgement, address ) returns()
func (_Ics20transferbank *Ics20transferbankTransactor) OnAcknowledgementPacket(opts *bind.TransactOpts, packet Packet, acknowledgement []byte, arg2 common.Address) (*types.Transaction, error) {
	return _Ics20transferbank.contract.Transact(opts, "onAcknowledgementPacket", packet, acknowledgement, arg2)
}

// OnAcknowledgementPacket is a paid mutator transaction binding the contract method 0xfb8b532e.
//
// Solidity: function onAcknowledgementPacket((uint64,string,string,string,string,bytes,(uint64,uint64),uint64) packet, bytes acknowledgement, address ) returns()
func (_Ics20transferbank *Ics20transferbankSession) OnAcknowledgementPacket(packet Packet, acknowledgement []byte, arg2 common.Address) (*types.Transaction, error) {
	return _Ics20transferbank.Contract.OnAcknowledgementPacket(&_Ics20transferbank.TransactOpts, packet, acknowledgement, arg2)
}

// OnAcknowledgementPacket is a paid mutator transaction binding the contract method 0xfb8b532e.
//
// Solidity: function onAcknowledgementPacket((uint64,string,string,string,string,bytes,(uint64,uint64),uint64) packet, bytes acknowledgement, address ) returns()
func (_Ics20transferbank *Ics20transferbankTransactorSession) OnAcknowledgementPacket(packet Packet, acknowledgement []byte, arg2 common.Address) (*types.Transaction, error) {
	return _Ics20transferbank.Contract.OnAcknowledgementPacket(&_Ics20transferbank.TransactOpts, packet, acknowledgement, arg2)
}

// OnChanCloseConfirm is a paid mutator transaction binding the contract method 0x38c858bc.
//
// Solidity: function onChanCloseConfirm((string,string) ) returns()
func (_Ics20transferbank *Ics20transferbankTransactor) OnChanCloseConfirm(opts *bind.TransactOpts, arg0 IIBCModuleMsgOnChanCloseConfirm) (*types.Transaction, error) {
	return _Ics20transferbank.contract.Transact(opts, "onChanCloseConfirm", arg0)
}

// OnChanCloseConfirm is a paid mutator transaction binding the contract method 0x38c858bc.
//
// Solidity: function onChanCloseConfirm((string,string) ) returns()
func (_Ics20transferbank *Ics20transferbankSession) OnChanCloseConfirm(arg0 IIBCModuleMsgOnChanCloseConfirm) (*types.Transaction, error) {
	return _Ics20transferbank.Contract.OnChanCloseConfirm(&_Ics20transferbank.TransactOpts, arg0)
}

// OnChanCloseConfirm is a paid mutator transaction binding the contract method 0x38c858bc.
//
// Solidity: function onChanCloseConfirm((string,string) ) returns()
func (_Ics20transferbank *Ics20transferbankTransactorSession) OnChanCloseConfirm(arg0 IIBCModuleMsgOnChanCloseConfirm) (*types.Transaction, error) {
	return _Ics20transferbank.Contract.OnChanCloseConfirm(&_Ics20transferbank.TransactOpts, arg0)
}

// OnChanCloseInit is a paid mutator transaction binding the contract method 0x3c7df3fb.
//
// Solidity: function onChanCloseInit((string,string) msg_) returns()
func (_Ics20transferbank *Ics20transferbankTransactor) OnChanCloseInit(opts *bind.TransactOpts, msg_ IIBCModuleMsgOnChanCloseInit) (*types.Transaction, error) {
	return _Ics20transferbank.contract.Transact(opts, "onChanCloseInit", msg_)
}

// OnChanCloseInit is a paid mutator transaction binding the contract method 0x3c7df3fb.
//
// Solidity: function onChanCloseInit((string,string) msg_) returns()
func (_Ics20transferbank *Ics20transferbankSession) OnChanCloseInit(msg_ IIBCModuleMsgOnChanCloseInit) (*types.Transaction, error) {
	return _Ics20transferbank.Contract.OnChanCloseInit(&_Ics20transferbank.TransactOpts, msg_)
}

// OnChanCloseInit is a paid mutator transaction binding the contract method 0x3c7df3fb.
//
// Solidity: function onChanCloseInit((string,string) msg_) returns()
func (_Ics20transferbank *Ics20transferbankTransactorSession) OnChanCloseInit(msg_ IIBCModuleMsgOnChanCloseInit) (*types.Transaction, error) {
	return _Ics20transferbank.Contract.OnChanCloseInit(&_Ics20transferbank.TransactOpts, msg_)
}

// OnChanOpenAck is a paid mutator transaction binding the contract method 0x12f6ff6f.
//
// Solidity: function onChanOpenAck((string,string,string) msg_) returns()
func (_Ics20transferbank *Ics20transferbankTransactor) OnChanOpenAck(opts *bind.TransactOpts, msg_ IIBCModuleMsgOnChanOpenAck) (*types.Transaction, error) {
	return _Ics20transferbank.contract.Transact(opts, "onChanOpenAck", msg_)
}

// OnChanOpenAck is a paid mutator transaction binding the contract method 0x12f6ff6f.
//
// Solidity: function onChanOpenAck((string,string,string) msg_) returns()
func (_Ics20transferbank *Ics20transferbankSession) OnChanOpenAck(msg_ IIBCModuleMsgOnChanOpenAck) (*types.Transaction, error) {
	return _Ics20transferbank.Contract.OnChanOpenAck(&_Ics20transferbank.TransactOpts, msg_)
}

// OnChanOpenAck is a paid mutator transaction binding the contract method 0x12f6ff6f.
//
// Solidity: function onChanOpenAck((string,string,string) msg_) returns()
func (_Ics20transferbank *Ics20transferbankTransactorSession) OnChanOpenAck(msg_ IIBCModuleMsgOnChanOpenAck) (*types.Transaction, error) {
	return _Ics20transferbank.Contract.OnChanOpenAck(&_Ics20transferbank.TransactOpts, msg_)
}

// OnChanOpenConfirm is a paid mutator transaction binding the contract method 0x81b174dc.
//
// Solidity: function onChanOpenConfirm((string,string) ) returns()
func (_Ics20transferbank *Ics20transferbankTransactor) OnChanOpenConfirm(opts *bind.TransactOpts, arg0 IIBCModuleMsgOnChanOpenConfirm) (*types.Transaction, error) {
	return _Ics20transferbank.contract.Transact(opts, "onChanOpenConfirm", arg0)
}

// OnChanOpenConfirm is a paid mutator transaction binding the contract method 0x81b174dc.
//
// Solidity: function onChanOpenConfirm((string,string) ) returns()
func (_Ics20transferbank *Ics20transferbankSession) OnChanOpenConfirm(arg0 IIBCModuleMsgOnChanOpenConfirm) (*types.Transaction, error) {
	return _Ics20transferbank.Contract.OnChanOpenConfirm(&_Ics20transferbank.TransactOpts, arg0)
}

// OnChanOpenConfirm is a paid mutator transaction binding the contract method 0x81b174dc.
//
// Solidity: function onChanOpenConfirm((string,string) ) returns()
func (_Ics20transferbank *Ics20transferbankTransactorSession) OnChanOpenConfirm(arg0 IIBCModuleMsgOnChanOpenConfirm) (*types.Transaction, error) {
	return _Ics20transferbank.Contract.OnChanOpenConfirm(&_Ics20transferbank.TransactOpts, arg0)
}

// OnChanOpenInit is a paid mutator transaction binding the contract method 0x0b7b4ccb.
//
// Solidity: function onChanOpenInit((uint8,string[],string,string,(string,string),string) msg_) returns(address, string)
func (_Ics20transferbank *Ics20transferbankTransactor) OnChanOpenInit(opts *bind.TransactOpts, msg_ IIBCModuleInitializerMsgOnChanOpenInit) (*types.Transaction, error) {
	return _Ics20transferbank.contract.Transact(opts, "onChanOpenInit", msg_)
}

// OnChanOpenInit is a paid mutator transaction binding the contract method 0x0b7b4ccb.
//
// Solidity: function onChanOpenInit((uint8,string[],string,string,(string,string),string) msg_) returns(address, string)
func (_Ics20transferbank *Ics20transferbankSession) OnChanOpenInit(msg_ IIBCModuleInitializerMsgOnChanOpenInit) (*types.Transaction, error) {
	return _Ics20transferbank.Contract.OnChanOpenInit(&_Ics20transferbank.TransactOpts, msg_)
}

// OnChanOpenInit is a paid mutator transaction binding the contract method 0x0b7b4ccb.
//
// Solidity: function onChanOpenInit((uint8,string[],string,string,(string,string),string) msg_) returns(address, string)
func (_Ics20transferbank *Ics20transferbankTransactorSession) OnChanOpenInit(msg_ IIBCModuleInitializerMsgOnChanOpenInit) (*types.Transaction, error) {
	return _Ics20transferbank.Contract.OnChanOpenInit(&_Ics20transferbank.TransactOpts, msg_)
}

// OnChanOpenTry is a paid mutator transaction binding the contract method 0xa7a61e66.
//
// Solidity: function onChanOpenTry((uint8,string[],string,string,(string,string),string) msg_) returns(address, string)
func (_Ics20transferbank *Ics20transferbankTransactor) OnChanOpenTry(opts *bind.TransactOpts, msg_ IIBCModuleInitializerMsgOnChanOpenTry) (*types.Transaction, error) {
	return _Ics20transferbank.contract.Transact(opts, "onChanOpenTry", msg_)
}

// OnChanOpenTry is a paid mutator transaction binding the contract method 0xa7a61e66.
//
// Solidity: function onChanOpenTry((uint8,string[],string,string,(string,string),string) msg_) returns(address, string)
func (_Ics20transferbank *Ics20transferbankSession) OnChanOpenTry(msg_ IIBCModuleInitializerMsgOnChanOpenTry) (*types.Transaction, error) {
	return _Ics20transferbank.Contract.OnChanOpenTry(&_Ics20transferbank.TransactOpts, msg_)
}

// OnChanOpenTry is a paid mutator transaction binding the contract method 0xa7a61e66.
//
// Solidity: function onChanOpenTry((uint8,string[],string,string,(string,string),string) msg_) returns(address, string)
func (_Ics20transferbank *Ics20transferbankTransactorSession) OnChanOpenTry(msg_ IIBCModuleInitializerMsgOnChanOpenTry) (*types.Transaction, error) {
	return _Ics20transferbank.Contract.OnChanOpenTry(&_Ics20transferbank.TransactOpts, msg_)
}

// OnRecvPacket is a paid mutator transaction binding the contract method 0x2301c6f5.
//
// Solidity: function onRecvPacket((uint64,string,string,string,string,bytes,(uint64,uint64),uint64) packet, address ) returns(bytes acknowledgement)
func (_Ics20transferbank *Ics20transferbankTransactor) OnRecvPacket(opts *bind.TransactOpts, packet Packet, arg1 common.Address) (*types.Transaction, error) {
	return _Ics20transferbank.contract.Transact(opts, "onRecvPacket", packet, arg1)
}

// OnRecvPacket is a paid mutator transaction binding the contract method 0x2301c6f5.
//
// Solidity: function onRecvPacket((uint64,string,string,string,string,bytes,(uint64,uint64),uint64) packet, address ) returns(bytes acknowledgement)
func (_Ics20transferbank *Ics20transferbankSession) OnRecvPacket(packet Packet, arg1 common.Address) (*types.Transaction, error) {
	return _Ics20transferbank.Contract.OnRecvPacket(&_Ics20transferbank.TransactOpts, packet, arg1)
}

// OnRecvPacket is a paid mutator transaction binding the contract method 0x2301c6f5.
//
// Solidity: function onRecvPacket((uint64,string,string,string,string,bytes,(uint64,uint64),uint64) packet, address ) returns(bytes acknowledgement)
func (_Ics20transferbank *Ics20transferbankTransactorSession) OnRecvPacket(packet Packet, arg1 common.Address) (*types.Transaction, error) {
	return _Ics20transferbank.Contract.OnRecvPacket(&_Ics20transferbank.TransactOpts, packet, arg1)
}

// OnTimeoutPacket is a paid mutator transaction binding the contract method 0x52c7157d.
//
// Solidity: function onTimeoutPacket((uint64,string,string,string,string,bytes,(uint64,uint64),uint64) packet, address ) returns()
func (_Ics20transferbank *Ics20transferbankTransactor) OnTimeoutPacket(opts *bind.TransactOpts, packet Packet, arg1 common.Address) (*types.Transaction, error) {
	return _Ics20transferbank.contract.Transact(opts, "onTimeoutPacket", packet, arg1)
}

// OnTimeoutPacket is a paid mutator transaction binding the contract method 0x52c7157d.
//
// Solidity: function onTimeoutPacket((uint64,string,string,string,string,bytes,(uint64,uint64),uint64) packet, address ) returns()
func (_Ics20transferbank *Ics20transferbankSession) OnTimeoutPacket(packet Packet, arg1 common.Address) (*types.Transaction, error) {
	return _Ics20transferbank.Contract.OnTimeoutPacket(&_Ics20transferbank.TransactOpts, packet, arg1)
}

// OnTimeoutPacket is a paid mutator transaction binding the contract method 0x52c7157d.
//
// Solidity: function onTimeoutPacket((uint64,string,string,string,string,bytes,(uint64,uint64),uint64) packet, address ) returns()
func (_Ics20transferbank *Ics20transferbankTransactorSession) OnTimeoutPacket(packet Packet, arg1 common.Address) (*types.Transaction, error) {
	return _Ics20transferbank.Contract.OnTimeoutPacket(&_Ics20transferbank.TransactOpts, packet, arg1)
}

// SendTransfer is a paid mutator transaction binding the contract method 0xe0c0705d.
//
// Solidity: function sendTransfer(string denom, uint256 amount, string receiver, string sourcePort, string sourceChannel, uint64 timeoutHeight) returns()
func (_Ics20transferbank *Ics20transferbankTransactor) SendTransfer(opts *bind.TransactOpts, denom string, amount *big.Int, receiver string, sourcePort string, sourceChannel string, timeoutHeight uint64) (*types.Transaction, error) {
	return _Ics20transferbank.contract.Transact(opts, "sendTransfer", denom, amount, receiver, sourcePort, sourceChannel, timeoutHeight)
}

// SendTransfer is a paid mutator transaction binding the contract method 0xe0c0705d.
//
// Solidity: function sendTransfer(string denom, uint256 amount, string receiver, string sourcePort, string sourceChannel, uint64 timeoutHeight) returns()
func (_Ics20transferbank *Ics20transferbankSession) SendTransfer(denom string, amount *big.Int, receiver string, sourcePort string, sourceChannel string, timeoutHeight uint64) (*types.Transaction, error) {
	return _Ics20transferbank.Contract.SendTransfer(&_Ics20transferbank.TransactOpts, denom, amount, receiver, sourcePort, sourceChannel, timeoutHeight)
}

// SendTransfer is a paid mutator transaction binding the contract method 0xe0c0705d.
//
// Solidity: function sendTransfer(string denom, uint256 amount, string receiver, string sourcePort, string sourceChannel, uint64 timeoutHeight) returns()
func (_Ics20transferbank *Ics20transferbankTransactorSession) SendTransfer(denom string, amount *big.Int, receiver string, sourcePort string, sourceChannel string, timeoutHeight uint64) (*types.Transaction, error) {
	return _Ics20transferbank.Contract.SendTransfer(&_Ics20transferbank.TransactOpts, denom, amount, receiver, sourcePort, sourceChannel, timeoutHeight)
}
