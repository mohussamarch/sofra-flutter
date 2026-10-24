"""Square footprint correction; original r02 is preserved. Blender only."""
import bpy, math, json, sys
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
args=sys.argv[sys.argv.index('--')+1:]; source,out=Path(args[0]),Path(args[1])
out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(source)); bpy.context.view_layer.update()
scene=bpy.context.scene

# Extend the left run by exactly one600mm module. Keep600mm cabinet before range.
for o in list(bpy.data.objects):
    if o.parent: continue
    if o.name.startswith(('cabinet_','upper_','window_')) or o.name in ['sink_root','range_slot_900','hood_root','fridge_slot_900','preparation_board','hotspot_fridge','hotspot_freezer']:
        o.location.y+=.6

# Square plinth, square600mm tile grid. Wall aperture moves with sink/window.
bpy.data.objects['floor_plinth'].location.y=2.1
bpy.data.objects['floor_plinth'].dimensions.y=4.36
for i in range(7):
    template=bpy.data.objects['tile_%d_5'%i]
    copy=template.copy(); copy.data=template.data.copy(); copy.name='tile_%d_6'%i
    template.users_collection[0].objects.link(copy); copy.location.y+=.6
bpy.data.objects['wall_back'].location.y+=.6
for n in ['wall_left_low','wall_left_high']:
    o=bpy.data.objects[n]; o.location.y=2.1; o.dimensions.y=4.2
bpy.data.objects['wall_left_front'].location.y=.975
bpy.data.objects['wall_left_front'].dimensions.y=1.95
bpy.data.objects['wall_left_rear'].location.y+=.6

# Duplicate plain left module to bridge the extra600mm at the front.
template=bpy.data.objects['cabinet_left_end_600']
root=template.copy(); root.name='cabinet_left_square_extension_600'
template.users_collection[0].objects.link(root); root.location.y-=.6
for child in list(template.children):
    clone=child.copy(); clone.data=child.data.copy() if child.data else None
    clone.name=child.name.replace('cabinet_left_end_600','cabinet_left_square_extension_600')
    child.users_collection[0].objects.link(clone); clone.parent=root

cam=scene.camera
target=Vector((2.1,2.1,1.10)); cam.location=target+Vector((8,-8,8))
cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
cam.data.ortho_scale=7.2
scene['stage']='r04 square-footprint composition, user review pending'
scene['footprint_m']='4.2 x 4.2'; scene.render.filepath=str(out/'square-kitchen-r04.png')
bpy.context.view_layer.update()
back=Vector((0,4.2,2.7)); front=Vector((4.2,0,0))
uvback=world_to_camera_view(scene,cam,back); uvfront=world_to_camera_view(scene,cam,front)
assert abs(uvback.x-uvfront.x)<1e-6
assert abs(uvback.x-.5)<1e-6
floor=bpy.data.objects['floor_plinth']; assert abs(floor.dimensions.x-floor.dimensions.y)<1e-5
assert abs(bpy.data.objects['sink_root'].location.y-2.7)<1e-5
assert abs(bpy.data.objects['window_sill'].location.y-2.7)<1e-5
bpy.ops.wm.save_as_mainfile(filepath=str(out/'sofra-square-kitchen-r04.blend'))
bpy.ops.render.render(write_still=True)
bpy.ops.export_scene.gltf(filepath=str(out/'sofra-square-kitchen-r04.glb'),export_format='GLB',export_cameras=True,export_lights=False)

# Optional alignment overlay is rendered in Blender on camera-facing curves.
# Clean .blend andGLB above contain no guide. No raster-editing tools used.
col=bpy.data.collections.new('ReviewGuidesOnly'); scene.collection.children.link(col)
ink=bpy.data.materials.new('review_guide_orange'); ink.use_nodes=True
nodes=ink.node_tree.nodes; nodes.clear(); emission=nodes.new('ShaderNodeEmission')
emission.inputs['Color'].default_value=(1,.30,.025,1); emission.inputs['Strength'].default_value=1
output=nodes.new('ShaderNodeOutputMaterial'); ink.node_tree.links.new(emission.outputs[0],output.inputs['Surface'])
def screen_point(x,y):
    return cam.matrix_world@Vector(((x-.5)*cam.data.ortho_scale,(y-.5)*cam.data.ortho_scale,-1))
def curve(name,coords,thickness=.006):
    data=bpy.data.curves.new(name,'CURVE'); data.dimensions='3D'; data.bevel_depth=thickness; data.bevel_resolution=2
    spline=data.splines.new('POLY'); spline.points.add(len(coords)-1)
    for p,co in zip(spline.points,coords):p.co=(*co,1)
    obj=bpy.data.objects.new(name,data); col.objects.link(obj); obj.data.materials.append(ink)
curve('vertical_corner_alignment',[screen_point(.5,max(.04,uvfront.y-.025)),screen_point(.5,min(.97,uvback.y+.025))],.005)
for label,uv in [('back_corner',uvback),('front_corner',uvfront)]:
    curve(label,[screen_point(uv.x+.009*math.cos(t*math.tau/48),uv.y+.009*math.sin(t*math.tau/48)) for t in range(49)],.005)
scene.render.filepath=str(out/'square-kitchen-r04-alignment.png'); bpy.ops.render.render(write_still=True)

# Reopen saved clean source and reimport actualGLB; preserve current source.
bpy.ops.wm.open_mainfile(filepath=str(out/'sofra-square-kitchen-r04.blend'))
assert 'ReviewGuidesOnly' not in bpy.data.collections
mesh_count=sum(o.type=='MESH' for o in bpy.data.objects)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(out/'sofra-square-kitchen-r04.glb'))
assert sum(o.type=='MESH' for o in bpy.data.objects)==mesh_count
assert all(n in bpy.data.objects for n in ['cabinet_left_square_extension_600','cabinet_corner_600','cabinet_fridge_buffer_600','sink_root','fridge_slot_900','cam_kitchen_iso'])
report={'blender':bpy.app.version_string,'footprint_m':[4.2,4.2],'module_m':.6,'modules_each_axis':7,'back_corner_screen_uv':[uvback.x,uvback.y],'front_corner_screen_uv':[uvfront.x,uvfront.y],'horizontal_alignment_error_pixels':abs(uvback.x-uvfront.x)*1400,'square_plinth_verified':True,'sink_window_center_y_m':2.7,'blend_reopened':True,'glb_reimported':True,'mesh_objects':mesh_count,'glb_bytes':(out/'sofra-square-kitchen-r04.glb').stat().st_size,'guide_in_clean_source':False,'style_selected':None,'visual_approval_pending':True,'runtime_test':False}
(out/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print('SQUARE_ALIGNMENT_COMPLETE',json.dumps(report))
