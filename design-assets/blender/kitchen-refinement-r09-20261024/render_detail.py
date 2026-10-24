"""Inspection view only; do not overwrite saved full-composition cameras."""
import bpy,sys
from pathlib import Path
from mathutils import Vector
p=Path(sys.argv[sys.argv.index('--')+1]);bpy.ops.wm.open_mainfile(filepath=str(p/'night_ceiling.blend'))
s=bpy.context.scene;cam=s.camera;t=Vector((1.61,3.15,1.35))
cam.location=t+Vector((8,-12,6));cam.rotation_euler=(t-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=2.2
prefs=bpy.context.preferences.addons['cycles'].preferences;prefs.compute_device_type='OPTIX';prefs.get_devices()
for d in prefs.devices:d.use=(d.type=='OPTIX')
s.cycles.device='GPU';s.cycles.samples=96;s.render.filepath=str(p/'stove-hood-detail.png')
bpy.ops.render.render(write_still=True);print('R09_DETAIL_COMPLETE')
