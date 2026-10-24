"""Sofra style exploration only. All options render identical r02 composition.
Standalone Blender script: --python build_styles.py -- BASE_BLEND OUTPUT_DIR.
"""
import bpy, sys, json
from pathlib import Path
from mathutils import Vector
args=sys.argv[sys.argv.index('--')+1:]
source,out=Path(args[0]),Path(args[1]); out.mkdir(parents=True,exist_ok=True)

def block(name,loc,size,material,parent=None,bevel=.006):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc)
    o=bpy.context.object; o.name=name; o.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    o.data.materials.append(material)
    if bevel:
        mod=o.modifiers.new('profile_soft_edges','BEVEL'); mod.width=bevel; mod.segments=2
        o.modifiers.new('profile_normals','WEIGHTED_NORMAL')
    if parent:
        world=o.matrix_world.copy(); o.parent=parent; o.matrix_world=world
    return o

reports=[]
for style in ['sleek_modern','classic','shaker']:
    bpy.ops.wm.open_mainfile(filepath=str(source)); bpy.context.view_layer.update()
    scene=bpy.context.scene
    base_material=bpy.data.materials['front']
    inset=base_material.copy(); inset.name='mat_'+style+'_panel'
    color=list(base_material.diffuse_color)
    inset.diffuse_color=(color[0]*.89,color[1]*.89,color[2]*.89,1)
    inset.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=inset.diffuse_color
    panels=[o for o in bpy.data.objects if o.type=='MESH' and o.parent and o.parent.name.startswith(('cabinet_','upper_','pantry_')) and (o.name.endswith('_front') or o.name=='pantry_door')]
    assert len(panels)==12, len(panels)
    for panel in panels:
        vs=[panel.matrix_world@Vector(v) for v in panel.bound_box]
        mn=Vector(tuple(min(v[i] for v in vs) for i in range(3)))
        mx=Vector(tuple(max(v[i] for v in vs) for i in range(3)))
        left=(mx.x-mn.x)<(mx.y-mn.y)
        width=(mx.y-mn.y) if left else (mx.x-mn.x)
        height=mx.z-mn.z
        horizontal=(mn.y+mx.y)/2 if left else (mn.x+mx.x)/2
        vertical=(mn.z+mx.z)/2
        front=mx.x+.008 if left else mn.y-.008
        parent=panel.parent
        def surface(suffix,h,z,w,ht,depth=.025,offset=0,material=base_material):
            normal=front+offset if left else front-offset
            loc=(normal,h,z) if left else (h,normal,z)
            size=(depth,w,ht) if left else (w,depth,ht)
            return block(panel.name+'_'+suffix,loc,size,material,parent=parent)
        if style=='sleek_modern':
            # Remove only cabinet pulls; preserve fridge/range handles.
            prefix=panel.name.removesuffix('_front') if panel.name!='pantry_door' else 'pantry'
            handle=bpy.data.objects.get(prefix+'_handle')
            if handle: bpy.data.objects.remove(handle,do_unlink=True)
            # Discrete integrated pull under the top edge, not decorative hardware.
            surface('finger_recess',horizontal,mx.z-.028,width-.06,.018,.008,material=bpy.data.materials['dark'])
        else:
            rail=.055 if style=='shaker' else .042
            # Recessed field and four frame pieces. Classic adds an inner bead.
            surface('recessed_field',horizontal,vertical,width-.028,height-.028,.005,material=inset)
            for side in [-1,1]:
                surface('stile_'+str(side),horizontal+side*(width/2-rail/2-.008),vertical,rail,height-.016)
                surface('rail_'+str(side),horizontal,vertical+side*(height/2-rail/2-.008),width-2*rail-.016,rail)
            if style=='classic':
                for side in [-1,1]:
                    surface('bead_v_'+str(side),horizontal+side*(width/2-rail-.014),vertical,.012,height-2*rail-.018,.018,offset=.008)
                    surface('bead_h_'+str(side),horizontal,vertical+side*(height/2-rail-.014),width-2*rail-.04,.012,.018,offset=.008)
    scene.render.resolution_x=1400; scene.render.resolution_y=1400
    scene.cycles.samples=32
    scene['style_study']=style; scene['visual_approval_pending']=True
    scene.render.filepath=str(out/(style+'.png'))
    bpy.ops.wm.save_as_mainfile(filepath=str(out/(style+'.blend')))
    bpy.ops.render.render(write_still=True)
    # Verify the saved source, not merely the in-memory generator.
    bpy.ops.wm.open_mainfile(filepath=str(out/(style+'.blend')))
    assert bpy.context.scene['style_study']==style
    camera=bpy.context.scene.camera
    reports.append({'style':style,'panel_count':len(panels),'blend_reopened':True,'png_bytes':(out/(style+'.png')).stat().st_size,'camera_position':list(camera.location),'camera_rotation':list(camera.rotation_euler),'cabinet_buffer_present':'cabinet_fridge_buffer_600' in bpy.data.objects,'corner_present':'cabinet_corner_600' in bpy.data.objects})
assert all(r['camera_position']==reports[0]['camera_position'] and r['camera_rotation']==reports[0]['camera_rotation'] for r in reports)
(out/'verification.json').write_text(json.dumps({'blender':bpy.app.version_string,'stage':'visual style proposals only','source_blend':str(source),'styles':reports,'selected_style':None,'third_style_approved':False,'runtime_implemented':False},indent=2),encoding='utf8')
print('SOFRA_THREE_STYLE_STUDY_COMPLETE')
