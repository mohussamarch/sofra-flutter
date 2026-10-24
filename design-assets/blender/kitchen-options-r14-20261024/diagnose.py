import bpy,json,math
from pathlib import Path
from mathutils import Vector
bpy.ops.wm.open_mainfile(filepath=r'E:\work\SOFRA\app\design-assets\blender\kitchen-dream-r13-20261024\morning-r13.blend')
r={}
for name in ['r13_continuous_room_walls','floor_plinth']:
 o=bpy.data.objects[name];r[name]={'modifiers':[{p:getattr(m,p,None) for p in ['name','type','limit_method','harden_normals','keep_sharp']} for m in o.modifiers],'smooth_faces':sum(p.use_smooth for p in o.data.polygons)}
 me=o.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh();angles=[]
 for p in me.polygons:
  if abs(p.normal.y)>.999 or abs(p.normal.x)>.999:
   angles += [math.degrees(p.normal.angle(me.corner_normals[i].vector)) for i in p.loop_indices]
 r[name]['max_corner_normal_error_degrees']=max(angles,default=0)
for n in ['cabinet_sink_600_top','curtain_rod','hood_duct_open_top','upper_prep_600_body']:
 o=bpy.data.objects[n];v=[o.matrix_world@Vector(c) for c in o.bound_box];r[n]={'loc':list(o.matrix_world.translation),'dim':list(o.dimensions),'bounds':[[min(p[i] for p in v),max(p[i] for p in v)] for i in range(3)]}
print(json.dumps(r));Path(r'C:\Users\atgs0\Documents\Codex\work\sofra-kitchen-options-r14\diagnosis.json').write_text(json.dumps(r,indent=2))
