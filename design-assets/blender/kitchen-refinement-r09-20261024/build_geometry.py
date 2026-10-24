"""Sofra r09 original geometry corrections before lighting comparison."""
import bpy,sys,math,json,hashlib
from pathlib import Path
from mathutils import Vector
args=sys.argv[sys.argv.index('--')+1:];source,out=Path(args[0]),Path(args[1]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(source));bpy.context.view_layer.update()
def bounds(o):
    v=[o.matrix_world@Vector(p) for p in o.bound_box]
    return [[min(p[i] for p in v),max(p[i] for p in v)] for i in range(3)]
def parent(o,r):
    world=o.matrix_world.copy();o.parent=r;o.matrix_world=world;return o
def box(name,loc,size,mat,r=None,bevel=.004):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat)
    if bevel:
        m=o.modifiers.new('cast_edge','BEVEL');m.width=bevel;m.segments=3;o.modifiers.new('normals','WEIGHTED_NORMAL')
    return parent(o,r) if r else o

# Align underside of hood head to the cabinet body's underside, not handle.
hood=bpy.data.objects['hood'];duct=bpy.data.objects['hood_duct']
target=bounds(bpy.data.objects['upper_prep_600_body'])[2][0]
drop=bounds(hood)[2][0]-target
hood.location.z-=drop
duct.dimensions.z+=drop;duct.location.z-=drop/2

# Straight shelves reach left wall, without anL return along window wall.
for o in list(bpy.data.objects):
    if o.name.startswith('open_shelf_') and o.name.endswith('_left'):bpy.data.objects.remove(o,do_unlink=True)
for o in bpy.data.objects:
    if o.name.startswith('decor_shelf_') and o.name.endswith('_left_anchor'):
        o.location.y=-.17 # Root at rear wall y3.6 => worldy3.43.
        o['side']='straight_shelf_left_slot'

# Smaller window1.2×1.1m, centered over the sink, with aperture rebuilt around it.
for o in bpy.data.objects:
    if o.name.startswith('window_side'):
        o.location.y=1.5 if o.location.y<2.1 else 2.7;o.dimensions=(.10,.05,1.15)
    elif o.name.startswith('window_horizontal'):
        o.location.z=1.2 if o.location.z<1.75 else 2.3;o.dimensions=(.10,1.25,.05)
    elif o.name=='window_mullion':o.dimensions=(.08,.04,1.08)
    elif o.name=='window_crossbar':o.dimensions=(.08,1.18,.04)
    elif o.name=='window_sill':o.dimensions=(.10,1.30,.025);o.location.z=1.1875
bpy.data.objects['wall_left_low'].location.z=.6;bpy.data.objects['wall_left_low'].dimensions=(.12,3.6,1.2)
bpy.data.objects['wall_left_high'].location.z=2.5;bpy.data.objects['wall_left_high'].dimensions=(.12,3.6,.4)
bpy.data.objects['wall_left_front'].location=( -.06,.75,1.75);bpy.data.objects['wall_left_front'].dimensions=(.12,1.5,1.1)
bpy.data.objects['wall_left_rear'].location=(-.06,3.15,1.75);bpy.data.objects['wall_left_rear'].dimensions=(.12,.9,1.1)

# Optional curtain assembly: removable root, open linen side panels.
bpy.ops.object.empty_add(type='PLAIN_AXES',location=(0,2.1,0));curtain=bpy.context.object;curtain.name='curtain_root_optional';curtain['removable']=True;curtain['variant']='open_linen_pair'
linen=bpy.data.materials.new('r09_linen');linen.diffuse_color=(.67,.57,.42,1)
p=linen.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=linen.diffuse_color;p.inputs['Roughness'].default_value=.94
rodmat=bpy.data.materials['r06_muted_brass']
bpy.ops.mesh.primitive_cylinder_add(vertices=32,radius=.012,depth=1.44,location=(.12,2.1,2.40),rotation=(math.pi/2,0,0));rod=bpy.context.object;rod.name='curtain_rod';rod.data.materials.append(rodmat);parent(rod,curtain)
for side,lo,hi in [('front',1.48,1.70),('rear',2.50,2.72)]:
    verts=[];faces=[];segments=32
    for z in [1.24,2.37]:
        for i in range(segments+1):
            y=lo+(hi-lo)*i/segments;x=.10+.018*math.cos(i/segments*math.tau*4)
            verts.append((x,y,z))
    for i in range(segments):faces.append((i,i+1,segments+i+2,segments+i+1))
    mesh=bpy.data.meshes.new('linen_pleats_'+side);mesh.from_pydata(verts,[],faces);mesh.update()
    o=bpy.data.objects.new('curtain_panel_'+side,mesh);bpy.context.collection.objects.link(o);o.data.materials.append(linen)
    for poly in o.data.polygons:poly.use_smooth=True
    s=o.modifiers.new('cloth_thickness','SOLIDIFY');s.thickness=.0015;parent(o,curtain)
    for j in range(3):
        y=lo+.025+(hi-lo-.05)*j/2
        bpy.ops.mesh.primitive_torus_add(major_radius=.025,minor_radius=.004,major_segments=24,minor_segments=8,location=(.12,y,2.4),rotation=(math.pi/2,0,0))
        o=bpy.context.object;o.name='curtain_ring_'+side+'_'+str(j);o.data.materials.append(rodmat);parent(o,curtain)

