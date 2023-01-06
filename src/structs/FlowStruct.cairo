%lang starknet

from starkware.cairo.common.uint256 import Uint256

struct inflow {
    id: felt,
    amount_per_second: Uint256,
    spent: Uint256,
    unspent: Uint256,
    created_timestamp: felt,
    last_updated_timestamp: felt,
    to: felt,
    from_sender: felt,
    outflow_id: felt,
    deposit: Uint256,
}

struct outflow {
    id: felt,
    amount_per_second: Uint256,
    created_timestamp: felt,
    to: felt,
    from_sender: felt,
    inflow_id: felt,
    deposit: Uint256,
}