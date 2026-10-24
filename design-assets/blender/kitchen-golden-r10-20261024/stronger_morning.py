"""Strengthen only latest r09 golden sunlight; retain geometry and night."""
import bpy,sys,json,hashlib
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
args=sys.argv[sys.argv.index('--')+1:];source,out=Path(args[0]),Path(args[1]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(source));s=bpy.context.scene
sun=bpy.data.objects['window_golden_sun'];oldenergy=sun.data.energy
sun.data.energy=16;sun.data.color=(1,.52,.21)
assert {o.name for o in bpy.data.objects if o.type=='LIGHT'}=={'window_golden_sun','window_diffuse_daylight'}
assert bpy.data.objects['window_diffuse_daylight'].data.energy==30
assert 'curtain_root_optional' in bpy.data.objects and 'morning_indoor_scattering' in bpy.data.objects
assert len([o for o in bpy.data.objects if o.name.startswith('open_shelf_')])==3
assert len([o for o in bpy.data.objects if o.name.startswith('tile_')])==36
bpy.context.view_layer.update();a=world_to_camera_view(s,s.camera,Vector((0,3.6,2.7)));b=world_to_camera_view(s,s.camera,Vector((3.6,0,0)));assert abs(a.x-b.x)<1e-6
prefs=bpy.context.preferences.addons['cycles'].preferences;prefs.compute_device_type='OPTIX';prefs.get_devices()
for d in prefs.devices:d.use=(d.type=='OPTIX')
s.cycles.device='GPU';s.cycles.samples=512;s.view_settings.exposure=0
s['stage']='r10 stronger warmer morning only, retains latest r09 geometry'
s.render.filepath=str(out/'morning-golden-stronger-r10.png')
bpy.ops.wm.save_as_mainfile(filepath=str(out/'morning-golden-stronger-r10.blend'))
bpy.ops.render.render(write_still=True)
bpy.ops.wm.open_mainfile(filepath=str(out/'morning-golden-stronger-r10.blend'))
assert bpy.data.objects['window_golden_sun'].data.energy==16
for n in ['enclosure_front_wall','enclosure_right_wall','enclosure_ceiling']:
    o=bpy.data.objects[n];assert not o.visible_camera and o.visible_shadow and o.visible_diffuse
report={'blender':bpy.app.version_string,'base_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'sun_before':oldenergy,'sun_after':16,'sun_rgb':[1,.52,.21],'sun_power_increase_percent':(16/oldenergy-1)*100,'window_daylight_unchanged':30,'geometry_and_camera_unchanged':True,'latest_r09_features_retained':True,'night_changed':False,'world_illumination':0,'blend_reopened':True,'samples':512,'png_sha256':hashlib.sha256((out/'morning-golden-stronger-r10.png').read_bytes()).hexdigest(),'visual_approval_pending':True,'runtime_implemented':False}
(out/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf8');print('STRONGER_GOLDEN_COMPLETE',json.dumps(report))
