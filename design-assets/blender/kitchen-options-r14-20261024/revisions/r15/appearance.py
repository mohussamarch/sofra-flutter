import bpy,math
from mathutils import Vector
def material(n,c,metal=0,rough=.5):
 m=bpy.data.materials.new(n);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough;return m
def assign(o,m):o.data.materials.clear();o.data.materials.append(m)
def bounds(o):
 v=[o.matrix_world@Vector(c) for c in o.bound_box];return Vector([min(p[i] for p in v) for i in range(3)]),Vector([max(p[i] for p in v) for i in range(3)])
def tube(n,pts,r,m):
 c=bpy.data.curves.new(n,'CURVE');c.dimensions='3D';c.bevel_depth=r;c.bevel_resolution=4;sp=c.splines.new('POLY');sp.points.add(len(pts)-1)
 for p,co in zip(sp.points,pts):p.co=(*co,1)
 o=bpy.data.objects.new(n,c);bpy.context.collection.objects.link(o);assign(o,m);return o
def wood(n,c):
 m=material(n,c,rough=.47);nodes=m.node_tree.nodes;l=m.node_tree.links;p=nodes.get('Principled BSDF');pos=nodes.new('ShaderNodeNewGeometry');scale=nodes.new('ShaderNodeVectorMath');scale.operation='MULTIPLY';scale.inputs[1].default_value=(13,13,.6);l.new(pos.outputs['Position'],scale.inputs[0]);noise=nodes.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=3;noise.inputs['Detail'].default_value=2;l.new(scale.outputs[0],noise.inputs['Vector']);r=nodes.new('ShaderNodeValToRGB')
 for e,f in zip(r.color_ramp.elements,[.68,1.20]):e.color=(*[v*f for v in c],1)
 l.new(noise.outputs['Fac'],r.inputs[0]);l.new(r.outputs[0],p.inputs['Base Color']);b=nodes.new('ShaderNodeBump');b.inputs['Strength'].default_value=.16;b.inputs['Distance'].default_value=.0008;l.new(noise.outputs['Fac'],b.inputs['Height']);l.new(b.outputs[0],p.inputs['Normal']);return m
def panels():return [o for o in bpy.data.objects if o.type=='MESH' and o.parent and o.parent.name.startswith(('cabinet_','upper_','pantry_')) and (o.name.endswith('_front') or o.name=='pantry_door')]
def finish_base():
 old=bpy.data.materials['r13_faded_teal_painted_wood'];new=wood('r15_classic_painted_timber',(.23,.34,.245));brass=material('r15_polished_aged_brass',(.48,.29,.095),.88,.22)
 # Replace paint only; historic cream fridge and stone remain exceptions.
 for o in bpy.data.objects:
  for slot in o.material_slots:
   if slot.material==old:slot.material=new
 for o in list(bpy.data.objects):
  if o.name.endswith('_brass_pull'):
   mn,mx=bounds(o);pos=(mn+mx)/2;left=o.parent and o.parent.name.startswith(('cabinet_left','cabinet_sink','cabinet_corner','pantry'))
   axis=Vector((1,0,0)) if left else Vector((0,-1,0));bpy.data.objects.remove(o,do_unlink=True)
   # Shaped vertical spindle and two mounting ends, more legible than tiny knobs.
   pts=[pos+Vector((0,0,z))+axis*depth for z,depth in [(-.055,0),(-.045,.014),(-.03,.022),(0,.027),(.03,.022),(.045,.014),(.055,0)]]
   tube('r15_vintage_pull',pts,.008,brass)
   for z in [-.055,.055]:
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,location=pos+Vector((0,0,z)));p=bpy.context.object;p.name='r15_vintage_rosette';p.scale=(.018,.018,.018);assign(p,brass)
 steel=material('r15_shared_warm_satin_stainless',(.47,.49,.50),.90,.29)
 for o in bpy.data.objects:
  group=o.get('option_group');name=o.name
  if group in ['microwave','double_fridge','builtin'] and o.type in ['MESH','CURVE']:
   if 'glass' not in name and 'recess' not in name and 'hob' not in name and 'cabinet' not in name and 'stone' not in name and 'upstand' not in name:assign(o,steel)
  if name.startswith(('hood_','range_','oven_')):
   for slot in o.material_slots:
    if slot.material and ('steel' in slot.material.name or 'stainless' in slot.material.name or 'hood_metal' in slot.material.name):slot.material=steel
 # Sample stickers, not personalized character artwork. Both doors use same slot.
 colors=[(.88,.34,.16),(.96,.69,.12),(.24,.51,.57)]
 for k,(x,z) in enumerate([(3.01,1.78),(3.43,1.84),(3.47,1.55)]):
  if k==1:points=[(x+(.058 if i%2==0 else .027)*math.sin(i*math.pi/5),2.749,z+(.058 if i%2==0 else .027)*math.cos(i*math.pi/5)) for i in range(10)]
  else:points=[(x+.052*math.cos(i*math.tau/32),2.749,z+.052*math.sin(i*math.tau/32)) for i in range(32)]
  me=bpy.data.meshes.new('sticker');me.from_pydata(points,[],[tuple(range(len(points)))]);me.update();o=bpy.data.objects.new('r15_double_fridge_sample_sticker_'+str(k),me);bpy.context.collection.objects.link(o);assign(o,material('sticker_'+str(k),colors[k],rough=.6));o['option_group']='double_fridge';o.hide_render=True;o.hide_set(True)
 bpy.context.scene['cabinet_styles']=['classic','modern_acrylic_J_pull','japandi_oak'];return steel
