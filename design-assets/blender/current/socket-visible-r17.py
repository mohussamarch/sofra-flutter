import bpy,sys,math
from pathlib import Path
from mathutils import Vector,Matrix
ROOT=Path('E:/work/SOFRA/app/design-assets/blender/current');sys.path.insert(0,str(ROOT.parent/'kitchen-options-r14-20261024/revisions/r15'))
from appearance import tube
for mode in ['morning','night','golden']:
 bpy.ops.wm.open_mainfile(filepath=str(ROOT/('kitchen-'+mode+'.blend')));bpy.context.preferences.filepaths.save_version=0
 if bpy.context.scene.get('r17_socket_visible_leftwall'):continue
 plate=bpy.data.objects['microwave_fixed_socket'];old=plate.location.copy();dest=Vector((.025,2.97,1.28));rot=Matrix.Rotation(math.pi/2,3,'Z')
 for o in bpy.data.objects:
  if o.name.startswith(('microwave_fixed_socket','socket_hole','microwave_plug')):o.location=dest+rot@(o.location-old);o.rotation_euler.z+=math.pi/2
 body=bpy.data.objects['microwave_body'];bpy.context.view_layer.update();end=body.matrix_world@Vector((-.265,.08,-.07));bpy.data.objects['r17_microwave_cable_grommet'].location=end
 o=bpy.data.objects['microwave_connected_cable'];bpy.data.objects.remove(o,do_unlink=True)
 points=[Vector((.09,2.97,1.26)),Vector((.15,2.97,1.14)),Vector((.21,3.03,.98)),end];smooth=[]
 for i in range(len(points)-1):
  p0=points[max(0,i-1)];p1=points[i];p2=points[i+1];p3=points[min(len(points)-1,i+2)]
  for j in range(16):
   t=j/16;smooth.append(.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t))
 smooth.append(end);o=tube('microwave_connected_cable',smooth,.0045,bpy.data.materials['r16_power_lead']);o['option_group']='microwave';c=bpy.data.collections['Options / microwave']
 for prior in list(o.users_collection):prior.objects.unlink(o)
 c.objects.link(o);bpy.context.scene['r17_socket_visible_leftwall']=True;bpy.context.scene['r17_microwave_endpoint_world']=list(end);exec(bpy.data.texts['SELECT-OPTION.py'].as_string());bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/('kitchen-'+mode+'.blend')),compress=True)
