import bpy,sys,math,random,json
from pathlib import Path
from mathutils import Vector,Matrix
ROOT=Path('E:/work/SOFRA/app/design-assets/blender/current')
sys.path.insert(0,str(ROOT.parent/'kitchen-options-r14-20261024/revisions/r15'))
from appearance import material,assign,bounds,tube
from furniture import box
random.seed(17)
def group(o,g):o['option_group']=g;return o
def cube(n,p,d,m,g=None,b=.002):
 o=box(n,p,d,m,b)
 if g:group(o,g)
 return o
def wood(n,color):
 m=material(n,color,rough=.48);ns=m.node_tree.nodes;lk=m.node_tree.links;p=ns.get('Principled BSDF');tex=ns.new('ShaderNodeTexCoord');v=ns.new('ShaderNodeVectorMath');v.operation='MULTIPLY';v.inputs[1].default_value=(3,65,8);lk.new(tex.outputs['Generated'],v.inputs[0]);noise=ns.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=2.8;noise.inputs['Detail'].default_value=3;noise.inputs['Roughness'].default_value=.7;lk.new(v.outputs[0],noise.inputs['Vector']);r=ns.new('ShaderNodeValToRGB')
 for e,f in zip(r.color_ramp.elements,[.48,1.40]):e.color=(*[min(.9,c*f) for c in color],1)
 lk.new(noise.outputs['Fac'],r.inputs[0]);lk.new(r.outputs[0],p.inputs['Base Color']);pores=ns.new('ShaderNodeTexNoise');pores.inputs['Scale'].default_value=95;lk.new(v.outputs[0],pores.inputs['Vector']);b=ns.new('ShaderNodeBump');b.inputs['Strength'].default_value=.32;b.inputs['Distance'].default_value=.0013;lk.new(pores.outputs['Fac'],b.inputs['Height']);lk.new(b.outputs[0],p.inputs['Normal']);return m
def lathe(n,profile,pos,mat,g=None):
 vs=[(pos[0]+r*math.cos(i*math.tau/40),pos[1]+r*math.sin(i*math.tau/40),pos[2]+z) for r,z in profile for i in range(40)];fs=[]
 for j in range(len(profile)-1):
  for i in range(40):fs.append((j*40+i,j*40+(i+1)%40,(j+1)*40+(i+1)%40,(j+1)*40+i))
 me=bpy.data.meshes.new(n);me.from_pydata(vs,[],fs);me.update();o=bpy.data.objects.new(n,me);bpy.context.collection.objects.link(o);assign(o,mat)
 for p in me.polygons:p.use_smooth=True
 if g:group(o,g)
 return o
def glass():
 m=material('r17_clear_thick_glass',(.83,.94,.95),rough=.09);p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Transmission Weight'].default_value=1;p.inputs['IOR'].default_value=1.46;p.inputs['Coat Weight'].default_value=.2;return m
def leaf(n,a,b,w,m,g):
 a=Vector(a);b=Vector(b);d=b-a;side=Vector((-d.y,d.x,0)).normalized()*w;mid=a+d*.55
 vs=[a,mid+side,b,mid-side,mid+Vector((0,0,.012))];me=bpy.data.meshes.new(n);me.from_pydata(vs,[],[(0,1,4),(1,2,4),(2,3,4),(3,0,4)]);me.update();o=bpy.data.objects.new(n,me);bpy.context.collection.objects.link(o);assign(o,m);group(o,g);mod=o.modifiers.new('leaf_thickness','SOLIDIFY');mod.thickness=.0006;return o
