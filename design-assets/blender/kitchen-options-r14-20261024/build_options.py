import bpy,sys,math,json
from pathlib import Path
from mathutils import Vector
out=Path(__file__).parent;sys.path.insert(0,str(out));from common import *
bpy.ops.wm.open_mainfile(filepath=str(out/'base-geometry.blend'))
wood=bpy.data.materials['r13_faded_teal_painted_wood'];stone=bpy.data.materials['worktop'];steel=mat('r14_modern_satin_steel',(.44,.51,.56),.27,.82);dark=mat('r14_appliance_blackglass',(.018,.035,.045),.18,.25);ivory=mat('r14_ivory',(.86,.79,.65),.55);timber=mat('r14_table_honey_wood',(.36,.19,.075),.6);iron=bpy.data.materials['r06_cast_iron'];brass=bpy.data.materials['r06_muted_brass']
def cylinder(n,loc,r,h,m):
 bpy.ops.mesh.primitive_cylinder_add(vertices=24,radius=r,depth=h,location=loc);o=bpy.context.object;o.name=n;assign(o,m);b=o.modifiers.new('soft_rounding','BEVEL');b.width=.004;b.segments=3;return o

def group(name,fn):
 before=set(bpy.data.objects);fn();members=set(bpy.data.objects)-before
 for o in members:o['option_group']=name;o.hide_render=True;o.hide_set(True)
 return sorted(o.name for o in members)
def tagtree(root,name):
 for o in [root]+list(root.children_recursive):o['option_group']=name

tagtree(bpy.data.objects['fridge_slot_900'],'default_fridge');tagtree(bpy.data.objects['range_slot_900'],'default_range');tagtree(bpy.data.objects['curtain_root_optional'],'default_curtain')
for n in ['counter_continuous_L','counter_right_buffer','stone_upstand_back_left','stone_upstand_back_right']:bpy.data.objects[n]['option_group']='default_counter'
# Diagonal microwave: its front normal points exactly toward isometric camera XY.
def microwave():
 bpy.ops.object.empty_add(type='PLAIN_AXES',location=(.48,3.10,.91));root=bpy.context.object;root.name='microwave_root';root.rotation_euler.z=math.pi/4
 def part(n,p,d,m):
  o=box(n,p,d,m,.015);o.parent=root;o.location=p;return o
 part('microwave_body',(0,0,.16),(.53,.40,.32),ivory);part('microwave_front_glass',(-.045,-.207,.17),(.36,.018,.22),dark);part('microwave_right_panel',(.207,-.212,.17),(.082,.025,.22),steel)
 for i in range(3):part('microwave_button_'+str(i),(.205,-.230,.10+i*.055),(.025,.01,.014),brass)
 part('microwave_handle',(.107,-.235,.17),(.018,.025,.17),steel)
 # Tiny neutral display, no invented operational state.
 part('microwave_display',(.205,-.230,.25),(.052,.008,.022),dark)
# Generic modern side-by-side design, no brand/logo or brand model claim.
def doublefridge():
 x,y=3.27,3.20
 box('double_fridge_body',(x,y,1.075),(1.10,.76,2.15),steel,.045)
 for i,dx in enumerate([-.272,.272]):
  box('double_fridge_door_'+str(i),(x+dx,y-.405,1.09),(.532,.075,2.04),steel,.025)
  box('double_fridge_handle_'+str(i),(x+(-.042 if i==0 else .042),y-.465,1.25),(.023,.04,.60),dark,.01)
 box('double_fridge_water_recess',(x-.285,y-.45,1.18),(.20,.015,.29),dark,.015);box('double_fridge_dispenser_lip',(x-.285,y-.48,1.04),(.20,.07,.025),steel,.008)
# Hanging plants are optional and distinct from removed default pot.
def hanging():
 green=mat('r14_hanging_leaf',(.13,.34,.08),.7);pot=mat('r14_hanging_pot',(.59,.27,.14),.65)
 for k,(x,y,z) in enumerate([(.16,3.39,2.338),(.47,3.37,1.988),(.26,.28,2.09)]):
  cylinder('hanging_pot_'+str(k),(x,y,z+.055),.065,.11,pot)
  for stem in range(3):
   pts=[]
   for j in range(12):
    t=j/11;px=x+.045*math.sin(t*6+stem*2);py=y-.05-.10*t;pz=z+.055-.36*t;pts.append((px,py,pz))
   tube('hanging_vine_'+str(k)+'_'+str(stem),pts,.003,green)
   for j in range(1,6):
    t=j/6;px=x+.045*math.sin(t*6+stem*2);py=y-.05-.10*t;pz=z+.055-.36*t
    o=sphere('hanging_leaf_'+str(k)+'_'+str(stem)+'_'+str(j),(px+(-1 if j%2 else 1)*.025,py,pz),(.037,.012,.025),green);o.rotation_euler.y=(-1 if j%2 else 1)*.6
