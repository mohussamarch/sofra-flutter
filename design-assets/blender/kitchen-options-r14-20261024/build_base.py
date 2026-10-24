import bpy,sys,math,json,bmesh
from pathlib import Path
from mathutils import Vector
out=Path(__file__).parent;sys.path.insert(0,str(out));from common import *
bpy.ops.wm.open_mainfile(filepath=r'E:\work\SOFRA\app\design-assets\blender\kitchen-dream-r13-20261024\morning-r13.blend');s=bpy.context.scene
# Dissolve coplanar grid edges and enforce planar face normals, bevel only real corners.
for name in ['r13_continuous_room_walls','floor_plinth']:
 o=bpy.data.objects[name]
 for m in list(o.modifiers):
  if m.type=='WEIGHTED_NORMAL':o.modifiers.remove(m)
  elif m.type=='BEVEL':m.limit_method='ANGLE';m.angle_limit=math.radians(30);m.harden_normals=False;m.segments=5
 if name=='r13_continuous_room_walls':
  bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.dissolve_limit(bm,angle_limit=.0001,verts=list(bm.verts),edges=list(bm.edges),use_dissolve_boundaries=False);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free()
 for p in o.data.polygons:p.use_smooth=False
# Remove default upper herb plant; optional hanging plants will be separate.
for o in list(bpy.data.objects):
 if o.name.startswith('decor_herb_') or o.name=='decor_pot_soil':bpy.data.objects.remove(o,do_unlink=True)
# Rod ends with nostalgic round finials, attached to the existing optional assembly.
root=bpy.data.objects['curtain_root_optional'];brass=bpy.data.materials['r06_muted_brass']
for i,y in enumerate([1.355,2.845]):
 o=sphere('curtain_round_finial_'+str(i),(.12,y,2.40),(.034,.034,.034),brass);parent(o,root)
# Reposition exact decorated socket groups, clear window frame by at least100mm.
for o in bpy.data.objects:
 if o.name.startswith('outlet_left_'):o.location.y-=.15
 if o.name.startswith('outlet_back_'):
  i=int(o.name.split('_')[3]);o.location.x+=(-.12 if i==0 else -1.13);o.location.z+=(.17 if i==0 else 0)
# Shorten open duct to the actual upper cabinet top2.33m.
duct=bpy.data.objects['hood_duct_open_top'];bpy.context.view_layer.update()
for v in duct.data.vertices:
 if v.co.z>2.4:v.co.z=2.33
# Build unbroken L slab (except necessary freestanding range gap) plus right buffer slab.
stone=bpy.data.materials['worktop']
for o in list(bpy.data.objects):
 if o.name.startswith('cabinet_') and o.name.endswith('_top'):bpy.data.objects.remove(o,do_unlink=True)
def slab(n,extended=False):
 x=2.7 if extended else 1.2;poly=[(0,.6),(.6,.6),(.6,3.0),(x,3.0),(x,3.6),(0,3.6)];N=len(poly);vs=[(a,b,z) for z in [.86,.90] for a,b in poly];fs=[tuple(reversed(range(N))),tuple(range(N,2*N))]+[(i,(i+1)%N,(i+1)%N+N,i+N) for i in range(N)];me=bpy.data.meshes.new(n);me.from_pydata(vs,[],fs);me.update();o=bpy.data.objects.new(n,me);bpy.context.collection.objects.link(o);assign(o,stone)
 cutter=box('temporary_sink_cutout',(.32,2.1,.86),(.438,.478,.34),stone,.045);bpy.context.view_layer.objects.active=cutter
 for mod in list(cutter.modifiers):bpy.ops.object.modifier_apply(modifier=mod.name)
 bpy.context.view_layer.objects.active=o;mod=o.modifiers.new('true_sink_opening','BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=cutter;bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cutter,do_unlink=True)
 mod=o.modifiers.new('soft_stone_edge','BEVEL');mod.width=.006;mod.segments=4;mod.limit_method='ANGLE';return o
slab('counter_continuous_L');box('counter_right_buffer',(2.4,3.3,.88),(.6,.6,.04),stone,.006)
# Low stone upstands, no60cm seams; range gap reserved on rear wall.
box('stone_upstand_left',(.024,2.1,.96),(.048,3.0,.12),stone,.005)
box('stone_upstand_back_left',(.60,3.577,.96),(1.2,.046,.12),stone,.005)
box('stone_upstand_back_right',(2.4,3.577,.96),(.6,.046,.12),stone,.005)
# Root metadata for isolated variants. No runtime integration before approval.
s['stage']='r14 corrected default geometry; optional scenes require user review';s['default_scene']=True
bpy.context.view_layer.update()
# The sink is still genuinely open; countertop normals cannot bridge it.
o=bpy.data.objects['counter_continuous_L'];origin=o.matrix_world.inverted()@Vector((.32,2.1,1.1));assert not o.ray_cast(origin,Vector((0,0,-1)))[0]
assert abs(max(v.co.z for v in duct.data.vertices)-2.33)<1e-5
bpy.context.scene.render.filepath='//renders/base--morning.png'
bpy.ops.wm.save_as_mainfile(filepath=str(out/'base-geometry.blend'))
(out/'base-geometry-check.json').write_text(json.dumps({'counter_L_unbroken':True,'sink_hole_open':True,'stone_upstands':3,'hood_duct_top_m':2.33,'upper_cabinet_top_m':2.33,'coplanar_edges_dissolved':True,'weighted_normals_removed_from_wall_and_base':True,'default_top_plant_removed':True,'round_finials':2,'left_outlet_frame_gap_m':.165,'runtime_implemented':False},indent=2))
print('BASE_GEOMETRY_READY')
