"""Read-only consistency audit of the frozen 650-target candidates and source evidence. No promotion or network access."""
from pathlib import Path
from fractions import Fraction
from datetime import datetime,timezone
import json,re,hashlib,unicodedata,copy,collections
root=Path(__file__).resolve().parents[2];base=root/'data/recipes/catalog-650-20261021'
def load(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,v):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def norm(s):return ''.join(c for c in unicodedata.normalize('NFKD',s).lower() if c.isalnum())
def leading_amount(s):
 s=''.join(str(unicodedata.digit(c)) if c.isdigit() else c for c in s).strip()
 s=re.sub(r'^Optional:\s*','',s,flags=re.I)
 words={'one':1,'two':2,'three':3,'four':4,'five':5,'six':6,'half':.5}
 w=re.match(r'^(one|two|three|four|five|six|half)\b',s,re.I)
 if w:return words[w[1].lower()],s[w.end():].strip()
 m=re.match(r'^(\d+)?\s*([¼½¾\u2150-\u215f])',s)
 if m:return (int(m[1]) if m[1] else 0)+unicodedata.numeric(m[2]),s[m.end():].strip()
 m=re.match(r'^(?:(\d+)\s+)?(\d+)\s*/\s*(\d+)',s)
 if m:return (int(m[1]) if m[1] else 0)+float(Fraction(int(m[2]),int(m[3]))),s[m.end():].strip()
 m=re.match(r'^\d+(?:[.,]\d+)?',s)
 if not m:return None,s
 rest=s[m.end():].strip()
 if re.match(r'^(?:[-–—]|إلى|الى|to\b)',rest):return None,s
 return float(m[0].replace(',','.')),rest
aliases={'g':'جرام','gm':'جرام','gram':'جرام','grams':'جرام','kg':'كيلو','kilogram':'كيلو','ml':'مل','l':'لتر','cup':'كوب','cups':'كوب','tbsp':'ملعقة كبيرة','tablespoon':'ملعقة كبيرة','tablespoons':'ملعقة كبيرة','tsp':'ملعقة صغيرة','teaspoon':'ملعقة صغيرة','teaspoons':'ملعقة صغيرة','clove':'فص','cloves':'فص','pound':'رطل','pounds':'رطل','lb':'رطل','lbs':'رطل','حبات':'حبة','حبتان':'حبة'}
unit_pattern=r'^(tablespoons?|teaspoons?|tbsp|tsp|cups?|grams?|gm|kg|g|ml|cloves?|pounds?|lbs?|قطع|قطعة|شرائح|شريحة|علبة|علب)\b'
manual_holds={
 'ma650-manal-macaroni-bechamel-20261021b':'Existing bechamel pasta; source variant held outside new-dish target.',
 'ma650-manal-fried-kibbeh-20261021b':'Existing fried kibbeh; variant held.',
 'ma650-manal-fish-sayadiya-20261021b':'Existing sayadiya; variant held.',
 'ma650-manal-rice-pudding-20261021b':'Existing rice pudding; semantic duplicate held.',
 'ma650-manal-grape-leaves-olive-oil-20261021b':'Existing grape leaves; variant held.',
 'ma650-manal-chicken-kabsa-20261021b':'Existing chicken kabsa; variant held.',
 'ma650-manal-chicken-shawarma-20261021b':'Existing chicken shawarma; variant held.',
 'ma650-manal-okra-stew-20261021b':'Existing okra stew; variant held.',
 'ma650-manal-tiramisu-mold-20261021b':'Existing tiramisu; variant held.',
 'ma650-manal-lasagna-mushroom-20261021b':'Existing lasagna; variant held.',
 'ma650-manal-luxury-maamoul-20261021b':'Existing maamoul; variant held.',
 'ma650-manal-simple-chicken-biryani-20261021b':'Same batch already contains chicken biryani; simpler variant held.',
 'ma650-manal-umm-ali-puff-pastry-20261021b':'Same batch contains OmAli; pastry variant held.',
 'ma650-balkan-lunchbox-bosnian-tepsijas-20261021':'Source omits liquid identity in yeast activation; held for source clarification.',
 'bc650-tiramisu':'Existing tiramisu; variant held.',
}
title_cuisines={'ياباني':r'japan(?:ese)?|tokyo','صيني':r'chin(?:ese|a)','هندي':r'indian|india','تايلاندي':r'thai(?:land)?','كوري':r'korea(?:n)?','فيتنامي':r'vietnam(?:ese)?','إندونيسي':r'indones(?:ia|ian)','ماليزي':r'malays(?:ia|ian)','فلبيني':r'filipino|philippine','باكستاني':r'pakistan(?:i)?','مغربي':r'morocc(?:o|an)','يوناني':r'greek|greece','تركي':r'turkish','لبناني':r'leban(?:ese|on)','مكسيكي':r'mexic(?:an|o)','إيطالي':r'ital(?:ian|y)','إسباني':r'spanish|spain','فرنسي':r'french|france','برتغالي':r'portuguese|portugal','برازيلي':r'brazil(?:ian)?','جامايكي':r'jamaica(?:n)?','بيروفي':r'peru(?:vian)?','ألماني':r'german(?:y)?','سويدي':r'swed(?:ish|en)','مجري':r'hungar(?:ian|y)','بولندي':r'polish|poland','روسي':r'russia(?:n)?','أيرلندي':r'irish|ireland','بريطاني':r'british|english|britain','إثيوبي':r'ethiopia(?:n)?','سويسري':r'swiss|switzerland','فنلندي':r'finnish|finland','كندي':r'canad(?:ian|a)','أرجنتيني':r'argentin(?:ian|a)','أسترالي':r'australia(?:n)?','كاجوني':r'cajun','سيتشواني':r'szechuan|sichuan','كشميري':r'kashmir(?:i)?','بنجابي':r'punjab(?:i)?'}
def foodista_cuisine(title,current):
 if current.startswith('غير محدد') or current=='عالمي متنوع':return 'غير محدد' if current.startswith('غير محدد') else current
 matched=[c for c,p in title_cuisines.items() if re.search(r'\b(?:'+p+r')\b',title,re.I)]
 return matched[0] if len(matched)==1 else ('عالمي متنوع' if len(matched)>1 else 'غير محدد')
