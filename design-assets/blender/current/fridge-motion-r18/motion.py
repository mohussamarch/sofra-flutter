import bpy,math,json
from pathlib import Path
from mathutils import Vector,Euler
from bpy_extras.object_utils import world_to_camera_view
ROOT=Path('E:/work/SOFRA/app/design-assets/blender/current')
OUT=ROOT/'fridge-motion-r18'
N_APPROACH=30;N_DOOR=14;WIDTH=1080;HEIGHT=2340
def initialize(mode):
 bpy.ops.wm.open_mainfile(filepath=str(ROOT/('kitchen-'+mode+'.blend')));s=bpy.context.scene;exec(bpy.data.texts['SELECT-OPTION.py'].as_string());exec(bpy.data.texts['SET-FRIDGE-DOORS.py'].as_string());cam=s.camera
 s.render.resolution_x=WIDTH;s.render.resolution_y=HEIGHT;s.render.resolution_percentage=100;s.render.use_border=False;s.render.film_transparent=False;s.render.use_persistent_data=True
 s.cycles.samples=80;s.cycles.use_denoising=True;s.render.image_settings.file_format='PNG';cam.data.clip_end=1000;cam.data.dof.use_dof=False
 prefs=bpy.context.preferences.addons['cycles'].preferences;prefs.compute_device_type='OPTIX';prefs.get_devices()
 for d in prefs.devices:d.use=d.type=='OPTIX'
 s.cycles.device='GPU'
 return s
def camera_pose(s,t):
 cam=s.camera;q0=Euler((.9553165436,0,.7853981853)).to_quaternion();q1=Euler((math.pi/2,0,0)).to_quaternion();smooth=t*t*(3-2*t)
 start=Vector((1.95,1.65,1.12));end=Vector((3.15,2.842,1.10));target=start.lerp(end,smooth);q=q0.slerp(q1,smooth)
 cam.rotation_mode='QUATERNION';cam.rotation_quaternion=q;cam.data.sensor_fit='HORIZONTAL';cam.data.sensor_width=36;cam.data.shift_x=cam.data.shift_y=0
 if t==0:
  cam.data.type='ORTHO';cam.data.ortho_scale=7;cam.location=Vector((9.95,-6.35,9.12))
 else:
  cam.data.type='PERSP';distance=math.exp(math.log(1000*7/36)*(1-smooth)+math.log(1.72)*smooth);cam.data.lens=math.exp(math.log(1000)*(1-smooth)+math.log(50)*smooth);cam.location=target-(q@Vector((0,0,-1)))*distance;cam.data.shift_y=-.22*smooth/(36*distance/cam.data.lens)
 bpy.context.view_layer.update()
def door_pose(s,degrees):
 for name in ['r18_fridge_hinge','r18_freezer_hinge']:bpy.data.objects[name].rotation_euler.z=-math.radians(degrees)
 bpy.context.view_layer.update()
def render(s,path,percent=100):
 path.parent.mkdir(parents=True,exist_ok=True);s.render.resolution_percentage=percent;s.render.filepath=str(path);bpy.ops.render.render(write_still=True)
def xy(s,p):
 v=world_to_camera_view(s,s.camera,Vector(p));return [round(v.x*WIDTH,3),round((1-v.y)*HEIGHT,3)]
def layout(s):
 rows=[]
 for id,z0,z1 in [('produce',.13,.34),('lower',.405,.69),('middle',.755,1.03),('upper',1.095,1.32),('freezer',1.45,1.96)]:
  corners=[xy(s,(x,3.10,z)) for x,z in [(2.80,z1),(3.50,z1),(3.50,z0),(2.80,z0)]]
  rows.append({'id':id,'corners':corners,'anchors':[xy(s,(x,3.10,z0+.05)) for x in [2.88,3.06,3.24,3.42]],'compartment':'freezer' if id=='freezer' else 'fridge'})
 return {'canvas':[WIDTH,HEIGHT],'coordinateOrigin':'top-left pixels','rows':rows,'inventoryBaked':False,'bottomUiReserveFraction':.18}
if __name__=='__main__':
 s=initialize('morning');s.cycles.samples=64
 for id,t,angle in [('start',0,0),('quarter',.25,0),('middle',.5,0),('near',.75,0),('front',1,0),('open',1,104)]:camera_pose(s,t);door_pose(s,angle);render(s,OUT/'probe'/('morning-'+id+'.png'),50)
 (OUT/'shelf-layout.json').write_text(json.dumps(layout(s),indent=2));print('MOTION_PROBES_READY')
