from pathlib import Path
from PIL import Image
import json,hashlib,numpy as np
root=Path(__file__).resolve().parents[3] if 'design-assets' in str(Path(__file__)) else Path('E:/work/SOFRA/app')
p=root/'assets/scenes/kitchen/spike-r14';manifest=json.loads((p/'manifest.json').read_text());s=json.loads((p/'scene.json').read_text());report=json.loads((p/'validation.json').read_text())
assert len(manifest['assets'])==24 and report['passed'] and not s['mobileTested']
for a in manifest['assets']:
 f=p/a['file'];assert f.stat().st_size==a['bytes'] and hashlib.sha256(f.read_bytes()).hexdigest()==a['sha256'];im=Image.open(f);im.load();assert list(im.size)==a['size']
 if a['file'].startswith('base_'):assert im.size==(1440,1440) and f.stat().st_size<400000
 if a['file'].startswith('fridge_door_'):assert im.size==(s['fridgeDoor']['cropRect']['width'],s['fridgeDoor']['cropRect']['height'])
assert len({a['sha256'] for a in manifest['assets'] if a['file'].startswith('fridge_door_')})==16
assert len({json.dumps(x,sort_keys=True) for x in s['cameraByMode'].values()})==1
assert s['fridgeDoor']['anglesDegrees'][0]==0 and s['fridgeDoor']['anglesDegrees'][-1]==100
pixels=np.asarray(Image.open(p/'id_mask.png').convert('RGB'));assert len(np.unique(pixels.reshape(-1,3),axis=0))==8
for k,h in s['hotspots'].items():
 assert h['color']==manifest['idColors'][k] and h['visiblePixelCount']>10
 b=h['bbox'];assert 0<=b['x']<1440 and 0<=b['y']<1440 and b['x']+b['width']<=1440 and b['y']+b['height']<=1440
source_binaries_available=True
retention_path=root/'design-assets/blender/current/retention.json'
retention=json.loads(retention_path.read_text(encoding='utf-8-sig')) if retention_path.exists() else {}
pruned={str(Path(x['path']).resolve()).casefold() for x in retention.get('deleted',[])}
for name,sha in s['sourceHashes'].items():
 source=root/'design-assets/blender/kitchen-options-r14-20261024'/name
 if source.exists():assert hashlib.sha256(source.read_bytes()).hexdigest()==sha
 else:
  assert str(source.resolve()).casefold() in pruned, 'Missing source without authorized retention receipt'
  source_binaries_available=False
for name in ['window_mask.png','beam_mask_morning.png','beam_mask_golden.png']:assert Image.open(p/name).size==(1440,1440)
assert len((root/'docs/STATUS.md').read_text(encoding='utf-8-sig').splitlines())<40
assert len((root/'docs/handoff/codex.md').read_text(encoding='utf-8-sig').splitlines())<150
print(json.dumps({'passed':True,'mediaFiles':24,'doorFrames':16,'categoricalIds':7,'cameraModesAligned':3,'totalPackageBytes':sum(f.stat().st_size for f in p.iterdir() if f.is_file()),'sourceBinariesAvailable':source_binaries_available,'sourceHashesMatch':True if source_binaries_available else None,'historicalSourceHashesRetained':True,'mobileTested':False}))
