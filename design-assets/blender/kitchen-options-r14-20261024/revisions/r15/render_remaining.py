# Preserve the completed first batch; only render unchanged options against r15.
from pathlib import Path
p=Path(__file__).parent
code=(p/'render_variants.py').read_text().replace("['base','modern','japandi','double_fridge','microwave','builtin','table_chairs','rug_persian','rug_teal','rug_ochre']","['rug_persian','rug_teal','rug_ochre','hanging_plants','curtain_blue','white_blind','no_curtain']").replace("r=[]","r=[r for r in json.loads((out/'variant-manifest.json').read_text()) if not r['variant'].startswith('rug_')]")
exec(compile(code,str(p/'render_variants.py'),'exec'))
