import test from 'node:test';import assert from 'node:assert/strict';import {readFile} from 'node:fs/promises';
test('preparation source index preserves primary provenance and does not promote unknown factors or document licenses',async()=>{
 const j=JSON.parse(await readFile('data/nutrition/preparation-sources-review.json','utf8'));
 assert.equal(j.schemaVersion,1);assert.match(j.reviewedDate,/^\d{4}-\d{2}-\d{2}$/);assert.deepEqual(j.approvedFactors,[]);assert.deepEqual(j.approvedTransforms,[]);
 for(const key of ['massYield','edibleFraction','nutrientRetention']){assert.ok(j.quantityConcepts[key].definition);assert.match(j.quantityConcepts[key].status,/unknown/);}
 assert.equal(j.sources.length,4);assert.equal(new Set(j.sources.map(v=>v.id)).size,j.sources.length);assert.equal(new Set(j.sources.map(v=>v.url)).size,j.sources.length);
 for(const s of j.sources){
  for(const key of ['title','authority','publicationDate','retrievedDate','applicability','limitations','reviewStatus','license','dataLicense','documentLicense'])assert.ok(typeof s[key]==='string'&&s[key].trim(),key);
  for(const u of [s.url,s.documentUrl,s.downloadIndexUrl,s.dataLicenseEvidenceUrl].filter(Boolean)){const url=new URL(u);assert.equal(url.protocol,'https:');assert.ok(url.hostname==='usda.gov'||url.hostname.endsWith('.usda.gov'));}
  assert.ok(s.verifiedFindings.length>0);assert.equal(s.sourceBytesArchived,false);assert.equal(s.sourceSha256,null);assert.equal(s.documentLicense,'unknown');
  if(s.dataLicense.includes('CC0'))assert.equal(s.dataLicenseEvidenceUrl,'https://fdc.nal.usda.gov/api-guide/');else assert.equal(s.dataLicenseEvidenceUrl,null);
 }
});
