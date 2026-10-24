import bpy,math
from mathutils import Vector
from appearance import material,wood,tube,assign
def box(n,p,d,m,b=.012):
 bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.name=n;o.dimensions=d;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);assign(o,m)
 if b:mod=o.modifiers.new('rounded_corners','BEVEL');mod.width=b;mod.segments=4
 return o
def turned(n,x,y,height,m,radius=.03):
 prof=[(0,.75),(.025,.9),(.06,1),(.10,.72),(.22,.58),(.34,.72),(.42,1),(.48,.72),(.78,.65),(.90,.9),(1,.9)]
 vs=[(x+radius*r*math.cos(i*math.tau/20),y+radius*r*math.sin(i*math.tau/20),z*height) for z,r in prof for i in range(20)];fs=[]
 for j in range(len(prof)-1):
  for i in range(20):fs.append((j*20+i,j*20+(i+1)%20,(j+1)*20+(i+1)%20,(j+1)*20+i))
 fs += [tuple(reversed(range(20))),tuple(range((len(prof)-1)*20,len(prof)*20))];me=bpy.data.meshes.new(n);me.from_pydata(vs,[],fs);me.update();o=bpy.data.objects.new(n,me);bpy.context.collection.objects.link(o);assign(o,m);return o
def rebuild_furniture():
 for o in list(bpy.data.objects):
  if o.get('option_group')=='table_chairs' or o.name.startswith(('table_','chair_')):bpy.data.objects.remove(o,do_unlink=True)
 before=set(bpy.data.objects);timber=wood('r15_vintage_honey_table',(.43,.22,.085));edge=wood('r15_worn_wood_edges',(.34,.16,.055));x,y=2.65,.55
 box('vintage_square_table_top',(x,y,.755),(.78,.78,.055),timber,.025)
 box('vintage_table_underlip',(x,y,.714),(.745,.745,.025),edge,.012)
 for dx in [-.285,.285]:
  for dy in [-.285,.285]:turned('vintage_table_turned_leg',x+dx,y+dy,.706,edge,.041)
 for side in [-1,1]:
  box('vintage_apron_x',(x,y+side*.30,.65),(.65,.035,.12),timber)
  box('vintage_apron_y',(x+side*.30,y,.65),(.035,.65,.12),timber)
 # Deliberate fine plank marks, without large gaps through the table.
 for dx in [-.19,0,.19]:tube('table_plank_line',[(x+dx,y-.35,.783),(x+dx,y+.35,.783)],.0012,edge)
 for i,(cx,cy,angle) in enumerate([(2.65,-.055,0),(2.02,.55,-math.pi/2),(3.28,.55,math.pi/2)]):
  def tr(p):a,b,z=p;return (cx+a*math.cos(angle)-b*math.sin(angle),cy+a*math.sin(angle)+b*math.cos(angle),z)
  o=box('vintage_chair_'+str(i)+'_wood_seat',tr((0,0,.425)),(.37,.36,.048),timber,.025);o.rotation_euler.z=angle
  for a in [-.135,.135]:
   for b in [-.13,.13]:
    pos=tr((a,b,0));turned('vintage_chair_leg',pos[0],pos[1],.403,edge,.023)
  for a in [-.145,.145]:tube('vintage_chair_backpost',[tr((a,-.145,.36)),tr((a,-.175,.65)),tr((a,-.19,.85))],.020,timber)
  tube('vintage_chair_curved_back',[tr((-.15+j*.30/16,-.19-.015*math.sin(j*math.pi/16),.80+.026*math.sin(j*math.pi/16))) for j in range(17)],.036,timber)
  for a in [-.055,.055]:tube('vintage_chair_back_spindle',[tr((a,-.15,.46)),tr((a,-.185,.785))],.009,timber)
  for b in [-.12,.12]:tube('vintage_chair_stretcher',[tr((-.135,b,.19)),tr((.135,b,.19))],.012,edge)
 for o in set(bpy.data.objects)-before:o['option_group']='table_chairs';o.hide_render=True;o.hide_set(True)
 bpy.context.scene['table_zone_m']='x1.7..3.65;y-.3..1.3;center2.65,.55;3chairs'
def lower_grates():
 # Lower the steel deck and burners together. Compress short feet, preserving
 # physical connections; ring outer top exactly at the900mm countertop.
 root=bpy.data.objects['range_slot_900'];bpy.context.view_layer.update()
 for o in list(root.children_recursive):
  name=o.name
  if name.startswith(('r12_slim_grate_ring_','r12_support_foot_')):
   for sp in o.data.splines:
    for p in sp.points:
     co=o.matrix_world@Vector(p.co[:3]);co.z=.872+(co.z-.922)*(.022/.053);new=o.matrix_world.inverted()@co;p.co=(*new,1)
  elif name.startswith(('grate_x_finger_','grate_y_finger_','grate_center_bridge_','pan_support_')):
   w=o.matrix_world.copy();w.translation.z-=.081;o.matrix_world=w
  elif name.startswith(('hob_','burner_')):
   w=o.matrix_world.copy();w.translation.z-=.050;o.matrix_world=w
 bpy.context.view_layer.update();bpy.context.scene['grate_outer_top_m']=.900;bpy.context.scene['grate_foot_center_height_m']=.022
