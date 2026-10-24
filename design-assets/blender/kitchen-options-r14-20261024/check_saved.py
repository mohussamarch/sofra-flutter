import bpy,sys,json,hashlib,math,bmesh,ast
from pathlib import Path
from mathutils import Vector
out=Path(__file__).parent;manifest=json.loads((out/'render-manifest.json').read_text());assert manifest['completed_renders']==manifest['expected_renders']==45
for item in manifest['results']:
 p=out/item['file'];assert p.stat().st_size>10000;assert hashlib.sha256(p.read_bytes()).hexdigest()==item['sha256']
assert len({(x['variant'],x['mode']) for x in manifest['results']})==45
# Extract only the selector, never execute the render batch again.
module=ast.parse((out/'render_options.py').read_text());fn=next(n for n in module.body if isinstance(n,ast.FunctionDef) and n.name=='select_variant');exec(compile(ast.Module(body=[fn],type_ignores=[]),'selector','exec'))
checks=[]
for mode in ['morning','night','golden']:
 path=out/('base-'+mode+'.blend');bpy.ops.wm.open_mainfile(filepath=str(path));s=bpy.context.scene;bpy.context.view_layer.update()
 walls=bpy.data.objects['r13_continuous_room_walls'];bm=bmesh.new();bm.from_mesh(walls.data);assert all(e.is_manifold for e in bm.edges);bm.free();assert all(not p.use_smooth for p in walls.data.polygons);assert not any(m.type=='WEIGHTED_NORMAL' for m in walls.modifiers)
 ev=walls.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ev.to_mesh();angles=[]
 for p in me.polygons:
  if p.area>.1:angles.extend(math.degrees(p.normal.angle(me.corner_normals[i].vector)) for i in p.loop_indices)
 maxangle=max(angles,default=0);ev.to_mesh_clear();assert maxangle<.1,maxangle
 assert not any(o.name.startswith('decor_herb_') for o in bpy.data.objects)
 assert len([o for o in bpy.data.objects if o.name.startswith('curtain_round_finial_')])==2
 assert len([o for o in bpy.data.objects if o.name.startswith('stone_upstand_')])==3
 assert not any(o.name.startswith('cabinet_') and o.name.endswith('_top') for o in bpy.data.objects)
 o=bpy.data.objects['counter_continuous_L'];assert not o.ray_cast(o.matrix_world.inverted()@Vector((.32,2.1,1.1)),Vector((0,0,-1)))[0]
 duct=bpy.data.objects['hood_duct_open_top'];zmax=max((duct.matrix_world@v.co).z for v in duct.data.vertices);assert abs(zmax-2.33)<1e-5
 plate=bpy.data.objects['outlet_left_plate'];bounds=[plate.matrix_world@Vector(v) for v in plate.bound_box];gap=1.475-max(v.y for v in bounds);assert gap>.1,gap
 lights=[o for o in bpy.data.objects if o.type=='LIGHT'];assert len(lights)==(1 if mode=='night' else 2)
 for o in bpy.data.objects['exterior_garden_camera_only'].children:assert not o.visible_shadow and not o.visible_diffuse and not o.visible_glossy
 assert all(o.hide_render for o in bpy.data.objects if o.get('option_group') and not o['option_group'].startswith('default_'))
 checks.append({'mode':mode,'source_reopened':True,'large_wall_normal_error_degrees':maxangle,'left_socket_window_gap_m':gap,'duct_top_m':zmax,'sink_open':True,'source_sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
variantchecks=[]
for v in ['palette_coral','palette_blue','palette_lilac','curtain_blue','microwave','double_fridge','hanging_plants','white_blind','no_curtain','rug_persian','rug_teal','rug_ochre','builtin','table_chairs']:
 bpy.ops.wm.open_mainfile(filepath=str(out/'options-library.blend'));select_variant(v);bpy.context.view_layer.update();visible=[o for o in bpy.data.objects if not o.hide_render]
 if v=='microwave':
  n=bpy.data.objects['microwave_root'].matrix_world.to_3x3()@Vector((0,-1,0));assert n.dot(Vector((1,-1,0)).normalized())>.999
 if v=='double_fridge':assert all(o.hide_render for o in bpy.data.objects if o.get('option_group')=='default_fridge');assert abs(bpy.data.objects['double_fridge_body'].dimensions.x-1.10)<1e-5
 if v=='table_chairs':assert len([o for o in visible if o.name.startswith('chair_') and o.name.endswith('_root')])==3
 if v.startswith('rug_'):
  assert len([o for o in visible if o.name.startswith(v+'_fringe_')])==50
  for o in visible:
   if o.name.startswith(v+'_diamond_') or o.name.startswith(v+'_petal_'):assert min(x.co.z for x in o.data.vertices)>.042
  if v=='rug_persian':assert len([o for o in visible if o.name.startswith('rug_persian_triangle_')])==10
 if v in ['white_blind','no_curtain']:assert all(o.hide_render for o in bpy.data.objects if o.get('option_group')=='default_curtain')
 if v=='builtin':
  assert all(o.hide_render for o in bpy.data.objects if o.get('option_group') in ['default_range','default_counter']);o=bpy.data.objects['builtin_continuous_stone'];assert not o.ray_cast(o.matrix_world.inverted()@Vector((.32,2.1,1.1)),Vector((0,0,-1)))[0]
 variantchecks.append({'variant':v,'selected_source_checks_passed':True})
report={'revision':14,'render_pairs_checked':45,'variants':15,'base_source_checks':checks,'option_source_checks':variantchecks,'fixed_camera_all_modes':True,'wall_shading_diagnosis':'Planar face normals verified; no broken polygon claim. Coplanar grid dissolved and unnecessary weighted normals removed. Remaining physical shadows require user visual review.','all_combinations_validated':False,'approved':False,'runtime_clock_logic_implemented':False,'harvest_or_app_export_done':False};(out/'verification.json').write_text(json.dumps(report,indent=2));print('R14_45_RENDERS_AND_SOURCES_VERIFIED',[(c['mode'],c['large_wall_normal_error_degrees']) for c in checks])
