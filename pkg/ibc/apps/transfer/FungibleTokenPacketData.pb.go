// Code generated by protoc-gen-gogo. DO NOT EDIT.
// source: apps/20-transfer/FungibleTokenPacketData.proto

package transfer

import (
	fmt "fmt"
	_ "github.com/datachainlab/solidity-protobuf/protobuf-solidity/src/protoc/go"
	proto "github.com/gogo/protobuf/proto"
	io "io"
	math "math"
	math_bits "math/bits"
)

// Reference imports to suppress errors if they are not otherwise used.
var _ = proto.Marshal
var _ = fmt.Errorf
var _ = math.Inf

// This is a compile-time assertion to ensure that this generated file
// is compatible with the proto package it is being compiled against.
// A compilation error at this line likely means your copy of the
// proto package needs to be updated.
const _ = proto.GoGoProtoPackageIsVersion3 // please upgrade the proto package

// FungibleTokenPacketData defines a struct for the packet payload
// See FungibleTokenPacketData spec:
// https://github.com/cosmos/ibc/tree/master/spec/app/ics-020-fungible-token-transfer#data-structures
type FungibleTokenPacketData struct {
	// the token denomination to be transferred
	Denom string `protobuf:"bytes,1,opt,name=denom,proto3" json:"denom,omitempty"`
	// the token amount to be transferred
	Amount uint64 `protobuf:"varint,2,opt,name=amount,proto3" json:"amount,omitempty"`
	// the sender address
	Sender []byte `protobuf:"bytes,3,opt,name=sender,proto3" json:"sender,omitempty"`
	// the recipient address on the destination chain
	Receiver []byte `protobuf:"bytes,4,opt,name=receiver,proto3" json:"receiver,omitempty"`
	// optional memo
	Memo string `protobuf:"bytes,5,opt,name=memo,proto3" json:"memo,omitempty"`
}

func (m *FungibleTokenPacketData) Reset()         { *m = FungibleTokenPacketData{} }
func (m *FungibleTokenPacketData) String() string { return proto.CompactTextString(m) }
func (*FungibleTokenPacketData) ProtoMessage()    {}
func (*FungibleTokenPacketData) Descriptor() ([]byte, []int) {
	return fileDescriptor_8c6ae8b51064ff28, []int{0}
}
func (m *FungibleTokenPacketData) XXX_Unmarshal(b []byte) error {
	return m.Unmarshal(b)
}
func (m *FungibleTokenPacketData) XXX_Marshal(b []byte, deterministic bool) ([]byte, error) {
	if deterministic {
		return xxx_messageInfo_FungibleTokenPacketData.Marshal(b, m, deterministic)
	} else {
		b = b[:cap(b)]
		n, err := m.MarshalToSizedBuffer(b)
		if err != nil {
			return nil, err
		}
		return b[:n], nil
	}
}
func (m *FungibleTokenPacketData) XXX_Merge(src proto.Message) {
	xxx_messageInfo_FungibleTokenPacketData.Merge(m, src)
}
func (m *FungibleTokenPacketData) XXX_Size() int {
	return m.Size()
}
func (m *FungibleTokenPacketData) XXX_DiscardUnknown() {
	xxx_messageInfo_FungibleTokenPacketData.DiscardUnknown(m)
}

var xxx_messageInfo_FungibleTokenPacketData proto.InternalMessageInfo

func (m *FungibleTokenPacketData) GetDenom() string {
	if m != nil {
		return m.Denom
	}
	return ""
}

func (m *FungibleTokenPacketData) GetAmount() uint64 {
	if m != nil {
		return m.Amount
	}
	return 0
}

func (m *FungibleTokenPacketData) GetSender() []byte {
	if m != nil {
		return m.Sender
	}
	return nil
}

func (m *FungibleTokenPacketData) GetReceiver() []byte {
	if m != nil {
		return m.Receiver
	}
	return nil
}

func (m *FungibleTokenPacketData) GetMemo() string {
	if m != nil {
		return m.Memo
	}
	return ""
}

func init() {
	proto.RegisterType((*FungibleTokenPacketData)(nil), "FungibleTokenPacketData")
}

