%lang starknet

from starkware.cairo.common.uint256 import Uint256

from src.structs.FlowStruct import inflow, outflow

@contract_interface
namespace IStreamify {
    func name() -> (name: felt) {
    }

    func symbol() -> (symbol: felt) {
    }

    func decimals() -> (decimals: felt) {
    }

    func totalSupply() -> (totalSupply: Uint256) {
    }

    func balanceOf(account: felt) -> (balance: Uint256) {
    }

    func realtime_balanceOf(account: felt) -> (balance: Uint256) {
    }

    func allowance(owner: felt, spender: felt) -> (remaining: Uint256) {
    }

    func transfer(recipient: felt, amount: Uint256) -> (success: felt) {
    }

    func transferFrom(sender: felt, recipient: felt, amount: Uint256) -> (success: felt) {
    }

    func approve(spender: felt, amount: Uint256) -> (success: felt) {
    }

    func get_inflow_length(account: felt) -> (res: felt) {
    }

    func get_outflow_length(account: felt) -> (res: felt) {
    }

    func get_inflow_info(account: felt, id: felt) -> (res: inflow) {
    }

    func get_outflow_info(account: felt, id: felt) -> (res: outflow) {
    }

    func mint(recipient: felt, amount: Uint256) {
    }
}
