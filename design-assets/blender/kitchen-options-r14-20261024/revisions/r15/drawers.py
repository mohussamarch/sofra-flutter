import bpy
from mathutils import Vector
from appearance import bounds,assign,tube
from furniture import box
def three_drawers():
 bpy.context.view_layer.update()
 for ob in list(bpy.data.objects):
  if ob.name.startswith(('r15_vintage_pull','r15_vintage_rosette')):
   a,b=bounds(ob);pos=(a+b)/2
   if 2.1<pos.x<2.7 and 2.80<pos.y<3.05:bpy.data.objects.remove(ob,do_unlink=True)
 old=bpy.data.objects.get('cabinet_fridge_buffer_600_front')
 if not old:return
 mn,mx=bounds(old);root=old.parent;name=old.name;wood=old.data.materials[0];brass=bpy.data.materials['r15_polished_aged_brass'];y=mn.y;cx=(mn.x+mx.x)/2;w=mx.x-mn.x;h=(mx.z-mn.z-.020)/3
 for o in list(bpy.data.objects):
  pos=o.matrix_world.translation
  if o==old or o.name.startswith(name+'_') or (o.name.startswith(('r15_vintage_pull','r15_vintage_rosette')) and 2.1<pos.x<2.7 and 2.80<pos.y<3.05):bpy.data.objects.remove(o,do_unlink=True)
 for i in range(3):
  z=mn.z+h/2+i*(h+.010);prefix='cabinet_fridge_buffer_drawer_'+str(i)+'_front';panel=box(prefix,(cx,y+.014,z),(w,.028,h),wood,.008)
  bpy.context.view_layer.update();world=panel.matrix_world.copy();panel.parent=root;panel.matrix_world=world
  for side in [-1,1]:
   box(prefix+'_classic_v',(cx+side*(w/2-.027),y-.012,z),(.042,.030,h-.008),wood,.005)
   box(prefix+'_classic_h',(cx,y-.012,z+side*(h/2-.025)),(w-.085,.030,.040),wood,.005)
  box(prefix+'_raised_center',(cx,y-.010,z),(w-.11,.024,h-.10),wood,.008)
  tube(prefix+'_vintage_horizontal_pull',[(cx-.062,y-.038,z),(cx-.05,y-.062,z),(cx+.05,y-.062,z),(cx+.062,y-.038,z)],.008,brass)
 bpy.context.view_layer.update();bpy.context.scene['fridge_buffer_drawer_count']=3
