"""Prints what a kitchen .blend holds, for planning the real-time export:
objects, triangles, materials and whether their shading is procedural."""
import bpy, collections
tri = 0
kinds = collections.Counter()
for o in bpy.context.scene.objects:
    kinds[o.type] += 1
    if o.type == 'MESH' and not o.hide_render:
        m = o.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh()
        tri += sum(len(p.vertices) - 2 for p in m.polygons)
print('OBJECTS', dict(kinds), 'TRIS', tri)
procedural = 0
for mat in bpy.data.materials:
    if not mat.use_nodes:
        continue
    types = {n.type for n in mat.node_tree.nodes}
    if types & {'TEX_NOISE', 'TEX_VORONOI', 'TEX_WAVE', 'TEX_MUSGRAVE', 'TEX_BRICK', 'TEX_CHECKER', 'TEX_GRADIENT', 'VALTORGB', 'BUMP'}:
        procedural += 1
print('MATERIALS', len(bpy.data.materials), 'PROCEDURAL', procedural, 'IMAGES', len([i for i in bpy.data.images if i.source == 'FILE']))
print('CAMERA', bpy.context.scene.camera and bpy.context.scene.camera.name, bpy.context.scene.camera and bpy.context.scene.camera.data.type)
print('ENGINE', bpy.context.scene.render.engine)
top = sorted([o.name for o in bpy.context.scene.objects if o.parent is None])
print('ROOTS', len(top), top[:80])
