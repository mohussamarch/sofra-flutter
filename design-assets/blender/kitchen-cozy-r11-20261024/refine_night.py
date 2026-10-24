import bpy,json,hashlib
from pathlib import Path
from mathutils import Vector
out=Path(__file__).parent
preview=False
report=json.loads((out/'verification.json').read_text())
def bounds(o):
 v=[o.matrix_world@Vector(c) for c in o.bound_box];return [[min(p[i] for p in v),max(p[i] for p in v)] for i in range(3)]
prefs=bpy.context.preferences.addons['cycles'].preferences;prefs.compute_device_type='OPTIX';prefs.get_devices()
for d in prefs.devices:d.use=d.type=='OPTIX'
if not preview:
 bpy.ops.wm.open_mainfile(filepath=str(out/'cozy-morning-r11.blend'));s=bpy.context.scene
 for o in list(bpy.data.objects):
  if o.type=='LIGHT' or o.name=='morning_indoor_scattering':bpy.data.objects.remove(o,do_unlink=True)
 cardmat=bpy.data.objects['window_view_no_illumination'].data.materials[0]
 emission=next(n for n in cardmat.node_tree.nodes if n.type=='EMISSION');emission.inputs['Color'].default_value=(.01,.018,.035,1);emission.inputs['Strength'].default_value=.3
 bpy.ops.object.light_add(type='AREA',location=(1.95,1.65,2.635));lamp=bpy.context.object;lamp.name='ceiling_only_warm_light';lamp.data.energy=8;lamp.data.color=(1,.90,.78);lamp.data.shape='DISK';lamp.data.size=1.0;lamp.rotation_euler=(0,0,0)
 s.view_settings.exposure=0;s.cycles.samples=192;s['lighting_study']='r11 very dim night; future undercabinet LEDs absent';s.render.filepath=str(out/'cozy-night-r11.png')
 bpy.ops.wm.save_as_mainfile(filepath=str(out/'cozy-night-r11.blend'));bpy.ops.render.render(write_still=True)
 # Fresh source verification for both deliveries.
 checked=[]
 for mode in ['morning','night']:
  path=out/('cozy-'+mode+'-r11.blend');bpy.ops.wm.open_mainfile(filepath=str(path));s=bpy.context.scene;bpy.context.view_layer.update()
  assert not any('cornice' in o.name or o.name=='preparation_board' for o in bpy.data.objects)
  assert len([o for o in bpy.data.objects if o.name.startswith('curtain_panel_')])==2
  assert len([o for o in bpy.data.objects if o.name.startswith('curtain_tie_')])==2
  assert len([o for o in bpy.data.objects if o.name.startswith('tile_')])==36
  assert len([o for o in bpy.data.objects if o.name.startswith('border_')])==13
  for n in ['enclosure_front_wall','enclosure_right_wall','enclosure_ceiling']:
   o=bpy.data.objects[n];assert not o.visible_camera and o.visible_shadow and o.visible_diffuse
  assert abs(bounds(bpy.data.objects['hood'])[2][0]-bounds(bpy.data.objects['upper_prep_600_body'])[2][0])<1e-5
  lights=[o for o in bpy.data.objects if o.type=='LIGHT']
  assert {o.name for o in lights}==({'window_golden_sun','window_diffuse_daylight'} if mode=='morning' else {'ceiling_only_warm_light'})
  if mode=='night':assert lights[0].data.energy==8 and 'morning_indoor_scattering' not in bpy.data.objects
  checked.append({'mode':mode,'blend_reopened':True,'blend_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'png_sha256':hashlib.sha256((out/('cozy-'+mode+'-r11.png')).read_bytes()).hexdigest(),'lights':{o.name:o.data.energy for o in lights}})
 report['night_render_updated']=True;report['night_ceiling_watts']=8;report['night_exposure']=0;report['night_diffuser_diameter_m']=1.0;report['future_LED_built']=False;report['saved_source_checks']=checked
 (out/'verification.json').write_text(json.dumps(report,indent=2));print('BOTH_SOURCES_REOPENED_AND_CHECKED')
