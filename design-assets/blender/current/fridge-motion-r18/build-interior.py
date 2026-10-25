import bpy,sys,math,json
from pathlib import Path
from mathutils import Vector
ROOT=Path('E:/work/SOFRA/app/design-assets/blender/current')
sys.path.insert(0,str(ROOT.parent/'kitchen-options-r14-20261024/revisions/r15'))
from appearance import material,assign,tube
from furniture import box
def mark(o,role='fixed',parent=None):
 o['option_group']='default_fridge';o['fridge_role']=role
 if parent:
  w=o.matrix_world.copy();o.parent=parent;o.matrix_world=w
 return o
def cube(n,p,d,m,b=.008,role='fixed',parent=None):return mark(box(n,p,d,m,b),role,parent)
for mode in ['morning','night','golden']:
 bpy.ops.wm.open_mainfile(filepath=str(ROOT/('kitchen-'+mode+'.blend')));bpy.context.preferences.filepaths.save_version=0
 if bpy.context.scene.get('r18_fridge_interior'):raise RuntimeError('Interior already built; edit existing master instead')
 root=bpy.data.objects['fridge_slot_900'];old=bpy.data.objects['fridge_body'];cream=old.data.materials[0];bpy.data.objects.remove(old,do_unlink=True)
 liner=material('r18_warm_white_fridge_liner',(.60,.62,.58),rough=.42);seal=material('r18_fridge_gasket',(.20,.21,.19),rough=.78);metal=material('r18_fridge_shelf_edge',(.53,.57,.58),metal=.70,rough=.24)
 glass=material('r18_fridge_tempered_glass',(.79,.91,.92),rough=.12);p=glass.node_tree.nodes.get('Principled BSDF');p.inputs['Transmission Weight'].default_value=1;p.inputs['IOR'].default_value=1.46
 # A hollow shell, not an open door placed in front of the old solid block.
 for n,p,d in [('left',(2.735,3.24,1.05),(.05,.72,2.06)),('right',(3.565,3.24,1.05),(.05,.72,2.06)),('top',(3.15,3.24,2.055),(.88,.72,.05)),('bottom',(3.15,3.24,.045),(.88,.72,.05)),('back',(3.15,3.575,1.05),(.80,.05,2.00))]:cube('r18_fridge_outer_'+n,p,d,cream,.018,parent=root)
 for n,p,d in [('left',(2.772,3.23,1.05),(.018,.62,1.94)),('right',(3.528,3.23,1.05),(.018,.62,1.94)),('back',(3.15,3.535,1.05),(.75,.018,1.94)),('top',(3.15,3.23,2.017),(.75,.62,.018)),('bottom',(3.15,3.23,.084),(.75,.62,.018)),('freezer_divider',(3.15,3.22,1.378),(.75,.64,.042))]:cube('r18_fridge_liner_'+n,p,d,liner,.006,parent=root)
 # Thin glass shelves, recessed enough to clear the door bins when closed.
 for i,z in enumerate([.37,.72,1.06]):
  cube('r18_fridge_glass_shelf_'+str(i),(3.15,3.27,z),(.724,.45,.008),glass,.004,parent=root)
  cube('r18_fridge_shelf_front_'+str(i),(3.15,3.043,z),(.726,.010,.012),metal,.003,parent=root)
  for x in [2.795,3.505]:cube('r18_shelf_support',(x,3.28,z-.014),(.018,.35,.016),liner,.004,parent=root)
 # Empty produce drawers; inventory remains application data.
 for x in [2.968,3.332]:
  cube('r18_produce_bin_floor',(x,3.28,.115),(.338,.39,.009),glass,.004,parent=root)
  cube('r18_produce_bin_front',(x,3.08,.223),(.338,.012,.215),glass,.008,parent=root)
  for dx in [-.166,.166]:cube('r18_produce_bin_side',(x+dx,3.28,.223),(.009,.39,.215),glass,.004,parent=root)
  cube('r18_produce_bin_lip',(x,3.07,.333),(.338,.018,.014),liner,.004,parent=root)
 hinges={}
 for name,z0,z1 in [('fridge',.02,1.36),('freezer',1.385,2.015)]:
  door=bpy.data.objects[name+'_door'];bpy.ops.object.empty_add(type='PLAIN_AXES',location=(2.725,2.842,z0));h=bpy.context.object;h.name='r18_'+name+'_hinge';mark(h,'hinge',root);hinges[name]=h
  w=door.matrix_world.copy();door.parent=h;door.matrix_world=w;door['fridge_role']=name+'_door'
  if name=='fridge':
   for handle in [o for o in bpy.data.objects if o.name.startswith('fridge_door_handle')]:
    w=handle.matrix_world.copy();handle.parent=h;handle.matrix_world=w
  cube('r18_'+name+'_door_inner',(3.15,2.895,(z0+z1)/2),(.71,.015,z1-z0-.07),liner,.018,name+'_door',h)
  for x in [2.78,3.52]:cube('r18_'+name+'_seal_vertical',(x,2.891,(z0+z1)/2),(.016,.015,z1-z0-.035),seal,.006,name+'_door',h)
  for z in [z0+.025,z1-.025]:cube('r18_'+name+'_seal_horizontal',(3.15,2.891,z),(.75,.015,.016),seal,.006,name+'_door',h)
  if name=='fridge':
   for z in [.29,.65,1.03]:
    cube('r18_door_bin_floor',(3.15,2.945,z),(.65,.09,.009),glass,.005,'fridge_door',h)
    cube('r18_door_bin_guard',(3.15,2.990,z+.055),(.65,.012,.11),glass,.006,'fridge_door',h)
    for x in [2.831,3.469]:cube('r18_door_bin_side',(x,2.945,z+.055),(.012,.09,.11),liner,.004,'fridge_door',h)
 # A real, fixed internal lamp. Door occlusion reveals it naturally; no frame-to-frame energy change.
 emitter=material('r18_fridge_lamp_diffuser',(.87,.88,.78),rough=.45);p=emitter.node_tree.nodes.get('Principled BSDF');p.inputs['Emission Color'].default_value=(1,.92,.80,1);p.inputs['Emission Strength'].default_value=1.5
 for z in [1.345,1.995]:
  cube('r18_fridge_inner_light_strip',(3.15,3.27,z),(.52,.18,.009),emitter,.006,parent=root)
  bpy.ops.object.light_add(type='AREA',location=(3.15,3.27,z-.012));o=bpy.context.object;o.name='r18_fridge_inner_light';o.data.energy=2.0;o.data.color=(1,.93,.83);o.data.shape='RECTANGLE';o.data.size=.48;o.data.size_y=.14;mark(o,'fixed',root)
 # Put new objects in a named collection; never save an extra .blend for the open pose.
 c=bpy.data.collections.get('Fridge / interior and hinges') or bpy.data.collections.new('Fridge / interior and hinges')
 if c.name not in bpy.context.scene.collection.children:bpy.context.scene.collection.children.link(c)
 for o in bpy.data.objects:
  if o.name.startswith('r18_'):
   for prior in list(o.users_collection):prior.objects.unlink(o)
   c.objects.link(o)
 script='''import bpy,math
def set_fridge_open(degrees=0,freezer_degrees=None):
 bpy.data.objects['r18_fridge_hinge'].rotation_euler.z=-math.radians(degrees)
 bpy.data.objects['r18_freezer_hinge'].rotation_euler.z=-math.radians(degrees if freezer_degrees is None else freezer_degrees)
 bpy.context.view_layer.update()
set_fridge_open(0)
'''
 t=bpy.data.texts.get('SET-FRIDGE-DOORS.py') or bpy.data.texts.new('SET-FRIDGE-DOORS.py');t.clear();t.write(script)
 exec(bpy.data.texts['SELECT-OPTION.py'].as_string());exec(script);bpy.context.scene['r18_fridge_interior']=True
 bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/('kitchen-'+mode+'.blend')),compress=True);print('INTERIOR_READY',mode,flush=True)
