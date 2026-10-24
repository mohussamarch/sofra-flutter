import bpy,ast,json,hashlib,math
from pathlib import Path
p=Path(__file__).parent;tree=ast.parse((p/'build.py').read_text());exec(compile(ast.Module(body=[n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='select'],type_ignores=[]),'select','exec'))
r=json.loads((p/'render-manifest.json').read_text());assert len(r)==46 and len({(x['variant'],x['mode']) for x in r})==46
for x in r:assert hashlib.sha256((p/x['file']).read_bytes()).hexdigest()==x['sha256']
cameras=[];reports=[]
for mode in ['morning','night','golden']:
 bpy.ops.wm.open_mainfile(filepath=str(p/('kitchen-'+mode+'.blend')));s=bpy.context.scene;bpy.context.view_layer.update();cameras.append([list(row) for row in s.camera.matrix_world])
 assert s['chair_count']==4 and len([o for o in bpy.data.objects if o.name.startswith('chair_') and o.name.endswith('_seat')])==4
 assert list(s['table_center_m'])==[3.0,.60];assert abs(s['rug_square_m']-2.5)<1e-5
 for o in bpy.data.objects:
  if 'woven_base' in o.name and o.get('option_group') in ['rug_persian','rug_teal','rug_ochre']:assert abs(o.dimensions.x-2.5)<1e-4 and abs(o.dimensions.y-2.5)<1e-4
 assert bpy.data.objects['microwave_fixed_socket'].get('option_group') is None
 assert bpy.data.objects['microwave_connected_cable']['option_group']=='microwave'
 assert len([o for o in bpy.data.objects if o.get('cabinet_style')=='modern' and o.name.startswith('modern_') and not o.name.startswith('modern_recess') and o.type=='MESH' and len(o.data.vertices)>8])>=10
 assert 'SELECT-OPTION.py' in bpy.data.texts
 select('classic','base',mode);assert bpy.data.objects['microwave_connected_cable'].hide_render
 select('classic','microwave',mode);assert not bpy.data.objects['microwave_connected_cable'].hide_render and not bpy.data.objects['microwave_fixed_socket'].hide_render
 select('classic','builtin',mode);assert bpy.data.objects['range_open_glass_lid'].hide_render;assert not bpy.data.objects['builtin_flush_wood_stile'].hide_render
 select('classic','no_curtain',mode);assert bpy.data.objects['curtain_wall_bracket'].hide_render
 select('classic','led',mode);lights=[o for o in bpy.data.objects if o.type=='LIGHT' and o.get('option_group')=='led'];assert len(lights)==2 and all(o.hide_render==(mode!='night') for o in lights)
 if mode!='night':assert abs(math.degrees(bpy.data.objects['window_golden_sun'].data.angle)-.8)<.001
 reports.append({'mode':mode,'file':'kitchen-'+mode+'.blend','sha256':hashlib.sha256((p/('kitchen-'+mode+'.blend')).read_bytes()).hexdigest(),'objects':len(bpy.data.objects),'collections':len(bpy.data.collections),'checks':'passed'})
assert cameras[0]==cameras[1]==cameras[2]
(p/'verification.json').write_text(json.dumps({'renderHashes':46,'masterFiles':3,'cameraAligned':True,'sources':reports,'visualApproval':False,'retentionLimit':3},indent=2));print('R16_CHECKS_PASS')
