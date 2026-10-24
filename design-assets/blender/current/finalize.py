import bpy,ast
from pathlib import Path
from mathutils import Matrix,Vector
p=Path(__file__).parent
tree=ast.parse((p/'build.py').read_text());f=next(n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='select');selector='import bpy\n'+ast.unparse(f)+'\n\n# Styles: classic / modern / japandi\n# Options: base / microwave / double_fridge / builtin / table_chairs / rug_persian / rug_teal / rug_ochre / white_blind / no_curtain / hanging_plants / led\nselect(style="classic",variant="base",mode=bpy.context.scene["lighting_mode"])\n'
for mode in ['morning','night','golden']:
 bpy.ops.wm.open_mainfile(filepath=str(p/('kitchen-'+mode+'.blend')));bpy.context.preferences.filepaths.save_version=0
 if 'r16_terracotta_painted_wood' not in bpy.data.materials:
  mat=bpy.data.materials['r15_classic_painted_timber'].copy();mat.name='r16_terracotta_painted_wood';rgb=[int(h,16)/255 for h in ['C7','83','6C']];rgb=[v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in rgb];ramp=next(n for n in mat.node_tree.nodes if n.type=='VALTORGB')
  for e,factor in zip(ramp.color_ramp.elements,[.75,1.15]):e.color=(*[v*factor for v in rgb],1)
 bpy.data.materials['r16_terracotta_painted_wood'].use_fake_user=True
 if not bpy.context.scene.get('final_fixes_r16'):
  for o in bpy.data.objects:
   if o.name.startswith(('curtain_wall_bracket','curtain_support_arm')):o['option_group']='default_curtain'
   if o.name.startswith('builtin_hob_ring'):
    c=Vector((1.65,3.30,.92));o.matrix_world=Matrix.Translation(c)@Matrix.Diagonal((.86,.86,1,1))@Matrix.Translation(-c)@o.matrix_world
   if o.name in ['builtin_oven_frame','builtin_oven_glass','builtin_oven_handle','builtin_oven_knob_1.42','builtin_oven_knob_1.88']:o.location.y+=.064
  bpy.context.scene['final_fixes_r16']=True
 t=bpy.data.texts.get('SELECT-OPTION.py') or bpy.data.texts.new('SELECT-OPTION.py');t.clear();t.write(selector)
 bpy.ops.wm.save_as_mainfile(filepath=str(p/('kitchen-'+mode+'.blend')),compress=True)
