import bpy,json,math,hashlib,sys
from pathlib import Path
from mathutils import Vector
BASE=Path('E:/work/SOFRA/app/design-assets/blender/current/fridge-motion-r18');sys.path.insert(0,str(BASE))
from motion import initialize,camera_pose,door_pose,xy,layout
reports=[];saved_cameras=[]
for mode in ['morning','golden','night']:
 file=BASE.parent/f'kitchen-{mode}.blend';bpy.ops.wm.open_mainfile(filepath=str(file));s=bpy.context.scene;saved_cameras.append([list(r) for r in s.camera.matrix_world]);assert s['r18_fridge_interior'];assert all(abs(bpy.data.objects[n].rotation_euler.z)<1e-6 for n in ['r18_fridge_hinge','r18_freezer_hinge'])
 assert len([o for o in bpy.data.objects if o.name.startswith('r18_fridge_glass_shelf_')])==3
 assert len([o for o in bpy.data.objects if o.name.startswith('r18_produce_bin_floor')])==2
 assert len([o for o in bpy.data.objects if o.name.startswith('r18_fridge_outer_')])==5
 assert 'fridge_body' not in bpy.data.objects,'Original solid cube must not block the cavity'
 assert abs(bpy.data.objects['r18_fridge_glass_shelf_0'].matrix_world.translation.y-3.27)<1e-5
 # The door's bins stay in front of the shelves in the closed pose.
 shelf_front=min((o.matrix_world@Vector(v)).y for o in bpy.data.objects if o.name.startswith('r18_fridge_glass_shelf_') for v in o.bound_box)
 bin_back=max((o.matrix_world@Vector(v)).y for o in bpy.data.objects if o.name.startswith('r18_door_bin_') for v in o.bound_box)
 assert shelf_front-bin_back>.02
 s=initialize(mode);camera_pose(s,1);forward=s.camera.matrix_world.to_quaternion()@Vector((0,0,-1));assert abs(forward.x)<1e-5 and abs(forward.z)<1e-5 and forward.y>.999
 assert s.camera.data.type=='PERSP' and abs(s.camera.data.lens-50)<.001
 a=xy(s,(2.80,2.842,.75));b=xy(s,(3.50,2.842,.75));assert abs(a[1]-b[1])<.01,'Front horizontal must stay horizontal'
 a=xy(s,(2.80,2.842,.20));b=xy(s,(2.80,2.842,1.90));assert abs(a[0]-b[0])<.01,'Front vertical must stay vertical'
 bottom=xy(s,(3.15,2.842,.02))[1]/2340;assert .16<1-bottom<.21
 main=bpy.data.objects['fridge_door'];handle=bpy.data.objects['fridge_door_handle'];assert main.parent.name=='r18_fridge_hinge' and handle.parent==main.parent
 original=main.matrix_world.copy();door_pose(s,104);print('DOOR_DELTA',mode,list(original.translation),list(main.matrix_world.translation),flush=True);assert (main.matrix_world@Vector(main.bound_box[6])-original@Vector(main.bound_box[6])).length>.5;assert abs(math.degrees(bpy.data.objects['r18_fridge_hinge'].rotation_euler.z)+104)<.01
 regions=layout(s);assert len(regions['rows'])==5
 for row in regions['rows']:
  for x,y in row['anchors']:assert 0<x<1080 and 0<y<2340*.84
 reports.append({'mode':mode,'file':file.name,'sha256':hashlib.sha256(file.read_bytes()).hexdigest(),'finalCameraMatrix':[list(r) for r in s.camera.matrix_world],'floorFromBottomFraction':1-bottom,'checks':'passed'})
assert saved_cameras[0]==saved_cameras[1]==saved_cameras[2]
files=[f for f in BASE.parent.parent.rglob('*') if f.is_file() and (f.suffix=='.blend' or '.blend1' in f.name)];assert len(files)==3
(BASE/'geometry-verification.json').write_text(json.dumps({'masterFiles':3,'shelves':3,'produceDrawers':2,'onePointFrontPerspective':True,'emptyInventory':True,'masters':reports},indent=2));print('FRIDGE_GEOMETRY_PASS')
