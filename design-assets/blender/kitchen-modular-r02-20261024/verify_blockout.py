import bpy, json, math, sys
from pathlib import Path
from mathutils import Vector
p=Path(sys.argv[sys.argv.index('--')+1])
m=json.loads((p/'manifest.json').read_text())
bpy.ops.wm.open_mainfile(filepath=str(p/'sofra-kitchen-modular-r02.blend'))
bpy.context.view_layer.update()
def obj(n): return bpy.data.objects[n]
def bounds(n):
    o=obj(n); vs=[o.matrix_world@Vector(v) for v in o.bound_box]
    return [[min(v[i] for v in vs),max(v[i] for v in vs)] for i in range(3)]
cam=obj('cam_kitchen_iso'); assert cam.data.type=='ORTHO'
direction=cam.rotation_euler.to_matrix()@Vector((0,0,-1))
assert max(abs(v) for v in direction)-min(abs(v) for v in direction)<1e-6
axes=[cam.matrix_world.inverted().to_3x3()@Vector(v) for v in [(1,0,0),(0,1,0),(0,0,1)]]
lengths=[math.hypot(v.x,v.y) for v in axes]
assert max(lengths)-min(lengths)<1e-6
buffer=bounds('cabinet_fridge_buffer_600_body')
stove=bounds('stove_body'); fridge=bounds('fridge_body')
assert abs(buffer[0][1]-buffer[0][0]-.6)<1e-5
assert stove[0][1]<=buffer[0][0]+1e-5 and buffer[0][1]<=fridge[0][0]+.02
corner=bounds('cabinet_corner_600_body')
assert all(abs(corner[i][0])<.015 for i in [0]) and abs(corner[1][1]-3.6)<.015
assert abs(obj('sink_root').location.y-m['window']['center_y_m'])<1e-5
assert bounds('pantry_body')[1][1] < m['window']['opening_y_m'][0]
for unit in m['base_modules']:
    assert abs(unit['width_m']-.6)<1e-5 and abs(unit['depth_m']-.6)<1e-5
assert obj('fridge_door_handle').parent==obj('fridge_door')
required=['cam_kitchen_iso','fridge_slot_900','range_slot_900','pantry_slot_600','cabinet_corner_600','sink_root','hotspot_fridge','hotspot_freezer','hotspot_pantry']
mesh_count=sum(o.type=='MESH' for o in bpy.data.objects)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(p/'sofra-kitchen-modular-r02.glb'))
assert all(n in bpy.data.objects for n in required)
assert sum(o.type=='MESH' for o in bpy.data.objects)==mesh_count
report={'blender':bpy.app.version_string,'blend_reopened':True,'glb_reimported':True,'equal_projected_axis_lengths':lengths,'buffer_between_range_and_fridge_m':.6,'corner_unit_present':True,'sink_centered_under_window':True,'pantry_outside_window_footprint':True,'base_module_m':[.6,.6],'mesh_objects':mesh_count,'glb_bytes':(p/'sofra-kitchen-modular-r02.glb').stat().st_size,'visual_approval_pending':True,'app_customization_built':False}
(p/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print(json.dumps(report))
