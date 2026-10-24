"""Original Sofra appliance/classic-facade review, based on square r05.
Not runtime-ready art. Run Blender --python-exit-code1 with BASE_BLEND OUT.
"""
import bpy, math, sys, json, hashlib
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
args=sys.argv[sys.argv.index('--')+1:]; source,out=Path(args[0]),Path(args[1]); out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(source)); bpy.context.view_layer.update()
scene=bpy.context.scene
def mat(name,color,metal=0,rough=.5):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1)
    p=m.node_tree.nodes.get('Principled BSDF'); p.inputs['Base Color'].default_value=(*color,1)
    p.inputs['Metallic'].default_value=metal; p.inputs['Roughness'].default_value=rough
    return m
steel=mat('r06_brushed_steel',(.47,.55,.56),.72,.30)
enamel=mat('r06_warm_enamel',(.82,.82,.76),.12,.28)
iron=mat('r06_cast_iron',(.035,.045,.043),.35,.57)
glass=mat('r06_oven_glass',(.045,.065,.069),.35,.19)
dark=mat('r06_dark_inset',(.09,.12,.12),.25,.42)
brass=mat('r06_muted_brass',(.48,.30,.12),.75,.30)
cream=mat('r06_classic_frame',(.76,.70,.58),0,.5)
panelmat=mat('r06_classic_raised_panel',(.66,.63,.51),0,.5)
fieldmat=mat('r06_classic_recess',(.48,.47,.38),0,.6)
def attach(o,parent):
    if parent:
        world=o.matrix_world.copy();o.parent=parent;o.matrix_world=world
    return o
def box(name,loc,size,material,parent=None,bevel=.008):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc); o=bpy.context.object;o.name=name;o.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(material)
    if bevel:
        b=o.modifiers.new('rounded_profile','BEVEL');b.width=bevel;b.segments=3
        o.modifiers.new('weighted_normals','WEIGHTED_NORMAL')
    return attach(o,parent)
def cyl(name,loc,radius,depth,material,parent=None,rotation=None):
    bpy.ops.mesh.primitive_cylinder_add(vertices=32,radius=radius,depth=depth,location=loc)
    o=bpy.context.object;o.name=name;o.data.materials.append(material)
    if rotation:o.rotation_euler=rotation
    b=o.modifiers.new('edge_rounding','BEVEL');b.width=min(.004,depth/4);b.segments=2
    o.modifiers.new('weighted_normals','WEIGHTED_NORMAL');return attach(o,parent)
def tube(name,points,radius,material,parent=None):
    c=bpy.data.curves.new(name,'CURVE');c.dimensions='3D';c.bevel_depth=radius;c.bevel_resolution=4;c.resolution_u=16
    s=c.splines.new('POLY');s.points.add(len(points)-1)
    for p,co in zip(s.points,points):p.co=(*co,1)
    o=bpy.data.objects.new(name,c);bpy.context.collection.objects.link(o);o.data.materials.append(material);return attach(o,parent)
def clear_children(root):
    for o in list(root.children_recursive):bpy.data.objects.remove(o,do_unlink=True)
def bounds(o):
    vs=[o.matrix_world@Vector(v) for v in o.bound_box]
    return Vector(tuple(min(v[i] for v in vs) for i in range(3))),Vector(tuple(max(v[i] for v in vs) for i in range(3)))

# Five burners: four outer burners and a central larger wok burner.
range_root=bpy.data.objects['range_slot_900'];clear_children(range_root)
cx,cy=2.25,3.9
box('range_enamel_body',(cx,cy,.43),(.89,.59,.80),enamel,range_root,.025)
box('range_lower_plinth',(cx,cy,.065),(.83,.53,.08),iron,range_root,.012)
box('hob_steel_rim',(cx,cy,.89),(.90,.60,.045),steel,range_root,.018)
box('hob_recessed_enamel',(cx,cy,.915),(.866,.557,.014),enamel,range_root,.016)
burners=[('back_left',-.28,.16,.066),('front_left',-.28,-.16,.072),('center_wok',0,0,.096),('back_right',.28,.16,.072),('front_right',.28,-.16,.058)]
for name,dx,dy,r in burners:
    x,y=cx+dx,cy+dy
    cyl('burner_'+name+'_base',(x,y,.932),r+.014,.015,steel,range_root)
    cyl('burner_'+name+'_cap',(x,y,.945),r,.018,iron,range_root)
    if name=='center_wok':
        cyl('burner_center_wok_inner',(x,y,.958),.051,.009,steel,range_root)
        cyl('burner_center_wok_inner_cap',(x,y,.965),.041,.008,iron,range_root)
    for k in range(4):
        a=k*math.pi/2; distance=r+.022
        support=box('pan_support_'+name+'_'+str(k),(x+math.cos(a)*distance,y+math.sin(a)*distance,.976),(.075,.020,.020),iron,range_root,.005)
        support.rotation_euler.z=a
