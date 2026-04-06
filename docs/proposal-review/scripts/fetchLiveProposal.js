const fs = require('fs');
const path = require('path');

const TALLY_API_URL = 'https://api.tally.xyz/query';
const API_KEY = '365b418f59bd6dc4a0d7f23c2e8c12d982f156e9069695a6f0a2dcc3232448df';

// Build slug -> governorId lookup from dao-registry.json
function loadGovernorLookup() {
    // Walk up from scripts/ -> proposal-review/ -> skills/ -> .claude/ -> repo root -> src/
    const registryPath = path.resolve(__dirname, '..', '..', '..', '..', 'src', 'dao-registry.json');
    const registry = JSON.parse(fs.readFileSync(registryPath, 'utf-8'));
    const lookup = {};
    for (const [key, dao] of Object.entries(registry.daos)) {
        if (dao.tallySlug && dao.contracts.governor) {
            lookup[dao.tallySlug] = `eip155:1:${dao.contracts.governor}`;
        }
    }
    return lookup;
}

function usage() {
    console.log('Usage: node fetchLiveProposal.js <TALLY_URL_OR_ONCHAIN_ID> <OUTPUT_DIR>');
    console.log('');
    console.log('Examples:');
    console.log('  node .claude/skills/proposal-review/scripts/fetchLiveProposal.js https://www.tally.xyz/gov/ens/proposal/10731397... src/ens/proposals/ep-6-32');
    console.log('  node .claude/skills/proposal-review/scripts/fetchLiveProposal.js 107313977323541760723614084561841045035159333942448750767795024713131429640046 src/ens/proposals/ep-6-32');
    process.exit(1);
}

function parseOnchainId(input) {
    const urlMatch = input.match(/\/proposal\/(\d+)/);
    if (urlMatch) return urlMatch[1];
    if (/^\d+$/.test(input)) return input;
    console.error(`Error: Cannot parse on-chain proposal ID from "${input}"`);
    process.exit(1);
}

function extractSlugFromUrl(input) {
    const slugMatch = input.match(/\/gov\/([^/]+)\/proposal\//);
    if (slugMatch) return slugMatch[1];
    return null;
}

function resolveGovernorId(input) {
    const lookup = loadGovernorLookup();
    const slug = extractSlugFromUrl(input);

    if (slug) {
        if (!lookup[slug]) {
            console.error(`Error: DAO slug "${slug}" not found in dao-registry.json`);
            console.error(`Available DAOs: ${Object.keys(lookup).join(', ')}`);
            process.exit(1);
        }
        console.log(`Detected DAO: ${slug}`);
        return { governorId: lookup[slug], slug };
    }

    console.log(`Detected DAO: ens (default — no slug in input)`);
    return { governorId: lookup['ens'], slug: 'ens' };
}

async function fetchLiveProposal(onchainId, outputDir, governorId) {
    const query = `
query ProposalDetails($input: ProposalInput!) {
    proposal(input: $input) {
        id
        onchainId
        createdAt
        block { number timestamp }
        start { ... on Block { number timestamp } }
        end { ... on Block { number timestamp } }
        proposer { address name }
        metadata { description }
        executableCalls { value target calldata }
    }
}
`;

    const variables = {
        input: {
            governorId: governorId,
            onchainId: onchainId
        }
    };

    try {
        console.log(`Fetching live proposal ${onchainId.substring(0, 20)}... from Tally API...`);

        const response = await fetch(TALLY_API_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Api-Key': API_KEY
            },
            body: JSON.stringify({ query, variables })
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();

        if (data.errors) {
            throw new Error(`GraphQL error: ${JSON.stringify(data.errors)}`);
        }

        const proposal = data.data.proposal;

        if (!proposal) {
            throw new Error(`Proposal not found for onchainId: ${onchainId}`);
        }

        const executableCalls = proposal.executableCalls;
        const description = proposal.metadata?.description || '';

        if (!executableCalls || executableCalls.length === 0) {
            throw new Error('No executable calls found in the proposal');
        }

        console.log(`Found ${executableCalls.length} executable call(s)`);

        console.log(`\nLive Proposal Information:`);
        console.log(`  Tally ID: ${proposal.id}`);
        console.log(`  Onchain ID: ${proposal.onchainId}`);
        console.log(`  Created at block: ${proposal.block?.number} (${proposal.block?.timestamp})`);
        console.log(`  Voting start block: ${proposal.start?.number} (${proposal.start?.timestamp})`);
        console.log(`  Voting end block: ${proposal.end?.number} (${proposal.end?.timestamp})`);
        if (proposal.proposer) {
            console.log(`  Proposer: ${proposal.proposer.name || 'Unknown'} (${proposal.proposer.address})`);
        }

        const calldataJson = {
            proposalId: proposal.onchainId || onchainId,
            blockNumber: proposal.block?.number,
            votingStart: proposal.start?.number,
            votingEnd: proposal.end?.number,
            createdAt: proposal.createdAt,
            executableCalls: executableCalls.map(call => ({
                target: call.target,
                calldata: call.calldata,
                value: call.value || "0"
            }))
        };

        const resolvedDir = path.resolve(outputDir);
        fs.mkdirSync(resolvedDir, { recursive: true });

        const jsonPath = path.join(resolvedDir, 'proposalCalldata.json');
        const mdPath = path.join(resolvedDir, 'proposalDescription.md');

        fs.writeFileSync(jsonPath, JSON.stringify(calldataJson, null, 2));
        console.log(`\nWrote ${jsonPath}`);

        fs.writeFileSync(mdPath, description);
        console.log(`Wrote ${mdPath}`);

        executableCalls.forEach((call, index) => {
            console.log(`\nCall ${index + 1}:`);
            console.log(`  Target: ${call.target}`);
            console.log(`  Value: ${call.value || "0"}`);
            console.log(`  Calldata: ${call.calldata.substring(0, 66)}...`);
        });

        console.log('\nDone!');
        console.log(`\nIMPORTANT: The description from Tally may differ from the on-chain description`);
        console.log(`(trailing whitespace, encoding). If the test fails with "Governor: unknown proposal id",`);
        console.log(`extract the exact description from the ProposalCreated event on-chain.`);

    } catch (error) {
        console.error('Error fetching live proposal:', error.message);
        process.exit(1);
    }
}

if (require.main === module) {
    if (typeof fetch === 'undefined') {
        console.error('This script requires Node.js 18+ for fetch support');
        process.exit(1);
    }

    const args = process.argv.slice(2);
    if (args.length < 2) usage();

    const { governorId, slug } = resolveGovernorId(args[0]);
    const onchainId = parseOnchainId(args[0]);
    const outputDir = args[1];

    fetchLiveProposal(onchainId, outputDir, governorId);
}

module.exports = { fetchLiveProposal };
