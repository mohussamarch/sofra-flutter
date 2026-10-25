import bpy,math
from pathlib import Path
ROOT=Path('E:/work/SOFRA/app/design-assets/blender/current')
for mode in ['morning','night','golden']:
 bpy.ops.wm.open_mainfile(filepath=str(ROOT/('kitchen-'+mode+'.blend')));bpy.context.preferences.filepaths.save_version=0
 if bpy.context.scene.get('r17_cloth_contact'):continue
 cloth=bpy.data.objects['r17_draped_runner']
 for i,v in enumerate(cloth.data.vertices):
  row=i//13;k=i%13
  if 4<=row<=8:v.co.z=.790+.0015*math.sin(k*1.6)
 for o in bpy.data.objects:
  if o.name.startswith(('r17_glass_vase','r17_vase_stem','r17_vase_leaf','r17_small_flower')):o.location.z-=.0112
 bpy.context.scene['r17_cloth_contact']=True
 bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/('kitchen-'+mode+'.blend')),compress=True)