def table(gl):
 for o in list(bpy.data.objects):
  if o.get('option_group')=='table_chairs':bpy.data.objects.remove(o,do_unlink=True)
 before=set(bpy.data.objects);timber=wood('r17_visible_open_grain',(.39,.195,.075));edge=wood('r17_endgrain',(.30,.125,.04));x,y=3,.60
 for k in range(4):cube('r17_table_board',(x-.33+k*.22,y,.755),(.218,.88,.065),timber,b=.002)
 for dx in [-.32,.32]:
  for dy in [-.32,.32]:cube('r17_table_straight_leg',(x+dx,y+dy,.36),(.075,.075,.72),edge)
 for s in [-1,1]:cube('r17_table_apron',(x,y+s*.34,.66),(.74,.04,.12),timber);cube('r17_table_apron',(x+s*.34,y,.66),(.04,.74,.12),timber)
 for i,(cx,cy,a) in enumerate([(x,y-.63,0),(x-.63,y,-math.pi/2),(x+.63,y,math.pi/2),(x,y+.63,math.pi)]):
  def tr(u,v,z):return(cx+u*math.cos(a)-v*math.sin(a),cy+u*math.sin(a)+v*math.cos(a),z)
  o=cube('chair_'+str(i)+'_seat',tr(0,0,.43),(.39,.39,.045),timber);o.rotation_euler.z=a
  for u in [-.15,.15]:
   for v in [-.15,.15]:cube('r17_chair_square_leg',tr(u,v,.21),(.045,.045,.40),edge)
   o=cube('r17_chair_straight_backpost',tr(u,-.16,.62),(.043,.043,.46),timber);o.rotation_euler.z=a
  for z in [.69,.81]:
   o=cube('r17_chair_flat_backrail',tr(0,-.16,z),(.34,.040,.075),timber);o.rotation_euler.z=a
 linen=material('r17_soft_blue_woven_runner',(.34,.48,.57),rough=.95);ns=linen.node_tree.nodes;lk=linen.node_tree.links;no=ns.new('ShaderNodeTexNoise');no.inputs['Scale'].default_value=180;bum=ns.new('ShaderNodeBump');bum.inputs['Strength'].default_value=.25;bum.inputs['Distance'].default_value=.00065;lk.new(no.outputs['Fac'],bum.inputs['Height']);lk.new(bum.outputs[0],ns.get('Principled BSDF').inputs['Normal'])
 path=[(-.49,.57),(-.48,.64),(-.47,.72),(-.45,.79),(-.42,.796),(-.21,.797),(0,.797),(.21,.797),(.42,.796),(.45,.79),(.47,.72),(.48,.64),(.49,.57)];vs=[]
 for v,z in path:
  for k in range(13):u=-.17+k*.34/12;vs.append((x+u,y+v,z+.003*math.sin(k*1.6)*(1+abs(v))))
 fs=[(j*13+k,j*13+k+1,(j+1)*13+k+1,(j+1)*13+k) for j in range(len(path)-1) for k in range(12)];me=bpy.data.meshes.new('runner');me.from_pydata(vs,[],fs);me.update();o=bpy.data.objects.new('r17_draped_runner',me);bpy.context.collection.objects.link(o);assign(o,linen);mod=o.modifiers.new('cotton_thickness','SOLIDIFY');mod.thickness=.0016
 for s in [-1,1]:
  for k in range(15):tube('r17_runner_fringe',[(x-.16+k*.32/14,y+s*.49,.57),(x-.16+k*.32/14,y+s*.50,.537)],.0018,linen)
 lathe('r17_glass_vase',[(.028,0),(.056,.008),(.060,.07),(.037,.15),(.029,.19),(.026,.19),(.033,.15),(.055,.07),(.050,.012),(.028,.008)],(x,y,.802),gl)
 green=material('r17_deep_foliage',(.025,.105,.042),rough=.55);cream=material('r17_tiny_petals',(.85,.63,.52),rough=.65)
 for i in range(7):
  a=i*2.4;end=Vector((x+.085*math.cos(a),y+.085*math.sin(a),1.12+.035*math.sin(i)));start=Vector((x,y,.82));tube('r17_vase_stem',[start,(start+end)/2,end],.0019,green)
  for j in [0,1]:
   p=start+(end-start)*(.55+j*.14);leaf('r17_vase_leaf',p,p+Vector((.055*math.cos(a+j),.055*math.sin(a+j),.025)),.018,green,'table_chairs')
  for j in range(5):
   bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,location=end+Vector((.009*math.cos(j*math.tau/5),.009*math.sin(j*math.tau/5),0)));o=bpy.context.object;o.name='r17_small_flower';o.scale=(.008,.008,.004);assign(o,cream)
 for o in set(bpy.data.objects)-before:group(o,'table_chairs')
