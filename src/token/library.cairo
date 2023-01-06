%lang starknet

from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_block_timestamp,
    get_contract_address,
)
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_le
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_check,
    uint256_eq,
    uint256_not,
    uint256_add,
    uint256_lt,
)

from openzeppelin.security.safemath.library import SafeUint256
from openzeppelin.utils.constants.library import UINT8_MAX

from src.structs.FlowStruct import inflow, outflow

//
// Events
//

@event
func Transfer(from_: felt, to: felt, value: Uint256) {
}

@event
func Approval(owner: felt, spender: felt, value: Uint256) {
}

//
// Storage
//

@storage_var
func ERC20_name() -> (name: felt) {
}

@storage_var
func ERC20_symbol() -> (symbol: felt) {
}

@storage_var
func ERC20_decimals() -> (decimals: felt) {
}

@storage_var
func ERC20_total_supply() -> (total_supply: Uint256) {
}

@storage_var
func ERC20_balances(account: felt) -> (balance: Uint256) {
}

@storage_var
func ERC20_realtime_balances(account: felt) -> (balance: Uint256) {
}

@storage_var
func ERC20_allowances(owner: felt, spender: felt) -> (remaining: Uint256) {
}

@storage_var
func inflow_len_by_addr(recipient: felt) -> (res: felt) {
}

@storage_var
func inflow_info_by_addr(recipient: felt, index: felt) -> (res: inflow) {
}

@storage_var
func outflow_len_by_addr(sender: felt) -> (res: felt) {
}

@storage_var
func outflow_info_by_addr(sender: felt, index: felt) -> (res: outflow) {
}

namespace SuperERC20 {
    //
    // Initializer
    //

