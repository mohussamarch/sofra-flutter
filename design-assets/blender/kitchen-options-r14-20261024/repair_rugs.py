import bpy,sys,json,hashlib,ast
from pathlib import Path
out=Path(__file__).parent;sys.path.insert(0,str(out));from modes import configure
# Fix layer separation in canonical library and its three saved default scenes.
for filename in ['options-library.blend','base-morning.blend','base-night.blend','base-golden.blend']:
 path=out/filename;bpy.ops.wm.open_mainfile(filepath=str(path))
 for o in bpy.data.objects:
  if o.type=='MESH' and o.name.startswith('rug_'):
   if '_diamond_' in o.name or '_petal_' in o.name:
    for v in o.data.vertices:v.co.z=.043
   elif '_center_' in o.name:
    for v in o.data.vertices:v.co.z=.044
 motif=bpy.data.materials['rug_persian_motif']
 for side in [-1,1]:
  for j in range(5):
   cy=1.38+(j-2)*.27;xx=1.75+side*.34;points=[(xx,cy-.06,.043),(xx,cy+.06,.043),(xx-side*.08,cy,.043)];name='rug_persian_triangle_'+str(side)+'_'+str(j);me=bpy.data.meshes.new(name);me.from_pydata(points,[],[(0,1,2)]);me.update();o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o);o.data.materials.append(motif);o['option_group']='rug_persian';o.hide_render=True
 bpy.ops.wm.save_as_mainfile(filepath=str(path))
module=ast.parse((out/'render_options.py').read_text());fn=next(n for n in module.body if isinstance(n,ast.FunctionDef) and n.name=='select_variant');exec(compile(ast.Module(body=[fn],type_ignores=[]),'selector','exec'))
m=json.loads((out/'render-manifest.json').read_text())
for v in ['rug_persian','rug_teal','rug_ochre']:
 bpy.ops.wm.open_mainfile(filepath=str(out/'options-library.blend'));select_variant(v)
 for mode in ['morning','night','golden']:
  s=configure(mode);s.cycles.samples=160;s.render.resolution_x=s.render.resolution_y=900;p=out/'renders'/(v+'--'+mode+'.png');s.render.filepath=str(p);bpy.ops.render.render(write_still=True)
  item=next(x for x in m['results'] if x['variant']==v and x['mode']==mode);item['sha256']=hashlib.sha256(p.read_bytes()).hexdigest();print('RUG_FIXED',v,mode,flush=True)
m['rug_coplanar_motif_overlap_corrected']=True;(out/'render-manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2));print('ALL_NINE_RUGS_FIXED')
