"""Original Sofra composition study. Run with Blender --background --python.
No external models, textures, AI images or product code. Units: meters.
"""
import bpy, math, json, sys
from pathlib import Path
from mathutils import Vector

OUT = Path(sys.argv[sys.argv.index('--') + 1]) if '--' in sys.argv else Path(__file__).parent
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for col in list(bpy.data.collections):
    if col.name != 'Collection': bpy.data.collections.remove(col)
base = bpy.data.collections.get('Collection'); base.name = 'Kitchen'
cols = {'Kitchen': base}
for n in ['Cameras', 'Lights', 'Hotspots']:
    cols[n] = bpy.data.collections.new(n); bpy.context.scene.collection.children.link(cols[n])

def move(obj, collection):
    for c in list(obj.users_collection): c.objects.unlink(obj)
    cols[collection].objects.link(obj)

def mat(name, color, roughness=.7):
    m = bpy.data.materials.new(name); m.diffuse_color = (*color, 1)
    m.use_nodes = True
    p = m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = (*color, 1); p.inputs['Roughness'].default_value = roughness
    return m

M = {n: mat(n,c) for n,c in {
    'wall':(.77,.78,.68), 'floor':(.67,.61,.51), 'tile':(.70,.65,.56),
    'cabinet':(.35,.48,.42), 'front':(.46,.59,.51), 'worktop':(.91,.85,.72),
    'fridge':(.86,.85,.75), 'metal':(.37,.41,.40), 'dark':(.11,.15,.15),
    'window':(.96,.91,.76), 'glass':(.55,.76,.81), 'wood':(.56,.38,.22)
}.items()}

def box(name, loc, size, material, bevel=.035):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o=bpy.context.object; o.name=name; o.dimensions=size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.data.materials.append(M[material])
    if bevel:
        mod=o.modifiers.new('soft_block_edges','BEVEL'); mod.width=bevel; mod.segments=3
        o.modifiers.new('weighted_corner_normals','WEIGHTED_NORMAL')
    return o

def cyl(name, loc, radius, depth, material, rotation=None):
    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=radius, depth=depth, location=loc)
    o=bpy.context.object; o.name=name; o.data.materials.append(M[material])
    if rotation: o.rotation_euler=rotation
    b=o.modifiers.new('rounded_edge','BEVEL'); b.width=.015; b.segments=2
    o.modifiers.new('weighted_normals','WEIGHTED_NORMAL')
    return o

# Revision 02: exact orthographic isometry, modular 600 mm kitchen.
MODULE=.60
DEPTH=.60
TOP=.90
W,H=4.2,3.6
box('floor_plinth',(W/2,H/2,-.09),(W+.16,H+.16,.18),'floor',.04)
for i in range(7):
    for j in range(6):
        box('tile_%d_%d'%(i,j),(.3+i*.6,.3+j*.6,.005),(.592,.592,.018),'tile',.004)
box('wall_back',(W/2,H+.06,1.35),(W+.12,.12,2.7),'wall',.012)
# Window opening from y=1.35..2.85; pantry ends at1.2, never overlaps.
box('wall_left_low',(-.06,H/2,.55),(.12,H,1.1),'wall',.01)
box('wall_left_high',(-.06,H/2,2.55),(.12,H,.3),'wall',.01)
box('wall_left_front',(-.06,.675,1.75),(.12,1.35,1.3),'wall',.01)
box('wall_left_rear',(-.06,3.225,1.75),(.12,.75,1.3),'wall',.01)
for y in [1.35,2.85]: box('window_side',(0,y,1.75),(.10,.05,1.3),'window',.01)
for z in [1.1,2.4]: box('window_horizontal',(0,2.1,z),(.1,1.55,.05),'window',.01)
box('window_mullion',(0,2.1,1.75),(.08,.04,1.28),'window',.008)
box('window_crossbar',(0,2.1,1.78),(.08,1.48,.04),'window',.008)
box('window_sill',(.05,2.1,1.08),(.26,1.65,.065),'worktop',.012)

modules=[]
def root(name,loc,children):
    bpy.ops.object.empty_add(type='PLAIN_AXES',location=loc)
    o=bpy.context.object; o.name=name; o.empty_display_size=.12
    for child in children:
        world=child.matrix_world.copy(); child.parent=o; child.matrix_world=world
    return o

