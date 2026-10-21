"""Read-only evidence audit of the frozen 21 October acquisition round.

Run from the sole E checkout with Python3. No network or recipe mutations.
Exact source text coverage is not culinary, dietary, or nutrition approval.
"""
import collections, gzip, hashlib, json, re, sys, unicodedata
from pathlib import Path

root=Path.cwd()
digest=lambda b:hashlib.sha256(b).hexdigest()
read=lambda p:json.loads((root/p).read_text(encoding='utf-8'))
base=Path('data/recipes/curated-local/foodista-scale-20261021b')
paths=[base/'normalized-recipes.json']+sorted((root/base/'batches').glob('*/normalized-recipes.json'))
paths=[p.relative_to(root) if p.is_absolute() else p for p in paths]
assert len(paths)==10
cache=root/'data/recipes/modern-scale-20261021b-bulk/source-cache/00003_foodista.jsonl.gz'
assert digest(cache.read_bytes())=='9706998001be7270ea61b31e8808b68f36521088d9540b97447d68994f5b2e43'
raw_rows={str(row['id']):(row,line) for line in gzip.decompress(cache.read_bytes()).decode('utf-8').splitlines() if line.strip() for row in [json.loads(line)]}
def compact(s):return ''.join(c for c in s if not c.isspace() and ord(c)!=0xfeff)
def content_norm(s):return ''.join(c for c in re.sub('https?://'+chr(92)+'S+','',unicodedata.normalize('NFKC',s).lower()) if c.isalnum())
def section(text,name,next_names):
 match=re.search(r'(?im)^\s*(?:#{1,6}\s*)?(?:'+name+r')\s*:?\s*$([\s\S]*)',text)
 assert match, ('missing source section',name)
 s=match.group(1)
 end=re.search(r'(?im)^\s*(?:#{1,6}\s*)?(?:'+next_names+r')\s*:?\s*$',s)
 if end:s=s[:end.start()]
 lines=[re.sub(r'^\s*(?:[-*+]\s+|\d+[.)]\s+)','',x.strip()).strip() for x in s.splitlines() if x.strip()]
 return ''.join(x for x in lines if not re.fullmatch(r'(?i)(?:Ingredients?|Preparation|Directions?|Instructions?|Method|Steps?)\s*:?\s*',x))
coverage_errors=[];duplicate_content=[];ids=set();urls=set();content_keys={};packs=[];ingredient_count=method_count=0;kind_counts=collections.Counter()
for path in paths:
 payload=read(path);assert len(payload['recipes'])==1000
 for r in payload['recipes']:
  assert r['id'] not in ids;ids.add(r['id'])
  p=r['provenance'];url=p['sourceUrl'].split('?')[0].split('#')[0].lower();assert url not in urls;urls.add(url)
  assert r['runtimeReady'] is False and r['nutrition'] is None and r.get('cuisines')==[]
  assert p.get('translationStatus')=='not-translated' and r['sourceLanguage']=='en'
  snapshot_file=root/p['sourceSnapshotFile'];assert digest(snapshot_file.read_bytes())==p['sourceSnapshotSha256']
  snap=json.loads(snapshot_file.read_text(encoding='utf-8'))
  for key in ['recordId','sourceId','sourceRevision','sourceRevisionTimestamp','sourceUrl','sourceSha256','license']:
   assert p[key]==snap['sourceRecord'][key],(r['id'],key)
  raw,rawline=raw_rows[r['id'].rsplit(':',1)[1]]
  assert digest(rawline.encode())==p['sourceSha256'] and digest(raw['text'].encode())==p['sourceTextSha256']
  assert raw['text']==snap['sourceText'] and raw['metadata']['url']==p['sourceUrl']
  assert raw['metadata']['license']==p['license']['declaration']
  assert re.search(r'https?://creativecommons.org/licenses/by/(?:3\.0|4\.0)/?',raw['metadata']['license'])
  ingredient_text=section(raw['text'],'Ingredients?','Preparation|Directions?|Instructions?|Method|Steps?|Reviews?|Discussion|Tools?|Comments?|About|Notes?|Nutrition|Source|Tags?')
  method_text=section(raw['text'],'Preparation|Directions?|Instructions?|Method|Steps?','Reviews?|Discussion|Tools?|Comments?|About|Notes?|Nutrition(?:al Information)?|Source|Tags?')
  if compact(ingredient_text)!=compact(''.join(i['sourceText'] for i in r['ingredients'])):coverage_errors.append(('ingredients',r['id']))
  if compact(method_text)!=compact(''.join(s['text'] for s in r['steps'])):coverage_errors.append(('method',r['id']))
  ck=content_norm(ingredient_text)+'|'+content_norm(method_text)
  if ck in content_keys:duplicate_content.append((content_keys[ck],r['id']))
  else:content_keys[ck]=r['id']
  ingredient_count+=len(r['ingredients']);method_count+=len(r['steps']);kind_counts[r.get('recipeKind','unknown')]+=1
 packs.append({'file':str(path).replace('\\','/'),'sha256':digest((root/path).read_bytes()),'records':1000})

arabic_path=Path('data/recipes/arabic-youtube/manal-scale-20261021b/finalpackrecipes.json')
arabic=read(arabic_path);assert len(arabic['recipes'])==103
for r in arabic['recipes']:
 assert r['sourceUrl'] not in urls;urls.add(r['sourceUrl'])
 assert r['sourceKind']=='creator-website' and r['youtubeDerived'] is False and r.get('runtimeReady') is not True and r.get('nutrition') is None
 ev=r['sourceEvidence'];assert ev['ingredientListCompleteInExtract'] and ev['methodCompleteInExtract']
 assert digest((root/ev['sourceExtractFile']).read_bytes())==ev['sourceExtractSha256']
 assert len(r['steps'])==ev['methodSourceStepCount']
 assert r['httpBodyHash'] is None and r.get('reuseRights') is None

result={'sourceRecordsNew':len(ids)+len(arabic['recipes']),'foodistaNew':len(ids),'manalNew':len(arabic['recipes']),'foodistaSnapshotChecks':len(ids),'foodistaRawRecordHashChecks':len(ids),'foodistaExactIngredientSectionChecks':len(ids),'foodistaExactMethodSectionChecks':len(ids),'foodistaUniqueCanonicalUrls':len(ids),'foodistaIngredientLines':ingredient_count,'foodistaMethodBlocks':method_count,'recipeKindReviewFlags':dict(kind_counts),'arabicIngredientLines':sum(len(r['ingredients']) for r in arabic['recipes']),'arabicSourceSteps':sum(len(r['steps']) for r in arabic['recipes']),'arabicPackSha256':digest((root/arabic_path).read_bytes()),'packs':packs,'scope':'Full captured source sections with minimal recipe screening, not culinary completeness, semantic dish deduplication, translation, runtime, nutrition or diet approval.'}
result['duplicateContentPairs']=duplicate_content
result['coverageErrors']=coverage_errors
(root/'data/recipes/modern-scale-20261021b-bulk/root-audit.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(result,ensure_ascii=False,indent=2))
assert not coverage_errors and not duplicate_content, (coverage_errors[:20],duplicate_content)
