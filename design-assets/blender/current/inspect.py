import bpy,json
from pathlib import Path
p=Path(__file__).parent;bpy.ops.wm.open_mainfile(filepath=str(p/'kitchen-morning.blend'))
r=[]
for o in bpy.data.objects:
 if o.type=='MESH' and any(s in o.name.lower() for s in ['window','frame','mullion','sill']):r.append({'name':o.name,'materials':[m.name for m in o.data.materials]})
(p/'inspect.json').write_text(json.dumps(r,indent=2));print(json.dumps(r))
