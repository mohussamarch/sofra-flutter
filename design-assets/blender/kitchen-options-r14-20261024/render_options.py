import bpy,sys,json,hashlib,time
from pathlib import Path
out=Path(__file__).parent;sys.path.insert(0,str(out));from modes import configure
variants=[('base','الأساس'),('microwave','ميكروويف الركن'),('double_fridge','تلاجة معدن بابين'),('palette_coral','دواليب باستيل مرجاني'),('palette_blue','دواليب باستيل أزرق'),('palette_lilac','دواليب باستيل ليلكي'),('hanging_plants','زرع متدلّي'),('curtain_blue','كاروهات أزرق'),('white_blind','ستارة مكتبية بيضاء'),('no_curtain','بدون ستارة'),('rug_persian','سجادة فارسية داكنة'),('rug_teal','سجادة معينات تركواز'),('rug_ochre','سجادة زهور خردلي'),('builtin','مسطح وفرن بلت إن'),('table_chairs','ترابيزة و3 كراسي')]
(out/'renders').mkdir(exist_ok=True);results=[]
def select_variant(v):
 for o in bpy.data.objects:
  tag=o.get('option_group')
  if tag:o.hide_render=not tag.startswith('default_')
 active={'microwave','double_fridge','hanging_plants','white_blind','rug_persian','rug_teal','rug_ochre','builtin','table_chairs'}
 if v in active:
  for o in bpy.data.objects:
   if o.get('option_group')==v:o.hide_render=False
 hides=[]
 if v=='double_fridge':hides=['default_fridge']
 if v in ['white_blind','no_curtain']:hides=['default_curtain']
 if v=='builtin':hides=['default_range','default_counter']
 for o in bpy.data.objects:
  if o.get('option_group') in hides:o.hide_render=True
 if v.startswith('palette_'):
  colors={'palette_coral':(.64,.29,.25),'palette_blue':(.24,.47,.65),'palette_lilac':(.47,.32,.57)};c=colors[v];old=bpy.data.materials['r13_faded_teal_painted_wood'];new=old.copy();new.name=v
  ramp=next(n for n in new.node_tree.nodes if n.type=='VALTORGB')
  for e,f in zip(ramp.color_ramp.elements,[.90,1.10]):e.color=(*[min(.95,x*f) for x in c],1)
  for o in bpy.data.objects:
   if o.type=='MESH':
    for slot in o.material_slots:
     if slot.material==old:slot.material=new
 if v=='curtain_blue':
  m=bpy.data.materials['r13_cotton_gingham'];ramp=next(n for n in m.node_tree.nodes if n.type=='VALTORGB');colors=[(.9,.87,.74,1),(.34,.57,.69,1),(.12,.31,.48,1)]
  for e,c in zip(sorted(ramp.color_ramp.elements,key=lambda e:e.position),colors):e.color=c
 for o in bpy.data.objects:
  if o.get('option_group'):o.hide_set(o.hide_render)
 return v
for v,label in variants:
 bpy.ops.wm.open_mainfile(filepath=str(out/'options-library.blend'));select_variant(v)
 for mode in ['morning','night','golden']:
  s=configure(mode);s.cycles.samples=(512 if mode!='night' else 192) if v=='base' else 160;s.render.resolution_x=s.render.resolution_y=1400 if v=='base' else 900;s.render.resolution_percentage=100
  path=out/'renders'/(v+'--'+mode+'.png');s.render.filepath='//renders/'+path.name
  if v=='base':bpy.ops.wm.save_as_mainfile(filepath=str(out/('base-'+mode+'.blend')))
  bpy.ops.render.render(write_still=True)
  results.append({'variant':v,'label_ar':label,'mode':mode,'file':'renders/'+path.name,'width':s.render.resolution_x,'samples':s.cycles.samples,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
  manifest={'revision':14,'variants':len(variants),'expected_renders':len(variants)*3,'completed_renders':len(results),'review_only':True,'approved':False,'runtime_clock_implemented':False,'combination_cross_product_validated':False,'results':results};(out/'render-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2));print('RENDER_PROGRESS',len(results),len(variants)*3,v,mode,flush=True)
print('ALL_REVIEW_RENDERS_COMPLETE',len(results),flush=True)
