import bpy,json,hashlib,math
from pathlib import Path
from mathutils import Vector
out=Path(__file__).parent
prefs=bpy.context.preferences.addons['cycles'].preferences;prefs.compute_device_type='OPTIX';prefs.get_devices()
for d in prefs.devices:d.use=d.type=='OPTIX'
checks=[]
for mode in ['morning','night']:
 path=out/(mode+'-r12.blend');bpy.ops.wm.open_mainfile(filepath=str(path));s=bpy.context.scene
 feet=[o for o in bpy.data.objects if o.name.startswith('r12_support_foot_')];assert len(feet)==12
 for o in feet:
  parts=o.name.split('_');i,sx,sy=int(parts[-3]),int(parts[-2]),int(parts[-1]);x=[1.37,1.65,1.93][i]+sx*(.099+.025/math.sqrt(2));y=3.3+sy*(.233+.025/math.sqrt(2))
  for p in o.data.splines[0].points:p.co.x=x;p.co.y=y
  ring=bpy.data.objects['r12_slim_grate_ring_'+str(i)]
  top=o.matrix_world@Vector(o.data.splines[0].points[-1].co[:3]);ringpoints=[ring.matrix_world@Vector(p.co[:3]) for p in ring.data.splines[0].points]
  assert min((p-top).length for p in ringpoints)<1e-5
 s.render.filepath=str(out/(mode+'-r12.png'));bpy.ops.wm.save_as_mainfile(filepath=str(path));bpy.ops.render.render(write_still=True)
 bpy.ops.wm.open_mainfile(filepath=str(path));s=bpy.context.scene
 lights=[o for o in bpy.data.objects if o.type=='LIGHT'];assert len(lights)==(2 if mode=='morning' else 1)
 if mode=='night':assert lights[0].data.type=='SPOT' and abs(lights[0].data.spot_blend-.8)<1e-5
 assert bpy.data.objects['hob_metal_inset'].data.materials[0].name=='r12_range_satin_metal'
 for o in bpy.data.objects:
  if o.type=='MESH' and o.name.startswith(('cabinet_','pantry_','upper_')) and not o.name.endswith('_top') and 'brass_pull' not in o.name:assert o.data.materials[0].name=='r12_unified_jade'
 for n in ['enclosure_front_wall','enclosure_right_wall','enclosure_ceiling']:
  o=bpy.data.objects[n];assert not o.visible_camera and o.visible_shadow and o.visible_diffuse
 checks.append({'mode':mode,'blend_reopened':True,'feet_connected':12,'blend_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'png_sha256':hashlib.sha256((out/(mode+'-r12.png')).read_bytes()).hexdigest()})
r=json.loads((out/'verification.json').read_text());r['saved_checks']=checks;r['grate_foot_contact_corrected_before_delivery']=True;(out/'verification.json').write_text(json.dumps(r,indent=2));print('FINAL_R12_CHECKED')
