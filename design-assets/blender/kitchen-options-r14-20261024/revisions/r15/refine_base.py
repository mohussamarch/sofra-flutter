import bpy, sys, json, math, hashlib
from pathlib import Path
src=Path(__file__).resolve().parents[2]
out=Path(__file__).resolve().parent
out.mkdir(exist_ok=True);(out/'renders').mkdir(exist_ok=True)
sys.path.insert(0,str(src))
sys.path.insert(0,str(out))
from modes import configure
from appearance import finish_base
from mathutils import Vector
def rebuild_walls():
 old=bpy.data.objects['r13_continuous_room_walls'];material=old.data.materials[0]
 bpy.data.objects.remove(old,do_unlink=True)
 # A fresh, explicitly quad-only ring around the window. No inherited mesh,
 # custom normals, smoothing, n-gon triangulation or wall bevel modifiers.
 outer=[(-.42,0),(3.72,0),(3.72,2.7),(-.42,2.7)]
 inner=[(1.5,1.2),(2.7,1.2),(2.7,2.3),(1.5,2.3)]
 verts=[(x,y,z) for x in [-.12,0] for y,z in outer+inner];faces=[]
 for side in [0,8]:
  for i in range(4):
   j=(i+1)%4;face=(side+i,side+j,side+4+j,side+4+i)
   faces.append(tuple(reversed(face)) if side==0 else face)
 for loop in [0,4]:
  for i in range(4):
   j=(i+1)%4;faces.append((loop+i,loop+j,loop+j+8,loop+i+8))
 def mesh(name,vs,fs):
  import bmesh
  me=bpy.data.meshes.new(name);me.from_pydata(vs,[],fs);me.update()
  bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));assert all(e.is_manifold for e in bm.edges);bm.to_mesh(me);bm.free()
  ob=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(ob);me.materials.append(material)
  for p in me.polygons:p.use_smooth=False
  assert all(len(p.vertices)==4 for p in me.polygons)
  return ob
 mesh('r15_window_wall_quad_ring',verts,faces)
 vs=[(x,y,z) for z in [0,2.7] for y in [3.6,3.72] for x in [0,4.02]]
 mesh('r15_back_wall_simple_box',vs,[(0,2,3,1),(4,5,7,6),(0,1,5,4),(2,6,7,3),(0,4,6,2),(1,3,7,5)])
results=[]
for mode in ['morning','night','golden']:
 bpy.ops.wm.open_mainfile(filepath=str(src/'options-library.blend'))
 s=configure(mode)
 rebuild_walls()
 oldvol=bpy.data.objects['morning_indoor_scattering'];vmaterial=oldvol.data.materials[0];bpy.data.objects.remove(oldvol,do_unlink=True)
 bpy.ops.mesh.primitive_cube_add(size=1,location=(1.95,1.65,1.35));newvol=bpy.context.object;newvol.name='morning_indoor_scattering';newvol.dimensions=(3.88,3.88,2.68);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);newvol.data.materials.append(vmaterial);newvol.hide_render=mode=='night'
 finish_base()
 bpy.ops.object.select_all(action='DESELECT')
 for name in ['stone_upstand_left','stone_upstand_back_left','stone_upstand_back_right']:
  o=bpy.data.objects[name];o.location.z=.94
  if name=='stone_upstand_left':o.dimensions=(.020,3.0,.08);o.location.x=.010
  else:o.dimensions=(1.2 if name.endswith('left') else .6,.020,.08);o.location.y=3.590
  bpy.context.view_layer.update()
  bpy.context.view_layer.objects.active=o;o.select_set(True)
  bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.select_set(False)
  for mod in o.modifiers:
   if mod.type=='BEVEL':mod.width=.003
 if mode=='morning':bpy.data.objects['window_golden_sun'].data.angle=math.radians(3)
 sky=bpy.data.objects['window_view_no_illumination'];m=sky.data.materials[0].copy();sky.data.materials[0]=m
 n=m.node_tree.nodes;l=m.node_tree.links;n.clear()
 tex=n.new('ShaderNodeTexCoord');sep=n.new('ShaderNodeSeparateXYZ');l.new(tex.outputs['Generated'],sep.inputs[0])
 ramp=n.new('ShaderNodeValToRGB');ramp.color_ramp.interpolation='EASE';l.new(sep.outputs['Z'],ramp.inputs[0])
 colors={'night':[(.018,.045,.14,1),(.004,.012,.043,1)],'golden':[(1,.44,.10,1),(.12,.22,.49,1)],'morning':[(.08,.38,.95,1),(.08,.38,.95,1)]}[mode]
 for e,c in zip(ramp.color_ramp.elements,colors):e.color=c
 output=ramp.outputs['Color']
 if mode=='golden':
  mid=ramp.color_ramp.elements.new(.40);mid.color=(.77,.30,.22,1)
  combine=n.new('ShaderNodeCombineXYZ');l.new(sep.outputs['Y'],combine.inputs['Y']);l.new(sep.outputs['Z'],combine.inputs['Z'])
  dist=n.new('ShaderNodeVectorMath');dist.operation='DISTANCE';l.new(combine.outputs[0],dist.inputs[0]);dist.inputs[1].default_value=(0,.57,.34)
  soft=n.new('ShaderNodeMapRange');soft.interpolation_type='SMOOTHSTEP';soft.clamp=True;l.new(dist.outputs['Value'],soft.inputs['Value'])
  for key,value in [('From Min',.025),('From Max',.16),('To Min',.9),('To Max',0)]:soft.inputs[key].default_value=value
  mix=n.new('ShaderNodeMixRGB');l.new(soft.outputs[0],mix.inputs[0]);l.new(output,mix.inputs[1]);mix.inputs[2].default_value=(1,.74,.28,1);output=mix.outputs[0]
 em=n.new('ShaderNodeEmission');em.inputs['Strength'].default_value=.65 if mode=='night' else .8;l.new(output,em.inputs['Color']);end=n.new('ShaderNodeOutputMaterial');l.new(em.outputs[0],end.inputs['Surface'])
 s['revision']='r15 base review only; option pre-render layers pending approval';s['morning_sun_angle_degrees']=3
 s.render.resolution_x=s.render.resolution_y=1400;s.render.resolution_percentage=100;s.cycles.samples=192 if mode=='night' else 384
 s.render.filepath='//renders/base--'+mode+'.png'
 bpy.context.view_layer.update()
 assert all(abs(bpy.data.objects[x].dimensions.z-.08)<1e-5 for x in ['stone_upstand_left','stone_upstand_back_left','stone_upstand_back_right'])
 assert not sky.visible_shadow and not sky.visible_diffuse
 if mode=='morning':assert abs(math.degrees(bpy.data.objects['window_golden_sun'].data.angle)-3)<.001
 bpy.ops.wm.save_as_mainfile(filepath=str(out/('base-'+mode+'.blend')))
 bpy.ops.render.render(write_still=True)
 p=out/'renders'/('base--'+mode+'.png');results.append({'mode':mode,'file':'renders/'+p.name,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'samples':s.cycles.samples})
 (out/'verification.json').write_text(json.dumps({'renders':results,'upstand_depth_m':.02,'upstand_height_m':.08,'sun_angle_before_degrees':7,'sun_angle_after_degrees':3,'wall_rebuilt':True,'volume_rebuilt_inset_m':.01,'visual_approval_pending':True,'runtime_or_layer_export_done':False},indent=2))
 print('R15_RENDER_READY',mode,flush=True)
