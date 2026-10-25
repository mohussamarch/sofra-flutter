import bpy,json,hashlib,shutil,sys
from pathlib import Path
BASE=Path('E:/work/SOFRA/app/design-assets/blender/current/fridge-motion-r18')
sys.path.insert(0,str(BASE));from motion import initialize,camera_pose,door_pose,render,layout,N_APPROACH,N_DOOR
rows=json.loads((BASE/'raw-manifest.json').read_text()) if (BASE/'raw-manifest.json').exists() else []
done={(r['mode'],r['phase'],r['index']):r for r in rows}
for mode in ['morning','golden','night']:
 s=initialize(mode)
 for phase,count in [('approach',N_APPROACH),('door',N_DOOR)]:
  for i in range(count):
   key=(mode,phase,i)
   if key in done and (BASE/done[key]['file']).is_file() and hashlib.sha256((BASE/done[key]['file']).read_bytes()).hexdigest()==done[key]['sha256']:continue
   t=i/(count-1);angle=104*(t*t*(3-2*t)) if phase=='door' else 0;camera_pose(s,t if phase=='approach' else 1);door_pose(s,angle)
   file=BASE/'raw'/mode/(phase+'_'+str(i).zfill(3)+'.png');file.parent.mkdir(parents=True,exist_ok=True)
   if phase=='door' and i==0:shutil.copyfile(BASE/'raw'/mode/('approach_'+str(N_APPROACH-1).zfill(3)+'.png'),file)
   else:render(s,file)
   rows.append({'mode':mode,'phase':phase,'index':i,'angleDegrees':angle,'file':file.relative_to(BASE).as_posix(),'sha256':hashlib.sha256(file.read_bytes()).hexdigest(),'cameraType':s.camera.data.type,'lensMm':s.camera.data.lens,'shiftY':s.camera.data.shift_y,'cameraMatrix':[list(r) for r in s.camera.matrix_world]})
   (BASE/'raw-manifest.json').write_text(json.dumps(rows,indent=2));print('MOTION_FRAME_READY',mode,phase,i,flush=True)
 camera_pose(s,1);door_pose(s,104)
 (BASE/('shelf-layout-'+mode+'.json')).write_text(json.dumps(layout(s),indent=2))
print('MOTION_RENDER_COMPLETE',len(rows),flush=True)
