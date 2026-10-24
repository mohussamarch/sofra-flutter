"""r11: local, actual Blender cozy color/geometry study, derived from r10."""
import bpy,math,json,hashlib,sys
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
out=Path(__file__).parent
source=Path(r'E:\work\SOFRA\app\design-assets\blender\kitchen-golden-r10-20261024\morning-golden-stronger-r10.blend')
bpy.ops.wm.open_mainfile(filepath=str(source));s=bpy.context.scene
preview='--preview' in sys.argv

def mat(name,c,rough=.7,metal=0):
 m=bpy.data.materials.get(name) or bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*c,1)
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
 return m

def box(name,loc,dim,m,bevel=.008):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=dim;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(m)
 if bevel:
  b=o.modifiers.new('soft_cartoon_edges','BEVEL');b.width=bevel;b.segments=4;o.modifiers.new('corner_normals','WEIGHTED_NORMAL')
 return o

def assign(o,m):
 o.data.materials.clear();o.data.materials.append(m)

def parent(o,p):
 w=o.matrix_world.copy();o.parent=p;o.matrix_world=w

def bounds(o):
 v=[o.matrix_world@Vector(c) for c in o.bound_box];return [[min(p[i] for p in v),max(p[i] for p in v)] for i in range(3)]

# Color study: no invented decorative clutter, maintain recognizable chosen geometry.
sage=mat('r11_sage_body',(.28,.43,.32));frame=mat('r11_sage_frame',(.36,.51,.38));panel=mat('r11_sage_panel',(.40,.55,.42));recess=mat('r11_sage_recess',(.24,.36,.27))
cream=mat('r11_upper_vanilla',(.83,.75,.58));upperpanel=mat('r11_upper_panel',(.9,.82,.66));warmwall=mat('wall',(.78,.69,.53));tile=mat('tile',(.65,.47,.30));tile2=mat('r11_tile_honey',(.74,.56,.37));plinth=mat('floor',(.42,.29,.17));counter=mat('worktop',(.86,.79,.65),.55)
fridge=mat('fridge',(.86,.77,.55),.35);steel=mat('r11_satin_steel',(.48,.55,.57),.30,.8);linen=mat('r11_peach_linen',(.68,.31,.20),.92);brass=mat('r06_muted_brass',(.57,.32,.10),.32,.65)
removed=[]
for o in list(bpy.data.objects):
 if 'cornice' in o.name or o.name=='preparation_board' or o.name.startswith('curtain_panel_'):
  removed.append(o.name);bpy.data.objects.remove(o,do_unlink=True)
for o in bpy.data.objects:
 if o.type!='MESH':continue
 n=o.name
 if n.startswith(('cabinet_','pantry_','upper_')):
  if 'brass_pull' in n:assign(o,brass)
  elif n.endswith('_top'):assign(o,counter)
  elif 'raised_center' in n:assign(o,upperpanel if n.startswith('upper_') else panel)
  elif n.endswith('_front') or n=='pantry_door':assign(o,cream if n.startswith('upper_') else recess)
  elif 'classic_' in n or 'inner_bead' in n:assign(o,cream if n.startswith('upper_') else frame)
  elif n.endswith('_body'):assign(o,cream if n.startswith('upper_') else sage)
 if n.startswith('open_shelf_'):assign(o,cream)
 if n in ['hood','hood_duct']:assign(o,steel)
 if n.startswith('tile_'):
  ix,iy=[int(v) for v in n.split('_')[1:3]];assign(o,tile if (ix+iy)%2 else tile2)
 # Rounded, clean edges instead of grain/photoreal textures.
 if n in ['fridge_body','fridge_door','pantry_body']:
  for mod in o.modifiers:
   if mod.type=='BEVEL':mod.width=min(.035,min(o.dimensions)*.12);mod.segments=5

# Retain six full 600mm modules and add 300mm perimeter strip at both exposed ends.
bpy.data.objects['floor_plinth'].location=(1.95,1.65,-.09);bpy.data.objects['floor_plinth'].dimensions=(4.06,4.06,.18)
bpy.data.objects['wall_back'].location.x=1.95;bpy.data.objects['wall_back'].dimensions=(4.02,.12,2.7)
for n in ['wall_left_low','wall_left_high']:
 o=bpy.data.objects[n];o.location.y=1.65;o.dimensions=(.12,3.9,o.dimensions.z)
o=bpy.data.objects['wall_left_front'];o.location.y=.6;o.dimensions=(.12,1.8,1.1)
for n,loc,dim in [('enclosure_front_wall',(1.95,-.36,1.35),(4.14,.12,2.7)),('enclosure_right_wall',(3.96,1.65,1.35),(.12,4.14,2.7)),('enclosure_ceiling',(1.95,1.65,2.76),(4.14,4.14,.12))]:
 o=bpy.data.objects[n];o.location=loc;o.dimensions=dim