def fixtures(gl):
 white=wood('r17_white_painted_window_wood',(.58,.56,.50));p=white.node_tree.nodes.get('Principled BSDF');p.inputs['Roughness'].default_value=.82;p.inputs['Specular IOR Level'].default_value=.12
 # Keep white paint variation subtle; wood grain is relief, not brown metal.
 ramp=next(n for n in white.node_tree.nodes if n.type=='VALTORGB')
 for e,f in zip(ramp.color_ramp.elements,[.88,1.06]):e.color=(.58*f,.56*f,.50*f,1)
 for o in bpy.data.objects:
  for slot in o.material_slots:
   if slot.material and slot.material.name=='r16_window_satin_ivory':slot.material=white
 pantry=bpy.data.objects['japandi_pantry_door'];mn,mx=bounds(pantry)
 for o in list(bpy.data.objects):
  if o.name.startswith('japandi_handle'):
   a,b=bounds(o)
   if a.z>1.3 and abs((a.y+b.y)/2-(mn.y+mx.y)/2)<.1:bpy.data.objects.remove(o,do_unlink=True)
 bronze=bpy.data.materials['r16_brushed_bronze'];u=mn.y+.07
 o=tube('r17_japandi_pantry_edge_handle',[(mx.x+.018,u,1.04),(mx.x+.045,u,1.04),(mx.x+.045,u,1.18),(mx.x+.018,u,1.18)],.007,bronze);o['cabinet_style']='japandi'
 for o in list(bpy.data.objects):
  if o.name.startswith(('decor_mug','decor_jar')):bpy.data.objects.remove(o,do_unlink=True)
 lid=wood('r17_jar_wood_lids',(.38,.21,.09));contents=material('r17_jar_grains',(.54,.34,.12),rough=.86)
 for i,(x,z,h) in enumerate([(.17,1.64,.19),(.43,1.64,.16),(.17,1.99,.22),(.43,1.99,.25)]):
  lathe('r17_shelf_glass_jar',[(.042,0),(.059,.006),(.059,h-.02),(.052,h),(.048,h),(.055,h-.02),(.055,.012),(.042,.009)],(x,3.43,z),gl)
  lathe('r17_jar_lid',[(0,0),(.062,0),(.062,.023),(.0,.023)],(x,3.43,z+h),lid)
  lathe('r17_visible_jar_contents',[(0,0),(.049,0),(.049,h*.65),(0,h*.65)],(x,3.43,z+.015),contents)
 # Place the outlet in clear wall area to the microwave's right.
 delta=Vector((.16,0,.01))
 for o in bpy.data.objects:
  if o.name.startswith(('microwave_fixed_socket','socket_hole','microwave_plug')):o.location+=delta
 o=bpy.data.objects.get('microwave_connected_cable');bpy.data.objects.remove(o,do_unlink=True)
 rubber=bpy.data.materials['r16_power_lead'];body=bpy.data.objects['microwave_body'];bpy.context.view_layer.update();mn,mx=bounds(body);end=Vector((mx.x,3.27,1.00))
 points=[Vector((.94,3.503,1.35)),Vector((.96,3.47,1.24)),Vector((.92,3.43,1.13)),Vector((.83,3.38,1.03)),end];smooth=[]
 for i in range(len(points)-1):
  p0=points[max(0,i-1)];p1=points[i];p2=points[i+1];p3=points[min(len(points)-1,i+2)]
  for j in range(12):t=j/12;smooth.append(.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t))
 smooth.append(end);group(tube('microwave_connected_cable',smooth,.0045,rubber),'microwave');cube('r17_microwave_cable_grommet',end,(.016,.02,.02),rubber,'microwave')
