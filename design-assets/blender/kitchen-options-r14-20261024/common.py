import bpy, math
from mathutils import Vector
def mat(n,c,rough=.7,metal=0):
 m=bpy.data.materials.new(n);m.use_nodes=True;m.diffuse_color=(*c,1);p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal;return m

def assign(o,m):o.data.materials.clear();o.data.materials.append(m)
def parent(o,r):
 bpy.context.view_layer.update();w=o.matrix_world.copy();o.parent=r;o.matrix_world=w

def box(n,loc,d,m,b=.008):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=n;o.dimensions=d;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);assign(o,m)
 if b:mod=o.modifiers.new('soft_edge','BEVEL');mod.width=b;mod.segments=4;o.modifiers.new('normals','WEIGHTED_NORMAL')
 return o

def tube(n,pts,r,m,closed=False):
 c=bpy.data.curves.new(n,'CURVE');c.dimensions='3D';c.bevel_depth=r;c.bevel_resolution=3;sp=c.splines.new('POLY');sp.points.add(len(pts)-1)
 for p,co in zip(sp.points,pts):p.co=(*co,1)
 sp.use_cyclic_u=closed;o=bpy.data.objects.new(n,c);bpy.context.collection.objects.link(o);assign(o,m);return o

def sphere(n,loc,sc,m):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=12,location=loc);o=bpy.context.object;o.name=n;o.scale=sc;assign(o,m)
 for p in o.data.polygons:p.use_smooth=True
 return o

def camera_only(o):
 o.visible_shadow=False;o.visible_diffuse=False;o.visible_glossy=False;o.visible_transmission=False;o.visible_volume_scatter=False;return o

def flatmat(n,c,strength=.8):
 m=mat(n,c);nodes=m.node_tree.nodes;nodes.clear();e=nodes.new('ShaderNodeEmission');e.inputs['Color'].default_value=(*c,1);e.inputs['Strength'].default_value=strength;end=nodes.new('ShaderNodeOutputMaterial');m.node_tree.links.new(e.outputs[0],end.inputs[0]);return m