# White office-style slatted blind, removable alternative to curtain/rod.
def blind():
 white=mat('r14_white_blind',(.88,.87,.80),.75);box('blind_headrail',(.11,2.1,2.39),(.11,1.30,.065),white,.01)
 for i in range(16):
  o=box('blind_slat_'+str(i),(.12,2.1,2.29-i*.064),(.065,1.20,.017),white,.004);o.rotation_euler.y=math.radians(32)
 for y in [1.65,2.55]:tube('blind_cord_'+str(y),[(.147,y,2.31),(.147,y,1.29)],.0025,ivory)
 tube('blind_pull_cord',[(.14,2.77,2.36),(.14,2.77,1.30)],.003,ivory);sphere('blind_pull',(.14,2.77,1.28),(.011,.011,.024),ivory)
# Vintage rugs: original flat woven motifs and actual fringe on both short ends.
def patch(n,pts,m,z=.043):
 mesh=bpy.data.meshes.new(n);mesh.from_pydata([(x,y,z) for x,y in pts],[],[tuple(range(len(pts)))]);mesh.update();o=bpy.data.objects.new(n,mesh);bpy.context.collection.objects.link(o);assign(o,m);return o

def rug(style):
 colors={'persian':((.25,.022,.035),(.68,.41,.18),(.80,.65,.39)),'teal':((.035,.17,.21),(.25,.52,.47),(.83,.65,.37)),'ochre':((.60,.30,.065),(.29,.13,.075),(.91,.72,.37))};c,bc,mc=colors[style];base=mat('rug_'+style+'_body',c,.95);border=mat('rug_'+style+'_border',bc,.95);motif=mat('rug_'+style+'_motif',mc,.95);x,y=1.75,1.38;W,H=.95,1.65
 box('rug_'+style+'_woven',(x,y,.028),(W,H,.024),base,.008)
 for dx in [-W/2+.04,W/2-.04]:box('rug_'+style+'_sideborder_'+str(dx),(x+dx,y,.041),(.025,H-.05,.002),border,.001)
 for dy in [-H/2+.04,H/2-.04]:box('rug_'+style+'_endborder_'+str(dy),(x,y+dy,.041),(W-.05,.025,.002),border,.001)
 for i in range(3):
  cy=y+(i-1)*.44
  if style!='ochre':
   patch('rug_'+style+'_diamond_'+str(i),[(x-.25,cy),(x,cy-.18),(x+.25,cy),(x,cy+.18)],motif)
   patch('rug_'+style+'_center_'+str(i),[(x-.12,cy),(x,cy-.095),(x+.12,cy),(x,cy+.095)],base,z=.044)
  else:
   for j in range(8):
    a=j*math.tau/8;px=x+.14*math.cos(a);py=cy+.14*math.sin(a)
    patch('rug_ochre_petal_'+str(i)+'_'+str(j),[(px-.055,py),(px,py-.07),(px+.055,py),(px,py+.07)],motif)
   patch('rug_ochre_center_'+str(i),[(x-.06,cy),(x,cy-.06),(x+.06,cy),(x,cy+.06)],border,z=.044)
 if style=='persian':
  for side in [-1,1]:
   for j in range(5):
    cy=y+(j-2)*.27;xx=x+side*.34
    patch('rug_persian_triangle_'+str(side)+'_'+str(j),[(xx,cy-.06),(xx,cy+.06),(xx-side*.08,cy)],motif)
 for side in [-1,1]:
  for j in range(25):
   xx=x-W/2+.025+j*(W-.05)/24;yy=y+side*H/2;tube('rug_'+style+'_fringe_'+str(side)+'_'+str(j),[(xx,yy,.027),(xx+.005*math.sin(j),yy+side*.055,.021)],.0025,ivory)