# Three grate frames visually organize the five burners, rather than six coins.
for i,dx in enumerate([-.28,0,.28]):
    w=.123; ylo,yhi=cy-.265,cy+.265
    pts=[(cx+dx-w,ylo,.968),(cx+dx+w,ylo,.968),(cx+dx+w,yhi,.968),(cx+dx-w,yhi,.968),(cx+dx-w,ylo,.968)]
    tube('grate_frame_%02d'%i,pts,.008,iron,range_root)
box('range_controls_fascia',(cx,3.578,.802),(.87,.05,.115),steel,range_root,.015)
for k in range(6):
    x=cx-.35+k*.14
    cyl('range_control_%02d'%k,(x,3.535,.806),.023,.035,iron,range_root,(math.pi/2,0,0))
    box('control_indicator_%02d'%k,(x,3.515,.818),(.004,.003,.011),enamel,range_root,.001)
box('oven_door_frame',(cx,3.582,.43),(.82,.045,.57),steel,range_root,.026)
box('oven_dark_glass',(cx,3.553,.415),(.70,.018,.43),glass,range_root,.025)
box('oven_inner_view',(cx,3.541,.411),(.57,.006,.30),dark,range_root,.020)
for dx in [-.27,.27]:box('oven_handle_mount',(cx+dx,3.524,.69),(.034,.075,.035),steel,range_root,.008)
box('oven_bar_handle',(cx,3.48,.69),(.63,.035,.032),steel,range_root,.012)
box('oven_bottom_drawer',(cx,3.577,.105),(.80,.034,.065),enamel,range_root,.01)

# A genuine cavity: cut both worktop and cabinet-body top, not a dark decal.
sinkroot=bpy.data.objects['sink_root'];clear_children(sinkroot)
cutter=box('temporary_sink_cutout',(.32,2.7,.86),(.438,.478,.34),iron,None,.045)
bpy.context.view_layer.objects.active=cutter
for mod in list(cutter.modifiers):bpy.ops.object.modifier_apply(modifier=mod.name)
for name in ['cabinet_sink_600_top','cabinet_sink_600_body']:
    o=bpy.data.objects[name];bpy.context.view_layer.objects.active=o
    mod=o.modifiers.new('sink_real_opening','BOOLEAN');mod.operation='DIFFERENCE';mod.object=cutter
    bpy.ops.object.modifier_apply(modifier=mod.name)
bpy.data.objects.remove(cutter,do_unlink=True)
bpy.context.view_layer.update()
top=bpy.data.objects['cabinet_sink_600_top']
origin=top.matrix_world.inverted()@Vector((.32,2.7,1.5))
direction=top.matrix_world.inverted().to_3x3()@Vector((0,0,-1))
assert not top.ray_cast(origin,direction)[0], 'Sink worktop opening is blocked'
def rounded_ring(w,h,r,z):
    pts=[]
    for x,y,start in [(w/2-r,h/2-r,0),(-w/2+r,h/2-r,90),(-w/2+r,-h/2+r,180),(w/2-r,-h/2+r,270)]:
        for i in range(9):
            a=math.radians(start+i*90/8);pts.append((.32+x+r*math.cos(a),2.7+y+r*math.sin(a),z))
    return pts
rings=[rounded_ring(.50,.54,.055,.915),rounded_ring(.426,.466,.065,.912),rounded_ring(.332,.372,.065,.738)]
verts=sum(rings,[]);n=len(rings[0]);faces=[]
for ring in range(2):
    for i in range(n):faces.append((ring*n+i,ring*n+(i+1)%n,(ring+1)*n+(i+1)%n,(ring+1)*n+i))
