# TLD Oracle v2 Portal Walkthrough

Live demo: [dnssec.eketc.co/tld-oracle](https://dnssec.eketc.co/tld-oracle)
Sepolia receipt: [`0x9999...9ec9`](https://sepolia.etherscan.io/tx/0x99998721d5e108f11c8e695e0543e5c2473f09d2fe6a04005dd51e4d329e9ec9)

---

## 1. Claim TLD

![Claim TLD](screenshots/00-claim-tld.png)

The claim interface is a 3-step process. Anyone can submit a claim (acting as a gas relayer), but the TLD is always minted to the owner address in the `_ens.nic.{tld}` TXT record -- which only the DNS registry operator can set. The contract enforces a 14-day proof freshness window to prevent replay attacks: if a DNSSEC proof is older than 14 days, the registry must re-sign before a claim can proceed.

---

## 2. Ready to Claim

![Ready to Claim](screenshots/01-ready-to-claim.png)

These are the 7 TLDs that are both on the allowlist and have published working DNSSEC chains with `_ens.nic.{tld}` TXT records. The "Stale" badges show the proof freshness system in action -- these proofs are older than 14 days, so claims would revert until the registry re-signs. Two TLDs (.gift, .property) have already been claimed on the Sepolia testnet. The proof freshness check uses Algorithm 13 (ECDSA-P256), which Verisign adopted for .com/.net/.edu in 2023, signaling industry readiness.

---

## 3. On the Allowlist

![On the Allowlist](screenshots/02-allowlist.png)

The contract-level gate: 1,166 post-2012 ICANN New gTLD Program TLDs are eligible for self-serve claims. Pre-2012 gTLDs (.com, .net, .org) and ccTLDs (.uk, .de) are excluded because the `nic.tld` namespace is only contractually reserved for post-2012 gTLDs under the ICANN New gTLD Agreement. Any TLD not on the allowlist reverts immediately without burning gas on DNSSEC proof verification. Delegates can check any TLD against the allowlist using the input field.

---

## 4. Governance and Veto

![Governance and Veto](screenshots/03-governance-veto.png)

The safety mechanism. During the timelock window (15 minutes on testnet, 7 days on mainnet), either the ENS DAO or the Security Council can veto a pending claim. The veto function is shown inline -- it checks `msg.sender` against the stored DAO timelock and Security Council multisig addresses. Veto scenarios include fraudulent DNSSEC proofs, disputed TLD ownership, or incorrectly allowlisted TLDs. After the Security Council's mandate expires (July 24, 2026), only the DAO retains veto authority.

---

## 5. How It Works

![How It Works](screenshots/04-how-it-works.png)

The end-to-end flow in 5 steps: (1) Contract verifies the TLD is on the 1,166-entry allowlist, (2) DNS registry publishes an `a=0x...` record at `_ens.nic.{tld}`, (3) Claim is submitted with DNSSEC proofs to TLDMinter, (4) 7-day timelock window for DAO/Security Council review, (5) After timelock expires with no veto, anyone can execute to mint the TLD in ENS. The entire flow is trustless -- no manual intervention from ENS Labs required.
