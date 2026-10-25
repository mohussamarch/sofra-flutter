import json,hashlib,shutil
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from PIL import Image
from transparent_frames import ensure_alpha,apply_native_alpha,backdrop_for
alpha=ensure_alpha()
mattes={(mode,r["phase"],r["index"]):r for mode,m in alpha["modes"].items() for r in m["frames"]}
backdrops={mode:backdrop_for(mode) for mode in ["morning","golden","night"]}
BASE=Path('E:/work/SOFRA/app/design-assets/blender/current/fridge-motion-r18')
ASSETS=Path('E:/work/SOFRA/app/assets/scenes/kitchen')
rows=json.loads((BASE/'raw-manifest.json').read_text());assert len(rows)==132
def encode(r):
 source=BASE/r['file'];image=Image.open(source);image.load();assert image.size==(1080,2340)
 matte=Image.open(BASE/mattes[(r['mode'],r['phase'],r['index'])]['file']);matte.load();image=apply_native_alpha(image,matte,backdrops[r['mode']])
 rel=f"moves/fridge/{r['mode']}/{r['phase']}_{r['index']:03d}.webp";target=ASSETS/rel;target.parent.mkdir(parents=True,exist_ok=True)
 for quality in [80,75,70,65]:
  image.save(target,'WEBP',quality=quality,method=6)
  if target.stat().st_size<70_000:return (rel,quality,target.stat().st_size)
 raise RuntimeError('Single-frame target not met:'+rel)
with ThreadPoolExecutor(max_workers=4) as pool:encoded=list(pool.map(encode,rows))
qualities={rel:q for rel,q,b in encoded};total=sum(b for rel,q,b in encoded);quality_selected=min(qualities.values())
files=[];movement={'id':'fridgeApproach','hotspot':'fridge','frameSize':[1080,2340],'approachByMode':{},'doorByMode':{}}
preview={'revision':'r18-fridge-motion-review','approved':False,'frameSize':[1080,2340],'approachCount':30,'doorCount':14,'timingMs':{'approach':60,'door':75},'modes':{},'shelves':json.loads((BASE/'shelf-layout-morning.json').read_text()),'webpQuality':quality_selected}
for mode in ['morning','golden','night']:
 phases={}
 for phase,count in [('approach',30),('door',14)]:
  paths=[]
  for i in range(count):
   rel=f'moves/fridge/{mode}/{phase}_{i:03d}.webp';f=ASSETS/rel;paths.append(rel);files.append({'path':rel,'bytes':f.stat().st_size,'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'quality':qualities[rel]});dest=BASE/'frames'/mode/f.name;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(f,dest)
  phases[phase]=[f'frames/{mode}/{Path(path).name}' for path in paths];movement[phase+'ByMode'][mode]=paths
 assert (ASSETS/f'moves/fridge/{mode}/approach_029.webp').read_bytes()==(ASSETS/f'moves/fridge/{mode}/door_000.webp').read_bytes()
 preview['modes'][mode]=phases
 # A precise reference to the square view fitted into the portrait's middle 1080px.
 first=Image.open(ASSETS/f'moves/fridge/{mode}/approach_000.webp').convert('RGBA');crop=first.crop((0,630,1080,1710));crop.save(BASE/'frames'/mode/'base-review.webp','WEBP',quality=80,method=6)
masters=[]
for mode in ['morning','golden','night']:
 p=BASE.parent/f'kitchen-{mode}.blend';masters.append({'mode':mode,'file':p.name,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
base_review={}
for mode in ['morning','golden','night']:
 source=BASE/f'frames/{mode}/base-review.webp';rel=f'base-r18/{mode}.webp';dest=ASSETS/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(source,dest);base_review[mode]={'path':rel,'size':[1080,1080],'bytes':dest.stat().st_size,'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'approved':False}
budget={'combinedCoreTargetBytes':4_000_000,'existingSpikeBytes':701633,'withinCombinedCoreTarget':total+701633<4_000_000,'requiresRuntimeBudgetDecision':False,'motionExcludedFromCoreBudget':True,'deferredLoadingRequired':True,'decisionEvidence':'Claude handoff C2C-004: motion excluded from4MB;one mode loaded on demand'}
payload={'schema':'sofra.scene.motion-review/1','sceneId':'kitchen','revision':'r18-fridge-motion-review','approved':False,'cameraMoves':[movement],'files':files,'totalBytes':total,'minimumWebpQuality':quality_selected,'budget':budget,'runtimeIntegrated':False,'runtimeIntegrationEvidence':'Claude reports local morning browser spike;full3-mode alpha package is not yet verified in runtime by Codex','alphaMethod':alpha['method'],'nativeAlphaManifest':'design-assets/blender/current/fridge-motion-r18/alpha-manifest.json','baseReview':base_review,'sourceMasters':masters,'interior':'Empty modeled shelves and drawers;inventory is not baked into frames','notes':'Technical review sidecar for Claude;canonical kitchen manifest is unchanged. Add moves/fridge/<mode>/ and base-r18/ to pubspec. Claude accepted deferred loading of one mode outside core4MB. The1080square transparent bases are a technical reference;coordinate canonical masks/canvas before replacement. Alpha comes from native Blender geometry mattes and backdrop edge unmatting;no RGB color key. No final visual approval.'}
(ASSETS/'fridge-motion-spike.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2));(BASE/'preview.json').write_text(json.dumps(preview,ensure_ascii=False,indent=2));(BASE/'package-report.json').write_text(json.dumps({'frames':132,'bytes':total,'minimumQuality':quality_selected,'maximumQuality':max(qualities.values()),'maxFrameBytes':max(f['bytes'] for f in files),'modes':3,'canonicalManifestUnchanged':True,'alpha':True,'baseFrames':3,'baseBytes':sum(x['bytes'] for x in base_review.values()),'masterFiles':3,'budget':budget},indent=2));print('MOTION_PACKAGE_READY',total,'minimumQuality',quality_selected)
