from pathlib import Path
import json
p=Path('E:/work/SOFRA/app/design-assets/blender/current')
keep=[r for r in json.loads((p/'r17-manifest.json').read_text()) if r['variant'] not in ['table_chairs','table_on_blue_rug']]
source=(p/'render-r17.py').read_text();start=source.index('variants=');stop=source.index(';',start)
source=source[:start]+"variants=['table_chairs','table_on_blue_rug']"+source[stop:];source=source.replace('results=[]','results='+repr(keep))
exec(compile(source,str(p/'render-r17.py'),'exec'))