for i in range(6):
 box('border_right_'+str(i),(3.75,.3+.6*i,.005),(.292,.592,.018),tile if i%2 else tile2,.003)
 box('border_front_'+str(i),(.3+.6*i,-.15,.005),(.592,.292,.018),tile if i%2 else tile2,.003)
box('border_corner',(3.75,-.15,.005),(.292,.292,.018),tile2,.003)
dust=bpy.data.objects['morning_indoor_scattering'];dust.location=(1.95,1.65,1.35);dust.dimensions=(3.9,3.9,2.7)
# Curved gathered curtains. At z1.66 tie, width narrows; below tie falls straight.
root=bpy.data.objects['curtain_root_optional'];root['variant']='curved_tieback_pair';root['removable']=True
for side,sgn,edge in [('front',1,1.48),('rear',-1,2.72)]:
 verts=[];faces=[];rows=48;cols=24
 for j in range(rows+1):
  z=1.24+1.13*j/rows
  if z<=1.66:width=.115;offset=0
  else:
   t=(z-1.66)/(.71);width=.10+.22*t*t;offset=-.028*math.sin(t*math.pi)
  for i in range(cols+1):
   u=i/cols;y=edge+sgn*(offset+width*u);x=.13+.022*math.cos(u*math.tau*5)+.055*math.sin(max(0,(z-1.66)/.71)*math.pi)
   verts.append((x,y,z))
 for j in range(rows):
  for i in range(cols):
   a=j*(cols+1)+i;faces.append((a,a+1,a+cols+2,a+cols+1))
 mesh=bpy.data.meshes.new('gathered_linen_'+side);mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new('curtain_panel_'+side,mesh);bpy.context.collection.objects.link(o);assign(o,linen)
 for p in mesh.polygons:p.use_smooth=True
 mod=o.modifiers.new('cloth_thickness','SOLIDIFY');mod.thickness=.002;parent(o,root)
 tie=box('curtain_tie_'+side,(.143,edge+sgn*.055,1.66),(.067,.132,.035),brass,.012);parent(tie,root)
 # Rings span actual expanded heading.
 rings=sorted([o for o in bpy.data.objects if o.name.startswith('curtain_ring_'+side)],key=lambda o:o.name)
 for i,o in enumerate(rings):
  w=o.matrix_world.copy();w.translation.y=edge+sgn*(.025+.27*i/max(1,len(rings)-1));o.matrix_world=w

# Sun higher in sky => patch falls lower on room/floor, nearer cooker.
sun=bpy.data.objects['window_golden_sun'];direction=Vector((1,.12,-.68)).normalized();sun.rotation_euler=direction.to_track_quat('-Z','Y').to_euler();sun.data.angle=math.radians(1.2)
s.cycles.diffuse_bounces=10;s.cycles.max_bounces=14
# Same actual window as the only morning source; no external studio fills.
bpy.data.objects['window_diffuse_daylight'].data.energy=180
s.view_settings.exposure=.4
bpy.data.materials['r09_subtle_sunbeam_volume'].node_tree.nodes.get('Volume Scatter').inputs['Density'].default_value=.018
cam=s.camera;target=Vector((1.95,1.65,1.12));cam.location=target+Vector((8,-8,8));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=7.0
bpy.context.view_layer.update()
a=world_to_camera_view(s,cam,Vector((0,3.6,2.7)));b=world_to_camera_view(s,cam,Vector((3.9,-.3,0)));assert abs(a.x-b.x)<1e-6
assert not any('cornice' in o.name or o.name=='preparation_board' for o in bpy.data.objects)
assert {o.name for o in bpy.data.objects if o.type=='LIGHT'}=={'window_golden_sun','window_diffuse_daylight'}
# Derive unobstructed real floor hits. Ignore volumetric bounds for ray inspection only.
dust.hide_set(True);bpy.context.view_layer.update();hits=[]
for y in [1.8,2.05,2.3,2.55]:
 for z in [1.31,1.5,1.95,2.15]:
  r=s.ray_cast(bpy.context.evaluated_depsgraph_get(),Vector((.12,y,z)),direction)
  if r[0] and r[4].name.startswith(('tile_','border_')):hits.append({'object':r[4].name,'position':list(r[1])})