def rugs():
 blue=material('r17_modern_ink_blue',(.055,.17,.30),rough=.93);light=material('r17_modern_cloud_blue',(.24,.43,.57),rough=.94)
 for o in list(bpy.data.objects):
  g=o.get('option_group')
  if g=='rug_teal' and 'motif' in o.name:bpy.data.objects.remove(o,do_unlink=True);continue
  if g in ['rug_persian','rug_teal','rug_ochre']:
   c=Vector((2.25,1.35,0));d=Vector((2.30,1.30,0));o.matrix_world=Matrix.Translation(d)@Matrix.Diagonal((3.1/2.5,3.1/2.5,1,1))@Matrix.Translation(-c)@o.matrix_world
   if g=='rug_teal' and 'woven_base' in o.name:assign(o,blue)
 for i in range(8):
  o=cube('r17_modern_rug_broken_stripe',(1.05+i*.34,1.30,.023),(.12,2.40-(i%3)*.21,.001),light if i%2 else blue,'rug_teal',b=0)
 bpy.context.scene['rug_square_m']=3.1;bpy.context.scene['rug_center_m']=[2.30,1.30]
def plants():
 for o in list(bpy.data.objects):
  if o.get('option_group')=='hanging_plants':bpy.data.objects.remove(o,do_unlink=True)
 green=material('r17_pothos_deep_green',(.035,.18,.065),rough=.58);young=material('r17_pothos_leaf_light',(.10,.28,.09),rough=.6);pot=material('r17_plant_pot',(.37,.18,.085),rough=.78)
 # Pots remain on shelf tops; vines descend in front of the shelf edge, never through a shelf.
 for k,(x,y,z) in enumerate([(.12,3.35,2.34),(.44,3.35,1.99)]):
  lathe('r17_hanging_pot',[(.038,0),(.052,.09),(.058,.10),(.052,.104),(.045,.09),(.032,.01)],(x,y,z),pot,'hanging_plants')
  for j in range(3):
   length=.47+.055*j;pts=[]
   for t in range(30):u=t/29;pts.append(Vector((x+(j-1)*.037+.025*math.sin(u*6+j),y-.20*min(1,u/.18),z+.055-.015*min(1,u/.18)-max(0,u-.18)/.82*length)))
   group(tube('r17_pothos_trailing_vine',pts,.0024,green),'hanging_plants')
   for q in range(2,29,3):
    a=pts[q];side=1 if q%2 else -1;b=a+Vector((side*.055,-.025,-.027));leaf('r17_pothos_heart_leaf',a,b,.022,young if q%3==0 else green,'hanging_plants')
for mode in ['morning','night','golden']:
 bpy.ops.wm.open_mainfile(filepath=str(ROOT/('kitchen-'+mode+'.blend')));bpy.context.preferences.filepaths.save_version=0
 if bpy.context.scene.get('revision')=='r17':raise RuntimeError('Already r17; do not apply transforms twice')
 gl=glass();table(gl);fixtures(gl);rugs();plants()
 for o in bpy.data.objects:
  if o.name.startswith('r17_'):
   name='Options / '+o.get('option_group') if o.get('option_group') else 'Cabinets / japandi' if o.get('cabinet_style')=='japandi' else 'Room and fixed objects';c=bpy.data.collections.get(name)
   if c is None:c=bpy.data.collections.new(name);bpy.context.scene.collection.children.link(c)
   for prior in list(o.users_collection):prior.objects.unlink(o)
   c.objects.link(o)
 exec(bpy.data.texts['SELECT-OPTION.py'].as_string());bpy.context.scene['revision']='r17';bpy.context.scene['r17_wood_straight']=True
 bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/('kitchen-'+mode+'.blend')),compress=True)
 print('R17_SAVED',mode,flush=True)
