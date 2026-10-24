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

# Open-front cutaway, rear + left walls only. Window is an actual aperture.
box('floor_plinth',(0,0,-.14),(6.4,5.2,.28),'floor',.08)
for ix in range(8):
    for iy in range(7):
        box('floor_tile_%02d_%02d'%(ix,iy),(-2.79+ix*.8,-2.2+iy*.72,.012),(.785,.705,.025),'tile',.008)
box('wall_back',(0,2.52,1.62),(6.4,.16,3.24),'wall',.02)
box('wall_left_low',(-3.12,0,.65),(.16,5.2,1.3),'wall',.02)
box('wall_left_high',(-3.12,0,3.04),(.16,5.2,.4),'wall',.02)
box('wall_left_rear',(-3.12,1.85,2.07),(.16,1.5,1.54),'wall',.02)
box('wall_left_front',(-3.12,-2.05,2.07),(.16,1.1,1.54),'wall',.02)
# Window frame, no glass so morning light reaches floor without heavy shaders.
for y in [-1.48,1.08]: box('window_frame_side',(-3.02,y,2.07),(.18,.08,1.56),'window',.015)
for z in [1.32,2.82]: box('window_frame_horizontal',(-3.02,-.2,z),(.18,2.64,.08),'window',.015)
box('window_mullion',(-3.02,-.2,2.07),(.14,.065,1.5),'window',.01)
box('window_crossbar',(-3.02,-.2,2.13),(.14,2.58,.055),'window',.01)
box('window_sill',(-2.94,-.2,1.29),(.48,2.88,.12),'worktop',.025)

# L-shaped run keeps open central circulation and distinct storage silhouettes.
for i,x in enumerate([-1.7,-.65,.4]):
    box('base_cabinet_%d'%i,(x,1.98,.52),(1.02,.88,.96),'cabinet')
    box('base_front_%d'%i,(x,1.517,.55),(.97,.055,.86),'front',.025)
    box('base_handle_%d'%i,(x,1.472,.88),(.30,.045,.035),'metal',.012)
box('counter_back',(-.65,1.96,1.04),(3.24,1.04,.13),'worktop')
for i,y in enumerate([.83,-.2]):
    box('left_cabinet_%d'%i,(-2.56,y,.52),(.92,1,.96),'cabinet')
    box('left_front_%d'%i,(-2.077,y,.55),(.05,.94,.86),'front',.025)
    box('left_handle_%d'%i,(-2.035,y,.88),(.04,.30,.035),'metal',.01)
box('counter_left',(-2.55,.32,1.04),(1.04,2.12,.13),'worktop')
for i,x in enumerate([-1.7,-.65]):
    box('upper_cabinet_%d'%i,(x,2.19,2.37),(1.01,.48,.85),'cabinet')
    box('upper_front_%d'%i,(x,1.935,2.37),(.96,.045,.79),'front',.025)
    box('upper_handle_%d'%i,(x,1.9,2.1),(.22,.04,.03),'metal',.01)
# Sink inset represented as nested blocks in this composition study.
box('sink_rim',(-1.63,1.93,1.12),(.76,.65,.055),'metal',.06)
box('sink_basin',(-1.63,1.93,1.15),(.60,.49,.03),'dark',.07)
cyl('tap_stem',(-1.63,2.29,1.31),.035,.40,'metal')
cyl('tap_spout',(-1.63,2.16,1.50),.035,.28,'metal',(math.pi/2,0,0))
# Cooker on the right of the work run, leaving preparation surface between it and sink.
box('stove_body',(1.23,1.97,.54),(.82,.90,1.02),'fridge')
box('stove_top',(1.23,1.96,1.08),(.86,.94,.08),'dark',.025)
box('oven_window',(1.23,1.496,.52),(.63,.035,.48),'dark')
box('oven_handle',(1.23,1.44,.83),(.55,.07,.045),'metal',.015)
for x in [.99,1.47]:
    for y in [1.72,2.18]: cyl('burner',(x,y,1.135),.135,.015,'metal')
