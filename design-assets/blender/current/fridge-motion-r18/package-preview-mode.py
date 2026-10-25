import json,hashlib,shutil
from pathlib import Path
from PIL import Image
from concurrent.futures import ThreadPoolExecutor
BASE=Path('E:/work/SOFRA/app/design-assets/blender/current/fridge-motion-r18')
rows=[r for r in json.loads((BASE/'raw-manifest.json').read_text()) if r['mode']=='morning'];assert len(rows)==44
def encode(r):
 f=BASE/'frames'/'morning'/f"{r['phase']}_{r['index']:03d}.webp";f.parent.mkdir(parents=True,exist_ok=True);im=Image.open(BASE/r['file']);im.load()
 for q in [80,75,70,65]:
  im.save(f,'WEBP',quality=q,method=6)
  if f.stat().st_size<70000:break
 return f.stat().st_size
with ThreadPoolExecutor(max_workers=4) as pool:sizes=list(pool.map(encode,rows))
data={'revision':'r18-fridge-motion-review','approved':False,'partial':True,'frameSize':[1080,2340],'approachCount':30,'doorCount':14,'timingMs':{'approach':60,'door':75},'modes':{'morning':{phase:[f'frames/morning/{phase}_{i:03d}.webp' for i in range(n)] for phase,n in [('approach',30),('door',14)]}},'shelves':json.loads((BASE/'shelf-layout-morning.json').read_text())}
(BASE/'preview.json').write_text(json.dumps(data,ensure_ascii=False,indent=2));print('MORNING_PREVIEW_READY',sum(sizes),'bytes')
assets=Path('E:/work/SOFRA/app/assets/scenes/kitchen');files=[];move={'id':'fridgeApproach','hotspot':'fridge','frameSize':[1080,2340],'approachByMode':{'morning':[]},'doorByMode':{'morning':[]}}
for phase,n in [('approach',30),('door',14)]:
 for i in range(n):
  name=f'{phase}_{i:03d}.webp';source=BASE/'frames'/'morning'/name;relative=f'moves/fridge/morning/{name}';dest=assets/relative;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(source,dest);move[phase+'ByMode']['morning'].append(relative);files.append({'path':relative,'bytes':dest.stat().st_size,'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()})
payload={'schema':'sofra.scene.motion-review/1','sceneId':'kitchen','revision':'r18-fridge-motion-review','approved':False,'partial':True,'completedModes':['morning'],'pendingModes':['golden','night'],'cameraMoves':[move],'files':files,'totalBytes':sum(sizes),'runtimeIntegrated':False,'notes':'Technical morning handoff;canonical manifest unchanged. Do not add golden/night pubspec folders until delivered.'}
(assets/'fridge-motion-spike.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2))
