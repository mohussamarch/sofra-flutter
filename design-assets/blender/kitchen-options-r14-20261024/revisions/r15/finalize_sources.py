import bpy,sys
from pathlib import Path
p=Path(__file__).parent;sys.path.insert(0,str(p));from rugs import rebuild_rugs
for mode in ['morning','night','golden']:
 bpy.ops.wm.open_mainfile(filepath=str(p/('base-'+mode+'.blend')));rebuild_rugs()
 bpy.ops.object.select_all(action='DESELECT');o=bpy.data.objects['builtin_upstand'];o.dimensions=(2.7,.020,.08);o.location.y=3.590;o.location.z=.94;bpy.context.view_layer.update();o.select_set(True);bpy.context.view_layer.objects.active=o;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.select_set(False)
 for mod in o.modifiers:
  if mod.type=='BEVEL':mod.width=.003
 bpy.ops.wm.save_as_mainfile(filepath=str(p/('base-'+mode+'.blend')))
print('HIDDEN_BASE_RUG_LIBRARY_UPDATED_NO_VISIBLE_CHANGE')
