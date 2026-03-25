# TLD Oracle v2 — Proposal Rationale

## What this proposal is asking the DAO to do

This proposal asks ENS DAO to deploy a smart contract called TLDMinter and authorize it as a controller of the ENS Root. Once authorized, TLDMinter allows ICANN-registered top-level domain operators to claim their TLD as an ENS name — trustlessly, on-chain, without requiring manual intervention from ENS Labs.

The mechanism: a TLD operator publishes a DNSSEC-signed TXT record at `_ens.nic.{tld}` pointing to their Ethereum address. TLDMinter reads that cryptographic proof on-chain via the existing DNSSECImpl oracle, verifies it, and if the TLD is on the DAO-approved allowlist, opens a 7-day claim window. The DAO or Security Council can veto during that window. If no veto, the TLD is assigned.

The initial allowlist covers 1,166 post-2012 ICANN gTLDs — the full set of generic TLDs delegated since the 2012 expansion round. Pre-2012 TLDs and `.eth` are explicitly excluded. `.eth` is permanently locked at the Root contract level — `Root.locked["eth"] = true` — meaning even if `.eth` were somehow added to the allowlist, any attempt by TLDMinter to call `setSubnodeOwner` for it would revert at the Root. The protection is enforced by the Root contract, not by TLDMinter itself.

---

## Why two proposals are required (the EVM constraint)

Seeding 1,166 TLDs into the allowlist requires 1,166 SSTORE operations. Each SSTORE costs 20,000 gas. That's 23.3M gas at the floor, before deployment overhead.

Ethereum's block gas limit is 30M. A single proposal that deploys TLDMinter, authorizes it, and seeds the full allowlist would cost approximately 33.5M gas — exceeding the limit by 11%.

This is not a contract design choice. It is a hard EVM constraint. We explored every alternative:

- **Constructor-based seeding** — encoding the allowlist into the deployment bytecode and seeding in the constructor. Same 1,166 SSTOREs, same gas cost. Measured: 33.5M gas. Over limit.
- **Permissionless seeder** — deploy first, authorize second, have anyone call a seeder function post-execution. Same SSTOREs, same wall.
- **Chunked seeder with role** — introduce a named seeder role that can batch-add without DAO approval. Introduces a trust gap; the seeder could add unauthorized TLDs before the role is revoked.

The gas is in the storage writes. No calling mechanism changes that.

The solution is two sequential proposals:

**Proposal A** (~24.2M gas, 5 calls): Deploy TLDMinter via CREATE2, authorize it as Root controller, seed TLDs 1–900 across three batches of 300.

**Proposal B** (~6.5M gas, 1 call): Seed the remaining 266 TLDs. Submitted after Proposal A fully executes (post 2-day timelock).

Contract is live and operational for 900 TLDs immediately after Proposal A. Proposal B completes the set.

Total governance time: ~18 days (two 7-day voting periods + two 2-day timelocks).

---

## Rate limiting

TLDMinter enforces a rate limit on claim execution: a maximum of 10 TLD claims per 7-day rolling window. This is set at deploy time via constructor arguments and is enforced in .

The DAO can adjust these parameters post-deployment via , which is . The rate limit is a safety valve — it bounds the blast radius if a bad actor somehow obtained a valid DNSSEC proof for a non-intended TLD before the DAO could veto.

---

## Rate limiting

TLDMinter enforces a rate limit on claim execution: a maximum of 10 TLD claims per 7-day rolling window. This is set at deploy time via constructor arguments and is enforced in `submitClaim()`.

The DAO can adjust these parameters post-deployment via `setRateLimit()`, which is `onlyDAO`. The rate limit is a safety valve — it bounds the blast radius if a bad actor somehow obtained a valid DNSSEC proof for a non-intended TLD before the DAO could veto.

---

## The Merkle root alternative

There is a cleaner path that eliminates the two-proposal problem entirely.

Instead of writing 1,166 entries to storage, TLDMinter stores a single `bytes32` Merkle root at deploy time — a cryptographic commitment to the full 1,166-TLD set. When an operator submits a claim, they provide a Merkle proof that their TLD is in the approved set. TLDMinter verifies the proof on-chain in constant time and gas.

This collapses the proposal to **2 calls**:
1. CREATE2 factory → deploy TLDMinter (with Merkle root committed in constructor)
2. Root → setController(tldMinter, true)

No seeding transactions. No follow-up proposal. No sequencing dependency.

**The governance case for this approach is strong:**

- Single proposal, ~9 days total governance time (vs. ~18 days)
- Eliminates the risk that Proposal B fails quorum after Proposal A has already executed — leaving TLDMinter live but with an incomplete allowlist, requiring a third proposal
- The allowlist commitment is cryptographically fixed at deploy time — arguably more trustless than a storage-based allowlist that could theoretically be extended without a second proposal
- Delegates can verify the full 1,166-TLD Merkle tree against the committed root before voting

**The tradeoff:**

TLD operators submitting claims must provide a Merkle proof alongside their DNSSEC proof. This is a toolable, one-time step — but it is a UX change from the storage-based design, where the contract does the allowlist lookup internally. Future DAO additions to the allowlist would require a new Merkle root and a governance proposal to update it (vs. a simpler `addToAllowlist()` call under the current design).

**Implementation lift:** Merkle proof verification in `submitClaim()` is well-understood and auditable. The additional scope is meaningful but bounded.

---

## The question for delegates

The two-proposal structure is technically complete, fully tested, and ready to submit today. It works.

The Merkle root alternative is architecturally cleaner and saves ~9 days of governance overhead, but requires additional implementation and audit time before submission.

This rationale is presented to give delegates a clear view of the tradeoff — not to advocate for one path over the other. Both are sound. The DAO's preference on governance efficiency vs. implementation readiness should drive the decision.

---

## Emergency pause

Both `pause()` and `unpause()` are gated by `onlyVetoAuthority` — accessible by the DAO Timelock or the Security Council Multisig while the SC is active. After the Security Council's mandate expires (July 24, 2026), only the DAO Timelock can pause or unpause TLDMinter. This is intentional: emergency response transitions from the SC to full DAO governance as the protocol matures.

---

## Emergency pause

Both  and  are gated by  — accessible by the DAO Timelock or the Security Council Multisig while the SC is active. After the Security Council's mandate expires (July 24, 2026), only the DAO Timelock can pause or unpause TLDMinter. This is intentional: emergency response transitions from the SC to full DAO governance as the protocol matures.