files=sorted(p for p in (base/'arabic').glob('*chunk*.json') if '.review.' not in p.name)
files+=[base/'based/chunk-001.json',base/'based/chunk-002.json',base/'foodista/chunk-001.json',base/'foodista/chunk-101.json',base/'foodista-world/chunk-001.json']
files+=[base/'based/chunk-003.json',base/'foodista-world/chunk-002.json',base/'foodista-world/chunk-003.json']
files+=[base/'based/chunk-004.json',base/'based/chunk-005.json',base/'based/chunk-006.json',base/'foodista/chunk-102.json',base/'foodista/chunk-103.json',base/'foodista-world/chunk-004.json']
manual_holds.update({'bc650-beef-kidney':'Source method mentions wine/water absent from ingredient list; incomplete ingredient facts held.','bc650-rice-pudding':'Existing rice pudding; source variant held.','fi650-52440':'Pad Thai already in this round; source variant held.'})
files+=[base/'based/chunk-007.json',base/'based/chunk-008.json',base/'based/chunk-009.json',base/'based/chunk-010.json',base/'foodista/chunk-104.json']
files+=[base/'foodista/chunk-105.json',base/'foodista-world/chunk-005.json',base/'foodista-world/chunk-006.json',base/'foodista/chunk-106.json']
manual_holds['fiw650-52472']='Existing tabbouleh under another source identifier; variant held.'
files += [base/f'based-20261022/chunk-{n:03d}.json' for n in range(1,5)]
candidate_rows=[];source_checks=0;amount_checks=0
all_paths=None
for f in files:
 if not f.exists():continue
 rows=load(f)['recipes']
 if f.parent.name=='arabic':
  reviews={x['catalogId']:x for x in load(f.with_name(f.stem+'.review.json'))['records']}
  for row in rows:
   ev=reviews[row['id']];p=root/ev['sourceExtractFile']
   if not p.exists():
    if all_paths is None:all_paths=list((root/'data/recipes').rglob('*.json'))
    matches=[x for x in all_paths if str(x).replace('\\','/').endswith(ev['sourceExtractFile'].replace('\\','/'))]
    assert len(matches)==1,(row['id'],'unresolved extract',ev['sourceExtractFile']);p=matches[0]
   assert sha(p)==ev['sourceExtractSha256'],row['id'];source_checks+=1
   sp=root/ev['sourcePack'] if ev['sourcePack'].startswith('data/') else root/'data/recipes/arabic-youtube/manal-scale-20261021b/finalpackrecipes.json'
   original=next(x for x in load(sp)['recipes'] if x.get('recipeId',x.get('id'))==ev['sourceRowId'])
   assert len(row['ingredients'])==len(original['ingredients']) and len(row['steps'])==len(original['steps'])
   assert [s['text'] for s in row['steps']]==[s.get('textAr',s.get('text')) for s in original['steps']],row['id']
   for item,source_item in zip(row['ingredients'],original['ingredients']):
    assert item['label']==source_item.get('sourceQuantityText',source_item.get('sourceText',source_item.get('raw',''))),(row['id'],'rawquantity')
    if item['amount'] is None and source_item.get('amount') is not None and source_item.get('unit'):
     item.update(amount=source_item['amount'],unit=source_item['unit'],scale=True)
   for item in row['ingredients']:
    if item['amount'] is not None:
     a,_=leading_amount(item['label']);assert a is not None and abs(a-item['amount'])<1e-6,(row['id'],item['label'],a,item['amount']);item['amount']=a;amount_checks+=1
 elif f.parent.name.startswith('based'):
  reviews={x['recipeId']:x for x in load(f.with_name(f.stem+'.provenance.json'))['recipes']}
  for row in rows:
   ev=reviews[row['id']];source_path=ev.get('sourcePath') or ev['sourceUrl'].split('/content/',1)[1];p=root/'data/recipes/curated-local/based-cooking-20261015/source-snapshots'/Path(source_path).with_suffix('.json').name
   assert sha(p)==ev['snapshotSHA256'];snap=load(p);assert snap['sourceRecord']['rawGitText']==ev['sourceRawText'];source_checks+=1
   indices=[]
   for cross in ev['ingredientCrosswalk']:
    i=cross.get('sourceIngredientIndex')
    if i is not None:
     assert cross['sourceText']==ev['sourceIngredientLines'][i],(row['id'],'crosswalk');indices.append(i)
   missing=set(range(len(ev['sourceIngredientLines'])))-set(indices)
   assert len(indices)==len(set(indices)),(row['id'],'duplicate source mapping')
   allowed_nonfood={'Oven-safe pan','The following options are traditional but can be substituted with any desired toppings','For the bechamel','For the bites','optional additional toppings/decorations:','Two glass marbles (Optional, but it is a traditional way to prevent sticking, and they will not break in the process.)'}
   assert all(re.fullmatch(r'(?:seasonings?|sauce|filling|dough):',ev['sourceIngredientLines'][i].strip(),re.I) or ev['sourceIngredientLines'][i] in allowed_nonfood for i in missing),(row['id'],'unmapped ingredient facts',missing)
 elif f.parent.name in ['foodista','foodista-world']:
  raw_review=load(f.with_name(f.stem+'.review.json'));reviews={x.get('id',x.get('candidateId')):x for x in (raw_review if isinstance(raw_review,list) else raw_review['recipes'])}
  for row in rows:
   ev=reviews[row['id']];assert sha(root/ev['sourceSnapshotFile'])==ev['sourceSnapshotSha256'];source_checks+=1
   original=next(x for x in load(root/ev['sourcePack'])['recipes'] if x['id']==ev['sourceId'])
   assert ev['sourceIngredientLines']==[x['sourceText'] for x in original['ingredients']]
   assert ev['sourceMethod']==[x['text'] for x in original['steps']]
   targets={x['id']:x for x in row['ingredients']}
   for cross in ev.get('ingredientCrosswalk',[]):
    if cross.get('targetIngredientId'):
     assert cross['targetIngredientId'] in targets
     assert cross['translatedName']==targets[cross['targetIngredientId']]['name']
   if isinstance(row['notes'],list):row['notes']='\n'.join(row['notes'])
   original_cuisine=row['cuisine'];row['cuisine']=foodista_cuisine(original['name'],original_cuisine)
   if row['cuisine']!=original_cuisine:row['notes']+='؛ وصف المطبخ السابق غير مثبت كأصل قومي: '+original_cuisine+'؛ التصنيف الحالي يستند فقط لاسم البلد/الإقليم الصريح في عنوان المصدر، وإلا غير محدد.'
   for i,step in enumerate(row['steps']):
    step.setdefault('n',i+1);step.setdefault('passive',False)
 for row in rows:
  row['metadataPolicy']='source-unknowns-v1'
  candidate_rows.append((copy.deepcopy(row),str(f.relative_to(root)).replace('\\','/')))

tabid='fi650-'+load(base/'foodista/selection.json')['recipes'][12]['recipe']['id'].split(':')[-1]
manual_holds[tabid]='Existing tabbouleh; Lebanese source variant held outside the650distinct-recipe target.'
def source_identity(row):
 m=re.fullmatch(r'(?:fi650|fiw650)-(\d+)',row['id'])
 if m:return 'foodista:'+m[1]
 m=re.search(r'https://github\.com/LukeSmithxyz/based\.cooking/blob/[^/]+/content/([a-z0-9-]+)\.md',row.get('notes',''))
 return 'based:'+m[1] if m else None

print(json.dumps({'sourceSnapshotChecks':source_checks,'independentArabicNumericChecks':amount_checks,'candidateRows':len(candidate_rows),'scope':'source-consistency-only; not culinary/nutrition approval'},ensure_ascii=False))
