// Code generated by protoc-gen-gogo. DO NOT EDIT.
// source: client/mock/MockClient.proto

package mock

import (
	fmt "fmt"
	_ "github.com/datachainlab/solidity-protobuf/protobuf-solidity/src/protoc/go"
	proto "github.com/gogo/protobuf/proto"
	client "github.com/hyperledger-labs/yui-ibc-solidity/pkg/ibc/client"
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

type ClientState struct {
	LatestHeight *client.Height `protobuf:"bytes,1,opt,name=latest_height,json=latestHeight,proto3" json:"latest_height,omitempty"`
}

func (m *ClientState) Reset()         { *m = ClientState{} }
func (m *ClientState) String() string { return proto.CompactTextString(m) }
func (*ClientState) ProtoMessage()    {}
func (*ClientState) Descriptor() ([]byte, []int) {
	return fileDescriptor_aa8d7a2e1ed6d381, []int{0}
}
func (m *ClientState) XXX_Unmarshal(b []byte) error {
	return m.Unmarshal(b)
}
func (m *ClientState) XXX_Marshal(b []byte, deterministic bool) ([]byte, error) {
	if deterministic {
		return xxx_messageInfo_ClientState.Marshal(b, m, deterministic)
	} else {
		b = b[:cap(b)]
		n, err := m.MarshalToSizedBuffer(b)
		if err != nil {
			return nil, err
		}
		return b[:n], nil
	}
}
func (m *ClientState) XXX_Merge(src proto.Message) {
	xxx_messageInfo_ClientState.Merge(m, src)
}
func (m *ClientState) XXX_Size() int {
	return m.Size()
}
func (m *ClientState) XXX_DiscardUnknown() {
	xxx_messageInfo_ClientState.DiscardUnknown(m)
}

var xxx_messageInfo_ClientState proto.InternalMessageInfo

func (m *ClientState) GetLatestHeight() *client.Height {
	if m != nil {
		return m.LatestHeight
	}
	return nil
}

type ConsensusState struct {
	Timestamp uint64 `protobuf:"varint,1,opt,name=timestamp,proto3" json:"timestamp,omitempty"`
}

func (m *ConsensusState) Reset()         { *m = ConsensusState{} }
func (m *ConsensusState) String() string { return proto.CompactTextString(m) }
func (*ConsensusState) ProtoMessage()    {}
func (*ConsensusState) Descriptor() ([]byte, []int) {
	return fileDescriptor_aa8d7a2e1ed6d381, []int{1}
}
func (m *ConsensusState) XXX_Unmarshal(b []byte) error {
	return m.Unmarshal(b)
}
func (m *ConsensusState) XXX_Marshal(b []byte, deterministic bool) ([]byte, error) {
	if deterministic {
		return xxx_messageInfo_ConsensusState.Marshal(b, m, deterministic)
	} else {
		b = b[:cap(b)]
		n, err := m.MarshalToSizedBuffer(b)
		if err != nil {
			return nil, err
		}
		return b[:n], nil
	}
}
func (m *ConsensusState) XXX_Merge(src proto.Message) {
	xxx_messageInfo_ConsensusState.Merge(m, src)
}
func (m *ConsensusState) XXX_Size() int {
	return m.Size()
}
func (m *ConsensusState) XXX_DiscardUnknown() {
	xxx_messageInfo_ConsensusState.DiscardUnknown(m)
}

var xxx_messageInfo_ConsensusState proto.InternalMessageInfo

func (m *ConsensusState) GetTimestamp() uint64 {
	if m != nil {
		return m.Timestamp
	}
	return 0
}

type Header struct {
	Height    *client.Height `protobuf:"bytes,1,opt,name=height,proto3" json:"height,omitempty"`
	Timestamp uint64         `protobuf:"varint,2,opt,name=timestamp,proto3" json:"timestamp,omitempty"`
}

func (m *Header) Reset()         { *m = Header{} }
func (m *Header) String() string { return proto.CompactTextString(m) }
func (*Header) ProtoMessage()    {}
func (*Header) Descriptor() ([]byte, []int) {
	return fileDescriptor_aa8d7a2e1ed6d381, []int{2}
}
func (m *Header) XXX_Unmarshal(b []byte) error {
	return m.Unmarshal(b)
}
func (m *Header) XXX_Marshal(b []byte, deterministic bool) ([]byte, error) {
	if deterministic {
		return xxx_messageInfo_Header.Marshal(b, m, deterministic)
	} else {
		b = b[:cap(b)]
		n, err := m.MarshalToSizedBuffer(b)
		if err != nil {
			return nil, err
		}
		return b[:n], nil
	}
}
func (m *Header) XXX_Merge(src proto.Message) {
	xxx_messageInfo_Header.Merge(m, src)
}
func (m *Header) XXX_Size() int {
	return m.Size()
}
func (m *Header) XXX_DiscardUnknown() {
	xxx_messageInfo_Header.DiscardUnknown(m)
}

var xxx_messageInfo_Header proto.InternalMessageInfo

func (m *Header) GetHeight() *client.Height {
	if m != nil {
		return m.Height
	}
	return nil
}

func (m *Header) GetTimestamp() uint64 {
	if m != nil {
		return m.Timestamp
	}
	return 0
}

func init() {
	proto.RegisterType((*ClientState)(nil), "ibc.lightclients.mock.v1.ClientState")
	proto.RegisterType((*ConsensusState)(nil), "ibc.lightclients.mock.v1.ConsensusState")
	proto.RegisterType((*Header)(nil), "ibc.lightclients.mock.v1.Header")
}

func init() { proto.RegisterFile("client/mock/MockClient.proto", fileDescriptor_aa8d7a2e1ed6d381) }

var fileDescriptor_aa8d7a2e1ed6d381 = []byte{
	// 315 bytes of a gzipped FileDescriptorProto
	0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0xff, 0x84, 0x91, 0xb1, 0x4e, 0xf3, 0x30,
	0x10, 0xc7, 0x9b, 0x4f, 0x9f, 0x8a, 0x70, 0x81, 0xa1, 0x2c, 0x55, 0x55, 0x05, 0x94, 0x89, 0x81,
	0xd8, 0x02, 0x06, 0x84, 0x58, 0x2a, 0x3a, 0xd0, 0x85, 0xa5, 0x6c, 0x2c, 0x28, 0x76, 0x8f, 0xc4,
	0x6a, 0x12, 0x47, 0xbe, 0x0b, 0x22, 0x2b, 0x4f, 0xc0, 0xc6, 0x93, 0xf0, 0x0e, 0x8c, 0x1d, 0x19,
	0x51, 0xf3, 0x22, 0xa8, 0x71, 0x11, 0x05, 0x21, 0x31, 0xfe, 0xce, 0xff, 0xff, 0xef, 0xa4, 0x33,
	0x1b, 0xa8, 0x54, 0x43, 0x4e, 0x22, 0x33, 0x6a, 0x26, 0xae, 0x8c, 0x9a, 0x8d, 0x1a, 0xe6, 0x85,
	0x35, 0x64, 0xba, 0x3d, 0x2d, 0x15, 0x4f, 0x75, 0x9c, 0x90, 0x8b, 0x21, 0x5f, 0xe6, 0xf8, 0xfd,
	0x51, 0x3f, 0x40, 0x93, 0xea, 0xa9, 0xa6, 0x2a, 0x6c, 0x92, 0xb2, 0xbc, 0x0b, 0xe1, 0x81, 0x20,
	0x47, 0x6d, 0x72, 0x74, 0xed, 0xfe, 0xee, 0xca, 0xbd, 0xae, 0x0c, 0xce, 0x59, 0xc7, 0xf1, 0x35,
	0x45, 0x04, 0xdd, 0x43, 0xb6, 0x9d, 0x46, 0x04, 0x48, 0xb7, 0x09, 0x2c, 0xf7, 0xf4, 0xbc, 0x7d,
	0xef, 0xa0, 0x73, 0xbc, 0xc1, 0xc7, 0x0d, 0x4e, 0xb6, 0xdc, 0xab, 0xa3, 0x80, 0xb3, 0x9d, 0x91,
	0xc9, 0x11, 0x72, 0x2c, 0xd1, 0xf5, 0x07, 0x6c, 0x93, 0x74, 0x06, 0x48, 0x51, 0x56, 0x34, 0xdd,
	0xff, 0x93, 0xaf, 0x41, 0x70, 0xc9, 0xda, 0x63, 0x88, 0xa6, 0x60, 0xbb, 0x7b, 0xac, 0xfd, 0xfb,
	0x82, 0xd5, 0xf8, 0xbb, 0xe8, 0xdf, 0x0f, 0xd1, 0xc5, 0xb3, 0xf7, 0xf8, 0xd2, 0x3b, 0x63, 0xa7,
	0xc3, 0xa4, 0x2a, 0xc0, 0xa6, 0x30, 0x8d, 0xc1, 0x86, 0x69, 0x24, 0x51, 0x54, 0xa5, 0x0e, 0xb5,
	0x54, 0xe1, 0xe7, 0x3d, 0x84, 0x32, 0x39, 0xd9, 0x48, 0x11, 0x0a, 0x65, 0x2c, 0x08, 0xaa, 0x0a,
	0xc0, 0xd7, 0x85, 0xef, 0xcd, 0x17, 0xbe, 0xf7, 0xbe, 0xf0, 0xbd, 0xa7, 0xda, 0x6f, 0xcd, 0x6b,
	0xbf, 0xf5, 0x56, 0xfb, 0xad, 0x9b, 0x61, 0xac, 0x29, 0x29, 0x25, 0x57, 0x26, 0x13, 0x7f, 0xab,
	0x8b, 0x59, 0x2c, 0xb4, 0x54, 0x62, 0xed, 0xcf, 0x64, 0xbb, 0x39, 0xeb, 0xc9, 0x47, 0x00, 0x00,
	0x00, 0xff, 0xff, 0x98, 0x06, 0x79, 0x4f, 0xc9, 0x01, 0x00, 0x00,
}

func (m *ClientState) Marshal() (dAtA []byte, err error) {
	size := m.Size()
	dAtA = make([]byte, size)
	n, err := m.MarshalToSizedBuffer(dAtA[:size])
	if err != nil {
		return nil, err
	}
	return dAtA[:n], nil
}

func (m *ClientState) MarshalTo(dAtA []byte) (int, error) {
	size := m.Size()
	return m.MarshalToSizedBuffer(dAtA[:size])
}

func (m *ClientState) MarshalToSizedBuffer(dAtA []byte) (int, error) {
	i := len(dAtA)
	_ = i
	var l int
	_ = l
	if m.LatestHeight != nil {
		{
			size, err := m.LatestHeight.MarshalToSizedBuffer(dAtA[:i])
			if err != nil {
				return 0, err
			}
			i -= size
			i = encodeVarintMockClient(dAtA, i, uint64(size))
		}
		i--
		dAtA[i] = 0xa
	}
	return len(dAtA) - i, nil
}

func (m *ConsensusState) Marshal() (dAtA []byte, err error) {
	size := m.Size()
	dAtA = make([]byte, size)
	n, err := m.MarshalToSizedBuffer(dAtA[:size])
	if err != nil {
		return nil, err
	}
	return dAtA[:n], nil
}

func (m *ConsensusState) MarshalTo(dAtA []byte) (int, error) {
	size := m.Size()
	return m.MarshalToSizedBuffer(dAtA[:size])
}

func (m *ConsensusState) MarshalToSizedBuffer(dAtA []byte) (int, error) {
	i := len(dAtA)
	_ = i
	var l int
	_ = l
	if m.Timestamp != 0 {
		i = encodeVarintMockClient(dAtA, i, uint64(m.Timestamp))
		i--
		dAtA[i] = 0x8
	}
	return len(dAtA) - i, nil
}

func (m *Header) Marshal() (dAtA []byte, err error) {
	size := m.Size()
	dAtA = make([]byte, size)
	n, err := m.MarshalToSizedBuffer(dAtA[:size])
	if err != nil {
		return nil, err
	}
	return dAtA[:n], nil
}

func (m *Header) MarshalTo(dAtA []byte) (int, error) {
	size := m.Size()
	return m.MarshalToSizedBuffer(dAtA[:size])
}

func (m *Header) MarshalToSizedBuffer(dAtA []byte) (int, error) {
	i := len(dAtA)
	_ = i
	var l int
	_ = l
	if m.Timestamp != 0 {
		i = encodeVarintMockClient(dAtA, i, uint64(m.Timestamp))
		i--
		dAtA[i] = 0x10
	}
	if m.Height != nil {
		{
			size, err := m.Height.MarshalToSizedBuffer(dAtA[:i])
			if err != nil {
				return 0, err
			}
			i -= size
			i = encodeVarintMockClient(dAtA, i, uint64(size))
		}
		i--
		dAtA[i] = 0xa
	}
	return len(dAtA) - i, nil
}

func encodeVarintMockClient(dAtA []byte, offset int, v uint64) int {
	offset -= sovMockClient(v)
	base := offset
	for v >= 1<<7 {
		dAtA[offset] = uint8(v&0x7f | 0x80)
		v >>= 7
		offset++
	}
	dAtA[offset] = uint8(v)
	return base
}
func (m *ClientState) Size() (n int) {
	if m == nil {
		return 0
	}
	var l int
	_ = l
	if m.LatestHeight != nil {
		l = m.LatestHeight.Size()
		n += 1 + l + sovMockClient(uint64(l))
	}
	return n
}

func (m *ConsensusState) Size() (n int) {
	if m == nil {
		return 0
	}
	var l int
	_ = l
	if m.Timestamp != 0 {
		n += 1 + sovMockClient(uint64(m.Timestamp))
	}
	return n
}

func (m *Header) Size() (n int) {
	if m == nil {
		return 0
	}
	var l int
	_ = l
	if m.Height != nil {
		l = m.Height.Size()
		n += 1 + l + sovMockClient(uint64(l))
	}
	if m.Timestamp != 0 {
		n += 1 + sovMockClient(uint64(m.Timestamp))
	}
	return n
}

func sovMockClient(x uint64) (n int) {
	return (math_bits.Len64(x|1) + 6) / 7
}
func sozMockClient(x uint64) (n int) {
	return sovMockClient(uint64((x << 1) ^ uint64((int64(x) >> 63))))
}
func (m *ClientState) Unmarshal(dAtA []byte) error {
	l := len(dAtA)
	iNdEx := 0
	for iNdEx < l {
		preIndex := iNdEx
		var wire uint64
		for shift := uint(0); ; shift += 7 {
			if shift >= 64 {
				return ErrIntOverflowMockClient
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
			return fmt.Errorf("proto: ClientState: wiretype end group for non-group")
		}
		if fieldNum <= 0 {
			return fmt.Errorf("proto: ClientState: illegal tag %d (wire type %d)", fieldNum, wire)
		}
		switch fieldNum {
		case 1:
			if wireType != 2 {
				return fmt.Errorf("proto: wrong wireType = %d for field LatestHeight", wireType)
			}
			var msglen int
			for shift := uint(0); ; shift += 7 {
				if shift >= 64 {
					return ErrIntOverflowMockClient
				}
				if iNdEx >= l {
					return io.ErrUnexpectedEOF
				}
				b := dAtA[iNdEx]
				iNdEx++
				msglen |= int(b&0x7F) << shift
				if b < 0x80 {
					break
				}
			}
			if msglen < 0 {
				return ErrInvalidLengthMockClient
			}
			postIndex := iNdEx + msglen
			if postIndex < 0 {
				return ErrInvalidLengthMockClient
			}
			if postIndex > l {
				return io.ErrUnexpectedEOF
			}
			if m.LatestHeight == nil {
				m.LatestHeight = &client.Height{}
			}
			if err := m.LatestHeight.Unmarshal(dAtA[iNdEx:postIndex]); err != nil {
				return err
			}
			iNdEx = postIndex
		default:
			iNdEx = preIndex
			skippy, err := skipMockClient(dAtA[iNdEx:])
			if err != nil {
				return err
			}
			if (skippy < 0) || (iNdEx+skippy) < 0 {
				return ErrInvalidLengthMockClient
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
func (m *ConsensusState) Unmarshal(dAtA []byte) error {
	l := len(dAtA)
	iNdEx := 0
	for iNdEx < l {
		preIndex := iNdEx
		var wire uint64
		for shift := uint(0); ; shift += 7 {
			if shift >= 64 {
				return ErrIntOverflowMockClient
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
			return fmt.Errorf("proto: ConsensusState: wiretype end group for non-group")
		}
		if fieldNum <= 0 {
			return fmt.Errorf("proto: ConsensusState: illegal tag %d (wire type %d)", fieldNum, wire)
		}
		switch fieldNum {
		case 1:
			if wireType != 0 {
				return fmt.Errorf("proto: wrong wireType = %d for field Timestamp", wireType)
			}
			m.Timestamp = 0
			for shift := uint(0); ; shift += 7 {
				if shift >= 64 {
					return ErrIntOverflowMockClient
				}
				if iNdEx >= l {
					return io.ErrUnexpectedEOF
				}
				b := dAtA[iNdEx]
				iNdEx++
				m.Timestamp |= uint64(b&0x7F) << shift
				if b < 0x80 {
					break
				}
			}
		default:
			iNdEx = preIndex
			skippy, err := skipMockClient(dAtA[iNdEx:])
			if err != nil {
				return err
			}
			if (skippy < 0) || (iNdEx+skippy) < 0 {
				return ErrInvalidLengthMockClient
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
func (m *Header) Unmarshal(dAtA []byte) error {
	l := len(dAtA)
	iNdEx := 0
	for iNdEx < l {
		preIndex := iNdEx
		var wire uint64
		for shift := uint(0); ; shift += 7 {
			if shift >= 64 {
				return ErrIntOverflowMockClient
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
			return fmt.Errorf("proto: Header: wiretype end group for non-group")
		}
		if fieldNum <= 0 {
			return fmt.Errorf("proto: Header: illegal tag %d (wire type %d)", fieldNum, wire)
		}
		switch fieldNum {
		case 1:
			if wireType != 2 {
				return fmt.Errorf("proto: wrong wireType = %d for field Height", wireType)
			}
			var msglen int
			for shift := uint(0); ; shift += 7 {
				if shift >= 64 {
					return ErrIntOverflowMockClient
				}
				if iNdEx >= l {
					return io.ErrUnexpectedEOF
				}
				b := dAtA[iNdEx]
				iNdEx++
				msglen |= int(b&0x7F) << shift
				if b < 0x80 {
					break
				}
			}
			if msglen < 0 {
				return ErrInvalidLengthMockClient
			}
			postIndex := iNdEx + msglen
			if postIndex < 0 {
				return ErrInvalidLengthMockClient
			}
			if postIndex > l {
				return io.ErrUnexpectedEOF
			}
			if m.Height == nil {
				m.Height = &client.Height{}
			}
			if err := m.Height.Unmarshal(dAtA[iNdEx:postIndex]); err != nil {
				return err
			}
			iNdEx = postIndex
		case 2:
			if wireType != 0 {
				return fmt.Errorf("proto: wrong wireType = %d for field Timestamp", wireType)
			}
			m.Timestamp = 0
			for shift := uint(0); ; shift += 7 {
				if shift >= 64 {
					return ErrIntOverflowMockClient
				}
				if iNdEx >= l {
					return io.ErrUnexpectedEOF
				}
				b := dAtA[iNdEx]
				iNdEx++
				m.Timestamp |= uint64(b&0x7F) << shift
				if b < 0x80 {
					break
				}
			}
		default:
			iNdEx = preIndex
			skippy, err := skipMockClient(dAtA[iNdEx:])
			if err != nil {
				return err
			}
			if (skippy < 0) || (iNdEx+skippy) < 0 {
				return ErrInvalidLengthMockClient
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
func skipMockClient(dAtA []byte) (n int, err error) {
	l := len(dAtA)
	iNdEx := 0
	depth := 0
	for iNdEx < l {
		var wire uint64
		for shift := uint(0); ; shift += 7 {
			if shift >= 64 {
				return 0, ErrIntOverflowMockClient
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
					return 0, ErrIntOverflowMockClient
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
					return 0, ErrIntOverflowMockClient
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
				return 0, ErrInvalidLengthMockClient
			}
			iNdEx += length
		case 3:
			depth++
		case 4:
			if depth == 0 {
				return 0, ErrUnexpectedEndOfGroupMockClient
			}
			depth--
		case 5:
			iNdEx += 4
		default:
			return 0, fmt.Errorf("proto: illegal wireType %d", wireType)
		}
		if iNdEx < 0 {
			return 0, ErrInvalidLengthMockClient
		}
		if depth == 0 {
			return iNdEx, nil
		}
	}
	return 0, io.ErrUnexpectedEOF
}

var (
	ErrInvalidLengthMockClient        = fmt.Errorf("proto: negative length found during unmarshaling")
	ErrIntOverflowMockClient          = fmt.Errorf("proto: integer overflow")
	ErrUnexpectedEndOfGroupMockClient = fmt.Errorf("proto: unexpected end of group")
)