dust.hide_set(False);assert hits
prefs=bpy.context.preferences.addons['cycles'].preferences;prefs.compute_device_type='OPTIX';prefs.get_devices()
for d in prefs.devices:d.use=d.type=='OPTIX'
s.cycles.device='GPU';s.cycles.samples=128 if preview else 512;s.cycles.use_denoising=True
s.render.resolution_x=s.render.resolution_y=900 if preview else 1400;s.render.resolution_percentage=100
s['stage']='r11 cozy cartoon palette and wider perimeter';s['footprint_m']='3.9x3.9';s['world_illumination']=0;s['double_door_fridge_space_reserved_m']=1.2
name='cozy-preview' if preview else 'cozy-morning-r11';s.render.filepath=str(out/(name+'.png'))
bpy.ops.wm.save_as_mainfile(filepath=str(out/(name+'.blend')));bpy.ops.render.render(write_still=True)
report={'revision':11,'blender':bpy.app.version_string,'base_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'footprint_m':[3.9,3.9],'full_modules_600mm_retained':36,'end_extensions_m':.3,'future_fridge_slot_width_m':1.2,'cornices_removed':removed,'curtain':'curved tieback, straight lower fall','hood_metallic':.8,'sun_direction':list(direction),'sun_energy':sun.data.energy,'sun_floor_hits':hits,'corner_alignment_error_px':abs(a.x-b.x)*s.render.resolution_x,'exposure':.4,'window_diffuse_watts':180,'light_sources':['window_golden_sun','window_diffuse_daylight'],'visual_approval_pending':True,'runtime_implemented':False,'night_render_updated':False}
(out/('preview-verification.json' if preview else 'verification.json')).write_text(json.dumps(report,indent=2))
print('COZY_RENDER_COMPLETE',json.dumps(report))


# Night uses this exact revised geometry/palette; deliberately low ceiling light,
# leaving future under-cabinet LEDs unbuilt and absent from the light inventory.
if not preview:
 bpy.ops.wm.open_mainfile(filepath=str(out/'cozy-morning-r11.blend'));s=bpy.context.scene
 for o in list(bpy.data.objects):
  if o.type=='LIGHT' or o.name=='morning_indoor_scattering':bpy.data.objects.remove(o,do_unlink=True)
 cardmat=bpy.data.objects['window_view_no_illumination'].data.materials[0]
 emission=next(n for n in cardmat.node_tree.nodes if n.type=='EMISSION');emission.inputs['Color'].default_value=(.01,.018,.035,1);emission.inputs['Strength'].default_value=.3
 bpy.ops.object.light_add(type='AREA',location=(1.95,1.65,2.635));lamp=bpy.context.object;lamp.name='ceiling_only_warm_light';lamp.data.energy=8;lamp.data.color=(1,.90,.78);lamp.data.shape='DISK';lamp.data.size=1.0;lamp.rotation_euler=(0,0,0)
 s.view_settings.exposure=0;s.cycles.samples=192;s['lighting_study']='r11 very dim night; future undercabinet LEDs absent';s.render.filepath=str(out/'cozy-night-r11.png')
 bpy.ops.wm.save_as_mainfile(filepath=str(out/'cozy-night-r11.blend'));bpy.ops.render.render(write_still=True)
 # Fresh source verification for both deliveries.
 checked=[]
 for mode in ['morning','night']:
  path=out/('cozy-'+mode+'-r11.blend');bpy.ops.wm.open_mainfile(filepath=str(path));s=bpy.context.scene;bpy.context.view_layer.update()
  assert not any('cornice' in o.name or o.name=='preparation_board' for o in bpy.data.objects)
  assert len([o for o in bpy.data.objects if o.name.startswith('curtain_panel_')])==2
  assert len([o for o in bpy.data.objects if o.name.startswith('curtain_tie_')])==2
  assert len([o for o in bpy.data.objects if o.name.startswith('tile_')])==36
  assert len([o for o in bpy.data.objects if o.name.startswith('border_')])==13
  for n in ['enclosure_front_wall','enclosure_right_wall','enclosure_ceiling']:
   o=bpy.data.objects[n];assert not o.visible_camera and o.visible_shadow and o.visible_diffuse
  assert abs(bounds(bpy.data.objects['hood'])[2][0]-bounds(bpy.data.objects['upper_prep_600_body'])[2][0])<1e-5
  lights=[o for o in bpy.data.objects if o.type=='LIGHT']
  assert {o.name for o in lights}==({'window_golden_sun','window_diffuse_daylight'} if mode=='morning' else {'ceiling_only_warm_light'})
  if mode=='night':assert lights[0].data.energy==8 and 'morning_indoor_scattering' not in bpy.data.objects
  checked.append({'mode':mode,'blend_reopened':True,'blend_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'png_sha256':hashlib.sha256((out/('cozy-'+mode+'-r11.png')).read_bytes()).hexdigest(),'lights':{o.name:o.data.energy for o in lights}})
 report['night_render_updated']=True;report['night_ceiling_watts']=8;report['night_exposure']=0;report['night_diffuser_diameter_m']=1.0;report['future_LED_built']=False;report['saved_source_checks']=checked
 (out/'verification.json').write_text(json.dumps(report,indent=2));print('BOTH_SOURCES_REOPENED_AND_CHECKED')
