import bpy, json, sys
from pathlib import Path
p=Path(sys.argv[sys.argv.index('--')+1])
bpy.ops.wm.open_mainfile(filepath=str(p/'sofra-kitchen-blockout.blend'))
required=['cam_kitchen_iso','fridge_body','fridge_door','freezer_door','pantry_door','wall_back','wall_left_low','window_sill','sink_basin','stove_body','hotspot_fridge','hotspot_freezer','hotspot_pantry']
assert all(n in bpy.data.objects for n in required)
assert bpy.context.scene.camera.data.type=='ORTHO'
assert len([o for o in bpy.data.objects if o.type=='LIGHT'])==2
assert all(not im.filepath for im in bpy.data.images if im.type=='IMAGE')
blend_meshes=len([o for o in bpy.data.objects if o.type=='MESH'])
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(p/'sofra-kitchen-blockout.glb'))
assert all(n in bpy.data.objects for n in required)
assert len([o for o in bpy.data.objects if o.type=='MESH'])==blend_meshes
report={'source_reopened':True,'glb_reimported':True,'required_nodes_present':required,'mesh_objects':blend_meshes,'glb_bytes':(p/'sofra-kitchen-blockout.glb').stat().st_size,'png_bytes':(p/'kitchen-blockout-isometric.png').stat().st_size,'runtime_test':False,'visual_approval_pending':True}
(p/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print(json.dumps(report))