faces.append(tuple(range(2*n,3*n)))
mesh=bpy.data.meshes.new('sink_cavity_mesh');mesh.from_pydata(verts,[],faces);mesh.update()
bowl=bpy.data.objects.new('sink_true_basin',mesh);bpy.context.collection.objects.link(bowl);bowl.data.materials.append(steel);attach(bowl,sinkroot)
for poly in bowl.data.polygons:poly.use_smooth=True
# Consistent normals and a little shell thickness for the open basin.
bpy.context.view_layer.objects.active=bowl;bpy.ops.object.select_all(action='DESELECT');bowl.select_set(True)
bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT')
solid=bowl.modifiers.new('basin_shell','SOLIDIFY');solid.thickness=.002
cyl('sink_drain',(.32,2.7,.742),.031,.005,dark,sinkroot)
cyl('sink_drain_center',(.32,2.7,.746),.019,.004,steel,sinkroot)
for k in range(5):
    a=k*math.tau/5;cyl('drain_hole_%d'%k,(.32+.012*math.cos(a),2.7+.012*math.sin(a),.749),.0025,.002,iron,sinkroot)
# Gooseneck mixer with continuous bent tube, lever and downturned outlet.
tapx=.082;tapy=2.7
cyl('mixer_foot',(tapx,tapy,.929),.033,.025,steel,sinkroot)
points=[(tapx,tapy,.94),(tapx,tapy,1.16)]
for i in range(25):
    a=math.pi-i*math.pi/24
    points.append((.182+.10*math.cos(a),tapy,1.16+.10*math.sin(a)))
points.append((.282,tapy,1.115))
tube('mixer_gooseneck',points,.014,steel,sinkroot)
cyl('mixer_aerator',(.282,tapy,1.114),.017,.025,steel,sinkroot)
tube('mixer_lever',[(tapx,tapy+.034,.965),(tapx,tapy+.06,1.04)],.009,steel,sinkroot)

# Readable classic option: broad rails, stepped recessed field, raised panel,
# real brass pulls and modest cornices. This is an option, not chosen default.
cabmat=bpy.data.materials['cabinet'];cabmat.diffuse_color=(.62,.60,.49,1)
cabmat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=cabmat.diffuse_color
bpy.context.view_layer.update()
panels=[o for o in bpy.data.objects if o.type=='MESH' and o.parent and o.parent.name.startswith(('cabinet_','upper_','pantry_')) and (o.name.endswith('_front') or o.name=='pantry_door')]
assert len(panels)==13,len(panels)
for panel in panels:
    mn,mx=bounds(panel);left=(mx.x-mn.x)<(mx.y-mn.y)
    w=mx.y-mn.y if left else mx.x-mn.x;h=mx.z-mn.z
    u=(mn.y+mx.y)/2 if left else (mn.x+mx.x)/2;z=(mn.z+mx.z)/2
    normal=mx.x if left else mn.y;parent=panel.parent
    panel.data.materials.clear();panel.data.materials.append(fieldmat)
    prefix=panel.name.removesuffix('_front') if panel.name!='pantry_door' else 'pantry'
    handle=bpy.data.objects.get(prefix+'_handle')
    if handle:bpy.data.objects.remove(handle,do_unlink=True)
    def face(suffix,U,Z,W,H,depth,offset,material,bevel=.006):
        N=normal+offset if left else normal-offset
        return box(panel.name+'_'+suffix,(N,U,Z) if left else (U,N,Z),(depth,W,H) if left else (W,depth,H),material,parent,bevel)
    rail=.065
    for side in [-1,1]:
        face('classic_stile_'+str(side),u+side*(w/2-rail/2-.005),z,rail,h-.01,.032,.015,cream)
        face('classic_rail_'+str(side),u,z+side*(h/2-rail/2-.005),w-2*rail-.01,rail,.032,.015,cream)
        face('inner_bead_v_'+str(side),u+side*(w/2-rail-.014),z,.017,h-2*rail-.015,.025,.017,cream,.005)
        face('inner_bead_h_'+str(side),u,z+side*(h/2-rail-.014),w-2*rail-.045,.017,.025,.017,cream,.005)
    face('raised_center',u,z,w-.19,h-.19,.030,.017,panelmat,.018)
    pullu=u-w/2+.039 if left else u+w/2-.039
    pullz=z if panel.name=='pantry_door' else z+h*.23
    pullnormal=normal+.053 if left else normal-.053
    cyl(panel.name+'_brass_pull',(pullnormal,pullu,pullz) if left else (pullu,pullnormal,pullz),.016,.025,brass,parent,(0,math.pi/2,0) if left else (math.pi/2,0,0))
