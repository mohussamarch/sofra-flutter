"""r13: real Blender soft nostalgic cartoon kitchen. Local review only."""
import bpy,math,json,hashlib,sys,bmesh
from pathlib import Path
from mathutils import Vector
out=Path(__file__).parent;preview='--preview' in sys.argv
source=Path(r'E:\work\SOFRA\app\design-assets\blender\kitchen-color-r12-20261024\morning-r12.blend')
bpy.ops.wm.open_mainfile(filepath=str(source));s=bpy.context.scene

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

# Root cause of edge steps: mismatched base perimeter and multiple touching wall boxes.
wall=mat('r13_soft_cream_plaster',(.83,.73,.54),.84)
for n in ['wall_back','wall_left_low','wall_left_high','wall_left_front','wall_left_rear']:
 bpy.data.objects.remove(bpy.data.objects[n],do_unlink=True)
verts=[];vmap={};faces={}
def cell(x0,x1,y0,y1,z0,z1):
 coords=[(x0,y0,z0),(x1,y0,z0),(x1,y1,z0),(x0,y1,z0),(x0,y0,z1),(x1,y0,z1),(x1,y1,z1),(x0,y1,z1)];ids=[]
 for p in coords:
  key=tuple(round(v,6) for v in p)
  if key not in vmap:vmap[key]=len(verts);verts.append(p)
  ids.append(vmap[key])
 for f in [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]:
  face=tuple(ids[i] for i in f);key=tuple(sorted(face))
  if key in faces:del faces[key]
  else:faces[key]=face
ys=[-.42,1.5,2.7,3.6,3.72];zs=[0,1.2,2.3,2.7]
for i in range(4):
 for j in range(3):
  if i==1 and j==1:continue
  cell(-.12,0,ys[i],ys[i+1],zs[j],zs[j+1])
for j in range(3):cell(0,4.02,3.6,3.72,zs[j],zs[j+1])
mesh=bpy.data.meshes.new('continuous_L_walls');mesh.from_pydata(verts,[],list(faces.values()));mesh.update();o=bpy.data.objects.new('r13_continuous_room_walls',mesh);bpy.context.collection.objects.link(o);assign(o,wall)
# Remove collinear face subdivisions where possible, keep true window aperture.
bm=bmesh.new();bm.from_mesh(mesh);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));nonmanifold=sum(not e.is_manifold for e in bm.edges);bm.to_mesh(mesh);bm.free();assert nonmanifold==0,nonmanifold
be=o.modifiers.new('continuous_soft_corners','BEVEL');be.width=.012;be.segments=4;o.modifiers.new('soft_wall_normals','WEIGHTED_NORMAL')
floor=bpy.data.objects['floor_plinth'];floor.dimensions=(4.14,4.14,.18)
for m in floor.modifiers:
 if m.type=='BEVEL':m.width=.025;m.segments=5
for o in bpy.data.objects:
 if o.name.startswith('enclosure_'):assign(o,wall)
# Muted painted timber: broad gentle grain, no realistic scratch/noise overload.
wood=mat('r13_faded_teal_painted_wood',(.18,.33,.28),.65);n=wood.node_tree.nodes;l=wood.node_tree.links;p=n.get('Principled BSDF');geom=n.new('ShaderNodeNewGeometry');mapping=n.new('ShaderNodeVectorMath');mapping.operation='MULTIPLY';mapping.inputs[1].default_value=(9,9,.65);l.new(geom.outputs['Position'],mapping.inputs[0]);noise=n.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=3;noise.inputs['Detail'].default_value=1.1;noise.inputs['Roughness'].default_value=.45;l.new(mapping.outputs[0],noise.inputs['Vector']);ramp=n.new('ShaderNodeValToRGB');ramp.color_ramp.elements[0].position=.18;ramp.color_ramp.elements[0].color=(.175,.30,.255,1);ramp.color_ramp.elements[1].position=.82;ramp.color_ramp.elements[1].color=(.225,.355,.30,1);l.new(noise.outputs['Fac'],ramp.inputs[0]);l.new(ramp.outputs[0],p.inputs['Base Color']);bump=n.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.07;bump.inputs['Distance'].default_value=.0005;l.new(noise.outputs['Fac'],bump.inputs['Height']);l.new(bump.outputs[0],p.inputs['Normal'])
for o in bpy.data.objects:
 if o.type=='MESH' and o.name.startswith(('cabinet_','pantry_','upper_','open_shelf_')) and not o.name.endswith('_top') and 'brass_pull' not in o.name:assign(o,wood)
