from pathlib import Path
import json
p=Path(__file__).parent;data=json.loads((p/'render-manifest.json').read_text());keep=[r for r in data if r['variant'] not in ['builtin','white_blind','no_curtain']]
code=(p/'render.py').read_text().replace("variants=['modern','white_blind','table_chairs','base','japandi','double_fridge','microwave','builtin','rug_persian','rug_teal','rug_ochre','hanging_plants','curtain_blue','no_curtain','terracotta','led']","variants=['builtin','white_blind','no_curtain','terracotta','led']").replace('results=[]','results='+repr(keep))
exec(compile(code,str(p/'render.py'),'exec'))
