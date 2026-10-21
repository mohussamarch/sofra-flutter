import test from 'node:test';
import assert from 'node:assert/strict';
import {parseGermanSource,hasCompleteIngredientMethod,contentSignature,visibleText,loadInputs,buildBatch,auditRawIngredientCoverage,auditRawMethodCoverage,hasCompleteSourceRecord} from './bulk-normalize-5000.mjs';

test('German extraction retains only source lines in ingredient and method sections',()=>{
 const raw='== Zutaten ==\n* 2 Eier\n* 100 g Mehl\n== Zubereitung ==\n* Eier verrühren.\n* Mehl unterheben.\n== Tipps ==\n* nicht als Methode zählen';
 const parsed=parseGermanSource(raw);
 assert.deepEqual(parsed.ingredients.map(x=>x.sourceText),['2 Eier','100 g Mehl']);
 assert.deepEqual(parsed.steps.map(x=>x.text),['Eier verrühren.','Mehl unterheben.']);
});

test('only records with nonempty ingredient names and method text qualify as complete',()=>{
 assert.equal(hasCompleteIngredientMethod({ingredients:[{sourceText:'1 Ei'}],steps:[{text:'Backen.'}]}),true);
 assert.equal(hasCompleteIngredientMethod({ingredients:[{sourceText:'{{Zutat}}'}],steps:[{text:'Backen.'}]}),false);
 assert.equal(hasCompleteIngredientMethod({ingredients:[{sourceText:' '}],steps:[{text:'Backen.'}]}),false);
 assert.equal(hasCompleteIngredientMethod({ingredients:[{sourceText:'1 Ei'}],steps:[]}),false);
});

test('ingredient-method signatures ignore case and whitespace but preserve recipe text',()=>{
 assert.equal(contentSignature(['  1 Ei  '],['Backen  im Ofen.']),contentSignature(['1 ei'],['Backen im Ofen.']));
 assert.notEqual(contentSignature(['1 Ei'],['Backen im Ofen.']),contentSignature(['2 Eier'],['Backen im Ofen.']));
});

test('visible text restores only explicit source literals from known Spanish templates',()=>{
 assert.equal(visibleText('750 g [[Kochbuch/Erdbeere|Erdbeeren]]'),'750 g Erdbeeren');
 assert.equal(visibleText('1 {{ing|pato|Pato}} cortado'),'1 Pato cortado');
 assert.equal(visibleText('½ litro de {{ing|Agua}} o {{rec|caldo de verduras}}'),'½ litro de Agua o caldo de verduras');
 assert.equal(visibleText('{{coc|Freír}} u hornear {{ute|bol}}'),'Freír u hornear bol');
 assert.equal(visibleText('Se {{ter|macera|m}} en el {{ter|mortero|m}}'),'Se macera en el mortero');
 assert.equal(visibleText('{{tbc|brunoise|dados}}'),'dados');
 assert.equal(visibleText('{{w|Quark|Magerquark}}'),'Magerquark');
 assert.equal(visibleText('{{ute|bol|unvalidated}}'),'{{ute|bol|unvalidated}}');
 assert.equal(visibleText('{{min|5}}'),'{{min|5}}');
 assert.equal(visibleText('1 {{ing|ají}} cortado [[Archivo:Stock help-agent.png|tooltip|15px]]'),'1 ají cortado [[Archivo:Stock help-agent.png|tooltip|15px]]');
 assert.equal(visibleText('<span class="x">1 taza</span>'),'<span class="x">1 taza</span>');
 assert.equal(visibleText('{{unknown template}}'),'{{unknown template}}');
 assert.equal(hasCompleteIngredientMethod({ingredients:[{sourceText:'1 {{ing|ají}} cortado [[Archivo:Stock help-agent.png|tooltip|15px]]'}],steps:[{text:'Cocinar.'}]}),false);
 assert.equal(hasCompleteIngredientMethod({ingredients:[{sourceText:'1 {{ute|bol|unvalidated}}'}],steps:[{text:'Cocinar.'}]}),false);
 assert.equal(hasCompleteIngredientMethod({ingredients:[{sourceText:'<span>1 taza</span>'}],steps:[{text:'Cocinar.'}]}),false);
});

test('raw ingredient list coverage catches lines omitted by the parser',()=>{
 const item={language:'de',source:{recipe:{ingredients:[{sourceText:'1 Ei'}],steps:[{text:'Backen.'}]}},snapshotSource:{sourceWikitext:'== Zutaten ==\n* 1 Ei\n* 1 Eigelb\n== Zubereitung ==\n* Backen.'}};
 assert.deepEqual(auditRawIngredientCoverage(item),{rawIngredientListLineCount:2,parsedIngredientLineCount:1,allParsedLinesFoundInRawSource:true,rawIngredientCoverageReviewRequired:true});
 assert.equal(hasCompleteSourceRecord(item),false);
});