# Actual open rectangular duct: wall thickness10mm, top has annular rim, no cap.
old=bpy.data.objects['hood_duct'];v=[old.matrix_world@Vector(c) for c in old.bound_box];x0,x1=min(p.x for p in v),max(p.x for p in v);y0,y1=min(p.y for p in v),max(p.y for p in v);z0,z1=min(p.z for p in v),max(p.z for p in v);bpy.data.objects.remove(old,do_unlink=True)
metal=bpy.data.materials['r11_satin_steel'];w=.010;loops=[[(x0,y0),(x1,y0),(x1,y1),(x0,y1)],[(x0+w,y0+w),(x1-w,y0+w),(x1-w,y1-w),(x0+w,y1-w)]];vs=[(x,y,z) for z in [z0,z1] for loop in loops for x,y in loop];fs=[]
for i in range(4):
 j=(i+1)%4;fs += [(i,j,8+j,8+i),(4+j,4+i,12+i,12+j),(8+i,8+j,12+j,12+i),(j,i,4+i,4+j)]
m=bpy.data.meshes.new('open_duct_shell');m.from_pydata(vs,[],fs);m.update();duct=bpy.data.objects.new('hood_duct_open_top',m);bpy.context.collection.objects.link(duct);assign(duct,metal);be=duct.modifiers.new('rolled_metal_rim','BEVEL');be.width=.0025;be.segments=3;duct.modifiers.new('normals','WEIGHTED_NORMAL');parent(duct,bpy.data.objects['hood_root'])
# Cotton gingham weave with actual translucent backlighting.
cotton=mat('r13_cotton_gingham',(.84,.61,.41),.95);n=cotton.node_tree.nodes;l=cotton.node_tree.links;p=n.get('Principled BSDF');pos=n.new('ShaderNodeNewGeometry');sep=n.new('ShaderNodeSeparateXYZ');l.new(pos.outputs['Position'],sep.inputs[0]);bands=[]
for axis in ['Y','Z']:
 mult=n.new('ShaderNodeMath');mult.operation='MULTIPLY';mult.inputs[1].default_value=math.tau/.12;l.new(sep.outputs[axis],mult.inputs[0]);sin=n.new('ShaderNodeMath');sin.operation='SINE';l.new(mult.outputs[0],sin.inputs[0]);gt=n.new('ShaderNodeMath');gt.operation='GREATER_THAN';gt.inputs[1].default_value=0;l.new(sin.outputs[0],gt.inputs[0]);bands.append(gt)
add=n.new('ShaderNodeMath');add.operation='ADD';l.new(bands[0].outputs[0],add.inputs[0]);l.new(bands[1].outputs[0],add.inputs[1]);half=n.new('ShaderNodeMath');half.operation='MULTIPLY';half.inputs[1].default_value=.5;l.new(add.outputs[0],half.inputs[0]);cr=n.new('ShaderNodeValToRGB');cr.color_ramp.interpolation='CONSTANT';cr.color_ramp.elements[0].color=(.92,.81,.63,1);cr.color_ramp.elements[1].position=.75;cr.color_ramp.elements[1].color=(.48,.19,.10,1);cr.color_ramp.elements.new(.25).color=(.73,.40,.23,1);l.new(half.outputs[0],cr.inputs[0]);l.new(cr.outputs[0],p.inputs['Base Color']);trans=n.new('ShaderNodeBsdfTranslucent');l.new(cr.outputs[0],trans.inputs[0]);mix=n.new('ShaderNodeMixShader');mix.inputs[0].default_value=.25;l.new(p.outputs[0],mix.inputs[1]);l.new(trans.outputs[0],mix.inputs[2]);l.new(mix.outputs[0],n.get('Material Output').inputs['Surface'])
root=bpy.data.objects['curtain_root_optional'];ties=mat('r13_cotton_ties',(.80,.65,.41),.9)
for o in list(bpy.data.objects):
 if o.name.startswith(('curtain_panel_','curtain_tie_','curtain_knot_')):bpy.data.objects.remove(o,do_unlink=True)
