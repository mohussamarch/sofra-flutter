import {fixture} from './runtime-adapter.fixture.mjs';
import {buildRuntimeRecipeCandidate} from './runtime-adapter.mjs';
const f=fixture();console.log(JSON.stringify(buildRuntimeRecipeCandidate(f.source,f.draft,f.metadata,{foods:f.foods})));
