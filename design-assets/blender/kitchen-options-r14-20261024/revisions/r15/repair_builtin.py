from pathlib import Path
p=Path(__file__).parent
code=(p/'render_variants.py').read_text().replace("['base','modern','japandi','double_fridge','microwave','builtin','table_chairs','rug_persian','rug_teal','rug_ochre']","['builtin']").replace("r=[]","r=[r for r in json.loads((out/'variant-manifest.json').read_text()) if r['variant']!='builtin']")
exec(compile(code,str(p/'render_variants.py'),'exec'))
