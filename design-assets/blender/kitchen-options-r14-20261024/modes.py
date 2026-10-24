import bpy,math
from mathutils import Vector

def configure(mode):
 s=bpy.context.scene
 for o in list(bpy.data.objects):
  if o.type=='LIGHT':bpy.data.objects.remove(o,do_unlink=True)
 night=mode=='night';gold=mode=='golden'
 for o in bpy.data.objects['exterior_garden_camera_only'].children:o.hide_render=night
 em=next(n for n in bpy.data.objects['window_view_no_illumination'].data.materials[0].node_tree.nodes if n.type=='EMISSION');em.inputs['Color'].default_value=(.01,.018,.035,1) if night else ((.33,.48,.72,1) if gold else (.08,.38,.95,1));em.inputs['Strength'].default_value=.3 if night else .8
 vol=bpy.data.objects['morning_indoor_scattering'];vol.hide_render=night
 vm=vol.data.materials[0].node_tree.nodes.get('Volume Scatter');vm.inputs['Density'].default_value=.032 if gold else .012
 for o in bpy.data.objects:
  if o.name.startswith('morning_dream_mote_'):o.hide_render=not gold
 if night:
  bpy.ops.object.light_add(type='SPOT',location=(1.95,1.65,2.635));lamp=bpy.context.object;lamp.name='ceiling_vintage_center_lamp';lamp.data.energy=200;lamp.data.color=(1,.87,.68);lamp.data.spot_size=math.radians(100);lamp.data.spot_blend=.8;lamp.data.shadow_soft_size=.24
 else:
  direction=Vector((1,.245,-.40) if gold else (1,.24,-.54)).normalized();bpy.ops.object.light_add(type='SUN',location=(-4,1.1,3.1));sun=bpy.context.object;sun.name='window_golden_sun';sun.rotation_euler=direction.to_track_quat('-Z','Y').to_euler();sun.data.energy=24 if gold else 16;sun.data.color=(1,.48,.12) if gold else (1,.78,.48);sun.data.angle=math.radians(7)
  bpy.ops.object.light_add(type='AREA',location=(-.16,2.1,1.75));sky=bpy.context.object;sky.name='window_diffuse_daylight';sky.data.energy=90 if gold else 180;sky.data.color=(1,.75,.5) if gold else (.88,.92,1);sky.data.shape='RECTANGLE';sky.data.size=1.05;sky.data.size_y=.95;sky.rotation_euler=Vector((1,0,0)).to_track_quat('-Z','Y').to_euler()
 s.view_settings.exposure=0 if night else .25
 if s.compositing_node_group:
  for n in s.compositing_node_group.nodes:
   if n.bl_idname=='CompositorNodeGlare':n.inputs['Strength'].default_value=.30 if gold else .12
 s['lighting_mode']=mode;s['runtime_clock_logic_implemented']=False
 prefs=bpy.context.preferences.addons['cycles'].preferences;prefs.compute_device_type='OPTIX';prefs.get_devices()
 for d in prefs.devices:d.use=d.type=='OPTIX'
 s.cycles.device='GPU'
 return s
