"""Sofra r12 genuine Blender colorful cartoon refinement, local review only."""
import bpy,math,json,hashlib,sys
from pathlib import Path
from mathutils import Vector
out=Path(__file__).parent
source=Path(r'E:\work\SOFRA\app\design-assets\blender\kitchen-cozy-r11-20261024\cozy-morning-r11.blend')
bpy.ops.wm.open_mainfile(filepath=str(source));s=bpy.context.scene
preview='--preview' in sys.argv

def mat(n,c,rough=.65,metal=0):
 m=bpy.data.materials.new(n);m.use_nodes=True;m.diffuse_color=(*c,1);p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal;return m

def assign(o,m):o.data.materials.clear();o.data.materials.append(m)
def parent(o,r):
 w=o.matrix_world.copy();o.parent=r;o.matrix_world=w

def tube(n,pts,r,m,closed=False,root=None):
 c=bpy.data.curves.new(n,'CURVE');c.dimensions='3D';c.bevel_depth=r;c.bevel_resolution=3;sp=c.splines.new('POLY');sp.points.add(len(pts)-1)
 for p,co in zip(sp.points,pts):p.co=(*co,1)
 sp.use_cyclic_u=closed;o=bpy.data.objects.new(n,c);bpy.context.collection.objects.link(o);o.data.materials.append(m)
 if root:parent(o,root)
 return o

def sphere(n,loc,scale,m):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=12,location=loc);o=bpy.context.object;o.name=n;o.scale=scale;assign(o,m)
 for p in o.data.polygons:p.use_smooth=True
 return o

def cylinder(n,loc,r,h,m):
 bpy.ops.mesh.primitive_cylinder_add(vertices=32,radius=r,depth=h,location=loc);o=bpy.context.object;o.name=n;assign(o,m);be=o.modifiers.new('rounded','BEVEL');be.width=min(.012,h*.15);be.segments=3;o.modifiers.new('normals','WEIGHTED_NORMAL');return o

teal=mat('r12_unified_jade',(.025,.31,.21),.48);wall=mat('r12_warm_butter_wall',(.91,.78,.49),.82);steel=mat('r12_range_satin_metal',(.43,.51,.55),.28,.78);coral=mat('r12_coral_linen',(.76,.22,.12),.92);yellow=mat('r12_sunshine_ceramic',(.95,.54,.055),.33);terracotta=mat('r12_coral_ceramic',(.72,.18,.09),.4);cream=mat('r12_ivory_ceramic',(.92,.84,.65),.3);leafmat=mat('r12_leaf_green',(.065,.31,.06),.7);brass=bpy.data.materials['r06_muted_brass'];iron=bpy.data.materials['r06_cast_iron']
for o in bpy.data.objects:
 if o.type=='MESH' and o.name.startswith(('cabinet_','pantry_','upper_')) and not o.name.endswith('_top') and 'brass_pull' not in o.name:assign(o,teal)
 if o.name.startswith('wall_') or o.name.startswith('enclosure_'):assign(o,wall)
 if o.name.startswith('open_shelf_'):assign(o,teal)
# Replace white enamel insert with continuous matching metal; simplify heavy supports.
assign(bpy.data.objects['hob_recessed_enamel'],steel);bpy.data.objects['hob_recessed_enamel'].name='hob_metal_inset'
assign(bpy.data.objects['hob_steel_rim'],steel);assign(bpy.data.objects['range_enamel_body'],steel)
root=bpy.data.objects['range_slot_900']
for o in list(bpy.data.objects):
 if o.name.startswith('cast_grate_ring_') or o.name.startswith('grate_contact_foot_'):bpy.data.objects.remove(o,do_unlink=True)
for o in bpy.data.objects:
 if o.name.startswith(('grate_x_finger_','grate_y_finger_','grate_center_bridge_')):
  d=list(o.dimensions);d[2]=.012
  if o.name.startswith('grate_x_') or o.name.startswith('grate_center_'):d[1]=.012
  else:d[0]=.012
  o.dimensions=d
  for mod in o.modifiers:
   if mod.type=='BEVEL':mod.width=.003
for i,x in enumerate([1.37,1.65,1.93]):
 y=3.3;w=.248;h=.516;rad=.025;pts=[]
 for cx,cy,start in [(x+w/2-rad,y+h/2-rad,0),(x-w/2+rad,y+h/2-rad,90),(x-w/2+rad,y-h/2+rad,180),(x+w/2-rad,y-h/2+rad,270)]:
  for j in range(7):
   a=math.radians(start+j*15);pts.append((cx+rad*math.cos(a),cy+rad*math.sin(a),.975))
 tube('r12_slim_grate_ring_'+str(i),pts,.006,iron,True,root)
 for sx in [-1,1]:
  for sy in [-1,1]:tube('r12_support_foot_'+str(i)+'_'+str(sx)+'_'+str(sy),[(x+sx*(.099+.025/math.sqrt(2)),y+sy*(.233+.025/math.sqrt(2)),.922),(x+sx*(.099+.025/math.sqrt(2)),y+sy*(.233+.025/math.sqrt(2)),.975)],.006,iron,root=root)
