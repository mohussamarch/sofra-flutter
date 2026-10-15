import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';

const status=JSON.parse(await readFile(new URL('../../data/recipes/arabic-youtube/eighth-batch-20261015/source-attempt.json',import.meta.url),'utf8'));

test('unavailable official source is recorded as a blocker with no invented recipe',()=>{
 assert.equal(status.outcome,'blocked-source-unavailable');
 assert.equal(status.recipesAccepted,0);
 assert.equal(status.sourceRequests.length,1);
 assert.equal(status.sourceRequests[0].outcome.startsWith('Failed to fetch'),true);
 assert.equal(status.sourceRequests[0].videoId,'FmpmSDkknD0');
 assert.equal(status.identityStatus,'video-attribution-observed-in-prior-search-result; direct-page-content-unavailable');
 assert.equal(status.videoAttributionEvidence.sourceUrl,status.sourceRequests[0].url);
 assert.equal(status.videoAttributionEvidence.displayedByline,'Manal Alalem (Verified)');
 assert.match(status.videoAttributionEvidence.evidenceOrigin,/prior web search result/);
 assert.match(status.sourceIdentityContext.verificationEvidenceSelector,/corroborates channel identity only/);
 assert.equal(status.descriptionHash,null);
 assert.equal(status.rights,null);
 assert.equal(status.mediaDownloaded,false);
 assert.equal(status.transcriptAccessed,false);
});

test('request and quota boundaries are retained',()=>{
 assert.equal(status.requestCount,1);
 assert.equal(status.requestCap,4);
 assert.equal(status.quotaAtStart.primaryUsedPercent,80);
 assert.equal(status.quotaAtStart.ordinaryUsageAllowed,true);
 assert.ok(status.requestCount<=status.requestCap);
});
