%lang starknet

from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.security.safemath.library import SafeUint256

from src.token.interfaces.IStreamify import IStreamify

@external
func __setup__{syscall_ptr: felt*}() {
    let (contract_address) = get_contract_address();
    %{ context.streamify_contract_address = deploy_contract("./src/token/Streamify.cairo", [1539470638642759296633, 21332, 18, 10000000000000000000000000000, 0, ids.contract_address]).contract_address %}
    // 1539470638642759296633 is "Streamify" in felt
    // 21332 is "ST" in felt
    // 10000000000000000000000000000 is the initial supply
    return ();
}

@external
func test_name{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    tempvar streamify_contract_address;
    %{ ids.streamify_contract_address = context.streamify_contract_address %}
    let (name) = IStreamify.name(contract_address=streamify_contract_address);
    assert name = 'Streamify';
    return ();
}

@external
func test_symbol{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    tempvar streamify_contract_address;
    %{ ids.streamify_contract_address = context.streamify_contract_address %}
    let (symbol) = IStreamify.symbol(contract_address=streamify_contract_address);
    assert symbol = 'ST';
    return ();
}

@external
func test_decimals{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    tempvar streamify_contract_address;
    %{ ids.streamify_contract_address = context.streamify_contract_address %}
    let (decimals) = IStreamify.decimals(contract_address=streamify_contract_address);
    assert decimals = 18;
    return ();
}

@external
func test_total_supply{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    tempvar streamify_contract_address;
    %{ ids.streamify_contract_address = context.streamify_contract_address %}
    let (total_supply) = IStreamify.totalSupply(contract_address=streamify_contract_address);
    assert total_supply.low = 10000000000000000000000000000;
    assert total_supply.high = 0;
    return ();
}

@external
func test_balanceOf{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    let (contract_address) = get_contract_address();
    tempvar streamify_contract_address;
    %{ ids.streamify_contract_address = context.streamify_contract_address %}
    let (balance_of) = IStreamify.balanceOf(
        contract_address=streamify_contract_address, account=contract_address
    );
    assert balance_of.low = 10000000000000000000000000000;
    assert balance_of.high = 0;
    return ();
}

@external
func test_transfer{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    let (contract_address) = get_contract_address();
    tempvar streamify_contract_address;
    %{ ids.streamify_contract_address = context.streamify_contract_address %}
    // Checks recipient's initial balance
    let (balance_of) = IStreamify.balanceOf(
        contract_address=streamify_contract_address,
        account=1565469677252859192847898975119307575614736926786890019570412842545559096530,
    );
    assert balance_of.low = 0;
    assert balance_of.high = 0;
    // Transfer to recipient
    IStreamify.transfer(
        contract_address=streamify_contract_address,
        recipient=1565469677252859192847898975119307575614736926786890019570412842545559096530,
        amount=Uint256(100000000, 0),
    );
    // Checks recipient new balance
    let (balance_of) = IStreamify.balanceOf(
        contract_address=streamify_contract_address,
        account=1565469677252859192847898975119307575614736926786890019570412842545559096530,
    );
    assert balance_of.low = 100000000;
    assert balance_of.high = 0;
    // Checks sender's new balance
    let (senders_new_balance) = SafeUint256.sub_le(
        Uint256(10000000000000000000000000000, 0), Uint256(100000000, 0)
    );
    let (balance_of) = IStreamify.balanceOf(
        contract_address=streamify_contract_address, account=contract_address
    );
    assert balance_of.low = senders_new_balance.low;
    assert balance_of.high = senders_new_balance.high;
    return ();
}
