import bpy,ast,math,json,hashlib
from pathlib import Path
OUT=Path(__file__).parent;tree=ast.parse((OUT/'build.py').read_text());exec(compile(ast.Module(body=[n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='select'],type_ignores=[]),'visibility','exec'))
variants=['table_chairs','table_on_blue_rug','hanging_plants','microwave','japandi','rug_teal','base','modern','white_blind','double_fridge','builtin','rug_persian','rug_ochre','curtain_blue','no_curtain','terracotta','led'];(OUT/'renders-r17').mkdir(exist_ok=True);results=[]
for variant in variants:
 for mode in ['morning','night','golden']:
  if variant=='led' and mode!='night':continue
  bpy.ops.wm.open_mainfile(filepath=str(OUT/('kitchen-'+mode+'.blend')));s=bpy.context.scene;select(variant if variant in ['modern','japandi'] else 'classic',variant if variant not in ['modern','japandi','terracotta'] else 'base',mode)
  if variant=='table_on_blue_rug':
   select('classic','rug_teal',mode)
   for o in bpy.data.objects:
    if o.get('option_group')=='table_chairs':o.hide_render=False;o.hide_set(False)
  if variant=='terracotta':
   old=bpy.data.materials['r15_classic_painted_timber'];new=bpy.data.materials['r16_terracotta_painted_wood']
   for o in bpy.data.objects:
    for slot in o.material_slots:
     if slot.material==old:slot.material=new
  if variant=='curtain_blue':
   mat=bpy.data.materials['r13_cotton_gingham'];ramp=next(n for n in mat.node_tree.nodes if n.type=='VALTORGB')
   for e,c in zip(sorted(ramp.color_ramp.elements,key=lambda e:e.position),[(.9,.87,.74,1),(.34,.57,.69,1),(.12,.31,.48,1)]):e.color=c
  prefs=bpy.context.preferences.addons['cycles'].preferences;prefs.compute_device_type='OPTIX';prefs.get_devices()
  for d in prefs.devices:d.use=d.type=='OPTIX'
  s.cycles.device='GPU';s.cycles.samples=192 if variant=='base' else 128;s.render.resolution_x=s.render.resolution_y=1400 if variant=='base' else 1100;s.render.resolution_percentage=100;s.render.filepath=str(OUT/'renders-r17'/(variant+'--'+mode+'.png'));bpy.ops.render.render(write_still=True)
  p=Path(s.render.filepath);results.append({'variant':variant,'mode':mode,'file':'renders-r17/'+p.name,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()});(OUT/'r17-manifest.json').write_text(json.dumps(results,indent=2));print('REVIEW_READY',variant,mode,flush=True)
