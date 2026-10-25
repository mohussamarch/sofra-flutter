import bpy,sys,math
from pathlib import Path
from mathutils import Vector
ROOT=Path('E:/work/SOFRA/app/design-assets/blender/current')
sys.path.insert(0,str(ROOT.parent/'kitchen-options-r14-20261024/revisions/r15'))
from appearance import tube,assign,material
for mode in ['morning','night','golden']:
 bpy.ops.wm.open_mainfile(filepath=str(ROOT/('kitchen-'+mode+'.blend')));bpy.context.preferences.filepaths.save_version=0
 if bpy.context.scene.get('r17_refinements_done'):continue
 body=bpy.data.objects['microwave_body'];bpy.context.view_layer.update();end=body.matrix_world@Vector((.265,.08,-.07))
 bpy.data.objects['r17_microwave_cable_grommet'].location=end
 o=bpy.data.objects['microwave_connected_cable'];bpy.data.objects.remove(o,do_unlink=True)
 points=[Vector((.94,3.503,1.35)),Vector((.96,3.47,1.24)),Vector((.92,3.43,1.13)),Vector((.83,3.38,1.03)),end];smooth=[]
 for i in range(len(points)-1):
  p0=points[max(0,i-1)];p1=points[i];p2=points[i+1];p3=points[min(len(points)-1,i+2)]
  for j in range(12):
   t=j/12;smooth.append(.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t))
 smooth.append(end);o=tube('microwave_connected_cable',smooth,.0045,bpy.data.materials['r16_power_lead']);o['option_group']='microwave'
 c=bpy.data.collections['Options / microwave']
 for prior in list(o.users_collection):prior.objects.unlink(o)
 c.objects.link(o)
 # Soil and a few upright shoots make the trailing plants originate inside pots.
 import ast
 tree=ast.parse((ROOT/'update-r17.py').read_text())
 exec(compile(ast.Module(body=[n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name in ['leaf','group']],type_ignores=[]),'botanical_helpers','exec'))
 soil=material('r17_potting_soil',(.035,.021,.012),rough=.98);green=bpy.data.materials['r17_pothos_deep_green']
 for x,y,z in [(.12,3.35,2.34),(.44,3.35,1.99)]:
  bpy.ops.mesh.primitive_cylinder_add(vertices=32,radius=.043,depth=.006,location=(x,y,z+.083));o=bpy.context.object;o.name='r17_pothos_soil';assign(o,soil);group(o,'hanging_plants')
  for j in range(3):
   t=j*math.tau/3;start=Vector((x,y,z+.08));end=start+Vector((.052*math.cos(t),.052*math.sin(t),.10));group(tube('r17_pothos_crown_stem',[start,end],.0019,green),'hanging_plants');leaf('r17_pothos_heart_leaf_crown',end,end+Vector((.04*math.cos(t),.04*math.sin(t),.015)),.021,green,'hanging_plants')
 # Heart-shaped pothos leaves: organic lobes, tapered tip, raised midrib.
 for o in bpy.data.objects:
  if o.name.startswith('r17_pothos_heart_leaf'):
   a=o.data.vertices[0].co.copy();b=o.data.vertices[2].co.copy();d=b-a;L=d.length;axis=d.normalized();side=Vector((-axis.y,axis.x,0)).normalized();vs=[]
   for j in range(24):
    t=j*math.tau/24;hx=math.sin(t)**3;hy=(13*math.cos(t)-5*math.cos(2*t)-2*math.cos(3*t)-math.cos(4*t))/17
    vs.append(a+axis*((.35-hy*.5)*L)+side*(hx*.025))
   vs.append(a+d*.5+Vector((0,0,.008)));me=bpy.data.meshes.new('r17_botanical_pothos_leaf');me.from_pydata(vs,[],[(j,(j+1)%24,24) for j in range(24)]);me.update();me.materials.append(o.data.materials[0]);o.data=me
 for name in ['r17_visible_open_grain','r17_endgrain']:
  m=bpy.data.materials[name]
  next(n for n in m.node_tree.nodes if n.type=='VECT_MATH').inputs[1].default_value=(1.8,18,3.5)
 vertical=bpy.data.materials['r17_endgrain'].copy();vertical.name='r17_vertical_structural_wood';next(n for n in vertical.node_tree.nodes if n.type=='VECT_MATH').inputs[1].default_value=(24,24,1.5)
 for o in bpy.data.objects:
  if o.name.startswith(('r17_table_straight_leg','r17_chair_square_leg','r17_chair_straight_backpost')):o.data.materials.clear();o.data.materials.append(vertical)
 exec(bpy.data.texts['SELECT-OPTION.py'].as_string());bpy.context.scene['r17_microwave_endpoint_world']=list(end);bpy.context.scene['r17_refinements_done']=True
 bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/('kitchen-'+mode+'.blend')),compress=True)
