%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.uint256 import Uint256

from src.token.library import SuperERC20
from src.structs.FlowStruct import inflow, outflow

//
// CONSTRUCTOR
//

// @dev intitialized on deployment
// @param _name the ERC20 token name
// @param _symbol the ERC20 token symbol
// @param _decimals the ERC20 token decimals
// @param initialSupply a Uint256 representation of the token initial supply
// @param recipient the token owner
@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _name: felt, _symbol: felt, _decimals: felt, initialSupply: Uint256, recipient: felt
) {
    SuperERC20.initializer(_name, _symbol, _decimals);
    SuperERC20._mint(recipient, initialSupply);
    return ();
}

//
// GETTERS
//

// @dev returns the name of the token
@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
    let (name) = SuperERC20.name();
    return (name,);
}

// @dev returns the symbol of the token
@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (symbol: felt) {
    let (symbol) = SuperERC20.symbol();
    return (symbol,);
}

// @dev returns the decimals of the token
@view
func decimals{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    decimals: felt
) {
    let (decimals) = SuperERC20.decimals();
    return (decimals,);
}

// @dev returns the total supply of the token
@view
func totalSupply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    totalSupply: Uint256
) {
    let (totalSupply) = SuperERC20.total_supply();
    return (totalSupply,);
}

// @dev returns the token balance of an address
@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) -> (
    balance: Uint256
) {
    let (balance) = SuperERC20.balance_of(account);
    return (balance,);
}

// @dev returns the realtime token balance of an address
@view
func realtime_balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt
) -> (balance: Uint256) {
    let (balance) = SuperERC20.realtime_balance_of(account);
    return (balance,);
}

@view
func get_inflow_length{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt
) -> (res: felt) {
    let (len) = SuperERC20.get_inflow_length(account);
    return (res=len);
}

@view
func get_outflow_length{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt
) -> (res: felt) {
    let (len) = SuperERC20.get_outflow_length(account);
    return (res=len);
}

@view
func get_inflow_info{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt, id: felt
) -> (res: inflow) {
    let (_inflow) = SuperERC20.get_inflow_info(account, id);
    return (res=_inflow);
}

@view
func get_outflow_info{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt, id: felt
) -> (res: outflow) {
    let (_outflow) = SuperERC20.get_outflow_info(account, id);
    return (res=_outflow);
}

// @dev returns the allowance to an address
@view
func allowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, spender: felt
) -> (remaining: Uint256) {
    let (allowance) = SuperERC20.allowance(owner, spender);
    return (allowance,);
}

//
// SETTERS
//

// @dev carries out ERC20 token transfer
// @param recipient the address of the receiver
// @param amount the Uint256 representation of the transaction amount
@external
func transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    recipient: felt, amount: Uint256
) -> (success: felt) {
    SuperERC20.transfer(recipient, amount);
    return (TRUE,);
}

// @dev transfers token on behalf of another account
// @param sender the from address
// @param recipient the to address
// @param amount the amount being sent
@external
func transferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    sender: felt, recipient: felt, amount: Uint256
) -> (success: felt) {
    SuperERC20.transfer_from(sender, recipient, amount);
    return (TRUE,);
}

// @dev approves token to be spent on your behalf
// @param spender address of the spender
// @param amount amount being approved for spending
@external
func approve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    spender: felt, amount: Uint256
) -> (success: felt) {
    SuperERC20.approve(spender, amount);
    return (TRUE,);
}

@external
func start_stream{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    recipient: felt, amount_per_second: Uint256, deposit_amount: Uint256
) {
    return SuperERC20._start_stream(recipient, amount_per_second, deposit_amount);
}

@external
func mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    recipient: felt, amount: Uint256
) {
    return SuperERC20._mint(recipient, amount);
}