box('hood',(1.23,2.20,2.20),(1.02,.60,.20),'fridge')
box('hood_duct',(1.23,2.34,2.63),(.34,.30,.70),'fridge')
# Independent freezer and fridge door blocks. Origins at left-hand hinges.
box('fridge_body',(2.35,1.93,1.30),(1.06,1.05,2.56),'fridge',.07)
for name,z,h in [('freezer_door',2.13,.79),('fridge_door',.93,1.55)]:
    o=box(name,(2.35,1.375,z),(1.0,.12,h),'fridge',.045)
    hinge=Vector((1.85,1.375,z)); shift=o.location-hinge
    for v in o.data.vertices: v.co+=shift
    o.location=hinge
    box(name+'_handle',(2.70,1.27,z),(.045,.07,min(.48,h*.5)),'metal',.02)
# Dry-food pantry, distinct from the rear fridge, at open end of left run.
box('pantry_body',(-2.52,-1.33,1.22),(.98,.90,2.40),'cabinet')
box('pantry_door',(-2.00,-1.33,1.24),(.07,.84,2.24),'front',.035)
box('pantry_handle',(-1.94,-1.62,1.25),(.05,.055,.34),'metal',.02)
box('preparation_board',(-.55,1.92,1.13),(.63,.48,.045),'wood',.04)

for name,loc in [('hotspot_fridge',(2.35,1.25,.93)),('hotspot_freezer',(2.35,1.25,2.13)),('hotspot_pantry',(-1.92,-1.33,1.25))]:
    bpy.ops.object.empty_add(type='CUBE',location=loc)
    o=bpy.context.object; o.name=name; o.empty_display_size=.25; move(o,'Hotspots')

def camera(name,loc,target,scale):
    bpy.ops.object.camera_add(location=loc); o=bpy.context.object; o.name=name
    o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler()
    o.data.type='ORTHO'; o.data.ortho_scale=scale; move(o,'Cameras'); return o

cam=camera('cam_kitchen_iso',(9,-12,10),(0,.15,1.1),9.8)
scene=bpy.context.scene; scene.camera=cam
bpy.ops.object.light_add(type='AREA',location=(-3,-4,8))
o=bpy.context.object; o.name='morning_softbox'; o.data.energy=650; o.data.shape='DISK'; o.data.size=5
o.rotation_euler=(Vector((0,0,0))-o.location).to_track_quat('-Z','Y').to_euler(); move(o,'Lights')
bpy.ops.object.light_add(type='SUN',location=(-6,-4,8))
o=bpy.context.object; o.name='morning_window_sun'; o.data.energy=2; o.data.angle=math.radians(4)
o.rotation_euler=Vector((1.6,.5,-1.4)).to_track_quat('-Z','Y').to_euler(); move(o,'Lights')
scene.world.color=(.32,.36,.40)
scene.render.engine='CYCLES'; scene.cycles.samples=32; scene.cycles.use_denoising=True
scene.render.resolution_x=1400; scene.render.resolution_y=1400; scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'; scene.render.film_transparent=False
scene.view_settings.view_transform='AgX'
scene.render.filepath=str(OUT/'kitchen-blockout-isometric.png')
scene['stage']='composition study; not final art, not integrated in Flutter'
scene['units']='meters'; scene.unit_settings.system='METRIC'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'sofra-kitchen-blockout.blend'))
bpy.ops.render.render(write_still=True)
bpy.ops.export_scene.gltf(filepath=str(OUT/'sofra-kitchen-blockout.glb'),export_format='GLB',export_cameras=True,export_lights=False)
manifest={'stage':'composition-only','blender':bpy.app.version_string,'units':'meters','camera':cam.name,'source':'build_blockout.py','external_assets':[], 'gameplay':False,'flutter_integrated':False,'animation_implemented':False,'hotspots':['hotspot_fridge','hotspot_freezer','hotspot_pantry'],'notes':['GLB lighting will differ; no runtime renderer selected.','Door meshes have independent hinge origins; no opening animation in this blockout.','Review layout and perspective before details.']}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print('SOFRA_BLOCKOUT_COMPLETE', OUT)
