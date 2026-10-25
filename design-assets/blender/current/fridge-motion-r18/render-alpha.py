"""Native geometry mattes for the completed RGB frames; never color-key the kitchen."""
import bpy,sys,json,hashlib,shutil,array
from pathlib import Path
B=Path('E:/work/SOFRA/app/design-assets/blender/current/fridge-motion-r18')
sys.path.insert(0,str(B))
from motion import initialize,camera_pose,door_pose
rows=json.loads((B/'raw-manifest.json').read_text()); assert len(rows)==132
result={'schema':'sofra.motion.native-alpha/1','rawManifestSha256':hashlib.sha256((B/'raw-manifest.json').read_bytes()).hexdigest(),'method':'Blender Cycles transparent-film geometry matte; opaque emission material override; volume meshes hidden; no RGB color key','modes':{}}
cache={}
for mode in ['morning','golden','night']:
 s=initialize(mode)
 # A volume container must not become an opaque cube under the material override.
 for o in bpy.data.objects:
  if any(m and m.use_nodes and any(link.to_node.type=='OUTPUT_MATERIAL' and link.to_socket.name=='Volume' for link in m.node_tree.links) for m in getattr(o.data,'materials',[])):o.hide_render=True
 fingerprint=hashlib.sha256()
 for o in sorted(bpy.data.objects,key=lambda o:o.name):
  if o.type not in ['MESH','CURVE','FONT'] or o.hide_render:continue
  fingerprint.update(json.dumps([o.name,o.type,[list(x) for x in o.matrix_world],[(m.type,[(k,getattr(m,k,None)) for k in ['width','segments','levels','render_levels','thickness']]) for m in o.modifiers]],default=str).encode())
  if o.type=='MESH':
   coords=array.array('f',[0])*(len(o.data.vertices)*3);o.data.vertices.foreach_get('co',coords);fingerprint.update(coords.tobytes())
  if o.type=='CURVE':
   for spline in o.data.splines:
    fingerprint.update(str([(list(p.co),list(p.handle_left),list(p.handle_right)) for p in spline.bezier_points]).encode())
    fingerprint.update(str([list(p.co) for p in spline.points]).encode())
 signature=fingerprint.hexdigest()
 if signature in cache:
  result['modes'][mode]={'geometrySha256':signature,'reusedFrom':cache[signature]['mode'],'frames':cache[signature]['frames']};continue
 s.render.engine='CYCLES';s.render.film_transparent=True;s.use_nodes=False;s.render.use_compositing=False
 s.render.image_settings.color_mode='RGBA';s.render.image_settings.file_format='PNG';s.render.resolution_percentage=100
 s.cycles.samples=32;s.cycles.use_denoising=False;s.render.use_persistent_data=True
 mat=bpy.data.materials.new('r18_alpha_emission');mat.use_nodes=True;nodes=mat.node_tree.nodes;nodes.clear();out=nodes.new('ShaderNodeOutputMaterial');emission=nodes.new('ShaderNodeEmission');emission.inputs['Color'].default_value=(1,1,1,1);mat.node_tree.links.new(emission.outputs[0],out.inputs['Surface']);s.view_layers[0].material_override=mat
 frames=[]
 for r in [r for r in rows if r['mode']==mode]:
  phase=r['phase'];i=r['index'];camera_pose(s,i/29 if phase=='approach' else 1);door_pose(s,r['angleDegrees'])
  path=B/'alpha'/mode/(phase+f'_{i:03d}.png');path.parent.mkdir(parents=True,exist_ok=True)
  if phase=='door' and i==0:shutil.copyfile(B/'alpha'/mode/'approach_029.png',path)
  elif not path.exists():s.render.filepath=str(path);bpy.ops.render.render(write_still=True)
  frames.append({'phase':phase,'index':i,'file':path.relative_to(B).as_posix(),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
  print('NATIVE_ALPHA_READY',mode,phase,i,flush=True)
 cache[signature]={'mode':mode,'frames':frames};result['modes'][mode]={'geometrySha256':signature,'reusedFrom':None,'frames':frames}
(B/'alpha-manifest.json').write_text(json.dumps(result,indent=2));print('NATIVE_ALPHA_COMPLETE',len(cache),'unique geometries')
