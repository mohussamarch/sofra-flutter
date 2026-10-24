from pathlib import Path
import json,hashlib
import numpy as np
from PIL import Image
raw=Path(__file__).resolve().parent/'renders';out=Path(__file__).resolve().parents[3]/'assets/scenes/kitchen/spike-r14';out.mkdir(exist_ok=True)
scene=json.loads((raw/'scene.raw.json').read_text());N=1440
assert all(c==scene['cameraByMode']['morning'] for c in scene['cameraByMode'].values()),'Camera mismatch'
files=[]
def entry(p):files.append({'file':p.name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'size':list(Image.open(p).size)})
for name in ['base_morning','base_golden','base_night','fridge_closeup_morning']+['fridge_door_morning_'+str(i).zfill(2) for i in range(16)]:
 im=Image.open(raw/(name+'.png')).convert('RGB');p=out/(name+'.webp');im.save(p,'WEBP',quality=85,method=6);entry(p)
 if name.startswith('base_'):assert im.size==(N,N) and p.stat().st_size<400*1024
arr=np.asarray(Image.open(raw/'id_mask_raw.png').convert('RGB'));snapped=np.where(arr>=128,255,0).astype('uint8');p=out/'id_mask.png';Image.fromarray(snapped).save(p,optimize=True);entry(p)
palette={(0,0,0)}|{tuple(v) for v in scene['idColors'].values()};assert set(map(tuple,snapped.reshape(-1,3)))==palette
hotspots={}
for name,c in scene['idColors'].items():
 ys,xs=np.nonzero(np.all(snapped==c,axis=2));assert len(xs)>10,name
 hotspots[name]={'color':c,'hex':'#'+''.join(f'{x:02X}' for x in c),'bbox':{'x':int(xs.min()),'y':int(ys.min()),'width':int(xs.max()-xs.min()+1),'height':int(ys.max()-ys.min()+1)},'visiblePixelCount':len(xs)}
scene['hotspots']=hotspots;scene['windowRect']=hotspots['window']['bbox']
window=np.asarray(Image.open(raw/'window_mask_raw.png').convert('L'));window=np.where(window>=128,255,0).astype('uint8');assert np.count_nonzero(window)>1000;p=out/'window_mask.png';Image.fromarray(window).save(p,optimize=True);entry(p)
wy,wx=np.nonzero(window);scene['windowRect']={'x':int(wx.min()),'y':int(wy.min()),'width':int(wx.max()-wx.min()+1),'height':int(wy.max()-wy.min()+1)}
for mode in ['morning','golden']:
 a=np.asarray(Image.open(raw/('beam_mask_'+mode+'_raw.png')).convert('L'));a=np.where(a<=2,0,a).astype('uint8');assert np.count_nonzero(a)>1000;p=out/('beam_mask_'+mode+'.png');Image.fromarray(a).save(p,optimize=True);entry(p)
expected=scene['fridgeDoor']['cropRect'];sizes={tuple(x['size']) for x in files if x['file'].startswith('fridge_door_')};assert len(sizes)==1
actual=next(iter(sizes));assert abs(actual[0]-expected['width'])<=1 and abs(actual[1]-expected['height'])<=1
scene['fridgeDoor']['cropRoundingPixels']=[actual[0]-expected['width'],actual[1]-expected['height']];scene['fridgeDoor']['encodedFrameSize']=list(actual)
base=np.asarray(Image.open(raw/'base_morning.png').convert('RGB'),dtype='float32');zero=np.asarray(Image.open(raw/'fridge_door_morning_00.png').convert('RGB'),dtype='float32');candidates=[]
for dy in [-1,0,1]:
 for dx in [-1,0,1]:
  x=expected['x']+dx;y=expected['y']+dy;candidates.append((float(np.abs(base[y:y+actual[1],x:x+actual[0]]-zero).mean()),dx,dy))
error,dx,dy=min(candidates);scene['fridgeDoor']['requestedRenderBorderRect']=dict(expected);expected.update(x=expected['x']+dx,y=expected['y']+dy,width=actual[0],height=actual[1]);scene['fridgeDoor']['closedFrameAlignmentMeanAbsoluteError']=error
scene['idMaskMethod']='Categorical object-ID emission render, one sample, minimum pixel filter, snapped to exact8color binary RGB palette with no dithering/antialiasing in final PNG.'
scene['geometryCompositorEffects']=False;scene['mobileTested']=False;scene['productionContract']=False
(out/'scene.json').write_text(json.dumps(scene,indent=2))
manifest={'schema':'sofra-spike-r14-provisional-v1','spike':True,'notVisualApproval':True,'contractPending':'docs/SCENE-CONTRACT.md owned by Claude','resolution':[N,N],'pixelOrigin':'top-left','scene':'scene.json','assets':files,'idColors':scene['idColors'],'curtainsDeferred':scene['curtainsDeferred'],'lightGroupsDeferred':scene['lightGroupsDeferred']}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2))
report={'passed':True,'baseCount':3,'frameCount':16,'webpQuality':85,'alignedCameraModes':3,'maskSize':[N,N],'idPaletteColors':8,'allHotspotsPresent':True,'frameSize':list(actual),'cropRect':expected,'assetsBytes':sum(f['bytes'] for f in files),'baseBytes':{x['file']:x['bytes'] for x in files if x['file'].startswith('base_')},'decodesChecked':len(files),'mobileTested':False,'visualApproval':False,'curtainLayersPresent':False,'lightGroupExrsPresent':False}
(out/'validation.json').write_text(json.dumps(report,indent=2));print(json.dumps(report))
