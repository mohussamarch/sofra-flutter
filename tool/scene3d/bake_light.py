"""Bakes the Cycles lighting of the kitchen into vertex colours, so the
real-time model keeps the render's light (sun through the window, bounce,
soft shadows) while each material keeps its own colour (live recolour still
works: glTF multiplies COLOR_0 with the base colour).

Large flat faces (walls, floor, worktops) are subdivided first so shadows
have vertices to land on. The .blend is opened in a background Blender and
never saved; the result is a separate GLB.

    blender --background design-assets/blender/current/kitchen-morning.blend \
        --python tool/scene3d/bake_light.py -- assets/spike3d/kitchen.glb
"""

import math
import sys

import bmesh
import bpy

out = sys.argv[sys.argv.index("--") + 1]
scene = bpy.context.scene
EDGE = 0.07  # metres between vertices on big surfaces

# The dining table with its chairs and the microwave are part of the home
# kitchen; the masters keep them hidden as options.
for o in scene.objects:
    if o.get("option_group") in {"table_chairs", "microwave"}:
        o.hide_render = False
        o.hide_set(False)


def bounds(group):
    pts = [
        o.matrix_world @ v.co
        for o in scene.objects
        if o.get("option_group") == group and o.type == "MESH"
        for v in o.data.vertices
    ]
    lo = [round(min(p[i] for p in pts), 3) for i in range(3)]
    hi = [round(max(p[i] for p in pts), 3) for i in range(3)]
    print("BOUNDS", group, lo, hi)


bounds("table_chairs")
bounds("microwave")

# Same selection as export_glb.py: what the camera sees.
visible = [
    o
    for o in scene.objects
    if not o.hide_render
    and o.visible_camera
    and o.type in {"MESH", "CURVE"}
    and "scattering" not in o.name
]
curves = [o for o in visible if o.type == "CURVE"]
if curves:
    with bpy.context.temp_override(
        selected_objects=curves,
        selected_editable_objects=curves,
        active_object=curves[0],
    ):
        bpy.ops.object.convert(target="MESH")

# Shared meshes would bake one object's light onto all its copies.
for o in visible:
    if o.data.users > 1:
        o.data = o.data.copy()

for o in visible:
    mesh = o.data
    scale = max(o.matrix_world.to_scale())
    bm = bmesh.new()
    bm.from_mesh(mesh)
    longest = max((e.calc_length() for e in bm.edges), default=0) * scale
    cuts = min(40, math.ceil(longest / EDGE) - 1)
    if cuts > 0 and len(bm.verts) < 4000:
        bmesh.ops.subdivide_edges(
            bm, edges=bm.edges[:], cuts=cuts, use_grid_fill=True
        )
    bm.to_mesh(mesh)
    bm.free()
    attr = mesh.color_attributes.new("Light", "FLOAT_COLOR", "POINT")
    mesh.color_attributes.active_color = attr

scene.render.engine = "CYCLES"
scene.cycles.samples = 48
scene.cycles.use_denoising = False
bpy.ops.object.select_all(action="DESELECT")
for o in visible:
    o.select_set(True)
bpy.context.view_layer.objects.active = visible[0]
bpy.ops.object.bake(
    type="DIFFUSE",
    pass_filter={"DIRECT", "INDIRECT"},
    target="VERTEX_COLORS",
)

# Irradiance can exceed 1; scale so the brightest few percent sit at 1.
values = sorted(
    max(c.color[0], c.color[1], c.color[2])
    for o in visible
    for c in o.data.color_attributes["Light"].data
)
top = values[int(len(values) * 0.97)] or 1
for o in visible:
    for c in o.data.color_attributes["Light"].data:
        r, g, b, a = c.color
        c.color = (min(r / top, 1), min(g / top, 1), min(b / top, 1), 1)
print("BAKE_SCALE", top, "VERTS", len(values))

# The rest is export_glb.py: ramps flattened, door animations, Draco GLB.
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

fps = 30
scene.render.fps = fps


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
for o in scene.objects:
    if o.type == "EMPTY" and not o.hide_render:
        o.select_set(True)

bpy.ops.export_scene.gltf(
    filepath=out,
    export_format="GLB",
    use_selection=True,
    export_apply=True,
    export_cameras=False,
    export_lights=False,
    export_animations=True,
    export_animation_mode="ACTIONS",
    export_vertex_color="ACTIVE",
    export_draco_mesh_compression_enable=True,
    export_draco_mesh_compression_level=7,
)
print("BAKED_GLB_EXPORTED", out, len(visible))
