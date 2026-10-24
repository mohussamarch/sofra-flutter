"""Closed-room lighting study: window-only golden morning / ceiling-only night.
Blender --python-exit-code1 --python render_lighting.py -- BASE_BLEND OUT
"""
import bpy, sys, math, json, hashlib
from pathlib import Path
from mathutils import Vector
args=sys.argv[sys.argv.index('--')+1:]; source,out=Path(args[0]),Path(args[1]);out.mkdir(parents=True,exist_ok=True)
reports=[]
for mode in (['morning_golden'] if '--morning-only' in args else ['morning_golden','night_ceiling']):
    bpy.ops.wm.open_mainfile(filepath=str(source));bpy.context.view_layer.update()
    scene=bpy.context.scene
    for o in list(bpy.data.objects):
        if o.type=='LIGHT':bpy.data.objects.remove(o,do_unlink=True)
    # No world irradiance. The gray background is visible only to camera rays.
    world=bpy.data.worlds.new('r08_zero_environment_'+mode);world.use_nodes=True;scene.world=world
    nodes=world.node_tree.nodes;nodes.clear()
    path=nodes.new('ShaderNodeLightPath');mix=nodes.new('ShaderNodeMixShader')
    black=nodes.new('ShaderNodeBackground');black.inputs['Color'].default_value=(0,0,0,1);black.inputs['Strength'].default_value=0
    backdrop=nodes.new('ShaderNodeBackground');backdrop.inputs['Color'].default_value=(.075,.085,.10,1);backdrop.inputs['Strength'].default_value=1
    output=nodes.new('ShaderNodeOutputWorld')
    links=world.node_tree.links;links.new(path.outputs['Is Camera Ray'],mix.inputs[0]);links.new(black.outputs[0],mix.inputs[1]);links.new(backdrop.outputs[0],mix.inputs[2]);links.new(mix.outputs[0],output.inputs[0])
    col=bpy.data.collections.new('ClosedRoomLightingEnvelope');scene.collection.children.link(col)
    def box(name,loc,size,material):
        bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=size
        bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
        for c in list(o.users_collection):c.objects.unlink(o)
        col.objects.link(o);o.data.materials.append(material);return o
    # Camera cutaway only. These remain opaque to shadow/diffuse/glossy rays.
    wallmat=bpy.data.materials['wall']
    envelope=[box('enclosure_front_wall',(1.8,-.06,1.35),(3.84,.12,2.7),wallmat),box('enclosure_right_wall',(3.66,1.8,1.35),(.12,3.84,2.7),wallmat),box('enclosure_ceiling',(1.8,1.8,2.76),(3.84,3.84,.12),wallmat)]
    for o in envelope:
        o.visible_camera=False
        assert o.visible_shadow and o.visible_diffuse and o.visible_glossy
    # A camera-only sky card makes the window legible, without lighting the room.
    cardmat=bpy.data.materials.new('window_view_camera_only_'+mode);cardmat.use_nodes=True
    n=cardmat.node_tree.nodes;n.clear();p=n.new('ShaderNodeLightPath');m=n.new('ShaderNodeMixShader');t=n.new('ShaderNodeBsdfTransparent');e=n.new('ShaderNodeEmission');end=n.new('ShaderNodeOutputMaterial')
    e.inputs['Color'].default_value=(.60,.70,.78,1) if mode=='morning_golden' else (.010,.018,.035,1)
    e.inputs['Strength'].default_value=.8 if mode=='morning_golden' else .3
    l=cardmat.node_tree.links;l.new(p.outputs['Is Camera Ray'],m.inputs[0]);l.new(t.outputs[0],m.inputs[1]);l.new(e.outputs[0],m.inputs[2]);l.new(m.outputs[0],end.inputs[0])
    card=box('window_view_no_illumination',(-.38,2.1,1.75),(.01,1.7,1.5),cardmat);card.visible_shadow=False;card.visible_diffuse=False;card.visible_glossy=False
    # Discrete ceiling disk, camera-hidden with ceiling; no extra studio source.
    bpy.ops.mesh.primitive_cylinder_add(vertices=48,radius=.24,depth=.035,location=(1.8,1.8,2.665))
    fixture=bpy.context.object;fixture.name='ceiling_fixture_disk';fixture.data.materials.append(bpy.data.materials['fridge']);fixture.visible_camera=False
    if mode=='morning_golden':
        # Direct sunlight entering the real window toward the fridge door.
        direction=Vector((1,.235,-.36)).normalized()
        bpy.ops.object.light_add(type='SUN',location=(-4,1.1,3.1));sun=bpy.context.object;sun.name='window_golden_sun'
        sun.data.energy=4.5;sun.data.color=(1,.55,.24);sun.data.angle=math.radians(.7)
        sun.rotation_euler=direction.to_track_quat('-Z','Y').to_euler()
        # Soft skylight is outside the same opening, not inside the cutaway.
        bpy.ops.object.light_add(type='AREA',location=(-.16,2.1,1.75));sky=bpy.context.object;sky.name='window_diffuse_daylight'
        sky.data.energy=40;sky.data.color=(.82,.86,1);sky.data.shape='RECTANGLE';sky.data.size=1.35;sky.data.size_y=1.15
        sky.rotation_euler=Vector((1,0,0)).to_track_quat('-Z','Y').to_euler()
        bpy.context.view_layer.update()
        # Verify an actual unobstructed sun path from aperture to refrigerator.
        # Sample a clear pane, not the central wooden window mullion.
        result=scene.ray_cast(bpy.context.evaluated_depsgraph_get(),Vector((-.13,2.0,1.95)),direction)
        assert result[0] and result[4].name.startswith('fridge_door'), (result[0],result[4].name if result[4] else None)
        reached=result[4].name;hit=list(result[1])
        floor_result=scene.ray_cast(bpy.context.evaluated_depsgraph_get(),Vector((-.13,1.5,1.2)),direction)
        assert floor_result[0] and floor_result[4].name.startswith('tile_'), floor_result[4].name if floor_result[4] else None
        floor_hit=list(floor_result[1])
    else:
        bpy.ops.object.light_add(type='AREA',location=(1.8,1.8,2.635));lamp=bpy.context.object;lamp.name='ceiling_only_warm_light'
        lamp.data.energy=180;lamp.data.color=(1,.90,.76);lamp.data.shape='DISK';lamp.data.size=.42
        lamp.rotation_euler=(0,0,0) # Area emits local -Z, directly down.
        reached=None;hit=None;floor_hit=None
    lights=[o for o in bpy.data.objects if o.type=='LIGHT']
    assert len(lights)==(2 if mode=='morning_golden' else 1)
    assert all('window_' in o.name for o in lights) if mode=='morning_golden' else lights[0].name=='ceiling_only_warm_light'
    scene.cycles.samples=96;scene.cycles.use_denoising=True;scene.cycles.max_bounces=10;scene.cycles.diffuse_bounces=6;scene.cycles.transparent_max_bounces=8
    scene.render.resolution_x=1400;scene.render.resolution_y=1400;scene.render.resolution_percentage=100
    scene.view_settings.exposure=0;scene.view_settings.view_transform='AgX'
    scene['lighting_study']=mode;scene['closed_room']=True;scene['world_illumination']=0
    scene.render.filepath=str(out/(mode+'.png'))
    bpy.ops.wm.save_as_mainfile(filepath=str(out/(mode+'.blend')))
    bpy.ops.render.render(write_still=True)
    bpy.ops.wm.open_mainfile(filepath=str(out/(mode+'.blend')))
    assert bpy.context.scene['closed_room'] and len([o for o in bpy.data.objects if o.type=='LIGHT'])==len(lights)
    reports.append({'mode':mode,'blend_reopened':True,'lights':[{'name':o.name,'type':o.data.type,'energy':o.data.energy} for o in bpy.data.objects if o.type=='LIGHT'],'closed_envelope_objects':['enclosure_front_wall','enclosure_right_wall','enclosure_ceiling'],'envelope_camera_only_cutaway':True,'noncamera_world_illumination':0,'camera_position':list(bpy.context.scene.camera.location),'camera_rotation':list(bpy.context.scene.camera.rotation_euler),'exposure':0,'sun_ray_hit':reached,'sun_ray_hit_position':hit,'sun_floor_hit_position':floor_hit,'png_bytes':(out/(mode+'.png')).stat().st_size})
if '--morning-only' in args:
    prior=json.loads((out/'verification.json').read_text(encoding='utf8'))
    reports += [r for r in prior['reports'] if r['mode']=='night_ceiling']
assert len(reports)==2
assert reports[0]['camera_position']==reports[1]['camera_position'] and reports[0]['camera_rotation']==reports[1]['camera_rotation']
report={'blender':bpy.app.version_string,'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'footprint_m':[3.6,3.6],'module_count':[6,6],'samples':96,'reports':reports,'art_directed_lighting':True,'sun_time_or_geolocation_claim':False,'no_extra_LED_hood_studio_lights':True,'runtime_lighting_implemented':False,'visual_approval_pending':True}
(out/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf8');print('SOFRA_LIGHTING_COMPLETE',json.dumps(report))