def change_style(style):
 if style=='classic':return
 fronts=panels();woodmat=bpy.data.materials['r15_classic_painted_timber'];surf=material('r15_acrylic_soft_cream',(.72,.69,.59),rough=.24) if style=='modern' else wood('r15_japandi_honey_oak',(.56,.34,.15))
 metal=material('r15_japandi_bronze',(.16,.105,.045),.8,.32)
 for o in list(bpy.data.objects):
  if o.name.startswith(('r15_vintage_pull','r15_vintage_rosette')) or any(o.name.startswith(p.name+'_') for p in fronts):bpy.data.objects.remove(o,do_unlink=True)
 for o in bpy.data.objects:
  for slot in o.material_slots:
   if slot.material==woodmat:slot.material=surf
 for p in fronts:
  mn,mx=bounds(p);left=(mx.x-mn.x)<(mx.y-mn.y);w=mx.y-mn.y if left else mx.x-mn.x;h=mx.z-mn.z;u=(mn.y+mx.y)/2 if left else (mn.x+mx.x)/2;z=(mn.z+mx.z)/2;normal=mx.x if left else mn.y;upper=p.name.startswith('upper_')
  def xyz(U,D,Z):return (normal+D,U,Z) if left else (U,normal-D,Z)
  assign(p,surf)
  if style=='modern':
   # Extruded J-pull cross-section: concave curved finger recess is real geometry.
   profile=[(-.028,-h/2),(.008,-h/2),(.008,h/2-.050),(.006,h/2-.040),(.001,h/2-.031),(-.008,h/2-.025),(-.018,h/2-.022),(-.029,h/2-.022),(-.029,h/2),(-.039,h/2),(-.039,-h/2)]
   verts=[xyz(U,D,z+(-Z if upper else Z)) for U in [u-w/2,u+w/2] for D,Z in profile];n=len(profile);faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
   me=bpy.data.meshes.new('J_pull_profile');me.from_pydata(verts,[],faces);me.update();o=bpy.data.objects.new(p.name+'_J_pull',me);bpy.context.collection.objects.link(o);assign(o,surf);p.hide_render=True;p.hide_set(True)
  else:
   Z=z+(-h*.30 if upper else h*.30);tube('japandi_slim_pull',[xyz(u-.065,.024,Z),xyz(u-.050,.042,Z),xyz(u+.050,.042,Z),xyz(u+.065,.024,Z)],.006,metal)
   if p.name=='pantry_door':
    # Limited fluting on pantry alone, keeping the other fronts quiet.
    for i in range(int((w-.06)/.032)):
     U=u-w/2+.04+i*.032;tube('japandi_pantry_flute',[xyz(U,.017,z-h/2+.035),xyz(U,.017,z+h/2-.035)],.007,surf)
 bpy.context.view_layer.update()
