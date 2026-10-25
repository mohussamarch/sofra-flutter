import hashlib,json,math
from pathlib import Path
from PIL import Image,ImageChops,ImageStat
ROOT=Path('E:/work/SOFRA/app')
BASE=ROOT/'design-assets/blender/current/fridge-motion-r18'
ASSETS=ROOT/'assets/scenes/kitchen'
MODES=['morning','golden','night']
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
raw=json.loads((BASE/'raw-manifest.json').read_text())
payload=json.loads((ASSETS/'fridge-motion-spike.json').read_text())
preview=json.loads((BASE/'preview.json').read_text())
assert len(raw)==132 and len(payload['files'])==132
assert payload['approved'] is False and payload['runtimeIntegrated'] is False
assert not payload.get('partial',False)
assert sha(ASSETS/'manifest.json')=='8910973ee4f8b030005b50191302a42cd47a605c85f5c59e983c8e2a547ed691'
keys={(r['mode'],r['phase'],r['index']) for r in raw};assert len(keys)==132
bykey={(r['mode'],r['phase'],r['index']):r for r in raw}
files={r['path']:r for r in payload['files']}
adjacent=[];transparent_frames=0
for mode in MODES:
  allpaths=[]
  for phase,count in [('approach',30),('door',14)]:
    paths=payload['cameraMoves'][0][phase+'ByMode'][mode];assert len(paths)==count
    allpaths+=paths
    for i,rel in enumerate(paths):
      record=bykey[(mode,phase,i)];assert sha(BASE/record['file'])==record['sha256']
      f=ASSETS/rel;meta=files[rel];assert f.stat().st_size==meta['bytes']<70000 and sha(f)==meta['sha256']
      with Image.open(f) as im:
        assert im.size==(1080,2340);im.load();amin,amax=im.convert('RGBA').getchannel('A').getextrema()
        assert amax==255
        transparent_frames+=int(amin==0)
        if phase=='approach' and i==0:assert amin==0,('Opaque exterior backdrop',mode)
      ref=bykey[('morning',phase,i)]
      assert record['cameraType']==ref['cameraType']
      assert abs(record['shiftY']-ref['shiftY'])<1e-6
      assert max(abs(a-b) for x,y in zip(record['cameraMatrix'],ref['cameraMatrix']) for a,b in zip(x,y))<1e-5
  assert sha(ASSETS/allpaths[29])==sha(ASSETS/allpaths[30])
  assert bykey[(mode,'approach',0)]['cameraType']=='ORTHO'
  assert bykey[(mode,'approach',29)]['cameraType']=='PERSP'
  assert bykey[(mode,'door',13)]['angleDegrees']==104
  angles=[bykey[(mode,'door',i)]['angleDegrees'] for i in range(14)]
  assert angles==sorted(angles) and angles[0]==0
  layout=json.loads((BASE/f'shelf-layout-{mode}.json').read_text())
  assert layout==json.loads((BASE/'shelf-layout-morning.json').read_text())
  assert layout['canvas']==[1080,2340] and len(layout['rows'])==5
  for row in layout['rows']:
    assert len(row['anchors'])==4
    assert all(0<x<1080 and 0<y<2340*.84 for x,y in row['anchors'])
  # Record continuity numerically; this is supporting evidence, not aesthetic approval.
  images=[]
  for rel in allpaths:
    with Image.open(ASSETS/rel) as im:images.append(im.convert('RGB').resize((90,195)))
  diffs=[round(sum(ImageStat.Stat(ImageChops.difference(a,b)).mean)/3,3) for a,b in zip(images,images[1:])]
  assert max(diffs)<50,('Possible flash/cut',mode,max(diffs))
  adjacent.append({'mode':mode,'maximumMeanPixelChange':max(diffs),'approachDoorSeamExact':True})
masters=list(BASE.parent.parent.rglob('*.blend'));assert len(masters)==3
assert not list(BASE.parent.parent.rglob('*.blend?'))
geometry=json.loads((BASE/'geometry-verification.json').read_text())
assert geometry['onePointFrontPerspective'] and geometry['emptyInventory']
for r in payload['sourceMasters']:assert sha(BASE.parent/r['file'])==r['sha256']
assert sum(f['bytes'] for f in files.values())==payload['totalBytes']
alpha=json.loads((BASE/'alpha-manifest.json').read_text())
assert alpha['rawManifestSha256']==sha(BASE/'raw-manifest.json')
for mode in MODES:
  for record in alpha['modes'][mode]['frames']:assert sha(BASE/record['file'])==record['sha256']
  base=payload['baseReview'][mode];f=ASSETS/base['path'];assert sha(f)==base['sha256'] and f.stat().st_size==base['bytes']<400000
  with Image.open(f) as im:
    assert im.size==(1080,1080) and im.convert('RGBA').getchannel('A').getextrema()==(0,255)
    with Image.open(ASSETS/f'moves/fridge/{mode}/approach_000.webp') as first:
      crop=first.convert('RGBA').crop((0,630,1080,1710));assert crop.getchannel('A').tobytes()==im.convert('RGBA').getchannel('A').tobytes()
      mean=ImageStat.Stat(ImageChops.difference(crop.convert('RGB'),im.convert('RGB')),mask=crop.getchannel('A')).mean
      assert max(mean)<4,('Base reference does not match approach start',mode,mean)
assert payload['budget']['motionExcludedFromCoreBudget'] and not payload['budget']['requiresRuntimeBudgetDecision']
report={'result':'FRIDGE_MOTION_PASS','nativeFrames':132,'modes':MODES,'dimensions':[1080,2340],'masterFiles':3,'canonicalManifestUnchanged':True,'emptyInventory':True,'nativeGeometryAlpha':True,'transparentFrameCount':transparent_frames,'matchingTransparentBases':3,'baseDimensions':[1080,1080],'cameraMatricesAligned':True,'shelfCoordinatesAligned':True,'sourceHashesMatch':True,'maximumFrameBytes':max(f['bytes'] for f in files.values()),'totalBytes':payload['totalBytes'],'continuity':adjacent,'budget':payload['budget'],'visualApproval':False,'runtimeIntegrated':False,'deviceTested':False}
(BASE/'verification.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
print(json.dumps(report,ensure_ascii=False))
