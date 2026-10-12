"""Review queue only; never auto matches a food or quantity by name."""
import pathlib,json,hashlib
root=pathlib.Path(__file__).resolve().parents[2]
recipes=[]; ids=set(); count=0; hashes={}
for path in sorted((root/'recipes/data').glob('*.json')):
 hashes[path.name]=hashlib.sha256(path.read_bytes().replace(b'\r\n',b'\n')).hexdigest()
 for r in json.loads(path.read_text(encoding='utf-8-sig')).get('recipes',[]):
  if 'ingredients' not in r: continue
  lines=[]
  for index,row in enumerate(r['ingredients']):
   ids.add(row['id']); count+=1
   lines.append({'line':index,'ingredientId':row['id'],'name':row['name'],'quantity':row['amount'],'unit':row['unit'],
    'optional':row.get('optional',False),'selection':None,'status':'awaiting-explicit-food-form-and-amount-review'})
  recipes.append({'recipeId':r['id'],'name':r['name'],'lines':lines})
out={'schemaVersion':1,'recipesCount':len(recipes),'uniqueIngredientIds':len(ids),'linesCount':count,
 'confirmedBindings':0,'recipeSourceHashes':hashes,'recipes':recipes}
(root/'data/usda/recipe-coverage.json').write_text(json.dumps(out,ensure_ascii=False,separators=(',',':'))+'\n',encoding='utf-8')
print(json.dumps({k:out[k] for k in ('recipesCount','uniqueIngredientIds','linesCount','confirmedBindings')}))
