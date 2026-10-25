"""3D-engine spike: exports the kitchen exactly as rendered (visible objects
only) to a Draco-compressed GLB with door animations, for real-time display.

The .blend is opened read-only in a background Blender and never saved.

    blender --background design-assets/blender/current/kitchen-morning.blend \
        --python tool/scene3d/export_glb.py -- assets/spike3d/kitchen.glb

Animations (glTF names): fridge_open, freezer_open (0 to 104 degrees on the
r18 hinges, the same hinges and angle as the rendered motion).
"""

import math
import sys

import bpy

out = sys.argv[sys.argv.index("--") + 1]
scene = bpy.context.scene
fps = 30
scene.render.fps = fps

# Only what the camera sees: hidden variants, the camera-invisible cutaway
# walls/ceiling and the volumetric light box stay out.
for o in bpy.data.objects:
    o.select_set(False)
visible = [
    o
    for o in scene.objects
    if not o.hide_render
    and o.visible_camera
    and o.type in {"MESH", "CURVE", "EMPTY"}
    and "scattering" not in o.name
]

# Curves become meshes (glTF has no curves); in memory only.
curves = [o for o in visible if o.type == "CURVE"]
if curves:
    with bpy.context.temp_override(
        selected_objects=curves, selected_editable_objects=curves,
        active_object=curves[0],
    ):
        bpy.ops.object.convert(target="MESH")
for o in visible:
    o.select_set(True)


# Wood grain and gingham are colour ramps, which glTF cannot carry; flatten
# each ramp to its average colour so the surface keeps its real tone.
for mat in bpy.data.materials:
    if not mat.use_nodes:
        continue
    for node in mat.node_tree.nodes:
        if node.type != "BSDF_PRINCIPLED":
            continue
        base = node.inputs["Base Color"]
        if not base.is_linked or base.links[0].from_node.type != "VALTORGB":
            continue
        stops = base.links[0].from_node.color_ramp.elements
        avg = [sum(e.color[i] for e in stops) / len(stops) for i in range(4)]
        mat.node_tree.links.remove(base.links[0])
        base.default_value = avg


def door(name, action, sign):
    hinge = bpy.data.objects[name]
    hinge.animation_data_create()
    act = bpy.data.actions.new(action)
    hinge.animation_data.action = act
    for frame, angle in ((0, 0), (int(fps * 0.9), 104)):
        hinge.rotation_euler.z = sign * math.radians(angle)
        hinge.keyframe_insert("rotation_euler", index=2, frame=frame)
    hinge.rotation_euler.z = 0
    hinge.select_set(True)


door("r18_fridge_hinge", "fridge_open", -1)
door("r18_freezer_hinge", "freezer_open", -1)

bpy.ops.export_scene.gltf(
    filepath=out,
    export_format="GLB",
    use_selection=True,
    export_apply=True,
    export_cameras=False,
    export_lights=False,
    export_animations=True,
    export_animation_mode="ACTIONS",
    export_draco_mesh_compression_enable=True,
    export_draco_mesh_compression_level=7,
)
print("GLB_EXPORTED", out, len(visible))
