import bpy,ast,sys,json,hashlib
from pathlib import Path
out=Path(__file__).parent;sys.path.insert(0,str(out));from appearance import change_style
from furniture import rebuild_furniture,lower_grates
from drawers import three_drawers
from rugs import rebuild_rugs
old=out.parent/'sofra-kitchen-options-r14'
if not old.exists():old=out.parents[1]
tree=ast.parse((old/'render_options.py').read_text());fn=next(n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='select_variant');exec(compile(ast.Module(body=[fn],type_ignores=[]),'selectors','exec'))
r=[]
for variant in ['base','modern','japandi','double_fridge','microwave','builtin','table_chairs','rug_persian','rug_teal','rug_ochre']:
 for mode in ['morning','night','golden']:
  bpy.ops.wm.open_mainfile(filepath=str(out/('base-'+mode+'.blend')))
  prefs=bpy.context.preferences.addons['cycles'].preferences;prefs.compute_device_type='OPTIX';prefs.get_devices()
  for device in prefs.devices:device.use=device.type=='OPTIX'
  bpy.context.scene.cycles.device='GPU'
  if not bpy.context.scene.get('grates_lowered_r15'):lower_grates();rebuild_furniture();bpy.context.scene['grates_lowered_r15']=True
  three_drawers()
  rebuild_rugs()
  if variant in ['modern','japandi']:change_style(variant)
  elif variant!='base':select_variant(variant)
  s=bpy.context.scene;s.render.resolution_x=s.render.resolution_y=1400 if variant=='base' else 1100;s.cycles.samples=256 if variant=='base' else 160;s.render.filepath='//renders/'+variant+'--'+mode+'.png'
  bpy.ops.wm.save_as_mainfile(filepath=str(out/(variant+'-'+mode+'.blend')));bpy.ops.render.render(write_still=True)
  file=out/'renders'/(variant+'--'+mode+'.png');r.append({'variant':variant,'mode':mode,'file':'renders/'+file.name,'sha256':hashlib.sha256(file.read_bytes()).hexdigest()});(out/'variant-manifest.json').write_text(json.dumps(r,indent=2));print('VARIANT_READY',variant,mode,flush=True)