    func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        name: felt, symbol: felt, decimals: felt
    ) {
        ERC20_name.write(name);
        ERC20_symbol.write(symbol);
        with_attr error_message("ERC20: decimals exceed 2^8") {
            assert_le(decimals, UINT8_MAX);
        }
        ERC20_decimals.write(decimals);
        return ();
    }

    //
    // Public functions
    //

    func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
        return ERC20_name.read();
    }

    func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        symbol: felt
    ) {
        return ERC20_symbol.read();
    }

    func total_supply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        total_supply: Uint256
    ) {
        return ERC20_total_supply.read();
    }

    func decimals{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        decimals: felt
    ) {
        return ERC20_decimals.read();
    }

    func balance_of{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        account: felt
    ) -> (balance: Uint256) {
        let realtime_balance: Uint256 = realtime_balance_of(account);
        let _balance: Uint256 = ERC20_balances.read(account);
        let total_balance: Uint256 = SafeUint256.add(_balance, realtime_balance);
        return (total_balance,);
    }

    func realtime_balance_of{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        account: felt
    ) -> (balance: Uint256) {
        let (stream_len) = inflow_len_by_addr.read(account);
        let realtime_balance: Uint256 = _realtime_balance_of(account, stream_len, Uint256(0, 0));
        return (realtime_balance,);
    }

    func get_inflow_length{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        account: felt
    ) -> (res: felt) {
        let (len) = inflow_len_by_addr.read(account);
        return (res=len);
    }

    func get_outflow_length{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        account: felt
    ) -> (res: felt) {
        let (len) = outflow_len_by_addr.read(account);
        return (res=len);
    }

    func get_inflow_info{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        account: felt, id: felt
    ) -> (res: inflow) {
        let (_inflow) = inflow_info_by_addr.read(account, id);
        return (res=_inflow);
    }

    func get_outflow_info{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        account: felt, id: felt
    ) -> (res: outflow) {
        let (_outflow) = outflow_info_by_addr.read(account, id);
        return (res=_outflow);
    }

    func allowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        owner: felt, spender: felt
    ) -> (remaining: Uint256) {
        return ERC20_allowances.read(owner, spender);
    }

    func transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        recipient: felt, amount: Uint256
    ) -> (success: felt) {
        let (sender) = get_caller_address();
        _transfer(sender, recipient, amount);
        return (success=TRUE);
    }

    func transfer_from{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        sender: felt, recipient: felt, amount: Uint256
    ) -> (success: felt) {
        let (caller) = get_caller_address();
        _spend_allowance(sender, caller, amount);
        _transfer(sender, recipient, amount);
        return (success=TRUE);
    }

    func approve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        spender: felt, amount: Uint256
    ) -> (success: felt) {
        with_attr error_message("ERC20: amount is not a valid Uint256") {
            uint256_check(amount);
        }

        let (caller) = get_caller_address();
        _approve(caller, spender, amount);
        return (success=TRUE);
    }

    func increase_allowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        spender: felt, added_value: Uint256
    ) -> (success: felt) {
        with_attr error("ERC20: added_value is not a valid Uint256") {
            uint256_check(added_value);
        }

        let (caller) = get_caller_address();
        let (current_allowance: Uint256) = ERC20_allowances.read(caller, spender);

        // add allowance
        with_attr error_message("ERC20: allowance overflow") {
            let (new_allowance: Uint256) = SafeUint256.add(current_allowance, added_value);
        }

        _approve(caller, spender, new_allowance);
        return (success=TRUE);
    }

    func decrease_allowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        spender: felt, subtracted_value: Uint256
    ) -> (success: felt) {
        alloc_locals;
        with_attr error_message("ERC20: subtracted_value is not a valid Uint256") {
            uint256_check(subtracted_value);
        }

        let (caller) = get_caller_address();
        let (current_allowance: Uint256) = ERC20_allowances.read(owner=caller, spender=spender);

        with_attr error_message("ERC20: allowance below zero") {
            let (new_allowance: Uint256) = SafeUint256.sub_le(current_allowance, subtracted_value);
        }

        _approve(caller, spender, new_allowance);
        return (success=TRUE);
    }

    //
    // Internal
    //

    func _mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        recipient: felt, amount: Uint256
    ) {
        with_attr error_message("ERC20: amount is not a valid Uint256") {
            uint256_check(amount);
        }

        with_attr error_message("ERC20: cannot mint to the zero address") {
            assert_not_zero(recipient);
        }

        let (supply: Uint256) = ERC20_total_supply.read();
        with_attr error_message("ERC20: mint overflow") {
            let (new_supply: Uint256) = SafeUint256.add(supply, amount);
        }
        ERC20_total_supply.write(new_supply);
        _update_balance();
        let (balance: Uint256) = ERC20_balances.read(account=recipient);
        // overflow is not possible because sum is guaranteed to be less than total supply
        // which we check for overflow below
        let (new_balance: Uint256) = SafeUint256.add(balance, amount);
        ERC20_balances.write(recipient, new_balance);

        Transfer.emit(0, recipient, amount);
        return ();
    }

    func _transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        sender: felt, recipient: felt, amount: Uint256
    ) {
        with_attr error_message("ERC20: amount is not a valid Uint256") {
            uint256_check(amount);  // almost surely not needed, might remove after confirmation
        }

        with_attr error_message("ERC20: cannot transfer from the zero address") {
            assert_not_zero(sender);
        }

        with_attr error_message("ERC20: cannot transfer to the zero address") {
            assert_not_zero(recipient);
        }
        _update_balance();
        let sender_balance: Uint256 = ERC20_balances.read(sender);
        with_attr error_message("ERC20: transfer amount exceeds balance") {
            let (new_sender_balance: Uint256) = SafeUint256.sub_le(sender_balance, amount);
        }

        ERC20_balances.write(sender, new_sender_balance);

        // add to recipient
        let (recipient_balance: Uint256) = ERC20_balances.read(account=recipient);
        // overflow is not possible because sum is guaranteed by mint to be less than total supply
        let (new_recipient_balance: Uint256) = SafeUint256.add(recipient_balance, amount);
        ERC20_balances.write(recipient, new_recipient_balance);
        Transfer.emit(sender, recipient, amount);
        return ();
    }

    func _approve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        owner: felt, spender: felt, amount: Uint256
    ) {
        with_attr error_message("ERC20: amount is not a valid Uint256") {
            uint256_check(amount);
        }

        with_attr error_message("ERC20: cannot approve from the zero address") {
            assert_not_zero(owner);
        }

        with_attr error_message("ERC20: cannot approve to the zero address") {
            assert_not_zero(spender);
        }
        _update_balance();
        ERC20_allowances.write(owner, spender, amount);
        Approval.emit(owner, spender, amount);
        return ();
    }

    func _spend_allowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        owner: felt, spender: felt, amount: Uint256
    ) {
        alloc_locals;
        with_attr error_message("ERC20: amount is not a valid Uint256") {
            uint256_check(amount);  // almost surely not needed, might remove after confirmation
        }

        let (current_allowance: Uint256) = ERC20_allowances.read(owner, spender);
        let (infinite: Uint256) = uint256_not(Uint256(0, 0));
        let (is_infinite: felt) = uint256_eq(current_allowance, infinite);

        if (is_infinite == FALSE) {
            with_attr error_message("ERC20: insufficient allowance") {
                let (new_allowance: Uint256) = SafeUint256.sub_le(current_allowance, amount);
            }

            _approve(owner, spender, new_allowance);
            return ();
        }
        return ();
    }

    func _start_stream{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        recipient: felt, amount_per_second: Uint256, deposit_amount: Uint256
    ) {
        alloc_locals;
        let (caller) = get_caller_address();
        let (timestamp_now) = get_block_timestamp();

        let (recipient_len) = inflow_len_by_addr.read(recipient);
        let (sender_len) = outflow_len_by_addr.read(caller);
        local recipient_len = recipient_len;
        local sender_len = sender_len;

        // transfer deposit tokens to contract
        let (this_contract) = get_contract_address();
        _transfer(caller, this_contract, deposit_amount);

        // update inflow and outflow len
        inflow_len_by_addr.write(recipient, recipient_len + 1);
        outflow_len_by_addr.write(caller, sender_len + 1);

        let _inflow = inflow(
            recipient_len,
            amount_per_second,
            Uint256(0, 0),
            deposit_amount,
            timestamp_now,
            timestamp_now,
            recipient,
            caller,
            sender_len,
            deposit_amount,
        );

        let _outflow = outflow(
            sender_len,
            amount_per_second,
            timestamp_now,
            recipient,
            caller,
            recipient_len,
            deposit_amount,
        );

        // update inflow and outflow info
        inflow_info_by_addr.write(recipient, recipient_len, _inflow);
        outflow_info_by_addr.write(caller, sender_len, _outflow);

        return ();
    }

    func _realtime_balance_of{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        account: felt, stream_len: felt, accumulated_balance: Uint256
    ) -> (balance: Uint256) {
        if (stream_len == 0) {
            return (balance=accumulated_balance);
        }
        let (info) = inflow_info_by_addr.read(account, stream_len - 1);

        // calculate current balance
        let (_info, current_amount) = _calculate_unspent_streamed_in_amount(info);
        let (new_accumulated) = SafeUint256.add(current_amount, accumulated_balance);

        let (res) = _realtime_balance_of(account, stream_len - 1, new_accumulated);

        return (balance=res);
    }

    func _realtime_balance_of_and_update_state{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(account: felt, stream_len: felt, accumulated_balance: Uint256) -> (balance: Uint256) {
        if (stream_len == 0) {
            return (balance=accumulated_balance);
        }
        let (info) = inflow_info_by_addr.read(account, stream_len - 1);

        // calculate current balance
        let (streamed_amount) = _calculate_unspent_streamed_in_amount_and_update_state(info);
        let (new_accumulated) = SafeUint256.add(streamed_amount, accumulated_balance);

        let (res) = _realtime_balance_of(account, stream_len - 1, new_accumulated);

        return (balance=res);
    }

    func _calculate_unspent_streamed_in_amount{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(info: inflow) -> (res: inflow, current_amount: Uint256) {
        alloc_locals;
        let amount_unspent_is_zero: felt = uint256_eq(Uint256(0, 0), info.unspent);
        if (amount_unspent_is_zero == 1) {
            return (res=info, current_amount=Uint256(0, 0));
        } else {
            local last_updated_timestamp;

            last_updated_timestamp = info.last_updated_timestamp;

            let (current_timestamp) = get_block_timestamp();
            let time_diff = current_timestamp - last_updated_timestamp;
            let time_diff_as_uint256 = Uint256(time_diff, 0);
            let stream_amount: Uint256 = SafeUint256.mul(
                time_diff_as_uint256, info.amount_per_second
            );

            let unspent_balance = info.unspent;

            local final_streamed_amount: Uint256;
            let (is_deposit_balance_lt_streamed) = uint256_lt(unspent_balance, stream_amount);

            if (is_deposit_balance_lt_streamed == 1) {
                final_streamed_amount.low = unspent_balance.low;
                final_streamed_amount.high = unspent_balance.high;
            } else {
                final_streamed_amount.low = stream_amount.low;
                final_streamed_amount.high = stream_amount.high;
            }

            let spent: Uint256 = SafeUint256.add(info.spent, final_streamed_amount);
            let unspent: Uint256 = SafeUint256.sub_le(unspent_balance, final_streamed_amount);

            let _inflow = inflow(
                info.id,
                info.amount_per_second,
                spent,
                unspent,
                info.created_timestamp,
                current_timestamp,
                info.to,
                info.from_sender,
                info.outflow_id,
                info.deposit,
            );
            return (res=_inflow, current_amount=final_streamed_amount);
        }
    }

    func _calculate_unspent_streamed_in_amount_and_update_state{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(info: inflow) -> (res: Uint256) {
        let (_info, current_amount) = _calculate_unspent_streamed_in_amount(info);
        inflow_info_by_addr.write(_info.to, _info.id, _info);
        return (current_amount,);
    }

    func _update_balance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        alloc_locals;
        let (caller) = get_caller_address();
        let stream_len: felt = inflow_len_by_addr.read(caller);
        let realtime_balance: Uint256 = _realtime_balance_of_and_update_state(
            caller, stream_len, Uint256(0, 0)
        );
        ERC20_realtime_balances.write(caller, realtime_balance);
        let static_balance: Uint256 = ERC20_balances.read(caller);
        let total_balance: Uint256 = SafeUint256.add(static_balance, realtime_balance);
        ERC20_balances.write(caller, total_balance);
        return ();
    }
}
