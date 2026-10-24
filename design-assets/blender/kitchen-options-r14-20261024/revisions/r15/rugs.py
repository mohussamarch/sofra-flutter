import bpy,math
from collections import defaultdict
from appearance import material,assign
from furniture import box
def rebuild_rugs():
 for o in list(bpy.data.objects):
  if o.get('option_group') in ['rug_persian','rug_teal','rug_ochre']:bpy.data.objects.remove(o,do_unlink=True)
 x,y,W,H=2.15,1.25,2.05,2.15
 for style,group,base,ink,cream in [('persian','rug_persian',(.14,.008,.018),(.006,.012,.030),(.69,.57,.37)),('kilim','rug_teal',(.48,.24,.10),(.10,.28,.30),(.76,.64,.43)),('floral','rug_ochre',(.23,.32,.27),(.10,.19,.15),(.69,.61,.43))]:
  before=set(bpy.data.objects);mats=[material(style+'_ground',base,rough=.94),material(style+'_ink',ink,rough=.92),material(style+'_ivory',cream,rough=.94),material(style+'_accent',(.39,.14,.08) if style!='persian' else (.14,.24,.12),rough=.93)]
  for m in mats:
   n=m.node_tree.nodes;l=m.node_tree.links;p=n.get('Principled BSDF');noise=n.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=190;noise.inputs['Detail'].default_value=2;b=n.new('ShaderNodeBump');b.inputs['Strength'].default_value=.22;b.inputs['Distance'].default_value=.0007;l.new(noise.outputs['Fac'],b.inputs['Height']);l.new(b.outputs[0],p.inputs['Normal'])
  box(group+'_woven_base',(x,y,.014),(W,H,.016),mats[0],.010)
  accum=defaultdict(lambda:[[],[]])
  def poly(points,c,z):
   vs,fs=accum[c];start=len(vs);vs.extend([(a,b,z) for a,b in points]);fs.append(tuple(range(start,len(vs))))
  def rect(cx,cy,w,h,c,z):poly([(cx-w/2,cy-h/2),(cx+w/2,cy-h/2),(cx+w/2,cy+h/2),(cx-w/2,cy+h/2)],c,z)
  def med(cx,cy,r,c,z,sides=8):poly([(cx+r*math.cos(i*math.tau/sides+math.pi/8),cy+r*math.sin(i*math.tau/sides+math.pi/8)) for i in range(sides)],c,z)
  # Narrow nested borders and repeated small motifs instead of three large diamonds.
  for inset,width,c in [(.035,.022,2),(.075,.045,1),(.135,.018,2),(.165,.032,1)]:
   for side in [-1,1]:rect(x+side*(W/2-inset),y,width,H-2*inset,c,.023);rect(x,y+side*(H/2-inset),W-2*inset,width,c,.023)
  for side in [-1,1]:
   for i in range(26):
    t=-.86+i*1.72/25;med(x+side*(W/2-.078),y+t,.015,2,.024,4);med(x+t,y+side*(H/2-.078),.015,2,.024,4)
  if style=='persian':
   for i in range(3):
    for j in range(4):
     cx=x+(i-1)*.49;cy=y+(j-1.5)*.38
     poly([(cx+(.175 if k%2==0 else .130)*math.cos(k*math.pi/8),cy+(.175 if k%2==0 else .130)*math.sin(k*math.pi/8)) for k in range(16)],1,.0234)
     med(cx,cy,.120,0,.0238);med(cx,cy,.095,2,.0242,8);med(cx,cy,.076,1,.0246,8);med(cx,cy,.024,3,.0254,8)
     for k in range(8):
      a=k*math.tau/8;u=cx+.143*math.cos(a);v=cy+.143*math.sin(a);med(u,v,.014,2,.0254,4);med(cx+.045*math.cos(a),cy+.045*math.sin(a),.018,2,.0250,10)
     for side in [-1,1]:
      for a in [.045,.085,.125]:poly([(cx+side*.17,cy+a-.012),(cx+side*.205,cy+a+.017),(cx+side*.178,cy+a+.028)],3,.0251)
   for i in range(2):
    for j in range(2):
     cx=x+(i-.5)*.52;cy=y+(j-.5)*.55;med(cx,cy,.075,1,.024,4)
     for k in range(4):a=k*math.pi/2;med(cx+.034*math.cos(a),cy+.034*math.sin(a),.014,2,.025,4)
  elif style=='kilim':
   for j in range(7):
    cy=y+(j-3)*.235
    for i in range(5):
     cx=x+(i-2)*.29;poly([(cx-.135,cy),(cx,cy+.105),(cx+.135,cy),(cx,cy-.105)],1 if (i+j)%2 else 2,.0238);med(cx,cy,.034,3,.025,4)
  else:
   for i in range(5):
    for j in range(5):
     cx=x+(i-2)*.31;cy=y+(j-2)*.33
     for k in range(6):a=k*math.tau/6;med(cx+.042*math.cos(a),cy+.042*math.sin(a),.026,2,.024,12)
     med(cx,cy,.024,3,.025,10)
     for side in [-1,1]:poly([(cx+side*.06,cy-.04),(cx+side*.11,cy-.085),(cx+side*.10,cy-.02)],1,.0245)
  for c,(vs,fs) in accum.items():
   me=bpy.data.meshes.new(style+'_small_woven_motifs');me.from_pydata(vs,[],fs);me.update();o=bpy.data.objects.new(style+'_motif_layer_'+str(c),me);bpy.context.collection.objects.link(o);assign(o,mats[c])
  fringe=material(style+'_ecru_cotton_fringe',(.82,.77,.65),rough=.96)
  for side in [-1,1]:box(style+'_fringe_binding',(x,y+side*(H/2+.008),.017),(W-.012,.035,.012),fringe,.003)
  curve=bpy.data.curves.new(style+'_fringe','CURVE');curve.dimensions='3D';curve.bevel_depth=.004;curve.bevel_resolution=2
  for side in [-1,1]:
   for i in range(110):
    a=x-W/2+.025+i*(W-.05)/109;sp=curve.splines.new('POLY');sp.points.add(2)
    for p,co in zip(sp.points,[(a,y+side*H/2,.019,1),(a+.004*math.sin(i),y+side*(H/2+.045),.016,1),(a+.006*math.sin(i),y+side*(H/2+.09),.012,1)]):p.co=co
  ob=bpy.data.objects.new(style+'_220_fringe_strands',curve);bpy.context.collection.objects.link(ob);assign(ob,fringe)
  for ob in set(bpy.data.objects)-before:ob['option_group']=group;ob.hide_render=True;ob.hide_set(True)
 bpy.context.scene['rug_size_m']=[W,H];bpy.context.scene['rug_styles']=['red_multimedallion','warm_kilim','vintage_small_floral']
