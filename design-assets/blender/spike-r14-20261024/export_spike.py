import bpy,sys,json,math,hashlib
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
src=Path(__file__).resolve().parents[1]/'kitchen-options-r14-20261024'
out=Path(__file__).resolve().parent/'renders';out.mkdir(exist_ok=True)
N=1440;meta={'spike':True,'sourceRevision':'r14','resolution':[N,N],'pixelOrigin':'top-left','cameraByMode':{},'sourceHashes':{}}
colors={'fridge':[255,0,0],'freezer':[0,255,0],'pantry':[0,0,255],'stove':[255,255,0],'sink':[255,0,255],'window':[0,255,255],'shelves':[255,255,255]}
def opened(mode):
 file=src/('base-'+mode+'.blend');bpy.ops.wm.open_mainfile(filepath=str(file));s=bpy.context.scene
 meta['sourceHashes'][file.name]=hashlib.sha256(file.read_bytes()).hexdigest()
 s.render.resolution_x=s.render.resolution_y=N;s.render.resolution_percentage=100;s.render.use_border=False;s.render.film_transparent=False;s.render.image_settings.file_format='PNG';s.render.image_settings.color_mode='RGBA';s.render.image_settings.color_depth='8';s.compositing_node_group=None
 prefs=bpy.context.preferences.addons['cycles'].preferences;prefs.compute_device_type='OPTIX';prefs.get_devices()
 for d in prefs.devices:d.use=d.type=='OPTIX'
 s.cycles.device='GPU';s.cycles.samples=128;s.cycles.use_denoising=True;s.render.use_file_extension=True
 meta['cameraByMode'][mode]={'type':s.camera.data.type,'ortho_scale':s.camera.data.ortho_scale,'matrixWorld':[list(r) for r in s.camera.matrix_world],'lensShift':[s.camera.data.shift_x,s.camera.data.shift_y]}
 return s
def render(s,name,samples=128):s.cycles.samples=samples;s.render.filepath=str(out/(name+'.png'));bpy.ops.render.render(write_still=True);print('SPIKE_READY',name,flush=True)
def box(o):return [o.matrix_world@Vector(c) for c in o.bound_box]
def project(s,p):q=world_to_camera_view(s,s.camera,p);return [q.x*N,(1-q.y)*N]
def rect(s,points,pad=0):
 pp=[project(s,p) for p in points];x=max(0,math.floor(min(q[0] for q in pp))-pad);y=max(0,math.floor(min(q[1] for q in pp))-pad);r=min(N,math.ceil(max(q[0] for q in pp))+pad);b=min(N,math.ceil(max(q[1] for q in pp))+pad);return {'x':x,'y':y,'width':r-x,'height':b-y}
def names(o):
 arr=[]
 while o:arr.append(o.name.lower());o=o.parent
 return ' '.join(arr)
def kind(o):
 n=names(o)
 if 'fridge' in n:return 'freezer' if 'freezer' in n or (o.name.startswith(('fridge_heart','fridge_star'))) else 'fridge'
 if 'pantry' in n:return 'pantry'
 if 'range_slot' in n or o.name.startswith(('hob_','burner_','oven_','r12_slim_grate','r12_support_foot','grate_')):return 'stove'
 if 'sink_root' in n:return 'sink'
 if 'window' in n or 'exterior_garden' in n:return 'window'
 if 'open_shelf' in n or 'straight_shelf' in n:return 'shelves'
 return None
def emission(name,color):
 m=bpy.data.materials.new(name);m.use_nodes=True;n=m.node_tree.nodes;n.clear();e=n.new('ShaderNodeEmission');e.inputs['Color'].default_value=(*[v/255 for v in color],1);o=n.new('ShaderNodeOutputMaterial');m.node_tree.links.new(e.outputs[0],o.inputs['Surface']);return m
def blackworld(s):
 w=bpy.data.worlds.new('technical_black');w.use_nodes=True;w.node_tree.nodes.get('Background').inputs['Strength'].default_value=0;s.world=w
def masks(window=False):
 s=opened('morning');blackworld(s);s.view_settings.view_transform='Standard';s.view_settings.look='None';s.view_settings.exposure=0;s.view_settings.gamma=1;s.cycles.use_denoising=False;s.render.filter_size=.01
 mats={k:emission('ID_'+k,c) for k,c in colors.items()};black=emission('ID_background',[0,0,0]);white=emission('window_aperture',[255,255,255]);points={k:[] for k in colors}
 for o in bpy.data.objects:
  if o.name=='morning_indoor_scattering' or o.name.startswith('morning_dream_mote_'):o.hide_render=True
  if o.type not in ['MESH','CURVE','FONT','SURFACE']:continue
  tag=kind(o)
  if not o.hide_render and o.visible_camera and tag:points[tag]+=box(o)
  aperture='exterior_garden' in names(o) or o.name=='window_view_no_illumination'
  m=(white if aperture else black) if window else mats.get(tag,black)
  o.data.materials.clear();o.data.materials.append(m)
 if not window:
  meta['idColors']=colors;meta['projectedHotspots']={k:rect(s,v) for k,v in points.items() if v};meta['ceilingLampPixel']=project(s,Vector((1.95,1.65,2.635)))
 render(s,'window_mask_raw' if window else 'id_mask_raw',1)