# Replace visually suspended grate parts by3cast assemblies with contact feet.
for o in list(bpy.data.objects):
    if o.name.startswith(('grate_frame_','pan_support_')):bpy.data.objects.remove(o,do_unlink=True)
iron=bpy.data.materials['r06_cast_iron'];rangeroot=bpy.data.objects['range_slot_900'];feet=[]
def frame(name,x,y,r):
    # One extruded rectangular ring, no overlapping top planes at corners.
    w,h,t=.248,.516,.020;z0,z1=.950,.978
    outer=[(-w/2,-h/2),(w/2,-h/2),(w/2,h/2),(-w/2,h/2)]
    inner=[(-w/2+t,-h/2+t),(w/2-t,-h/2+t),(w/2-t,h/2-t),(-w/2+t,h/2-t)]
    verts=[(x+a,y+b,z) for z in [z0,z1] for loop in [outer,inner] for a,b in loop];faces=[]
    for i in range(4):
        j=(i+1)%4
        faces.extend([(i,j,8+j,8+i),(4+j,4+i,12+i,12+j),(8+i,8+j,12+j,12+i),(j,i,4+i,4+j)])
    m=bpy.data.meshes.new(name);m.from_pydata(verts,[],faces);m.update();o=bpy.data.objects.new(name,m);bpy.context.collection.objects.link(o);o.data.materials.append(iron)
    bevel=o.modifiers.new('cast_rounding','BEVEL');bevel.width=.003;bevel.segments=3;o.modifiers.new('normals','WEIGHTED_NORMAL');parent(o,r)
for col,dx in enumerate([-.28,0,.28]):
    x,y=1.65+dx,3.3
    bpy.ops.object.empty_add(type='PLAIN_AXES',location=(x,y,0));root=bpy.context.object;root.name='cast_grate_assembly_%d'%col;parent(root,rangeroot)
    frame('cast_grate_ring_%d'%col,x,y,root)
    for sx in [-1,1]:
        for sy in [-1,1]:
            f=box('grate_contact_foot_%d_%d_%d'%(col,sx,sy),(x+sx*.113,y+sy*.244,.939),(.025,.025,.038),iron,root);feet.append(f.name)
    if col!=1:box('grate_center_bridge_%d'%col,(x,y,.964),(.210,.022,.028),iron,root)
    ys=[0] if col==1 else [-.16,.16]
    for k,dy in enumerate(ys):
        inner=.08 if col==1 else .055
        for sign in [-1,1]:
            # Side fingers meet the real frame; inner tips stop over burner.
            length=.124-inner
            box('grate_x_finger_%d_%d_%d'%(col,k,sign),(x+sign*(inner+length/2),y+dy,.984),(length+.003,.024,.026),iron,root)
            if col==1:
                length=.258-inner;center=sign*(inner+length/2)
            elif dy*sign>0:
                length=.258-abs(dy)-inner;center=dy+sign*(inner+length/2)
            else:
                length=abs(dy)-inner;center=dy+sign*(inner+length/2)
            box('grate_y_finger_%d_%d_%d'%(col,k,sign),(x,y+center,.984),(.024,length+.003,.026),iron,root)

bpy.context.view_layer.update()
hoodbottom=bounds(hood)[2][0];assert abs(hoodbottom-target)<1e-5
assert len([o for o in bpy.data.objects if o.name.startswith('open_shelf_')])==3
assert len(feet)==12
hobtop=bounds(bpy.data.objects['hob_recessed_enamel'])[2][1]
for n in feet:
    b=bounds(bpy.data.objects[n]);assert b[2][0]<=hobtop+.001 and b[2][1]>=.950
assert len([o for o in bpy.data.objects if o.name.startswith('tile_')])==36
scene=bpy.context.scene;scene['stage']='r09 supported grates, aligned hood, straight shelves, smaller window and optional curtain'
bpy.ops.wm.save_as_mainfile(filepath=str(out/'kitchen-r09-geometry.blend'))
report={'base_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'footprint_m':[3.6,3.6],'window_opening_m':[1.2,1.1],'window_center_y_m':2.1,'curtain_root':'curtain_root_optional','curtain_clear_center_y_m':[1.70,2.50],'app_curtain_toggle_built':False,'hood_underside_m':hoodbottom,'upper_cabinet_underside_m':target,'hood_cover_cabinet':'future option, not built','straight_shelf_boards':3,'grate_assemblies':3,'grate_contact_feet':12,'grate_feet_contact_verified':True,'style_default_selected':False}
(out/'geometry-verification.json').write_text(json.dumps(report,indent=2),encoding='utf8');print('GEOMETRY_R09_COMPLETE',json.dumps(report))
