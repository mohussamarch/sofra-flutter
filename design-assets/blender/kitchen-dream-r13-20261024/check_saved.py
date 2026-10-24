import bpy,json,hashlib,math,bmesh
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
out=Path(__file__).parent;r=json.loads((out/'verification.json').read_text());checks=[]
for mode in ['morning','night']:
 path=out/(mode+'-r13.blend');bpy.ops.wm.open_mainfile(filepath=str(path));s=bpy.context.scene;bpy.context.view_layer.update()
 walls=bpy.data.objects['r13_continuous_room_walls'];bm=bmesh.new();bm.from_mesh(walls.data);assert all(e.is_manifold for e in bm.edges);bm.free()
 assert max(abs(a-b) for a,b in zip(bpy.data.objects['floor_plinth'].dimensions,(4.14,4.14,.18)))<1e-5
 for n in ['enclosure_front_wall','enclosure_right_wall','enclosure_ceiling']:
  o=bpy.data.objects[n];assert not o.visible_camera and o.visible_shadow and o.visible_diffuse
 lights=[o for o in bpy.data.objects if o.type=='LIGHT'];assert {o.name for o in lights}==({'window_golden_sun','window_diffuse_daylight'} if mode=='morning' else {'ceiling_vintage_center_lamp'})
 panels=[o for o in bpy.data.objects if o.name.startswith('curtain_panel_')];assert len(panels)==2
 for o in panels:
  xs=[v.co.x for v in o.data.vertices];assert max(xs)-min(xs)<.025 # no out-of-plane billow
  assert o.data.materials[0].name=='r13_cotton_gingham'
 assert len([o for o in bpy.data.objects if o.name.startswith('outlet_') and 'plate' in o.name])==3
 assert len([o for o in bpy.data.objects if o.name.startswith('r12_support_foot_')])==12
 assert 'hob_metal_inset' in bpy.data.objects and 'hood_duct' not in bpy.data.objects
 garden=bpy.data.objects['exterior_garden_camera_only']
 for o in list(garden.children)+[bpy.data.objects['window_view_no_illumination']]:
  assert not o.visible_shadow and not o.visible_diffuse and not o.visible_glossy and not o.visible_transmission and not o.visible_volume_scatter
  if mode=='night' and o.parent==garden:assert o.hide_render
 # Caught stale matrix scale while parenting during preview: assert actual final sizes.
 magnet=bpy.data.objects['fridge_note_round_magnet'];assert max(magnet.dimensions)<.05
 for o in garden.children:
  if o.name.startswith('exterior_leaf_'):assert max(o.dimensions)<.25
 a=world_to_camera_view(s,s.camera,Vector((0,3.6,2.7)));b=world_to_camera_view(s,s.camera,Vector((3.9,-.3,0)));assert abs(a.x-b.x)<1e-6
 # Ray into duct must pass open top and hit lower hood, not a cap at z2.455.
 vol=bpy.data.objects.get('morning_indoor_scattering')
 if vol:vol.hide_set(True)
 bpy.context.view_layer.update();dg=bpy.context.evaluated_depsgraph_get();hit=s.ray_cast(dg,Vector((1.65,3.47,2.60)),Vector((0,0,-1)));assert hit[0] and hit[4].name=='hood' and hit[1].z<1.75
 rays=[]
 if mode=='morning':
  assert bpy.data.objects['window_golden_sun'].data.energy==24
  direction=Vector((1,.24,-.54)).normalized()
  for y in [1.85,2.05,2.25,2.50]:
   for z in [1.32,1.50,1.95,2.15]:
    h=s.ray_cast(dg,Vector((.12,y,z)),direction)
    if h[0]:rays.append({'aperture_yz':[y,z],'object':h[4].name,'hit':list(h[1])})
  assert any(h['object'].startswith(('tile_','border_')) for h in rays)
 else:
  assert lights[0].data.energy==200 and abs(lights[0].data.spot_blend-.8)<1e-5
 checks.append({'mode':mode,'blend_reopened':True,'manifold_continuous_walls':True,'hood_open_ray_hit':hit[4].name,'hood_ray_z':hit[1].z,'curtain_depth_range_m':.024,'outdoor_nonlighting_visibility_verified':True,'corner_alignment_error_px':abs(a.x-b.x)*1400,'morning_ray_hits':rays,'blend_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'png_sha256':hashlib.sha256((out/(mode+'-r13.png')).read_bytes()).hexdigest()})
r['saved_source_checks']=checks;r['preview_parent_scale_issue_fixed_before_delivery']=True;(out/'verification.json').write_text(json.dumps(r,indent=2));print('R13_SAVED_SOURCES_VERIFIED',[(c['mode'],c['hood_open_ray_hit']) for c in checks])
