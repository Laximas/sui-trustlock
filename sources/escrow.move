module trustlock::escrow {
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::clock::{Self, Clock};
    use sui::event;

    // ── State Constants ───────────────────────────────────────────────────

    const STATE_CREATED:   u8 = 0;
    const STATE_ACTIVE:    u8 = 1;
    const STATE_DISPUTED:  u8 = 2;
    const STATE_COMPLETED: u8 = 3;
    const STATE_CANCELLED: u8 = 4;

    // 7 days in milliseconds — used for arbitrator timeout
    const DISPUTE_TIMEOUT_MS: u64 = 604_800_000;

    // ── Error Codes ───────────────────────────────────────────────────────

    const ENotBuyer:                  u64 = 0;
    const ENotSeller:                 u64 = 1;
    const ENotArbitrator:             u64 = 2;
    const EInvalidState:              u64 = 3;
    const EMilestoneOutOfRange:       u64 = 4;
    const EMilestoneAlreadyReleased:  u64 = 5;
    const EInvalidSplit:              u64 = 6;
    const ETimeoutNotReached:         u64 = 7;
    const EAmountMismatch:            u64 = 8;

    // ── Structs ───────────────────────────────────────────────────────────

    public struct Milestone has store, drop {
        amount: u64,
        released: bool,
    }

    public struct Escrow has key, store {
        id: UID,
        buyer: address,
        seller: address,
        arbitrator: address,
        funds: Coin<SUI>,
        milestones: vector<Milestone>,
        state: u8,
        dispute_raised_at: u64,
    }

    // ── Events ────────────────────────────────────────────────────────────

    public struct EscrowCreated has copy, drop {
        escrow_id: ID,
        buyer: address,
        seller: address,
        total_amount: u64,
    }

    public struct MilestoneReleased has copy, drop {
        escrow_id: ID,
        index: u64,
        amount: u64,
    }

    public struct DisputeRaised has copy, drop {
        escrow_id: ID,
        raised_by: address,
    }

    public struct DisputeResolved has copy, drop {
        escrow_id: ID,
        buyer_share: u64,
        seller_share: u64,
    }

    public struct EscrowCancelled has copy, drop {
        escrow_id: ID,
    }
}