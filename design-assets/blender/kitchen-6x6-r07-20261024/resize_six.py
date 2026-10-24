"""Resize actual Sofra room to six600mm modules, not a camera/image scale."""
import bpy, sys, json, hashlib
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
args=sys.argv[sys.argv.index('--')+1:]; source,out=Path(args[0]),Path(args[1]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(source));bpy.context.view_layer.update()
scene=bpy.context.scene
def remove_tree(name):
    r=bpy.data.objects[name]
    for child in list(r.children_recursive):bpy.data.objects.remove(child,do_unlink=True)
    bpy.data.objects.remove(r,do_unlink=True)
# Shorten each run by one real600mm module. Preserve range/fridge buffer.
for name in ['cabinet_back_600','upper_back_600','cabinet_left_square_extension_600']:remove_tree(name)
for o in list(bpy.data.objects):
    if o.parent:continue
    if o.name in ['cabinet_prep_600','cabinet_fridge_buffer_600','upper_prep_600','upper_buffer_600','range_slot_900','hood_root','fridge_slot_900','preparation_board','hotspot_fridge','hotspot_freezer']:
        o.location.x-=.6;o.location.y-=.6
    elif o.name.startswith(('cabinet_left_','window_')) or o.name in ['cabinet_corner_600','cabinet_sink_600','sink_root','open_corner_shelves_root']:
        o.location.y-=.6
for o in list(bpy.data.objects):
    if o.name.startswith('tile_'):
        i,j=map(int,o.name.split('_')[1:])
        if i>=6 or j>=6:bpy.data.objects.remove(o,do_unlink=True)
floor=bpy.data.objects['floor_plinth'];floor.location.x=1.8;floor.location.y=1.8;floor.dimensions=(3.76,3.76,.18)
backwall=bpy.data.objects['wall_back'];backwall.location.x=1.8;backwall.location.y=3.66;backwall.dimensions.x=3.72
for name in ['wall_left_low','wall_left_high']:
    o=bpy.data.objects[name];o.location.y=1.8;o.dimensions.y=3.6
frontwall=bpy.data.objects['wall_left_front'];frontwall.location.y=.675;frontwall.dimensions.y=1.35
bpy.data.objects['wall_left_rear'].location.y-=.6
# Deleted two-unit upper cabinet cornice becomes a new single-unit cap.
parent=bpy.data.objects['upper_prep_600'];material=bpy.data.materials['r06_classic_frame']
for name,z,width,depth,height in [('lower',2.35,.62,.35,.035),('top',2.378,.65,.38,.022)]:
    bpy.ops.mesh.primitive_cube_add(size=1,location=(.9,3.44,z));o=bpy.context.object;o.name='upper_prep_600_classic_cornice_'+name;o.dimensions=(width,depth,height)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(material)
    m=o.modifiers.new('rounded_cap','BEVEL');m.width=.006;m.segments=3;o.modifiers.new('weighted_normals','WEIGHTED_NORMAL')
    world=o.matrix_world.copy();o.parent=parent;o.matrix_world=world
cam=scene.camera;target=Vector((1.8,1.8,1.10));cam.location=target+Vector((8,-8,8));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=6.5
bpy.context.view_layer.update()
def bounds(name):
    o=bpy.data.objects[name];v=[o.matrix_world@Vector(p) for p in o.bound_box]
    return [[min(p[i] for p in v),max(p[i] for p in v)] for i in range(3)]
assert len([o for o in bpy.data.objects if o.name.startswith('tile_')])==36
assert abs(floor.dimensions.x-floor.dimensions.y)<1e-6
assert abs(bpy.data.objects['sink_root'].location.y-2.1)<1e-5
assert abs(bpy.data.objects['window_sill'].location.y-2.1)<1e-5
for name,y in [('cabinet_corner_600',3.3),('cabinet_left_rear_600',2.7),('cabinet_sink_600',2.1),('cabinet_left_front_600',1.5),('cabinet_left_end_600',.9),('pantry_slot_600',.3)]:
    assert abs(bpy.data.objects[name].location.y-y)<1e-5, name
top=bpy.data.objects['cabinet_sink_600_top']
origin=top.matrix_world.inverted()@Vector((.32,2.1,1.5))
direction=top.matrix_world.inverted().to_3x3()@Vector((0,0,-1))
assert not top.ray_cast(origin,direction)[0], 'Sink center must pass through countertop opening'
buffer=bounds('cabinet_fridge_buffer_600_body');rangebounds=bounds('range_enamel_body');fridge=bounds('fridge_body')
assert abs(buffer[0][1]-buffer[0][0]-.6)<1e-5
assert rangebounds[0][1]<buffer[0][0] and buffer[0][1]<=fridge[0][0]+.02
assert abs(bounds('cabinet_corner_600_body')[1][1]-3.6)<.001
a=world_to_camera_view(scene,cam,Vector((0,3.6,2.7)));b=world_to_camera_view(scene,cam,Vector((3.6,0,0)))
assert abs(a.x-b.x)<1e-6
caps=[o.name for o in bpy.data.objects if o.name.startswith('burner_') and o.name.endswith('_cap') and o.name!='burner_center_wok_inner_cap'];assert len(caps)==5
anchors=[o.name for o in bpy.data.objects if o.name.startswith('decor_shelf_')];assert len(anchors)==6
scene['stage']='r07 user-requested six-by-six modules; visual review pending';scene['footprint_m']='3.6 x 3.6';scene['module_m']=.6
scene.render.filepath=str(out/'kitchen-6x6-r07.png')
bpy.ops.wm.save_as_mainfile(filepath=str(out/'sofra-kitchen-6x6-r07.blend'))
bpy.ops.render.render(write_still=True)
bpy.ops.export_scene.gltf(filepath=str(out/'sofra-kitchen-6x6-r07.glb'),export_format='GLB',export_cameras=True,export_lights=False)
bpy.ops.wm.open_mainfile(filepath=str(out/'sofra-kitchen-6x6-r07.blend'))
assert abs(bpy.context.scene.camera.data.ortho_scale-6.5)<1e-5
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(out/'sofra-kitchen-6x6-r07.glb'))
assert all(n in bpy.data.objects for n in caps+anchors+['sink_true_basin','mixer_gooseneck','cabinet_corner_600','cabinet_fridge_buffer_600'])
report={'blender':bpy.app.version_string,'footprint_m':[3.6,3.6],'module_m':.6,'modules_each_axis':6,'floor_tiles':36,'actual_removed_modules':['cabinet_back_600','cabinet_left_square_extension_600'],'fridge_buffer_width_m':.6,'sink_window_center_y_m':2.1,'burners':5,'decoration_anchors':6,'corner_alignment_error_px':abs(a.x-b.x)*1400,'blend_reopened':True,'glb_reimported':True,'glb_bytes':(out/'sofra-kitchen-6x6-r07.glb').stat().st_size,'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'style_option':'classic, not approved default','visual_approval_pending':True,'runtime_ready':False}
(out/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf8');print('SOFRA_6X6_COMPLETE',json.dumps(report))