func init() {
	proto.RegisterFile("apps/20-transfer/FungibleTokenPacketData.proto", fileDescriptor_8c6ae8b51064ff28)
}

var fileDescriptor_8c6ae8b51064ff28 = []byte{
	// 292 bytes of a gzipped FileDescriptorProto
	0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0xff, 0x84, 0x90, 0x31, 0x4e, 0xc3, 0x30,
	0x14, 0x86, 0x6b, 0x68, 0x2b, 0xb0, 0x98, 0x22, 0x04, 0x56, 0x07, 0xab, 0xea, 0xd4, 0xc5, 0x35,
	0x2a, 0x1c, 0x00, 0x55, 0x88, 0x19, 0x55, 0x4c, 0x6c, 0xb6, 0xf3, 0x9a, 0x5a, 0x49, 0xec, 0xc8,
	0x76, 0x10, 0x59, 0xb9, 0x00, 0x0c, 0x5c, 0x85, 0x3b, 0x30, 0x76, 0x64, 0x44, 0xc9, 0x45, 0x10,
	0x6e, 0xcb, 0x86, 0xd8, 0xde, 0xf7, 0xde, 0xd3, 0xff, 0xeb, 0xff, 0xf1, 0x4c, 0x54, 0x95, 0xe7,
	0xf3, 0x0b, 0x16, 0x9c, 0x30, 0x7e, 0x05, 0x8e, 0xdf, 0xd6, 0x26, 0xd3, 0xb2, 0x80, 0x7b, 0x9b,
	0x83, 0xb9, 0x13, 0x2a, 0x87, 0x70, 0x23, 0x82, 0x98, 0x55, 0xce, 0x06, 0x3b, 0x9a, 0x78, 0x5b,
	0xe8, 0x54, 0x87, 0x86, 0x45, 0x96, 0xf5, 0x8a, 0xc1, 0x53, 0x00, 0xe3, 0xb5, 0x35, 0x7e, 0xfb,
	0x33, 0x79, 0x41, 0xf8, 0xfc, 0x0f, 0x95, 0xe4, 0x14, 0x0f, 0x52, 0x30, 0xb6, 0x24, 0x68, 0x8c,
	0xa6, 0xc7, 0xcb, 0x2d, 0x24, 0x67, 0x78, 0x28, 0x4a, 0x5b, 0x9b, 0x40, 0x0e, 0xc6, 0x68, 0xda,
	0x5f, 0xee, 0xe8, 0x67, 0xef, 0xc1, 0xa4, 0xe0, 0xc8, 0xe1, 0x18, 0x4d, 0x4f, 0x96, 0x3b, 0x4a,
	0x46, 0xf8, 0xc8, 0x81, 0x02, 0xfd, 0x08, 0x8e, 0xf4, 0xe3, 0xe5, 0x97, 0x93, 0x04, 0xf7, 0x4b,
	0x28, 0x2d, 0x19, 0x44, 0x83, 0x38, 0x2f, 0xde, 0xd0, 0xf3, 0x3b, 0xb9, 0xc2, 0xf3, 0xeb, 0x75,
	0x53, 0x81, 0x2b, 0x20, 0xcd, 0xc0, 0xb1, 0x42, 0x48, 0xcf, 0x9b, 0x5a, 0x33, 0x2d, 0x15, 0xdb,
	0xc7, 0xe2, 0xca, 0x9a, 0xe0, 0x84, 0x0a, 0x9e, 0xc7, 0x30, 0x1f, 0x2d, 0x45, 0x9b, 0x96, 0xa2,
	0xaf, 0x96, 0xa2, 0xd7, 0x8e, 0xf6, 0x36, 0x1d, 0xed, 0x7d, 0x76, 0xb4, 0xf7, 0xb0, 0xc8, 0x74,
	0x58, 0xd7, 0x72, 0xa6, 0x6c, 0xc9, 0xff, 0x57, 0xad, 0xf2, 0x8c, 0x6b, 0xa9, 0x78, 0x6c, 0x7b,
	0x5f, 0xb5, 0x1c, 0x46, 0x8b, 0xcb, 0xef, 0x00, 0x00, 0x00, 0xff, 0xff, 0x78, 0xb6, 0xb4, 0x67,
	0x85, 0x01, 0x00, 0x00,
}

