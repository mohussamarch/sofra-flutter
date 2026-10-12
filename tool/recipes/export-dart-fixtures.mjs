import {readFileSync,mkdirSync,writeFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import {join,dirname} from 'node:path';
import {scaleRecipe} from '../../recipes/src/scale.ts';
import {stepSchedule} from '../../recipes/src/steps.ts';
const root=join(dirname(fileURLToPath(import.meta.url)),'../..');
const index=JSON.parse(readFileSync(join(root,'recipes/data/index.json'),'utf8'));
const files=new Map(index.cuisines.map(c=>[c.file,JSON.parse(readFileSync(join(root,'recipes/data',c.file),'utf8'))]));
const fixtures=index.recipes.flatMap(entry=>{
 const recipe=files.get(entry.file).recipes.find(r=>r.id===entry.id);
 return [1,2,8,12].map(servings=>{
  const scaled=scaleRecipe(recipe,servings);
  return {id:recipe.id,servings,totalMinutes:scaled.totalTime,
   ingredients:scaled.ingredients.map(i=>[i.id,i.amount,i.display]),
   steps:stepSchedule(scaled).map(s=>[s.start,s.end])};
 });
});
mkdirSync(join(root,'test/fixtures'),{recursive:true});
writeFileSync(join(root,'test/fixtures/recipe-parity.json'),JSON.stringify(fixtures));
console.log(`Exported ${fixtures.length} TypeScript scaling/schedule reference cases.`);