def cabinet(name,x,y,side='back',width=.6):
    kids=[box(name+'_body',(x,y,.45),(width if side=='back' else .6,.6 if side=='back' else width,.82),'cabinet',.018)]
    if side=='back':
        kids += [box(name+'_front',(x,y-.314,.47),(width-.018,.028,.76),'front',.012),box(name+'_handle',(x,y-.34,.76),(.20,.03,.025),'metal',.008)]
    else:
        kids += [box(name+'_front',(x+.314,y,.47),(.028,width-.018,.76),'front',.012),box(name+'_handle',(x+.34,y,.76),(.03,.20,.025),'metal',.008)]
    kids += [box(name+'_top',(x,y,.88),(width if side=='back' else .6,.6 if side=='back' else width,.04),'worktop',.012)]
    r=root(name,(x,y,0),kids); r['width_m']=width; r['depth_m']=.6; r['style']='simple_blockout'
    modules.append({'id':name,'center_m':[x,y],'width_m':width,'depth_m':.6,'side':side})
    return r

# Right to left: fridge900, cabinet600, range900, cabinet600,cabinet600,corner600.
cabinet('cabinet_fridge_buffer_600',3.0,3.3)
cabinet('cabinet_prep_600',1.5,3.3)
cabinet('cabinet_back_600',.9,3.3)
cabinet('cabinet_corner_600',.3,3.3,side='left')
for name,y in [('cabinet_left_rear_600',2.7),('cabinet_sink_600',2.1),('cabinet_left_front_600',1.5),('cabinet_left_end_600',.9)]:
    cabinet(name,.3,y,side='left')
# Upper cabinets only on back wall; no tall or upper unit masks the window.
for name,x in [('upper_prep_600',1.5),('upper_back_600',.9),('upper_buffer_600',3.0)]:
    kids=[box(name+'_body',(x,3.44,1.97),(.59,.32,.72),'cabinet',.02),box(name+'_front',(x,3.268,1.97),(.57,.025,.69),'front',.012),box(name+'_handle',(x,3.245,1.69),(.18,.025,.02),'metal',.008)]
    root(name,(x,3.6,1.61),kids)

# Sink faces into room from left counter, directly centered under left window.
sinkkids=[box('sink_rim',(.3,2.1,.92),(.45,.51,.025),'metal',.035),box('sink_basin',(.3,2.1,.936),(.35,.41,.015),'dark',.04)]
sinkkids += [cyl('tap_stem',(.08,2.1,1.07),.022,.29,'metal'),cyl('tap_spout',(.18,2.1,1.20),.022,.23,'metal',(0,math.pi/2,0))]
root('sink_root',(.3,2.1,.9),sinkkids)

# 900 mm freestanding range; future built-in variant uses same900mm bay.
sx,sy=2.25,3.3
kids=[box('stove_body',(sx,sy,.44),(.89,.60,.84),'fridge',.02),box('stove_top',(sx,sy,.89),(.9,.6,.045),'dark',.018),box('oven_window',(sx,2.985,.43),(.69,.025,.43),'dark',.025),box('oven_handle',(sx,2.95,.72),(.62,.045,.035),'metal',.012)]
for dx in [-.26,0,.26]:
    for dy in [-.16,.16]: kids.append(cyl('burner',(sx+dx,sy+dy,.922),.080,.012,'metal'))
r=root('range_slot_900',(sx,sy,0),kids); r['width_m']=.9; r['depth_m']=.6
root('hood_root',(sx,3.6,1.8),[box('hood',(sx,3.38,1.85),(.9,.44,.12),'fridge',.025),box('hood_duct',(sx,3.47,2.18),(.26,.25,.55),'fridge',.018)])

# Tall fridge stays at right end;900mm bay reserves upgrade capacity.
fx,fy=3.75,3.24
fridgekids=[box('fridge_body',(fx,fy,1.05),(.88,.72,2.06),'fridge',.04)]
for name,z,h in [('freezer_door',1.70,.63),('fridge_door',.69,1.34)]:
    o=box(name,(fx,2.842,z),(.85,.085,h),'fridge',.026)
    hinge=Vector((fx-.425,2.842,z)); shift=o.location-hinge
    for v in o.data.vertices: v.co+=shift
    o.location=hinge
    handle=box(name+'_handle',(fx+.31,2.775,z),(.03,.045,min(.35,h*.5)),'metal',.012)
    world=handle.matrix_world.copy(); handle.parent=o; handle.matrix_world=world
    fridgekids.append(o)
