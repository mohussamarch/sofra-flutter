"""Sofra r05: restrained window sill and open corner shelves. Local review."""
import bpy, sys, json, hashlib
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
args=sys.argv[sys.argv.index('--')+1:]; source,out=Path(args[0]),Path(args[1])
out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(source)); bpy.context.view_layer.update()
scene=bpy.context.scene
sill=bpy.data.objects['window_sill']
sill.location.x=.025; sill.dimensions=(.10,1.57,.025); sill.location.z=1.0875
# Apply prior scaling before the smaller bevel, keeping proportions deterministic.
bpy.ops.object.select_all(action='DESELECT'); sill.select_set(True); bpy.context.view_layer.objects.active=sill
bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
for mod in sill.modifiers:
    if mod.type=='BEVEL': mod.width=.007; mod.segments=3

col=bpy.data.collections.new('OpenCornerShelves'); scene.collection.children.link(col)
bpy.ops.object.empty_add(type='PLAIN_AXES',location=(0,4.2,0))
root=bpy.context.object; root.name='open_corner_shelves_root'
for c in list(root.users_collection): c.objects.unlink(root)
col.objects.link(root)
root['purpose']='decorative display; not food inventory'
material=bpy.data.materials['worktop']
def shelf(name,loc,size):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc)
    o=bpy.context.object; o.name=name; o.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    for c in list(o.users_collection):c.objects.unlink(o)
    col.objects.link(o); o.data.materials.append(material)
    bevel=o.modifiers.new('soft_shelf_edge','BEVEL'); bevel.width=.008; bevel.segments=3
    o.modifiers.new('shelf_normals','WEIGHTED_NORMAL')
    world=o.matrix_world.copy(); o.parent=root; o.matrix_world=world
    return o
slots=[]
for level,z in enumerate([1.62,1.97,2.32],1):
    shelf('open_shelf_%02d_back'%level,(.30,4.04,z),(.60,.32,.035))
    shelf('open_shelf_%02d_left'%level,(.16,3.695,z),(.32,.37,.035))
    for side,loc in [('back',(.43,4.02,z+.0175)),('left',(.16,3.70,z+.0175))]:
        bpy.ops.object.empty_add(type='PLAIN_AXES',location=loc)
        anchor=bpy.context.object; anchor.name='decor_shelf_%02d_%s_anchor'%(level,side); anchor.empty_display_size=.06
        for c in list(anchor.users_collection):c.objects.unlink(anchor)
        col.objects.link(anchor)
        world=anchor.matrix_world.copy(); anchor.parent=root; anchor.matrix_world=world
        anchor['slot_type']='decoration'; anchor['suggested_max_width_m']=.20; anchor['suggested_max_height_m']=.27
        slots.append({'id':anchor.name,'level':level,'side':side,'position_m':list(loc),'suggested_envelope_m':[.20,.20,.27]})

bpy.context.view_layer.update()
def bounds(o):
    verts=[o.matrix_world@Vector(v) for v in o.bound_box]
    return [[min(v[i] for v in verts),max(v[i] for v in verts)] for i in range(3)]
sillbounds=bounds(sill)
assert abs(sillbounds[0][1]-.075)<1e-5
assert abs(sill.dimensions.z-.025)<1e-5
for o in col.objects:
    if o.type=='MESH':
        # Window ends aty3.45 after square revision: leave60mmclearance.
        assert bounds(o)[1][0]>=3.50
        assert bounds(o)[0][0]>=-.001 and bounds(o)[0][1]<=.601
cam=scene.camera
a=world_to_camera_view(scene,cam,Vector((0,4.2,2.7)))
b=world_to_camera_view(scene,cam,Vector((4.2,0,0)))
assert abs(a.x-b.x)<1e-6
scene['stage']='r05 sill refinement and open shelves; visual review pending'
scene.render.filepath=str(out/'kitchen-r05.png')
bpy.ops.wm.save_as_mainfile(filepath=str(out/'sofra-kitchen-r05.blend'))
bpy.ops.render.render(write_still=True)
bpy.ops.export_scene.gltf(filepath=str(out/'sofra-kitchen-r05.glb'),export_format='GLB',export_cameras=True,export_lights=False)
# Detail render uses the same source and a temporary camera framing only.
cam.data.ortho_scale=3.5
target=Vector((.70,3.35,1.75)); cam.location=target+Vector((8,-8,8))
cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
scene.render.filepath=str(out/'kitchen-r05-detail.png'); bpy.ops.render.render(write_still=True)

bpy.ops.wm.open_mainfile(filepath=str(out/'sofra-kitchen-r05.blend'))
assert abs(bpy.context.scene.camera.data.ortho_scale-7.2)<1e-5
assert all(slot['id'] in bpy.data.objects for slot in slots)
meshcount=sum(o.type=='MESH' for o in bpy.data.objects)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(out/'sofra-kitchen-r05.glb'))
assert sum(o.type=='MESH' for o in bpy.data.objects)==meshcount
assert all(slot['id'] in bpy.data.objects for slot in slots)
manifest={'revision':5,'blender':bpy.app.version_string,'base_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'footprint_m':[4.2,4.2],'sill':{'thickness_m':.025,'overall_depth_m':.10,'projection_into_room_m':.075},'open_shelves':{'levels':3,'boards':6,'root':'open_corner_shelves_root','window_clearance_m':.06,'decoration_slots':slots},'future_user_request':'Users can later place selected decoration/plants, including earnable items, on open shelves.','rewards_rules_decided':False,'reward_system_implemented':False,'app_customization_implemented':False,'style_selected':None,'visual_approval_pending':True}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
report={'blend_reopened':True,'glb_reimported':True,'mesh_objects':meshcount,'decoration_anchors_preserved':len(slots),'sill_projection_m':sillbounds[0][1],'sill_thickness_m':.025,'window_clearance_verified':True,'back_front_corner_alignment_error_px':abs(a.x-b.x)*1400,'full_camera_preserved':True,'glb_bytes':(out/'sofra-kitchen-r05.glb').stat().st_size,'source_sha256':manifest['base_sha256']}
(out/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print('SOFRA_R05_COMPLETE',json.dumps(report))