# Built-in hob + oven below, with a continuous stone surround and sink opening.
def builtin():
 box('builtin_cabinet_body',(1.65,3.30,.45),(.90,.60,.82),wood,.012);box('builtin_oven_frame',(1.65,2.978,.46),(.77,.035,.62),steel,.012);box('builtin_oven_glass',(1.65,2.95,.45),(.66,.018,.43),dark,.012);box('builtin_oven_handle',(1.65,2.916,.70),(.51,.035,.025),steel,.01)
 for x in [1.42,1.88]:sphere('builtin_oven_knob_'+str(x),(x,2.925,.75),(.025,.014,.025),steel)
 # Continuous L outline extends through former range gap.
 poly=[(0,.6),(.6,.6),(.6,3.0),(2.7,3.0),(2.7,3.6),(0,3.6)];N=len(poly);vs=[(a,b,z) for z in [.86,.90] for a,b in poly];fs=[tuple(reversed(range(N))),tuple(range(N,2*N))]+[(i,(i+1)%N,(i+1)%N+N,i+N) for i in range(N)];mesh=bpy.data.meshes.new('builtin_continuous_stone');mesh.from_pydata(vs,[],fs);mesh.update();obj=bpy.data.objects.new('builtin_continuous_stone',mesh);bpy.context.collection.objects.link(obj);assign(obj,stone)
 for name,loc,dim,bev in [('sink',(.32,2.1,.86),(.438,.478,.34),.045),('hob',(1.65,3.3,.88),(.80,.48,.30),.018)]:
  cut=box('temporary_'+name,loc,dim,stone,bev);bpy.context.view_layer.objects.active=cut
  for mod in list(cut.modifiers):bpy.ops.object.modifier_apply(modifier=mod.name)
  bpy.context.view_layer.objects.active=obj;mod=obj.modifiers.new('real_'+name+'_cutout','BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=cut;bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cut,do_unlink=True)
 be=obj.modifiers.new('stone_edge','BEVEL');be.width=.005;be.segments=3
 box('builtin_black_hob',(1.65,3.30,.907),(.83,.51,.025),dark,.018)
 for ix,iy in [(-1,-1),(-1,1),(1,-1),(1,1)]:
  x,y=1.65+ix*.215,3.3+iy*.13
  for r in [.072,.082]:tube('builtin_hob_ring_'+str(ix)+'_'+str(iy)+'_'+str(r),[(x+r*math.cos(a),y+r*math.sin(a),.922) for a in [i*math.tau/48 for i in range(48)]],.0015,steel,True)
 box('builtin_upstand',(1.35,3.577,.96),(2.7,.046,.12),stone,.005)
# Simple square wood dining table with exactly three seats.
def furniture():
 x,y=1.95,1.45;box('table_square_top',(x,y,.75),(.72,.72,.055),timber,.035)
 for dx in [-.27,.27]:
  for dy in [-.27,.27]:box('table_leg_'+str(dx)+'_'+str(dy),(x+dx,y+dy,.375),(.045,.045,.70),timber,.01)
 for i,(cx,cy,a) in enumerate([(1.95,.77,0),(1.27,1.45,-math.pi/2),(2.63,1.45,math.pi/2)]):
  bpy.ops.object.empty_add(type='PLAIN_AXES',location=(cx,cy,0));root=bpy.context.object;root.name='chair_'+str(i)+'_root';root.rotation_euler.z=a
  def part(n,p,d,m):
   o=box(n,p,d,m,.016);o.parent=root;o.location=p;return o
  part('chair_'+str(i)+'_seat',(0,0,.43),(.38,.38,.045),ivory)
  for dx in [-.14,.14]:
   for dy in [-.14,.14]:part('chair_'+str(i)+'_leg_'+str(dx)+'_'+str(dy),(dx,dy,.21),(.035,.035,.42),timber)
  for dx in [-.15,.15]:part('chair_'+str(i)+'_backpost_'+str(dx),(dx,-.16,.61),(.035,.035,.41),timber)
  part('chair_'+str(i)+'_back',(0,-.16,.76),(.34,.035,.12),timber)

registry={}
for name,fn in [('microwave',microwave),('double_fridge',doublefridge),('hanging_plants',hanging),('white_blind',blind),('rug_persian',lambda:rug('persian')),('rug_teal',lambda:rug('teal')),('rug_ochre',lambda:rug('ochre')),('builtin',builtin),('table_chairs',furniture)]:registry[name]=group(name,fn)
bpy.context.scene['stage']='r14 optional asset library, all alternatives hidden by default; not runtime-ready'
bpy.context.scene.render.filepath='//renders/base--morning.png'
bpy.ops.wm.save_as_mainfile(filepath=str(out/'options-library.blend'));(out/'option-groups.json').write_text(json.dumps(registry,indent=2));print('OPTION_LIBRARY_READY',list(registry))
