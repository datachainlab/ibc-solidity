// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "./ICS20Transfer.sol";
import "./IICS20Bank.sol";
import "../../core/25-handler/IBCHandler.sol";

contract ICS20TransferBank is ICS20Transfer {
    using strings for *;

    IBCHandler private ibcHandler;
    IICS20Bank private bank;

    constructor(IBCHandler ibcHandler_, IICS20Bank bank_) {
        ibcHandler = ibcHandler_;
        bank = bank_;
    }

    function sendTransfer(
        string calldata denom,
        uint64 amount,
        address receiver,
        string calldata sourcePort,
        string calldata sourceChannel,
        uint64 timeoutHeight,
        string calldata memo
    ) external {
        _sendTransfer(denom, amount, receiver, sourcePort, sourceChannel, timeoutHeight, memo);
    }

    function sendTransfer(
        string calldata denom,
        uint64 amount,
        address receiver,
        string calldata sourcePort,
        string calldata sourceChannel,
        uint64 timeoutHeight
    ) external {
        _sendTransfer(denom, amount, receiver, sourcePort, sourceChannel, timeoutHeight, "");
    }

    function _sendTransfer(
        string calldata denom,
        uint64 amount,
        address receiver,
        string calldata sourcePort,
        string calldata sourceChannel,
        uint64 timeoutHeight,
        string memory memo
    ) private {
        if (!denom.toSlice().startsWith(_makeDenomPrefix(sourcePort, sourceChannel))) {
            // sender is source chain
            require(_transferFrom(_msgSender(), _getEscrowAddress(sourceChannel), denom, amount));
        } else {
            require(_burn(_msgSender(), denom, amount));
        }

        _sendPacket(
            FungibleTokenPacketData.Data({
                denom: denom,
                amount: amount,
                sender: abi.encodePacked(_msgSender()),
                receiver: abi.encodePacked(receiver),
                memo : memo
            }),
            sourcePort,
            sourceChannel,
            timeoutHeight
        );
    }

    function _transferFrom(address sender, address receiver, string memory denom, uint256 amount)
        internal
        override
        returns (bool)
    {
        try bank.transferFrom(sender, receiver, denom, amount) {
            return true;
        } catch (bytes memory) {
            return false;
        }
    }

    function _mint(address account, string memory denom, uint256 amount) internal override returns (bool) {
        try bank.mint(account, denom, amount) {
            return true;
        } catch (bytes memory) {
            return false;
        }
    }

    function _burn(address account, string memory denom, uint256 amount) internal override returns (bool) {
        try bank.burn(account, denom, amount) {
            return true;
        } catch (bytes memory) {
            return false;
        }
    }

    function ibcAddress() public view virtual override returns (address) {
        return address(ibcHandler);
    }
}
