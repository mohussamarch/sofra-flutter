"""Verify the actual saved lighting files without rerendering."""
import bpy,sys,json,hashlib
from pathlib import Path
p=Path(sys.argv[sys.argv.index('--')+1]); checks=[]
for mode,expected in [('morning_golden',{'window_golden_sun','window_diffuse_daylight'}),('night_ceiling',{'ceiling_only_warm_light'})]:
    bpy.ops.wm.open_mainfile(filepath=str(p/(mode+'.blend')))
    s=bpy.context.scene
    assert {o.name for o in bpy.data.objects if o.type=='LIGHT'}==expected
    assert s['world_illumination']==0
    for name in ['enclosure_front_wall','enclosure_right_wall','enclosure_ceiling']:
        o=bpy.data.objects[name];assert not o.visible_camera and o.visible_shadow and o.visible_diffuse and o.visible_glossy
    assert any(n.type=='BACKGROUND' and n.inputs['Strength'].default_value==0 for n in s.world.node_tree.nodes)
    assert len([o for o in bpy.data.objects if o.name.startswith('tile_')])==36
    assert len([o for o in bpy.data.objects if o.name.startswith('open_shelf_')])==3
    assert 'curtain_root_optional' in bpy.data.objects
    assert len([o for o in bpy.data.objects if o.name.startswith('grate_contact_foot_')])==12
    assert ('morning_indoor_scattering' in bpy.data.objects)==(mode=='morning_golden')
    if mode=='night_ceiling':assert abs(bpy.data.objects['ceiling_only_warm_light'].data.energy-60)<1e-5
    checks.append({'mode':mode,'saved_light_sources_match':True,'enclosure_shadow_and_bounce_visible':True,'camera_only_cutaway':True,'world_illumination_zero':True,'png_sha256':hashlib.sha256((p/(mode+'.png')).read_bytes()).hexdigest(),'blend_sha256':hashlib.sha256((p/(mode+'.blend')).read_bytes()).hexdigest()})
report=json.loads((p/'verification.json').read_text());report['saved_source_checks']=checks
(p/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print('SAVED_LIGHTING_CHECKS_PASS',json.dumps(checks))
