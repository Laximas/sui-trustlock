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

    // ── Functions ─────────────────────────────────────────────────────────

    public fun create_escrow(
        seller: address,
        arbitrator: address,
        milestone_amounts: vector<u64>,
        payment: Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        let buyer = tx_context::sender(ctx);
        let total_milestones = vector::length(&milestone_amounts);

        // Build milestone objects from the amounts vector
        let mut milestones = vector::empty<Milestone>();
        let mut i = 0;
        let mut expected_total: u64 = 0;

        while (i < total_milestones) {
            let amount = *vector::borrow(&milestone_amounts, i);
            expected_total = expected_total + amount;
            vector::push_back(&mut milestones, Milestone {
                amount,
                released: false,
            });
            i = i + 1;
        };

        // Coin sent must exactly match sum of milestone amounts
        assert!(coin::value(&payment) == expected_total, EAmountMismatch);

        let escrow_uid = object::new(ctx);
        let escrow_id = object::uid_to_inner(&escrow_uid);

        let escrow = Escrow {
            id: escrow_uid,
            buyer,
            seller,
            arbitrator,
            funds: payment,
            milestones,
            state: STATE_CREATED,
            dispute_raised_at: 0,
        };

        // Make the escrow shared so both buyer and seller can access it
        transfer::share_object(escrow);

        event::emit(EscrowCreated {
            escrow_id,
            buyer,
            seller,
            total_amount: expected_total,
        });
    }

    public fun accept_escrow(
        escrow: &mut Escrow,
        ctx: &mut TxContext,
    ) {
        assert!(escrow.state == STATE_CREATED, EInvalidState);
        assert!(tx_context::sender(ctx) == escrow.seller, ENotSeller);

        escrow.state = STATE_ACTIVE;
    }

    public fun cancel_escrow(
        escrow: Escrow,
        ctx: &mut TxContext,
    ) {
        assert!(escrow.state == STATE_CREATED, EInvalidState);
        assert!(tx_context::sender(ctx) == escrow.buyer, ENotBuyer);

        let Escrow {
            id,
            buyer,
            seller: _,
            arbitrator: _,
            funds,
            milestones: _,
            state: _,
            dispute_raised_at: _,
        } = escrow;

        object::delete(id);
        transfer::public_transfer(funds, buyer);

        event::emit(EscrowCancelled {
            escrow_id: object::id_from_address(buyer), // placeholder — will fix in tests
        });
    }
}