func (m *FungibleTokenPacketData) Marshal() (dAtA []byte, err error) {
	size := m.Size()
	dAtA = make([]byte, size)
	n, err := m.MarshalToSizedBuffer(dAtA[:size])
	if err != nil {
		return nil, err
	}
	return dAtA[:n], nil
}

func (m *FungibleTokenPacketData) MarshalTo(dAtA []byte) (int, error) {
	size := m.Size()
	return m.MarshalToSizedBuffer(dAtA[:size])
}

func (m *FungibleTokenPacketData) MarshalToSizedBuffer(dAtA []byte) (int, error) {
	i := len(dAtA)
	_ = i
	var l int
	_ = l
	if len(m.Memo) > 0 {
		i -= len(m.Memo)
		copy(dAtA[i:], m.Memo)
		i = encodeVarintFungibleTokenPacketData(dAtA, i, uint64(len(m.Memo)))
		i--
		dAtA[i] = 0x2a
	}
	if len(m.Receiver) > 0 {
		i -= len(m.Receiver)
		copy(dAtA[i:], m.Receiver)
		i = encodeVarintFungibleTokenPacketData(dAtA, i, uint64(len(m.Receiver)))
		i--
		dAtA[i] = 0x22
	}
	if len(m.Sender) > 0 {
		i -= len(m.Sender)
		copy(dAtA[i:], m.Sender)
		i = encodeVarintFungibleTokenPacketData(dAtA, i, uint64(len(m.Sender)))
		i--
		dAtA[i] = 0x1a
	}
	if m.Amount != 0 {
		i = encodeVarintFungibleTokenPacketData(dAtA, i, uint64(m.Amount))
		i--
		dAtA[i] = 0x10
	}
	if len(m.Denom) > 0 {
		i -= len(m.Denom)
		copy(dAtA[i:], m.Denom)
		i = encodeVarintFungibleTokenPacketData(dAtA, i, uint64(len(m.Denom)))
		i--
		dAtA[i] = 0xa
	}
	return len(dAtA) - i, nil
}

func encodeVarintFungibleTokenPacketData(dAtA []byte, offset int, v uint64) int {
	offset -= sovFungibleTokenPacketData(v)
	base := offset
	for v >= 1<<7 {
		dAtA[offset] = uint8(v&0x7f | 0x80)
		v >>= 7
		offset++
	}
	dAtA[offset] = uint8(v)
	return base
}
func (m *FungibleTokenPacketData) Size() (n int) {
	if m == nil {
		return 0
	}
	var l int
	_ = l
	l = len(m.Denom)
	if l > 0 {
		n += 1 + l + sovFungibleTokenPacketData(uint64(l))
	}
	if m.Amount != 0 {
		n += 1 + sovFungibleTokenPacketData(uint64(m.Amount))
	}
	l = len(m.Sender)
	if l > 0 {
		n += 1 + l + sovFungibleTokenPacketData(uint64(l))
	}
	l = len(m.Receiver)
	if l > 0 {
		n += 1 + l + sovFungibleTokenPacketData(uint64(l))
	}
	l = len(m.Memo)
	if l > 0 {
		n += 1 + l + sovFungibleTokenPacketData(uint64(l))
	}
	return n
}

