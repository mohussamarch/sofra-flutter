import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {readFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
const root=fileURLToPath(new URL('../../',import.meta.url));
const sha=v=>createHash('sha256').update(v).digest('hex');

// Read-only build gate: changed sources require human re-review, not restamping.
export async function validateReview(review) {
  assert.equal(review.schemaVersion,1);
  const read=p=>readFile(path.join(root,p),'utf8');
  const indexText=await read('data/usda/index.json');
  assert.equal(sha(indexText.replaceAll('\r\n','\n')),review.sourceIndexSha256,'USDA index hash changed');
  const index=new Map(JSON.parse(indexText).foods.map(f=>[f.id,f]));
  const files=new Map(), shards=new Map(), keys=new Set(), recipes=new Set(), foodIds=new Set();
  const catalogue=JSON.parse(await read('recipes/data/index.json'));
  const allowedFiles=new Set(catalogue.cuisines.map(c=>'recipes/data/'+c.file));
  for(const entry of review.entries) {
    const key=JSON.stringify([entry.recipeId,entry.line]);
    assert.ok(!keys.has(key),'Duplicate review line'); keys.add(key); recipes.add(entry.recipeId);
    assert.ok(allowedFiles.has(entry.recipeSourceFile),'Unknown recipe source path');
    if(!files.has(entry.recipeSourceFile)) {
      const text=(await read(entry.recipeSourceFile)).replaceAll('\r\n','\n');
      files.set(entry.recipeSourceFile,{sha:sha(text),recipes:JSON.parse(text).recipes});
    }
    const source=files.get(entry.recipeSourceFile);
    assert.equal(entry.recipeSourceSha256,source.sha,'Recipe source hash changed; re-review required');
    const recipe=source.recipes.find(r=>r.id===entry.recipeId);
    assert.ok(recipe,'Unknown recipe ID'); assert.ok(Number.isInteger(entry.line)&&entry.line>=0);
    const row=recipe.ingredients[entry.line]; assert.ok(row,'Unknown recipe line');
    assert.equal(row.id,entry.ingredientId,'Recipe ingredient ID');
    assert.equal(row.name,entry.expectedName,'Recipe ingredient name');
    assert.equal(row.amount??null,entry.originalQuantity,'Recipe quantity');
    assert.equal(row.unit??null,entry.originalUnit,'Recipe unit');
    assert.equal(row.optional===true,entry.optional,'Recipe optional choice');
    assert.equal(typeof entry.blocked,'boolean');
    assert.equal(typeof entry.requiresUserChoice,'boolean');
    const compound=entry.issues.some(v=>v.startsWith('identity: Compound salt-and-black-pepper'));
    if(compound) assert.ok(entry.blocked&&entry.requiresUserChoice,'Compound line must remain blocked');
    assert.ok(entry.requiresUserChoice||entry.candidates.length===1,'Ambiguous reference requires choice');
    const candidateIds=new Set();
    for(const candidate of entry.candidates) {
      assert.ok(!candidateIds.has(candidate.foodId),'Duplicate food candidate'); candidateIds.add(candidate.foodId);
      const sourceEntry=index.get(candidate.foodId); assert.ok(sourceEntry,'Unknown food reference');
      assert.match(sourceEntry.file,/^[0-9]{2}\.json$/);
      assert.equal(candidate.sourceFile,'data/usda/shards/'+sourceEntry.file);
      if(!shards.has(sourceEntry.file)) shards.set(sourceEntry.file,JSON.parse(await read(candidate.sourceFile)));
      const food=shards.get(sourceEntry.file).find(f=>f.id===candidate.foodId); assert.ok(food);
      assert.equal(food.name,candidate.sourceDescription,'Food source identity description');
      assert.equal(food.version,candidate.sourceVersion,'Food source identity version');
      assert.equal(candidate.sourceUrl,`https://fdc.nal.usda.gov/food-details/${food.fdcId}/nutrients`);
      assert.deepEqual(food.basis,{amount:100,unit:'g',edibleOnly:true});
      assert.ok(['raw','cooked','asSold','prepared'].includes(candidate.form));
      for(const invented of ['nutrients','retention','gramsPerCount','gramsPerMl','price']) assert.ok(!(invented in candidate));
      foodIds.add(food.id);
    }
  }
  return {entries:keys.size,recipes:recipes.size,foodReferences:foodIds.size};
}
if(process.argv[1] && path.resolve(process.argv[1])===fileURLToPath(import.meta.url)) {
  const review=JSON.parse(await readFile(path.join(root,'data/nutrition/recipe-reference-review.json'),'utf8'));
  console.log(JSON.stringify(await validateReview(review)));
}