def beam(mode):
 s=opened(mode);blackworld(s)
 for o in bpy.data.objects:
  if o.type=='LIGHT' and o.data.type!='SUN':o.hide_render=True
  if o.name.startswith('morning_dream_mote_'):o.hide_render=True
  if o.name=='morning_indoor_scattering':continue
  if o.type not in ['MESH','CURVE','FONT','SURFACE']:continue
  floor=o.name=='floor_plinth' or 'floor_tile' in o.name or o.name.startswith('tile_')
  m=bpy.data.materials.new('beam_black_occluder');m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(0,0,0,1);p.inputs['Roughness'].default_value=1;p.inputs['Specular IOR Level'].default_value=0;o.data.materials.clear();o.data.materials.append(m)
  if floor and o.type=='MESH':
   white=m.copy();white.name='beam_upward_floor_only';white.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(1,1,1,1);o.data.materials.append(white)
   for polygon in o.data.polygons:polygon.material_index=1 if polygon.normal.z>.999 else 0
 s.view_settings.view_transform='Standard';s.view_settings.look='None';s.view_settings.exposure=0;render(s,'beam_mask_'+mode+'_raw',64)
for mode in ['morning','golden','night']:s=opened(mode);render(s,'base_'+mode)
masks();masks(True)
for mode in ['morning','golden']:beam(mode)
s=opened('morning');bpy.context.view_layer.update();door=bpy.data.objects['fridge_door'];bb=box(door);pivot=Vector((min(v.x for v in bb),min(v.y for v in bb),min(v.z for v in bb)))
bpy.ops.object.empty_add(type='PLAIN_AXES',location=pivot);hinge=bpy.context.object;hinge.name='technical_door_hinge'
move=[door]+[o for o in bpy.data.objects if o.name.startswith('fridge_door_handle') and o.parent!=door]
for o in move:w=o.matrix_world.copy();o.parent=hinge;o.matrix_world=w
allpoints=[]
for i in range(16):hinge.rotation_euler.z=-math.radians(100*i/15);bpy.context.view_layer.update();allpoints+=box(door)
allpoints += [v for o in bpy.data.objects if 'fridge' in o.name and o.type=='MESH' and not o.hide_render for v in box(o)]
crop=rect(s,allpoints,12);meta['fridgeDoor']={'frames':16,'anglesDegrees':[100*i/15 for i in range(16)],'rotationAxis':'world-Z','rotationSign':-1,'pivotWorld':list(pivot),'pivotPixel':project(s,pivot),'cropRect':crop,'composition':'opaque cropped full-scene patches; replace entire crop rectangle, not a transparent door overlay','interior':'existing solid r14 body only; interior design deferred'}
s.render.use_border=True;s.render.use_crop_to_border=True;s.render.border_min_x=crop['x']/N;s.render.border_max_x=(crop['x']+crop['width'])/N;s.render.border_min_y=1-(crop['y']+crop['height'])/N;s.render.border_max_y=1-crop['y']/N
for i in range(16):hinge.rotation_euler.z=-math.radians(100*i/15);bpy.context.view_layer.update();render(s,'fridge_door_morning_'+str(i).zfill(2),96)
s=opened('morning');points=[v for o in bpy.data.objects if 'fridge' in o.name and o.type=='MESH' and not o.hide_render for v in box(o)];target=sum(points,Vector())/len(points);offset=s.camera.matrix_world.to_quaternion()@Vector((0,0,8));s.camera.location=target+offset;s.camera.data.ortho_scale=3.15;bpy.context.view_layer.update();meta['fridgeCloseupCamera']={'type':'ORTHO','ortho_scale':3.15,'matrixWorld':[list(r) for r in s.camera.matrix_world],'resolution':[N,N]};render(s,'fridge_closeup_morning',160)
meta['curtainsDeferred']='The r14 cotton is translucent and its shadows are baked into the base. An animatable RGBA layer needs matching clean plates and shadow separation; postponed for this performance spike as allowed by user. No fake curtain overlay supplied.'
meta['lightGroupsDeferred']='Optional EXR light groups omitted from the minimal mobile performance spike; no raw EXR upload.'
meta['beamMaskMethod']='Sun-only Cycles scattering plus white floor, other geometry black occluders, normalized grayscale; technical mask, not a production motion/shadow contract.'
(out/'scene.raw.json').write_text(json.dumps(meta,indent=2));print('SPIKE_EXPORT_DONE',flush=True)
