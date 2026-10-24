import bpy,json
from pathlib import Path
out=Path(__file__).parent
for fn in ['base-geometry.blend','options-library.blend','base-morning.blend','base-night.blend','base-golden.blend']:
 bpy.ops.wm.open_mainfile(filepath=str(out/fn))
 for o in bpy.data.objects:
  if o.get('option_group'):o.hide_set(o.hide_render)
 mode='night' if fn=='base-night.blend' else ('golden' if fn=='base-golden.blend' else 'morning')
 bpy.context.scene.render.filepath='//renders/base--'+mode+'.png'
 bpy.ops.wm.save_as_mainfile(filepath=str(out/fn))
 if fn=='options-library.blend':
  groups={}
  for o in bpy.data.objects:
   tag=o.get('option_group')
   if tag and not tag.startswith('default_'):groups.setdefault(tag,[]).append(o.name)
  (out/'option-groups.json').write_text(json.dumps(groups,indent=2))
print('DEFAULT_VIEWPORT_CLEAN')
