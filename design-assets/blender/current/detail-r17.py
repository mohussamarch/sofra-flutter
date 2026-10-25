import bpy,ast,sys
from pathlib import Path
from mathutils import Vector
p=Path('E:/work/SOFRA/app/design-assets/blender/current');tree=ast.parse((p/'build.py').read_text());exec(compile(ast.Module(body=[n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='select'],type_ignores=[]),'select','exec'))
selected=set(sys.argv[sys.argv.index('--')+1:]) if '--' in sys.argv else set()
for variant,target,scale in [('table_chairs',(3,.60,.65),1.6),('microwave',(.55,3.18,1.20),1.35),('hanging_plants',(.30,3.30,2.13),1.1)]:
 if selected and variant not in selected:continue
 bpy.ops.wm.open_mainfile(filepath=str(p/'kitchen-morning.blend'));s=bpy.context.scene;select('classic',variant,'morning');cam=s.camera;cam.location=Vector(target)-(cam.rotation_euler.to_matrix()@Vector((0,0,-1)))*10;cam.data.ortho_scale=scale
 prefs=bpy.context.preferences.addons['cycles'].preferences;prefs.compute_device_type='OPTIX';prefs.get_devices()
 for d in prefs.devices:d.use=d.type=='OPTIX'
 s.cycles.device='GPU';s.cycles.samples=192;s.render.resolution_x=s.render.resolution_y=900;s.render.resolution_percentage=100;s.render.filepath=str(p/'renders-r17'/('detail-'+variant+'.png'));bpy.ops.render.render(write_still=True)
 # Diagnostic camera only: never save over the aligned master cameras.
