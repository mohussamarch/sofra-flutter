import bpy,ast,math,json,hashlib
from pathlib import Path
from mathutils import Vector
p=Path('E:/work/SOFRA/app/design-assets/blender/current')
tree=ast.parse((p/'build.py').read_text());exec(compile(ast.Module(body=[n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='select'],type_ignores=[]),'select','exec'))
renders=json.loads((p/'r17-manifest.json').read_text());assert len(renders)==49 and len({(r['variant'],r['mode']) for r in renders})==49
for r in renders:assert hashlib.sha256((p/r['file']).read_bytes()).hexdigest()==r['sha256']
sources=[];cameras=[]
def bb(o):
 vs=[o.matrix_world@Vector(c) for c in o.bound_box];return [min(v[i] for v in vs) for i in range(3)],[max(v[i] for v in vs) for i in range(3)]
for mode in ['morning','night','golden']:
 file=p/('kitchen-'+mode+'.blend');bpy.ops.wm.open_mainfile(filepath=str(file));s=bpy.context.scene;bpy.context.view_layer.update();assert s['revision']=='r17';cameras.append([list(row) for row in s.camera.matrix_world]);assert s['chair_count']==4
 legs=[o for o in bpy.data.objects if o.name.startswith(('r17_table_straight_leg','r17_chair_square_leg'))];assert len(legs)==20 and all(o.type=='MESH' and all(m.type=='BEVEL' and m.width<=.003 for m in o.modifiers) for o in legs)
 assert 'r17_draped_runner' in bpy.data.objects and 'r17_glass_vase' in bpy.data.objects
 vase_min,_=bb(bpy.data.objects['r17_glass_vase']);cloth=bpy.data.objects['r17_draped_runner'];center=cloth.matrix_world@cloth.data.vertices[6*13+6].co;assert 0<=vase_min[2]-center.z<.0035
 socket=bpy.data.objects['microwave_fixed_socket'];assert (socket.location-Vector((.025,2.97,1.28))).length<1e-4
 assert len([o for o in bpy.data.objects if o.name.startswith('r17_shelf_glass_jar')])==4
 assert not any(o.name.startswith('decor_mug') for o in bpy.data.objects)
 for r in [o for o in bpy.data.objects if 'woven_base' in o.name and o.get('option_group') in ['rug_teal','rug_persian','rug_ochre']]:assert abs(r.dimensions.x-3.1)<1e-4 and abs(r.dimensions.y-3.1)<1e-4
 rug=bpy.data.objects['rug_teal_woven_base'];rmin,rmax=bb(rug)
 for o in [o for o in bpy.data.objects if o.get('option_group')=='table_chairs' and o.type=='MESH']:
  omin,omax=bb(o);assert all(omin[i]>=rmin[i]-.001 and omax[i]<=rmax[i]+.001 for i in [0,1]),'Table/chair footprint outside rug:'+o.name
 h=bpy.data.objects['r17_japandi_pantry_edge_handle'];hmin,hmax=bb(h);assert 1<=hmin[2]<hmax[2]<1.25
 g=bpy.data.objects['r17_microwave_cable_grommet'];expected=bpy.data.objects['microwave_body'].matrix_world@Vector((-.265,.08,-.07));assert (g.location-expected).length<1e-4
 cable=bpy.data.objects['microwave_connected_cable'];last=Vector(cable.data.splines[0].points[-1].co[:3]);assert (last-expected).length<1e-4
 assert bpy.data.materials['r17_white_painted_window_wood'].node_tree.nodes.get('Principled BSDF').inputs['Metallic'].default_value==0
 foliage=[o for o in bpy.data.objects if o.name.startswith('r17_pothos_heart_leaf')];assert len(foliage)>=50 and all(len(o.data.vertices)==25 for o in foliage)
 for o in foliage:
  a,b=bb(o)
  for level in [1.62,1.97,2.32]:
   if a[2]<level+.019 and b[2]>level-.019:assert b[1]<3.28,'Leaf intersects shelf front'
 select('classic','base',mode);assert cable.hide_render and not bpy.data.objects['microwave_fixed_socket'].hide_render
 select('classic','microwave',mode);assert not cable.hide_render
 select('classic','led',mode);assert all(o.hide_render==(mode!='night') for o in bpy.data.objects if o.type=='LIGHT' and o.get('option_group')=='led')
 sources.append({'mode':mode,'file':file.name,'sha256':hashlib.sha256(file.read_bytes()).hexdigest(),'checks':'passed'})
assert cameras[0]==cameras[1]==cameras[2]
models=list(p.parent.rglob('*.blend'));assert len(models)==3
(p/'r17-verification.json').write_text(json.dumps({'renderHashes':49,'masterFiles':3,'cameraAligned':True,'tableFootprintInsideRug':True,'microwaveEndpointOnBody':True,'sources':sources,'visualApproval':False,'cameraMovesDelivered':False,'dustLoopDelivered':False},indent=2));print('R17_CHECKS_PASS')