for side,sign,edge in [('front',1,1.47),('rear',-1,2.73)]:
 vs=[];fs=[];R=64;C=40
 for j in range(R+1):
  z=1.18+1.19*j/R;t=max(0,(z-1.59)/.78)
  width=.115+.045*(1.59-z)/.41 if z<1.59 else .115+.225*(t**.62)
  for i in range(C+1):
   u=i/C;x=.125+.012*math.cos(u*math.tau*4);y=edge+sign*width*u
   vs.append((x,y,z+.004*math.cos(u*math.tau*4)*(1-j/R)))
 for j in range(R):
  for i in range(C):a=j*(C+1)+i;fs.append((a,a+1,a+C+2,a+C+1))
 me=bpy.data.meshes.new('flat_draped_gingham_'+side);me.from_pydata(vs,[],fs);me.update();o=bpy.data.objects.new('curtain_panel_'+side,me);bpy.context.collection.objects.link(o);assign(o,cotton)
 for f in me.polygons:f.use_smooth=True
 mod=o.modifiers.new('soft_cotton','SUBSURF');mod.levels=1;mod.render_levels=1;mod=o.modifiers.new('cotton_thickness','SOLIDIFY');mod.thickness=.0015;parent(o,root)
 pts=[(.125+.023*math.cos(a),edge+sign*.0575+.066*math.sin(a),1.59) for a in [i*math.tau/40 for i in range(40)]];o=tube('curtain_tie_'+side,pts,.007,ties,True);parent(o,root)
 # Small flat bow tails, not a wind-inflated knot.
 for d in [-1,1]:
  o=tube('curtain_bow_'+side+'_'+str(d),[(.15,edge+sign*.04,1.59),(.15,edge+sign*(.04+d*.023),1.56),(.15,edge+sign*(.04+d*.015),1.53)],.006,ties);parent(o,root)
 for i,o in enumerate(sorted([o for o in bpy.data.objects if o.name.startswith('curtain_ring_'+side)],key=lambda o:o.name)):
  mt=o.matrix_world.copy();mt.translation.y=edge+sign*(.02+.30*i/2);o.matrix_world=mt
root['variant']='flat_cotton_gingham_tied_pair_no_billow'
# Electrical sockets: decorative modeled plates/holes, not functional wiring.
ivory=mat('r13_socket_ivory',(.86,.79,.63),.5);hole=mat('r13_socket_holes',(.095,.075,.045),.9)
for i,x in enumerate([.9,2.4]):
 box('outlet_back_plate_'+str(i),(x,3.583,1.18),(.19,.022,.105),ivory)
 for c in [-1,1]:
  for d in [-1,1]:sphere('outlet_back_hole_'+str(i)+'_'+str(c)+'_'+str(d),(x+c*.044+d*.013,3.569,1.18),(.006,.003,.007),hole)
box('outlet_left_plate',(.014,1.38,1.16),(.024,.18,.10),ivory)
for c in [-1,1]:
 for d in [-1,1]:sphere('outlet_left_hole_'+str(c)+'_'+str(d),(.028,1.38+c*.043+d*.013,1.16),(.003,.006,.007),hole)
# Fridge lived-in touches: original flat magnets, a heart/star and a generic note.
coral=mat('r13_sticker_coral',(.78,.23,.13),.55);gold=mat('r13_sticker_gold',(.96,.61,.09),.5);paper=mat('r13_note_paper',(.90,.82,.56),.9);ink=mat('r13_note_ink',(.20,.28,.25),.9)
def decal(n,x,z,points,m):
 me=bpy.data.meshes.new(n);me.from_pydata([(x+px,2.794,z+pz) for px,pz in points],[],[tuple(range(len(points)))]);me.update();o=bpy.data.objects.new(n,me);bpy.context.collection.objects.link(o);assign(o,m);parent(o,bpy.data.objects['freezer_door']);return o
