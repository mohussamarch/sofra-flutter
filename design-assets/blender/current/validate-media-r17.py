import json,hashlib
from pathlib import Path
from PIL import Image
p=Path('E:/work/SOFRA/app/design-assets/blender/current');items=json.loads((p/'r17-manifest.json').read_text())
for r in items:
 im=Image.open(p/r['file']);im.load();expected=1400 if r['variant']=='base' else 1100;assert im.size==(expected,expected);assert hashlib.sha256((p/r['file']).read_bytes()).hexdigest()==r['sha256']
details=[]
for v in ['table_chairs','microwave','hanging_plants']:
 f=p/'renders-r17'/('detail-'+v+'.png');im=Image.open(f);im.load();assert im.size==(900,900);details.append({'variant':v,'file':'renders-r17/'+f.name,'bytes':f.stat().st_size,'size':list(im.size),'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'purpose':'diagnostic camera only;master camera unchanged'})
(p/'r17-detail-manifest.json').write_text(json.dumps(details,indent=2));print('R17_MEDIA_PASS:49review+3details decoded/hash/dimensions')