func sovFungibleTokenPacketData(x uint64) (n int) {
	return (math_bits.Len64(x|1) + 6) / 7
}
func sozFungibleTokenPacketData(x uint64) (n int) {
	return sovFungibleTokenPacketData(uint64((x << 1) ^ uint64((int64(x) >> 63))))
}
func (m *FungibleTokenPacketData) Unmarshal(dAtA []byte) error {
	l := len(dAtA)
	iNdEx := 0
	for iNdEx < l {
		preIndex := iNdEx
		var wire uint64
		for shift := uint(0); ; shift += 7 {
			if shift >= 64 {
				return ErrIntOverflowFungibleTokenPacketData
			}
			if iNdEx >= l {
				return io.ErrUnexpectedEOF
			}
			b := dAtA[iNdEx]
			iNdEx++
			wire |= uint64(b&0x7F) << shift
			if b < 0x80 {
				break
			}
		}
		fieldNum := int32(wire >> 3)
		wireType := int(wire & 0x7)
		if wireType == 4 {
			return fmt.Errorf("proto: FungibleTokenPacketData: wiretype end group for non-group")
		}
		if fieldNum <= 0 {
			return fmt.Errorf("proto: FungibleTokenPacketData: illegal tag %d (wire type %d)", fieldNum, wire)
		}
		switch fieldNum {
		case 1:
			if wireType != 2 {
				return fmt.Errorf("proto: wrong wireType = %d for field Denom", wireType)
			}
			var stringLen uint64
			for shift := uint(0); ; shift += 7 {
				if shift >= 64 {
					return ErrIntOverflowFungibleTokenPacketData
				}
				if iNdEx >= l {
					return io.ErrUnexpectedEOF
				}
				b := dAtA[iNdEx]
				iNdEx++
				stringLen |= uint64(b&0x7F) << shift
				if b < 0x80 {
					break
				}
			}
			intStringLen := int(stringLen)
			if intStringLen < 0 {
				return ErrInvalidLengthFungibleTokenPacketData
			}
			postIndex := iNdEx + intStringLen
			if postIndex < 0 {
				return ErrInvalidLengthFungibleTokenPacketData
			}
			if postIndex > l {
				return io.ErrUnexpectedEOF
			}
			m.Denom = string(dAtA[iNdEx:postIndex])
			iNdEx = postIndex
		case 2:
			if wireType != 0 {
				return fmt.Errorf("proto: wrong wireType = %d for field Amount", wireType)
			}
			m.Amount = 0
			for shift := uint(0); ; shift += 7 {
				if shift >= 64 {
					return ErrIntOverflowFungibleTokenPacketData
				}
				if iNdEx >= l {
					return io.ErrUnexpectedEOF
				}
				b := dAtA[iNdEx]
				iNdEx++
				m.Amount |= uint64(b&0x7F) << shift
				if b < 0x80 {
					break
				}
			}
		case 3:
			if wireType != 2 {
				return fmt.Errorf("proto: wrong wireType = %d for field Sender", wireType)
			}
			var byteLen int
			for shift := uint(0); ; shift += 7 {
				if shift >= 64 {
					return ErrIntOverflowFungibleTokenPacketData
				}
				if iNdEx >= l {
					return io.ErrUnexpectedEOF
				}
				b := dAtA[iNdEx]
				iNdEx++
				byteLen |= int(b&0x7F) << shift
				if b < 0x80 {
					break
				}
			}
			if byteLen < 0 {
				return ErrInvalidLengthFungibleTokenPacketData
			}
			postIndex := iNdEx + byteLen
			if postIndex < 0 {
				return ErrInvalidLengthFungibleTokenPacketData
			}
			if postIndex > l {
				return io.ErrUnexpectedEOF
			}
			m.Sender = append(m.Sender[:0], dAtA[iNdEx:postIndex]...)
			if m.Sender == nil {
				m.Sender = []byte{}
			}
			iNdEx = postIndex
		case 4:
			if wireType != 2 {
				return fmt.Errorf("proto: wrong wireType = %d for field Receiver", wireType)
			}
			var byteLen int
			for shift := uint(0); ; shift += 7 {
				if shift >= 64 {
					return ErrIntOverflowFungibleTokenPacketData
				}
				if iNdEx >= l {
					return io.ErrUnexpectedEOF
				}
				b := dAtA[iNdEx]
				iNdEx++
				byteLen |= int(b&0x7F) << shift
				if b < 0x80 {
					break
				}
			}
			if byteLen < 0 {
				return ErrInvalidLengthFungibleTokenPacketData
			}
			postIndex := iNdEx + byteLen
			if postIndex < 0 {
				return ErrInvalidLengthFungibleTokenPacketData
			}
			if postIndex > l {
				return io.ErrUnexpectedEOF
			}
			m.Receiver = append(m.Receiver[:0], dAtA[iNdEx:postIndex]...)
			if m.Receiver == nil {
				m.Receiver = []byte{}
			}
			iNdEx = postIndex
		case 5:
			if wireType != 2 {
				return fmt.Errorf("proto: wrong wireType = %d for field Memo", wireType)
			}
			var stringLen uint64
			for shift := uint(0); ; shift += 7 {
				if shift >= 64 {
					return ErrIntOverflowFungibleTokenPacketData
				}
				if iNdEx >= l {
					return io.ErrUnexpectedEOF
				}
				b := dAtA[iNdEx]
				iNdEx++
				stringLen |= uint64(b&0x7F) << shift
				if b < 0x80 {
					break
				}
			}
			intStringLen := int(stringLen)
			if intStringLen < 0 {
				return ErrInvalidLengthFungibleTokenPacketData
			}
			postIndex := iNdEx + intStringLen
			if postIndex < 0 {
				return ErrInvalidLengthFungibleTokenPacketData
			}
			if postIndex > l {
				return io.ErrUnexpectedEOF
			}
			m.Memo = string(dAtA[iNdEx:postIndex])
			iNdEx = postIndex
		default:
			iNdEx = preIndex
			skippy, err := skipFungibleTokenPacketData(dAtA[iNdEx:])
			if err != nil {
				return err
			}
			if (skippy < 0) || (iNdEx+skippy) < 0 {
				return ErrInvalidLengthFungibleTokenPacketData
			}
			if (iNdEx + skippy) > l {
				return io.ErrUnexpectedEOF
			}
			iNdEx += skippy
		}
	}

	if iNdEx > l {
		return io.ErrUnexpectedEOF
	}
	return nil
}
func skipFungibleTokenPacketData(dAtA []byte) (n int, err error) {
	l := len(dAtA)
	iNdEx := 0
	depth := 0
	for iNdEx < l {
		var wire uint64
		for shift := uint(0); ; shift += 7 {
			if shift >= 64 {
				return 0, ErrIntOverflowFungibleTokenPacketData
			}
			if iNdEx >= l {
				return 0, io.ErrUnexpectedEOF
			}
			b := dAtA[iNdEx]
			iNdEx++
			wire |= (uint64(b) & 0x7F) << shift
			if b < 0x80 {
				break
			}
		}
		wireType := int(wire & 0x7)
		switch wireType {
		case 0:
			for shift := uint(0); ; shift += 7 {
				if shift >= 64 {
					return 0, ErrIntOverflowFungibleTokenPacketData
				}
				if iNdEx >= l {
					return 0, io.ErrUnexpectedEOF
				}
				iNdEx++
				if dAtA[iNdEx-1] < 0x80 {
					break
				}
			}
		case 1:
			iNdEx += 8
		case 2:
			var length int
			for shift := uint(0); ; shift += 7 {
				if shift >= 64 {
					return 0, ErrIntOverflowFungibleTokenPacketData
				}
				if iNdEx >= l {
					return 0, io.ErrUnexpectedEOF
				}
				b := dAtA[iNdEx]
				iNdEx++
				length |= (int(b) & 0x7F) << shift
				if b < 0x80 {
					break
				}
			}
			if length < 0 {
				return 0, ErrInvalidLengthFungibleTokenPacketData
			}
			iNdEx += length
		case 3:
			depth++
		case 4:
			if depth == 0 {
				return 0, ErrUnexpectedEndOfGroupFungibleTokenPacketData
			}
			depth--
		case 5:
			iNdEx += 4
		default:
			return 0, fmt.Errorf("proto: illegal wireType %d", wireType)
		}
		if iNdEx < 0 {
			return 0, ErrInvalidLengthFungibleTokenPacketData
		}
		if depth == 0 {
			return iNdEx, nil
		}
	}
	return 0, io.ErrUnexpectedEOF
}

var (
	ErrInvalidLengthFungibleTokenPacketData        = fmt.Errorf("proto: negative length found during unmarshaling")
	ErrIntOverflowFungibleTokenPacketData          = fmt.Errorf("proto: integer overflow")
	ErrUnexpectedEndOfGroupFungibleTokenPacketData = fmt.Errorf("proto: unexpected end of group")
)
