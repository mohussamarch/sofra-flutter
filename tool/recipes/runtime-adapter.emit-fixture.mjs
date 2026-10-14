import {fixture} from './runtime-adapter.fixture.mjs';
import {buildRuntimeRecipeCandidate,packRuntimeRecipeCandidate} from './runtime-adapter.mjs';
import {snapshotFingerprint} from './review-target.mjs';
const f=fixture();
if(process.argv.includes('--second')){f.draft.lines[0].components[0].amount=200;f.metadata.draftSha256=snapshotFingerprint(f.draft);f.metadata.reviewNote='Second synthetic review';}
if(process.argv.includes('--large'))f.metadata.notes='x'.repeat(900000);
const candidate=buildRuntimeRecipeCandidate(f.source,f.draft,f.metadata,{foods:f.foods});
console.log(JSON.stringify(process.argv.includes('--transport')?packRuntimeRecipeCandidate(candidate,f.source,f.draft,f.metadata,{foods:f.foods}):candidate));
