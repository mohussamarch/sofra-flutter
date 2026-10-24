import bpy,sys,math,json
from pathlib import Path
from mathutils import Vector
ROOT=Path('E:/work/SOFRA/app/design-assets/blender');OLD=ROOT/'kitchen-options-r14-20261024/revisions/r15';OUT=Path(__file__).parent
sys.path.insert(0,str(OLD));from appearance import material,assign,bounds,tube,wood,panels
from furniture import box
def tag(o,group=None,style=None):
 if group:o['option_group']=group
 if style:o['cabinet_style']=style
 return o
def clone(o,name,mat):
 n=o.copy();n.data=o.data.copy();n.name=name;n.parent=None;n.matrix_world=o.matrix_world.copy();bpy.context.collection.objects.link(n);assign(n,mat);n.modifiers.clear();return n
def primitive(n,p,d,m,group=None,style=None,b=.01):return tag(box(n,p,d,m,b),group,style)
def style_geometry():
 fronts=panels();cream=material('r16_acrylic_semigloss',(.64,.60,.51),rough=.26);p=cream.node_tree.nodes.get('Principled BSDF');p.inputs['Coat Weight'].default_value=.25;p.inputs['Coat Roughness'].default_value=.26
 oak=wood('r16_honey_oak',(.56,.34,.15));bronze=material('r16_brushed_bronze',(.17,.105,.04),.8,.3);recess=material('r16_handle_recess',(.33,.30,.245),rough=.5)
 for o in list(bpy.data.objects):
  if o in fronts or o.name.startswith(('r15_vintage_pull','r15_vintage_rosette')) or any(o.name.startswith(f.name+'_') for f in fronts):tag(o,style='classic')
 for original in fronts:
  mn,mx=bounds(original);left=(mx.x-mn.x)<(mx.y-mn.y);w=(mx.y-mn.y) if left else (mx.x-mn.x);h=mx.z-mn.z;u=(mn.y+mx.y)/2 if left else (mn.x+mx.x)/2;z=(mn.z+mx.z)/2;normal=mx.x if left else mn.y
  def xyz(U,D,Z):return (normal+D,U,Z) if left else (U,normal-D,Z)
  modern=tag(clone(original,'modern_'+original.name,cream),style='modern');modern.hide_set(False);modern.hide_render=False
  pantry=original.name=='pantry_door';upper=original.name.startswith('upper_')
  U=u-w/2+.004 if pantry else u;Z=z+.16 if pantry else (mn.z-.01 if upper else mx.z+.01)
  size=(.10,.22) if pantry else (min(.18,w*.40),.085)
  cutter=primitive('temporary_local_curve',xyz(U,0,Z),(.18,size[0],size[1]) if left else (size[0],.18,size[1]),cream,b=.026)
  bpy.context.view_layer.objects.active=cutter
  for mod in list(cutter.modifiers):bpy.ops.object.modifier_apply(modifier=mod.name)
  bpy.context.view_layer.objects.active=modern;mod=modern.modifiers.new('localized_curved_integrated_pull','BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=cutter;bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cutter,do_unlink=True)
  mod=modern.modifiers.new('soft_acrylic_edges','BEVEL');mod.width=.004;mod.segments=4
  primitive('modern_recess_back',xyz(U,-.040,Z+(-.03 if not upper and not pantry else .03 if upper else 0)),(.012,size[0]-.008,size[1]) if left else (size[0]-.008,.012,size[1]),recess,style='modern',b=.012)
  jp=tag(clone(original,'japandi_'+original.name,oak),style='japandi');mod=jp.modifiers.new('soft_oak_edges','BEVEL');mod.width=.006;mod.segments=3
  pullZ=z+(-h*.30 if upper else h*.30);tag(tube('japandi_handle',[xyz(u-.065,.025,pullZ),xyz(u-.05,.042,pullZ),xyz(u+.05,.042,pullZ),xyz(u+.065,.025,pullZ)],.006,bronze),style='japandi')
  if pantry:
   for i in range(int((w-.06)/.032)):
    U=u-w/2+.04+i*.032;tag(tube('japandi_flute',[xyz(U,.017,mn.z+.035),xyz(U,.017,mx.z-.035)],.007,oak),style='japandi')
 terracotta=bpy.data.materials['r15_classic_painted_timber'].copy();terracotta.name='r16_terracotta_painted_wood';rgb=[int(h,16)/255 for h in ['C7','83','6C']];rgb=[v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in rgb];ramp=next(n for n in terracotta.node_tree.nodes if n.type=='VALTORGB')
 for e,f in zip(ramp.color_ramp.elements,[.75,1.15]):e.color=(*[v*f for v in rgb],1)
def furniture():
 for o in list(bpy.data.objects):
  if o.get('option_group')=='table_chairs':bpy.data.objects.remove(o,do_unlink=True)
 before=set(bpy.data.objects);timber=wood('r16_vintage_timber',(.42,.22,.09));dark=wood('r16_vintage_edges',(.30,.14,.05));cloth=material('r16_folded_linen',(.72,.62,.42),rough=.96)
 # Center of the front-right3x3tile block: x2.1..3.9, y-.3..1.5.
 x,y=3.0,.60
 primitive('table_square_top',(x,y,.755),(.82,.82,.065),timber,b=.035)
 for dx in [-.30,.30]:
  for dy in [-.30,.30]:primitive('table_chunky_rounded_leg',(x+dx,y+dy,.37),(.085,.085,.71),dark,b=.030)
 for side in [-1,1]:
  primitive('table_apron_x',(x,y+side*.32,.66),(.70,.045,.12),timber)
  primitive('table_apron_y',(x+side*.32,y,.66),(.045,.70,.12),timber)
 for j in range(3):primitive('table_folded_cloth_'+str(j),(x-.055,y,.793+j*.004),(.36-j*.012,.52-j*.012,.004),cloth,b=.002)
 for i,(cx,cy,a) in enumerate([(x,y-.63,0),(x-.63,y,-math.pi/2),(x+.63,y,math.pi/2),(x,y+.63,math.pi)]):
  def tr(p):u,v,z=p;return (cx+u*math.cos(a)-v*math.sin(a),cy+u*math.sin(a)+v*math.cos(a),z)
  seat=primitive('chair_'+str(i)+'_seat',tr((0,0,.43)),(.39,.39,.055),timber,b=.04);seat.rotation_euler.z=a
  for u in [-.14,.14]:
   for v in [-.14,.14]:primitive('chair_chunky_leg',tr((u,v,.21)),(.052,.052,.40),dark,b=.020)
  for u in [-.155,.155]:tube('chair_backpost',[tr((u,-.155,.40)),tr((u,-.19,.86))],.024,timber)
  rail=primitive('chair_'+str(i)+'_broad_back',tr((0,-.18,.77)),(.35,.052,.15),timber,b=.035);rail.rotation_euler.z=a
 for o in set(bpy.data.objects)-before:tag(o,'table_chairs')
 bpy.context.scene['table_center_m']=[3.0,.60];bpy.context.scene['chair_count']=4
def rugs():
 for o in bpy.data.objects:
  if o.get('option_group') not in ['rug_persian','rug_teal','rug_ochre']:continue
  # Identical X/Y extents centered between opposing room edges.
  M=o.matrix_world.copy();pivot=Vector((2.15,1.25,0));dest=Vector((2.25,1.35,0));S=__import__('mathutils').Matrix.Diagonal((2.50/2.05,2.50/2.15,1,1));T=__import__('mathutils').Matrix.Translation(dest)@S@__import__('mathutils').Matrix.Translation(-pivot);o.matrix_world=T@M
  if o.type=='CURVE':o.data.bevel_depth*=1.45
  if 'woven_base' in o.name:o.scale.z*=1.35;o.location.z-=.0028
  for m in o.data.materials:
   if not m or not m.use_nodes:continue
   for n in m.node_tree.nodes:
    if n.type=='BUMP':n.inputs['Strength'].default_value=.42;n.inputs['Distance'].default_value=.0014
 bpy.context.scene['rug_square_m']=2.5;bpy.context.scene['rug_center_m']=[2.25,1.35]
def appliances():
 metal=bpy.data.materials['r15_shared_warm_satin_stainless'];ivory=material('r16_warm_ivory_handle',(.58,.54,.43),.15,.32);rubber=material('r16_power_lead',(.035,.028,.022),rough=.68)
 for o in list(bpy.data.objects):
  if o.name.startswith(('fridge_door_handle','fridge_freezer_handle','double_fridge_handle')):
   mn,mx=bounds(o);x=(mn.x+mx.x)/2;y=mn.y-.018;z=(mn.z+mx.z)/2;length=max(.20,mx.z-mn.z)
   group=o.get('option_group');name=o.name;bpy.data.objects.remove(o,do_unlink=True)
   primitive(name,(x,y-.028,z),(.040,.045,length),metal if group else ivory,group,b=.016)
   for dz in [-length*.40,length*.40]:primitive(name+'_mount',(x,y+.005,z+dz),(.05,.07,.032),metal if group else ivory,group,b=.012)
 # Static power outlet remains with or without microwave.
 for o in list(bpy.data.objects):
  if o.name.startswith(('outlet_back_plate_0','outlet_back_hole_0')):bpy.data.objects.remove(o,do_unlink=True)
 plate=material('r16_socket_ivory',(.66,.62,.53),rough=.58)
 primitive('microwave_fixed_socket',(.78,3.568,1.36),(.13,.028,.09),plate,b=.012)
 for dx in [-.032,.032]:primitive('socket_hole',(.78+dx,3.550,1.36),(.008,.005,.022),rubber,b=.002)
 primitive('microwave_plug',(.78,3.529,1.36),(.047,.040,.054),rubber,'microwave',b=.009)
 tag(tube('microwave_connected_cable',[(.78,3.503,1.34),(.79,3.49,1.24),(.76,3.44,1.10),(.66,3.39,1.07),(.54,3.33,1.18)],.008,rubber),'microwave')
 # Open glass range lid, real rear hinge and frame; exclusive with built-in.
 glass=material('r16_stove_tinted_glass',(.22,.30,.29),rough=.16);p=glass.node_tree.nodes.get('Principled BSDF');p.inputs['Transmission Weight'].default_value=.75;p.inputs['IOR'].default_value=1.45
 primitive('range_open_glass_lid',(1.65,3.575,1.13),(.84,.016,.44),glass,'default_range',b=.015)
 for x in [1.24,2.06]:primitive('range_lid_side',(x,3.57,1.13),(.014,.022,.45),metal,'default_range',b=.006)
 for z in [.915,1.35]:primitive('range_lid_edge',(1.65,3.57,z),(.83,.022,.014),metal,'default_range',b=.006)
 for x in [1.34,1.96]:primitive('range_lid_hinge',(x,3.55,.91),(.065,.06,.035),metal,'default_range')
 # Smaller hob, preserving its four rings about the same center.
 for o in bpy.data.objects:
  if o.name=='builtin_black_hob' or o.name.startswith('builtin_hob_ring'):
   M=o.matrix_world.copy();c=Vector((1.65,3.30,.92));M.translation=c+(M.translation-c)*Vector((.86,.86,1));o.matrix_world=M;o.scale.x*=.86;o.scale.y*=.86
 for name in ['builtin_oven_frame','builtin_oven_glass','builtin_oven_handle','builtin_oven_knob_1.42','builtin_oven_knob_1.88']:
  o=bpy.data.objects.get(name)
  if o:o.location.y-=.026
 paint=bpy.data.materials['r15_classic_painted_timber']
 for x in [1.235,2.065]:primitive('builtin_flush_wood_stile',(x,2.965,.46),(.065,.06,.75),paint,'builtin')
 for z in [.085,.825]:primitive('builtin_flush_wood_rail',(1.65,2.965,z),(.86,.06,.065),paint,'builtin')
def curtains_and_led(mode):
 brass=bpy.data.materials['r06_muted_brass']
 for y in [1.40,2.80]:
  primitive('curtain_wall_bracket',(.018,y,2.40),(.035,.075,.09),brass,'default_curtain',b=.014)
  tag(tube('curtain_support_arm',[(.03,y,2.40),(.095,y,2.40),(.12,y,2.40)],.013,brass),'default_curtain')
 for o in bpy.data.objects:
  if o.name.startswith('blind_slat_'):o.rotation_euler.y=math.radians(10);o.visible_shadow=True
 emit=material('r16_led_diffuser',(.9,.68,.38),rough=.55);p=emit.node_tree.nodes.get('Principled BSDF');p.inputs['Emission Color'].default_value=(1,.66,.32,1);p.inputs['Emission Strength'].default_value=2.2
 for x,w in [(.88,.57),(2.38,.57)]:
  primitive('led_diffuser',(x,3.30,1.605),(w,.023,.018),emit,'led',b=.006)
  bpy.ops.object.light_add(type='AREA',location=(x,3.28,1.595));o=bpy.context.object;o.name='led_warm_under_cabinet';o.data.energy=18;o.data.color=(1,.73,.43);o.data.shape='RECTANGLE';o.data.size=w;o.data.size_y=.04;tag(o,'led')
def select(style='classic',variant='base',mode='morning'):
 for o in bpy.data.objects:
  st=o.get('cabinet_style');g=o.get('option_group');visible=(not st or st==style)
  if g and not g.startswith('default_'):visible &= g==variant and (g!='led' or mode=='night')
  if variant=='double_fridge' and g=='default_fridge':visible=False
  if variant in ['white_blind','no_curtain'] and g=='default_curtain':visible=False
  if variant=='builtin' and g in ['default_range','default_counter']:visible=False
  if mode=='night' and ('exterior_garden_camera_only' in [p.name for p in [o.parent] if p] or o.name=='morning_indoor_scattering'):visible=False
  if o.name.startswith('morning_dream_mote_') and mode!='golden':visible=False
  o.hide_render=not visible;o.hide_set(not visible)
  if not st or st=='classic':
   for slot in o.material_slots:
    if slot.material and slot.material.name in ['r15_classic_painted_timber','r16_acrylic_semigloss','r16_honey_oak','r16_terracotta_painted_wood']:slot.material=bpy.data.materials['r16_terracotta_painted_wood' if variant=='terracotta' else 'r15_classic_painted_timber' if st=='classic' else {'classic':'r15_classic_painted_timber','modern':'r16_acrylic_semigloss','japandi':'r16_honey_oak'}[style]]
 ramp=next(n for n in bpy.data.materials['r13_cotton_gingham'].node_tree.nodes if n.type=='VALTORGB')
 for e,c in zip(sorted(ramp.color_ramp.elements,key=lambda e:e.position),[(.9,.87,.74,1),(.34,.57,.69,1),(.12,.31,.48,1)] if variant=='curtain_blue' else [(.92,.81,.63,1),(.73,.40,.23,1),(.48,.19,.10,1)]):e.color=c
 bpy.context.scene['selected_style']=style;bpy.context.scene['selected_option']=variant
def organize():
 for o in list(bpy.data.objects):
  g=o.get('option_group');st=o.get('cabinet_style');name='Cabinets / '+st if st else 'Options / '+g if g else 'Lighting' if o.type=='LIGHT' else 'Room and fixed objects'
  col=bpy.data.collections.get(name)
  if not col:col=bpy.data.collections.new(name);bpy.context.scene.collection.children.link(col)
  for old in list(o.users_collection):old.objects.unlink(o)
  col.objects.link(o)
for mode in ['morning','night','golden']:
 bpy.ops.wm.open_mainfile(filepath=str(OLD/('base-'+mode+'.blend')));s=bpy.context.scene;bpy.context.preferences.filepaths.save_version=0
 style_geometry();furniture();rugs();appliances();curtains_and_led(mode)
 for m in bpy.data.materials:
  if m.name.startswith(('window','r09_window','r08_window','r13_window')) and m.use_nodes:
   p=m.node_tree.nodes.get('Principled BSDF')
   if p:p.inputs['Base Color'].default_value=(.50,.52,.48,1);p.inputs['Roughness'].default_value=.65;p.inputs['Specular IOR Level'].default_value=.18
 windowpaint=material('r16_window_satin_ivory',(.19,.21,.18),rough=.75)
 for o in bpy.data.objects:
  if o.type=='MESH' and o.name.startswith('window_') and o.name!='window_view_no_illumination':assign(o,windowpaint)
 s.view_settings.exposure=-.10 if mode=='night' else .08
 for o in bpy.data.objects:
  if o.type=='LIGHT' and o.data.type=='SUN':o.data.angle=math.radians(.8);o.data.energy*=.96
  if o.name=='window_diffuse_daylight':o.data.energy*=.80
 if s.compositing_node_group:
  for node in s.compositing_node_group.nodes:
   if node.bl_idname=='CompositorNodeGlare':node.inputs['Strength'].default_value=.18 if mode=='golden' else .06
 organize();select(mode=mode);s['review_revision']='r16';s['save_policy']='Exactly3masterblends;alloptionsincollections';s.render.filepath='//renders/base--'+mode+'.png'
 bpy.ops.wm.save_as_mainfile(filepath=str(OUT/('kitchen-'+mode+'.blend')));print('MASTER_READY',mode,flush=True)