for rootname,x,width in [('upper_back_600',1.2,1.2),('upper_buffer_600',3.0,.6)]:
    r=bpy.data.objects[rootname]
    # One continuous cornice over the adjacent pair; avoid coplanar overlaps.
    box(rootname+'_classic_cornice_lower',(x,4.04,2.35),(width+.02,.35,.035),cream,r,.008)
    box(rootname+'_classic_cornice_top',(x,4.04,2.378),(width+.05,.38,.022),cream,r,.006)

bpy.context.view_layer.update()
assert len([o for o in bpy.data.objects if o.name.startswith('burner_') and o.name.endswith('_cap') and o.name!='burner_center_wok_inner_cap'])==5
assert len([o for o in bpy.data.objects if o.name.startswith('range_control_')])==6
assert 'temporary_sink_cutout' not in bpy.data.objects
cam=scene.camera;a=world_to_camera_view(scene,cam,Vector((0,4.2,2.7)));b=world_to_camera_view(scene,cam,Vector((4.2,0,0)))
assert abs(a.x-b.x)<1e-6
scene['stage']='r06 detailed appliances and classic facade option; approval pending'
scene['cabinet_style']='classic_option_unapproved'
scene.render.resolution_x=1400;scene.render.resolution_y=1400;scene.cycles.samples=48
scene.render.filepath=str(out/'kitchen-r06-classic.png')
bpy.ops.wm.save_as_mainfile(filepath=str(out/'sofra-kitchen-detail-r06.blend'))
bpy.ops.render.render(write_still=True)
bpy.ops.export_scene.gltf(filepath=str(out/'sofra-kitchen-detail-r06.glb'),export_format='GLB',export_cameras=True,export_lights=False)
for name,target,scale in [('range',(2.28,3.82,.95),1.80),('sink-classic',(.47,3.08,1.26),2.85)]:
    if name=='range' and '--reuse-range-render' in args:
        assert (out/'kitchen-r06-range.png').is_file()
        continue
    target=Vector(target);cam.location=target+Vector((8,-8,8));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=scale
    scene.render.filepath=str(out/('kitchen-r06-'+name+'.png'));bpy.ops.render.render(write_still=True)

bpy.ops.wm.open_mainfile(filepath=str(out/'sofra-kitchen-detail-r06.blend'))
assert abs(bpy.context.scene.camera.data.ortho_scale-7.2)<1e-5
meshcount=sum(o.type=='MESH' for o in bpy.data.objects)
anchors=[o.name for o in bpy.data.objects if o.name.startswith('decor_shelf_')]
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(out/'sofra-kitchen-detail-r06.glb'))
assert all('burner_'+n+'_cap' in bpy.data.objects for n,_,_,_ in burners)
assert all(n in bpy.data.objects for n in anchors)
assert 'sink_true_basin' in bpy.data.objects
assert 'mixer_gooseneck' in bpy.data.objects and 'grate_frame_00' in bpy.data.objects
report={'blender':bpy.app.version_string,'burners':5,'control_knobs':6,'center_burner':'larger wok double ring','sink_depth_m':.174,'real_worktop_and_cabinet_cutouts':True,'classic_fronts':len(panels),'style_default_selected':False,'decoration_anchors_preserved':len(anchors),'square_corner_alignment_error_px':abs(a.x-b.x)*1400,'blend_reopened':True,'glb_reimported':True,'source_mesh_objects':meshcount,'glb_bytes':(out/'sofra-kitchen-detail-r06.glb').stat().st_size,'base_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'runtime_ready':False,'visual_approval_pending':True}
(out/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print('SOFRA_R06_COMPLETE',json.dumps(report))