handle=bpy.data.objects['fridge_door_handle'];before=handle.matrix_world.translation.z;handle.location.z+=.20
# New draped fabric: generous heading, softer diagonal inner edge, rounded gathered tie.
curtain=bpy.data.objects['curtain_root_optional']
for o in list(bpy.data.objects):
 if o.name.startswith(('curtain_panel_','curtain_tie_')):bpy.data.objects.remove(o,do_unlink=True)
for side,sign,edge in [('front',1,1.46),('rear',-1,2.74)]:
 verts=[];faces=[];R=60;C=36
 for j in range(R+1):
  z=1.18+1.19*j/R;t=max(0,(z-1.62)/.75)
  if z<1.62:
   q=(1.62-z)/.44;width=.13+.04*q;outer=-.01*q
  else:width=.13+.25*math.sin(t*math.pi/2);outer=-.018*math.sin(t*math.pi)
  for i in range(C+1):
   u=i/C;phase=u*math.tau*4;x=.15+.018*math.cos(phase)+.055*math.sin(t*math.pi);y=edge+sign*(outer+width*u)
   # Gentle uneven hem and softly rolled pleats, no rigid razor-sharp ribbon.
   zz=z+(.008*math.cos(phase) if j==0 else 0)
   verts.append((x,y,zz))
 for j in range(R):
  for i in range(C):a=j*(C+1)+i;faces.append((a,a+1,a+C+2,a+C+1))
 mesh=bpy.data.meshes.new('r12_soft_fabric_'+side);mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new('curtain_panel_'+side,mesh);bpy.context.collection.objects.link(o);assign(o,coral)
 for p in mesh.polygons:p.use_smooth=True
 mod=o.modifiers.new('soft_cloth','SUBSURF');mod.levels=1;mod.render_levels=1;mod=o.modifiers.new('fabric_thickness','SOLIDIFY');mod.thickness=.002;parent(o,curtain)
 # Fabric band follows gathered volume, not a square gold block.
 pts=[(.15+.033*math.cos(a),edge+sign*.064+.078*math.sin(a),1.62+.009*math.sin(a)) for a in [j*math.tau/40 for j in range(40)]]
 tie=tube('curtain_tie_'+side,pts,.009,cream,True,curtain)
 sphere('curtain_knot_'+side,(.183,edge+sign*.035,1.62),(.023,.022,.025),coral)
 for i,o in enumerate(sorted([o for o in bpy.data.objects if o.name.startswith('curtain_ring_'+side)],key=lambda o:o.name)):
  w=o.matrix_world.copy();w.translation.y=edge+sign*(.025+.33*i/2);o.matrix_world=w
curtain['variant']='r12_soft_draped_linen_fabric_ties'
# Small accessory groups, leaving hob and sink usable and window clear.
# Potted herb with explicitly modeled stems and leaves, upper shelf.
def plant(x,y,z):
 cylinder('decor_herb_pot',(x,y,z+.065),.075,.13,terracotta);soil=mat('r12_soil',(.065,.035,.018));cylinder('decor_pot_soil',(x,y,z+.13),.062,.008,soil)
 for i in range(7):
  a=i*2.4;tip=Vector((x+.075*math.cos(a),y+.075*math.sin(a),z+.25+.03*(i%3)));tube('decor_herb_stem_'+str(i),[(x,y,z+.13),tip],.003,leafmat)
  for sign in [-1,1]:
   leaf=sphere('decor_herb_leaf_'+str(i)+'_'+str(sign),tip+Vector((sign*.025,0,-.025)),(.042,.014,.018),leafmat);leaf.rotation_euler.y=sign*.5;leaf.rotation_euler.z=a
plant(.27,3.43,2.338)
# Two rounded storage jars on middle shelf.
for i,(x,h,m) in enumerate([(.17,.16,yellow),(.43,.19,cream)]):
 cylinder('decor_jar_'+str(i),(x,3.43,1.988+h/2),.064,h,m);cylinder('decor_jar_lid_'+str(i),(x,3.43,1.988+h+.009),.068,.018,brass);sphere('decor_jar_knob_'+str(i),(x,3.43,1.988+h+.026),(.014,.014,.012),brass)