heart=[(.052*math.sin(t)**3,.0033*(13*math.cos(t)-5*math.cos(2*t)-2*math.cos(3*t)-math.cos(4*t))) for t in [i*math.tau/64 for i in range(64)]];decal('fridge_heart_magnet',2.94,1.73,heart,coral)
star=[((.064 if i%2==0 else .029)*math.sin(i*math.pi/5),(.064 if i%2==0 else .029)*math.cos(i*math.pi/5)) for i in range(10)];decal('fridge_star_sticker',3.18,1.88,star,gold)
o=box('fridge_note',(3.08,2.794,1.12),(.17,.002,.16),paper,.004);parent(o,bpy.data.objects['fridge_door'])
for i,w in enumerate([.10,.12,.075]):
 o=box('fridge_note_line_'+str(i),(3.075,2.791,1.15-.033*i),(w,.001,.004),ink,.001);parent(o,bpy.data.objects['fridge_door'])
o=sphere('fridge_note_round_magnet',(3.08,2.788,1.197),(.018,.006,.018),coral);parent(o,bpy.data.objects['fridge_door'])
# Camera-only blue sky/garden: cannot cast shadows or affect diffuse/glossy rays.
card=bpy.data.objects['window_view_no_illumination'];sky=flatmat('r13_blue_sky_camera_only',(.08,.38,.95),.8);assign(card,sky)
# Increase card behind aperture enough to cover oblique orthographic sightlines.
card.location=(-.50,2.60,1.25);card.dimensions=(.01,1.20,1.10)
bpy.ops.object.empty_add(type='PLAIN_AXES');garden=bpy.context.object;garden.name='exterior_garden_camera_only'
leafm=[flatmat('r13_garden_leaf_'+str(i),c,.8) for i,c in enumerate([(.15,.39,.07),(.25,.52,.10),(.38,.62,.17)])];bark=flatmat('r13_garden_stem',(.29,.25,.10),.7)
for k,(cy,cz) in enumerate([(2.05,1.12),(2.75,1.28)]):
 o=camera_only(tube('exterior_stem_'+str(k),[(-.26,cy,cz-.3),(-.26,cy,cz+.33)],.015,bark));parent(o,garden)
 for i in range(9):
  a=i*2.4;y=cy+.15*math.cos(a);z=cz+.08+.22*math.sin(a)
  o=camera_only(sphere('exterior_leaf_'+str(k)+'_'+str(i),(-.27,y,z),(.025,.11,.09),leafm[i%3]));parent(o,garden)
for o in [card]+list(garden.children):camera_only(o)
# Morning: softer, lower-angle golden path over cooker/floor/lower refrigerator.
sun=bpy.data.objects['window_golden_sun'];direction=Vector((1,.24,-.54)).normalized();sun.rotation_euler=direction.to_track_quat('-Z','Y').to_euler();sun.data.energy=24;sun.data.color=(1,.54,.16);sun.data.angle=math.radians(7)
bpy.data.objects['window_diffuse_daylight'].data.energy=180
bpy.data.objects['window_diffuse_daylight'].data.color=(1,.88,.72)
volume=bpy.data.materials['r09_subtle_sunbeam_volume'].node_tree.nodes.get('Volume Scatter');volume.inputs['Density'].default_value=.022;volume.inputs['Anisotropy'].default_value=.20
# A few camera-only drawn dust glints; no additional illumination.
spark=flatmat('r13_dream_dust', (1,.73,.32),1.8)
for i in range(7):
 x=.50+i*.26;y=2.13+.09*i;z=1.85-.16*i
 camera_only(sphere('morning_dream_mote_'+str(i),(x,y,z),(.005,.005,.005),spark))
