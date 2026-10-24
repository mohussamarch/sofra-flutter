import bpy
from pathlib import Path
p=Path(__file__).parent
for mode in ['morning','night','golden']:
 bpy.ops.wm.open_mainfile(filepath=str(p/('kitchen-'+mode+'.blend')));bpy.context.preferences.filepaths.save_version=0
 m=bpy.data.materials['r16_window_satin_ivory'];s=m.node_tree.nodes.get('Principled BSDF');s.inputs['Base Color'].default_value=(.19,.21,.18,1);s.inputs['Roughness'].default_value=.75;s.inputs['Specular IOR Level'].default_value=.10
 for o in bpy.data.objects:
  if o.get('option_group') in ['rug_persian','rug_teal','rug_ochre'] and 'woven_base' in o.name:o.location.z-=.0028
 bpy.ops.wm.save_as_mainfile(filepath=str(p/('kitchen-'+mode+'.blend')))