test('raw method coverage catches prose omitted by the parser',()=>{
 const item={language:'de',source:{recipe:{ingredients:[{sourceText:'1 Ei'}],steps:[{text:'Eier verrühren.'}]}},snapshotSource:{sourceWikitext:'== Zutaten ==\n* 1 Ei\n== Zubereitung ==\n* Eier verrühren.\n* In einer Form backen.'}};
 assert.deepEqual(auditRawMethodCoverage(item),{rawMethodSourceLineCount:2,parsedMethodStepCount:1,allParsedStepsFoundInRawSource:true,unmatchedRawMethodLineCount:1,unmatchedRepeatedRawMethodLineCount:0,rawMethodCoverageReviewRequired:true});
 assert.equal(hasCompleteSourceRecord(item),false);
});

test('repeated raw method lines require distinct parsed step occurrences',async()=>{
 const item={language:'de',source:{recipe:{ingredients:[{sourceText:'1 Ei'}],steps:[{text:'Backen.'}]}},snapshotSource:{sourceWikitext:'== Zutaten ==\n* 1 Ei\n== Zubereitung ==\n* Backen.\n* Backen.'}};
 const coverage=auditRawMethodCoverage(item);
 assert.equal(coverage.unmatchedRawMethodLineCount,0);
 assert.equal(coverage.unmatchedRepeatedRawMethodLineCount,1);
 assert.equal(coverage.rawMethodCoverageReviewRequired,true);
 assert.equal(hasCompleteSourceRecord(item),false);
});

test('fifth batch distinguishes converted records from source-complete records',async()=>{
 const inputs=await loadInputs();
 const {report,pack}=buildBatch(inputs);
 assert.equal(report.counts.recipes,1000);
 assert.equal(report.counts.convertedRecords,1000);
 assert.equal(report.counts.completeIngredientAndMethodRecords,846);
 assert.equal(report.counts.incompleteIngredientAndMethodRecords,154);
 assert.equal(report.counts.omittedIngredientNames,0);
 assert.equal(report.counts.omittedMethodText,0);
 assert.equal(report.counts.rawIngredientCoverageVerifiedRecords,978);
 assert.equal(report.counts.rawIngredientCoverageReviewRequiredRecords,22);
 assert.equal(report.counts.rawMethodCoverageVerifiedRecords,853);
 assert.equal(report.counts.rawMethodCoverageReviewRequiredRecords,147);
 assert.equal(report.counts.unresolvedMarkupIngredientLines,12);
 assert.equal(report.counts.unresolvedMarkupMethodSteps,3);
 assert.deepEqual(report.completeCandidateCounts,{es:476,de:373});
 assert.deepEqual(report.incompleteCandidateCounts,{es:377,de:171});
 assert.deepEqual(report.rawIngredientCoverageReviewRequiredCandidates,{es:73,de:2});
 assert.deepEqual(report.rawMethodCoverageReviewRequiredCandidates,{es:311,de:149});
 for(const pageId of [156,162]){
  const candidate=inputs.spanish.find(x=>x.source.sourcePageId===pageId);
  assert.equal(auditRawIngredientCoverage(candidate).rawIngredientListLineCount,candidate.source.recipe.ingredients.length);
  assert.equal(auditRawIngredientCoverage(candidate).allParsedLinesFoundInRawSource,false);
  assert.equal(hasCompleteSourceRecord(candidate),false);
  const row=pack.recipes.find(r=>r.id===`curated-local:es:${pageId}`);
  if(row)assert.equal(row.sourceTextCompletenessVerified,false);
 }
 assert.equal(report.counts.newAcquisitions,0);
 assert.equal(report.counts.runtimeReady,0);
 assert.equal(report.counts.translatedRecords,0);
 assert.equal(report.untaggedRecords,1000);
 assert.deepEqual(report.languageCounts,{es:630,de:370});
 assert.equal(pack.recipes.filter(r=>r.rawIngredientCoverageReviewRequired).length,22);
 assert.equal(pack.recipes.filter(r=>r.rawMethodCoverageReviewRequired).length,147);
 assert.equal(report.counts.missingAmountLines,report.counts.ingredientLines);
 assert.equal(report.counts.missingUnitLines,report.counts.ingredientLines);
 assert.equal(report.integrityIsCulinaryOrRightsApproval,false);
 assert.equal(report.selectedCompleteRecords,846);
 assert.equal(report.selectedIncompleteRecords,154);
 assert.equal(report.counts.ingredientLines,8030);
 assert.equal(report.counts.steps,5894);
 assert.equal(pack.duplicateReview.excluded.incomplete,undefined);
 for(const row of pack.recipes){
  const snapshot=JSON.parse(await (await import('node:fs/promises')).readFile(row.provenance.sourceSnapshotFile,'utf8'));
  const source=snapshot.sourceRecord,provenance=row.provenance;
  for(const key of ['recordId','sourceId','sourceRevision','sourceRevisionTimestamp','sourceUrl','sourceSha256','license'])assert.deepEqual(source[key],provenance[key],`${row.id} snapshot ${key}`);
  assert.ok(snapshot.archivedSourceRecord,'original archive record retained separately');
 }
});