root('fridge_slot_900',(fx,fy,0),fridgekids)

# Pantry is outside aperture footprint and kept below window's projected foreground.
root('pantry_slot_600',(.3,.3,0),[box('pantry_body',(.3,.3,1.05),(.6,.6,2.06),'cabinet',.022),box('pantry_door',(.617,.3,1.06),(.035,.57,1.98),'front',.018),box('pantry_handle',(.65,.1,1.08),(.025,.03,.25),'metal',.01)])
box('preparation_board',(1.5,3.27,.932),(.38,.30,.035),'wood',.025)

for name,loc in [('hotspot_fridge',(fx,2.76,.69)),('hotspot_freezer',(fx,2.76,1.7)),('hotspot_pantry',(.66,.3,1.08))]:
    bpy.ops.object.empty_add(type='CUBE',location=loc)
    o=bpy.context.object; o.name=name; o.empty_display_size=.15; move(o,'Hotspots')

target=Vector((2.1,1.8,1.10))
bpy.ops.object.camera_add(location=target+Vector((8,-8,8)))
cam=bpy.context.object; cam.name='cam_kitchen_iso'
cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
cam.data.type='ORTHO'; cam.data.ortho_scale=6.9; move(cam,'Cameras')
scene=bpy.context.scene; scene.camera=cam
bpy.ops.object.light_add(type='AREA',location=(1,-2,6))
o=bpy.context.object; o.name='morning_softbox'; o.data.energy=450; o.data.shape='DISK'; o.data.size=4
o.rotation_euler=(Vector((2,2,0))-o.location).to_track_quat('-Z','Y').to_euler(); move(o,'Lights')
bpy.ops.object.light_add(type='SUN',location=(-4,0,6))
o=bpy.context.object; o.name='morning_window_sun'; o.data.energy=2; o.data.angle=math.radians(3)
o.rotation_euler=Vector((1.5,.5,-1.4)).to_track_quat('-Z','Y').to_euler(); move(o,'Lights')
scene.world.color=(.32,.36,.40)
scene.render.engine='CYCLES'; scene.cycles.samples=32; scene.cycles.use_denoising=True
scene.render.resolution_x=1400; scene.render.resolution_y=1400; scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'; scene.view_settings.view_transform='AgX'
scene.render.filepath=str(OUT/'kitchen-modular-r02.png')
scene['stage']='modular composition r02; visual approval pending'
scene['module_m']=.6; scene.unit_settings.system='METRIC'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'sofra-kitchen-modular-r02.blend'))
bpy.ops.render.render(write_still=True)
bpy.ops.export_scene.gltf(filepath=str(OUT/'sofra-kitchen-modular-r02.glb'),export_format='GLB',export_cameras=True,export_lights=False)
manifest={'revision':2,'stage':'composition-only','blender':bpy.app.version_string,'module_m':.6,'depth_m':.6,'room_m':[W,H], 'camera':{'id':cam.name,'projection':'orthographic','target':list(target),'offset':[8,-8,8],'azimuth_deg':45,'elevation_deg':35.26438968},'base_modules':modules,'appliance_bays':[{'id':'range_slot_900','width_m':.9,'depth_m':.6},{'id':'fridge_slot_900','width_m':.9,'depth_m':.72},{'id':'pantry_slot_600','width_m':.6,'depth_m':.6}],'window':{'wall':'left','center_y_m':2.1,'opening_y_m':[1.35,2.85],'opening_z_m':[1.1,2.4]},'sink_center_y_m':2.1,'pantry_y_max_m':.6,'future_customization':{'implemented_in_app':False,'requested':['fridge sizes and models','freestanding or built-in hob/oven with continued cabinets','cabinet colors and styles','floor materials','window size and curtain','optional backsplash','optional under-cabinet LED'],'style_choices':{'classic':'requested','sleek_modern':'requested','third':'undecided; propose shaker'}} ,'animation_implemented':False,'runtime_test':False,'notes':['Room dimensions are composition proposal, not user real kitchen.','600mm generic module; fridge depth is explicit720mm exception, range width900mm.','Parent roots/material names provide authoring structure only; no working app customization yet.','GLB lighting differs from Blender; validate renderer later.']}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
print('SOFRA_MODULAR_R02_COMPLETE')
