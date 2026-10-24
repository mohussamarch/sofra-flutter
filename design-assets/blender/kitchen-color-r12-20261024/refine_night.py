import bpy,json,hashlib
from pathlib import Path
out=Path(__file__).parent;path=out/'night-r12.blend'
bpy.ops.wm.open_mainfile(filepath=str(path));s=bpy.context.scene;o=bpy.data.objects['ceiling_vintage_center_lamp'];o.data.energy=160;o.data.color=(1,.87,.68)
prefs=bpy.context.preferences.addons['cycles'].preferences;prefs.compute_device_type='OPTIX';prefs.get_devices()
for d in prefs.devices:d.use=d.type=='OPTIX'
s.cycles.device='GPU';bpy.ops.wm.save_as_mainfile(filepath=str(path));bpy.ops.render.render(write_still=True);bpy.ops.wm.open_mainfile(filepath=str(path));assert bpy.data.objects['ceiling_vintage_center_lamp'].data.energy==160
r=json.loads((out/'verification.json').read_text());r['night']['watts']=160;r['night']['color']=[1,.87,.68];r['night']['initial_60W_preview_replaced_as_too_dark']=True
for c in r['saved_checks']:
 if c['mode']=='night':c['blend_sha256']=hashlib.sha256(path.read_bytes()).hexdigest();c['png_sha256']=hashlib.sha256((out/'night-r12.png').read_bytes()).hexdigest()
(out/'verification.json').write_text(json.dumps(r,indent=2));print('NIGHT_CENTER_BALANCE_VERIFIED')