# Two mugs on lower shelf.
for i,x in enumerate([.17,.43]):
 cylinder('decor_mug_'+str(i),(x,3.43,1.638+.055),.048,.11,yellow if i else coral)
 tube('decor_mug_handle_'+str(i),[(x+.055+.035*math.cos(a),3.43,1.693+.036*math.sin(a)) for a in [j*math.tau/24 for j in range(24)]],.009,cream,True)
# Utensil crock on prep counter, well away from the burners.
cylinder('decor_utensil_crock',(.89,3.43,1.01),.071,.19,yellow)
for i in range(3):
 x=.85+.035*i;tube('decor_wood_spoon_'+str(i),[(x,3.43,.98),(x+(i-1)*.02,3.43,1.26)],.009,brass);sphere('decor_spoon_bowl_'+str(i),(x+(i-1)*.02,3.43,1.28),(.025,.012,.040),brass)
# Fruit in a shallow ceramic bowl on front counter.
cylinder('decor_fruit_bowl',(.31,1.37,.94),.12,.045,cream)
for i,(dx,dy) in enumerate([(-.045,0),(.045,0),(0,.065)]):sphere('decor_citrus_'+str(i),(.31+dx,1.37+dy,1.005),(.050,.050,.050),yellow)
# Brighter warm wall from its own material and real window bounce. No added studio light.
s.view_settings.exposure=.25;s.view_settings.look='AgX - Medium High Contrast'
prefs=bpy.context.preferences.addons['cycles'].preferences;prefs.compute_device_type='OPTIX';prefs.get_devices()
for d in prefs.devices:d.use=d.type=='OPTIX'
s.cycles.device='GPU';s.cycles.samples=128 if preview else 512;s.render.resolution_x=s.render.resolution_y=900 if preview else 1400
s['stage']='r12 vivid cartoon color, soft fabric, slim metal hob, accessories';s.render.filepath=str(out/('preview.png' if preview else 'morning-r12.png'))
bpy.context.view_layer.update();assert abs(handle.matrix_world.translation.z-before-.2)<1e-4
assert len([o for o in bpy.data.objects if o.name.startswith('r12_slim_grate_ring_')])==3
assert len([o for o in bpy.data.objects if o.name.startswith('burner_') and o.name.endswith('_cap') and 'inner' not in o.name])==5
bpy.ops.wm.save_as_mainfile(filepath=str(out/('preview.blend' if preview else 'morning-r12.blend')));bpy.ops.render.render(write_still=True)
report={'revision':12,'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'unified_cabinet_material':'r12_unified_jade','wall_material':'r12_warm_butter_wall','grate_tube_diameter_m':.012,'white_enamel_hob_replaced_by_metal':True,'five_burners_retained':True,'lower_fridge_handle_raised_m':.2,'curtain':'replaced soft subdivided drape with fabric ties','accessories':['herb','2storagejars','2mugs','spooncrock','citrusbowl'],'footprint_m':[3.9,3.9],'visual_approval_pending':True,'runtime_implemented':False}
if not preview:
 bpy.ops.wm.open_mainfile(filepath=str(out/'morning-r12.blend'));s=bpy.context.scene
 for o in list(bpy.data.objects):
  if o.type=='LIGHT' or o.name=='morning_indoor_scattering':bpy.data.objects.remove(o,do_unlink=True)
 em=next(n for n in bpy.data.objects['window_view_no_illumination'].data.materials[0].node_tree.nodes if n.type=='EMISSION');em.inputs['Color'].default_value=(.01,.018,.035,1);em.inputs['Strength'].default_value=.3
 bpy.ops.object.light_add(type='SPOT',location=(1.95,1.65,2.635));lamp=bpy.context.object;lamp.name='ceiling_vintage_center_lamp';lamp.data.energy=160;lamp.data.color=(1,.87,.68);lamp.data.spot_size=math.radians(100);lamp.data.spot_blend=.8;lamp.data.shadow_soft_size=.16;lamp.rotation_euler=(0,0,0)
 s.view_settings.exposure=0;s.cycles.samples=192;s.render.filepath=str(out/'night-r12.png');s['lighting_study']='single centered warm ceiling spotlight with soft edge falloff; no LED'
 bpy.ops.wm.save_as_mainfile(filepath=str(out/'night-r12.blend'));bpy.ops.render.render(write_still=True)
 report['night']={'type':'SPOT','watts':160,'cone_degrees':100,'edge_blend':.8,'radius_m':.16,'color':[1,.87,.68],'under_cabinet_LED':False}
(out/('preview-verification.json' if preview else 'verification.json')).write_text(json.dumps(report,indent=2));print('R12_RENDER_COMPLETE')
