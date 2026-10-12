"""Offline provenance/integrity checks; no downloads or account access."""
import hashlib,json,pathlib,math
root=pathlib.Path(__file__).resolve().parents[2]
bank=root/'data/usda'
manifest=json.loads((bank/'manifest.json').read_text(encoding='utf-8'))
for name,digest in manifest['files'].items():
 assert hashlib.sha256((bank/name).read_bytes()).hexdigest()==digest, name
index=json.loads((bank/'index.json').read_text(encoding='utf-8'))['foods']
definitions=json.loads((bank/'nutrient-definitions.json').read_text(encoding='utf-8'))['nutrients']
rows={}
for path in sorted((bank/'shards').glob('*.json')):
 for food in json.loads(path.read_text(encoding='utf-8')):
  assert food['id'] not in rows, food['id']
  assert food['basis']=={'amount':100,'unit':'g','edibleOnly':True}
  for nid,value,derivation,points in food['nutrients']:
   assert str(nid) in definitions
   assert isinstance(value,(float,int)) and math.isfinite(value) and value>=0
  rows[food['id']]=path.name
assert len(rows)==len(index)==manifest['count']==8156
assert {x['id']:x['file'] for x in index}==rows
coverage=json.loads((bank/'recipe-coverage.json').read_text(encoding='utf-8'))
for name,digest in coverage['recipeSourceHashes'].items():
 assert hashlib.sha256((root/'recipes/data'/name).read_bytes().replace(b'\r\n',b'\n')).hexdigest()==digest,name
assert len(coverage['recipes'])==54
assert sum(len(v['lines']) for v in coverage['recipes'])==605
assert coverage['confirmedBindings']==0
print(json.dumps({'foods':len(rows),'manifestHashes':'pass','nutrientTuples':'pass','recipeCoverage':54,'recipeLines':605}))