# Subtle highlight bloom, not a blur over the geometry.
g=bpy.data.node_groups.new('r13_soft_highlight_glow','CompositorNodeTree');g.interface.new_socket(name='Image',in_out='OUTPUT',socket_type='NodeSocketColor');rl=g.nodes.new('CompositorNodeRLayers');gl=g.nodes.new('CompositorNodeGlare');gl.inputs['Type'].default_value='Fog Glow';gl.inputs['Quality'].default_value='High';gl.inputs['Threshold'].default_value=1.2;gl.inputs['Strength'].default_value=.22;gl.inputs['Size'].default_value=.22;end=g.nodes.new('NodeGroupOutput');g.links.new(rl.outputs['Image'],gl.inputs['Image']);g.links.new(gl.outputs['Image'],end.inputs['Image']);s.compositing_node_group=g
s.view_settings.look='AgX - Medium High Contrast';s.view_settings.exposure=.25
prefs=bpy.context.preferences.addons['cycles'].preferences;prefs.compute_device_type='OPTIX';prefs.get_devices()
for d in prefs.devices:d.use=d.type=='OPTIX'
s.cycles.device='GPU';s.cycles.samples=128 if preview else 512;s.render.resolution_x=s.render.resolution_y=900 if preview else 1400
s['stage']='r13 soft dreamy golden nostalgia, cotton gingham, open duct and lived-in touches';s.render.filepath=str(out/('preview.png' if preview else 'morning-r13.png'))
bpy.ops.wm.save_as_mainfile(filepath=str(out/('preview.blend' if preview else 'morning-r13.blend')));bpy.ops.render.render(write_still=True)
r={'revision':13,'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'continuous_wall_nonmanifold_edges':nonmanifold,'base_outer_dimensions_m':[4.14,4.14],'interior_square_m':3.9,'hood_top_open':True,'duct_wall_mm':10,'cotton_translucency':.25,'curtain_billow_removed':True,'cabinet':'muted faded teal with gentle procedural timber grain','outlet_plates':3,'fridge_stickers_and_note':True,'sun_direction':list(direction),'sun_angle_degrees':7,'sun_energy':24,'window_diffuse_watts':180,'outside_garden_camera_only':True,'subtle_compositor_glow':True,'visual_approval_pending':True,'runtime_implemented':False}
if not preview:
 bpy.ops.wm.open_mainfile(filepath=str(out/'morning-r13.blend'));s=bpy.context.scene
 for o in list(bpy.data.objects):
  if o.type=='LIGHT' or o.name=='morning_indoor_scattering' or o.name.startswith('morning_dream_mote_'):bpy.data.objects.remove(o,do_unlink=True)
 for o in bpy.data.objects['exterior_garden_camera_only'].children:o.hide_render=True
 sky=bpy.data.objects['window_view_no_illumination'].data.materials[0];em=next(n for n in sky.node_tree.nodes if n.type=='EMISSION');em.inputs['Color'].default_value=(.01,.018,.035,1);em.inputs['Strength'].default_value=.3
 bpy.ops.object.light_add(type='SPOT',location=(1.95,1.65,2.635));lamp=bpy.context.object;lamp.name='ceiling_vintage_center_lamp';lamp.data.energy=200;lamp.data.color=(1,.87,.68);lamp.data.spot_size=math.radians(100);lamp.data.spot_blend=.8;lamp.data.shadow_soft_size=.24;lamp.rotation_euler=(0,0,0)
 s.view_settings.exposure=0;s.cycles.samples=192;s.render.filepath=str(out/'night-r13.png');s['lighting_study']='r12 distribution retained, strength+25percent, softer shadows,noLED'
 bpy.ops.wm.save_as_mainfile(filepath=str(out/'night-r13.blend'));bpy.ops.render.render(write_still=True)
 r['night']={'watts':200,'power_increase_percent':25,'cone_degrees':100,'edge_blend':.8,'shadow_radius_m':.24,'LED':False}
(out/('preview-verification.json' if preview else 'verification.json')).write_text(json.dumps(r,indent=2));print('R13_RENDER_COMPLETE')
