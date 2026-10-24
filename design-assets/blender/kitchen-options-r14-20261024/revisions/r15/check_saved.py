import bpy, json,math,hashlib,bmesh
from pathlib import Path
from mathutils import Vector
p=Path(__file__).parent;r=json.loads((p/'variant-manifest.json').read_text());assert len(r)==42;assert len({(x['variant'],x['mode']) for x in r})==42
for x in r:assert hashlib.sha256((p/x['file']).read_bytes()).hexdigest()==x['sha256']
checks=[]
for filename in ['base-morning.blend','base-night.blend','base-golden.blend','modern-morning.blend','japandi-morning.blend','double_fridge-morning.blend','microwave-morning.blend','builtin-morning.blend','table_chairs-morning.blend','rug_persian-morning.blend','rug_teal-morning.blend','rug_ochre-morning.blend']:
 bpy.ops.wm.open_mainfile(filepath=str(p/filename));s=bpy.context.scene;bpy.context.view_layer.update()
 assert 'r13_continuous_room_walls' not in bpy.data.objects
 for name,count in [('r15_back_wall_simple_box',6),('r15_window_wall_quad_ring',16)]:
  o=bpy.data.objects[name];assert len(o.data.polygons)==count;assert not o.modifiers;assert all(len(f.vertices)==4 and not f.use_smooth for f in o.data.polygons)
  bm=bmesh.new();bm.from_mesh(o.data);assert all(e.is_manifold for e in bm.edges);bm.free()
 vol=bpy.data.objects['morning_indoor_scattering'];assert not vol.modifiers;assert all(abs(a-b)<1e-5 for a,b in zip(vol.dimensions,[3.88,3.88,2.68]))
 for n in ['stone_upstand_left','stone_upstand_back_left','stone_upstand_back_right']:assert abs(bpy.data.objects[n].dimensions.z-.08)<1e-5
 assert s['fridge_buffer_drawer_count']==3
 if not filename.startswith('modern'):assert len([o for o in bpy.data.objects if o.name.startswith('cabinet_fridge_buffer_drawer_') and o.name.endswith('_front')])==3
 else:assert len([o for o in bpy.data.objects if o.name.startswith('cabinet_fridge_buffer_drawer_') and o.name.endswith('_J_pull')])==3
 assert s['grates_lowered_r15'];tops=[]
 for o in bpy.data.objects:
  if o.name.startswith('r12_slim_grate_ring_'):
   tops.extend([(o.matrix_world@Vector(v.co[:3])).z+o.data.bevel_depth for v in o.data.splines[0].points])
 assert max(abs(z-.9) for z in tops)<1e-5
 if filename=='base-morning.blend':assert abs(math.degrees(bpy.data.objects['window_golden_sun'].data.angle)-3)<.001
 if filename=='base-night.blend':assert len([o for o in bpy.data.objects if o.type=='LIGHT'])==1 and vol.hide_render
 if filename.startswith('double_fridge'):
  stickers=[o for o in bpy.data.objects if o.name.startswith('r15_double_fridge_sample_sticker_')];assert len(stickers)==3 and all(not o.hide_render for o in stickers)
 if filename.startswith('table_chairs'):
  seats=[o for o in bpy.data.objects if o.name.startswith('vintage_chair_') and o.name.endswith('_wood_seat')];assert len(seats)==3;assert all(not o.hide_render for o in seats)
 if filename.startswith('builtin'):assert abs(bpy.data.objects['builtin_upstand'].dimensions.z-.08)<1e-5 and abs(bpy.data.objects['builtin_upstand'].dimensions.y-.02)<1e-5
 if filename.startswith('rug_'):
  strands=[o for o in bpy.data.objects if o.name.endswith('_220_fringe_strands') and not o.hide_render];assert len(strands)==1 and len(strands[0].data.splines)==220
 print('OUTPUT_PATH',filename,repr(s.render.filepath),flush=True)
 assert s.render.filepath.replace('\\','/').startswith('//renders/')
 checks.append(filename)
(p/'saved-checks.json').write_text(json.dumps({'render_hashes':42,'reopened_sources':checks,'wall_quads_manifold':True,'volume_inset_no_modifiers':True,'three_drawers_in_each_style':True,'grate_outer_top_m':.9,'visual_approval_pending':True,'runtime_layers_exported':False},indent=2));print('R15_SAVED_CHECKS_PASS')
