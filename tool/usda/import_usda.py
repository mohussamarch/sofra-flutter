"""Reproducible USDA-only reference bank. No guesses, OFF data or credentials.

python import_usda.py --foundation foundation.zip --legacy sr-legacy.zip --out ROOT
Official archives are retained outside Git; their hashes are in the manifest.
"""
import argparse
import hashlib
import json
import math
import pathlib
import zipfile

BASE = 'https://fdc.nal.usda.gov/fdc-datasets/'
SOURCES = {
    'foundation': ('FoodData_Central_foundation_food_json_2026-04-30.zip', '2026-04-30'),
    'legacy': ('FoodData_Central_sr_legacy_food_json_2018-04.zip', '2018-04'),
}

def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, separators=(',', ':')) + '\n', encoding='utf-8')

def run(args):
    out = pathlib.Path(args.out)
    shards, index, sources, seen, rejected, definitions = {}, [], [], set(), [], {}
    for dataset in ('foundation', 'legacy'):
        path = pathlib.Path(getattr(args, dataset))
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        filename, release = SOURCES[dataset]
        sources.append({'id': dataset, 'url': BASE+filename, 'release': release, 'sha256': digest, 'license': 'CC0-1.0'})
        with zipfile.ZipFile(path) as archive:
            obj = json.loads(archive.read(next(n for n in archive.namelist() if n.endswith('.json'))))
        for row in next(iter(obj.values())):
            if not isinstance(row, dict) or 'fdcId' not in row:
                rejected.append({'source': dataset, 'reason': 'null-or-invalid-record'}); continue
            fdc = row['fdcId']; rid = f'usda:{fdc}'
            if rid in seen:
                rejected.append({'id': rid, 'reason': 'duplicate'}); continue
            seen.add(rid)
            nutrients = []
            for item in row.get('foodNutrients', []):
                n, value = item.get('nutrient', {}), item.get('amount')
                if not isinstance(value, (float, int)) or not math.isfinite(value) or value < 0:
                    continue  # absence stays absence; never insert zeros
                definitions[str(n['id'])] = {'name': n['name'], 'unit': n['unitName']}
                nutrients.append([n['id'], value, item.get('foodNutrientDerivation', {}).get('code'), item.get('dataPoints')])
            shard = f'{fdc % 32:02d}.json'
            record = {'id': rid, 'fdcId': fdc, 'version': release, 'name': row['description'],
                      'dataType': row.get('dataType'), 'category': row.get('foodCategory', {}).get('description'),
                      'sourceDataset': dataset, 'publicationDate': row.get('publicationDate'),
                      'basis': {'amount': 100, 'unit': 'g', 'edibleOnly': True},
                      'nutrients': nutrients,
                      'portions': [{'amount': p.get('amount'), 'gramWeight': p.get('gramWeight'),
                                    'description': p.get('portionDescription'),
                                    'modifier': p.get('modifier'), 'measureUnit': p.get('measureUnit', {}).get('name')}
                                   for p in row.get('foodPortions', [])],
                      'allergens': {'status': 'unknown'}, 'form': 'requires-explicit-selection',
                      'market': None, 'isExactRetailProduct': False}
            shards.setdefault(shard, []).append(record)
            index.append({'id': rid, 'version': release, 'name': row['description'],
                          'category': record['category'], 'dataset': dataset, 'file': shard})
    for name, rows in sorted(shards.items()): write(out/'shards'/name, rows)
    write(out/'index.json', {'schemaVersion': 1, 'source': 'USDA FoodData Central', 'foods': index})
    write(out/'nutrient-definitions.json', {'schemaVersion':1, 'tupleFields':['fdcNutrientId','value','derivation','dataPoints'], 'nutrients':definitions})
    write(out/'manifest.json', {'schemaVersion': 1, 'retrievedOn': '2026-10-12', 'count': len(index),
                               'sources': sources, 'rejected': rejected,
                               'attribution': 'US Department of Agriculture, Agricultural Research Service. FoodData Central.',
                               'limitations': ['US reference values; no EG/SA availability or halal assertion.',
                                               'SR Legacy is historical 2018, not a current retail product bank.',
                                               'Raw/cooked form must be explicitly selected; no inferred density or count mass.',
                                               'Allergen absence is unknown; no medical or infant-feeding recommendations.'],
                               'files': {str(p.relative_to(out)).replace('\\','/'): hashlib.sha256(p.read_bytes()).hexdigest()
                                         for p in sorted(out.rglob('*.json')) if p.name != 'manifest.json'}})
    print(json.dumps({'foods': len(index), 'shards': len(shards), 'rejected': len(rejected)}))

if __name__ == '__main__':
    p=argparse.ArgumentParser(); p.add_argument('--foundation', required=True); p.add_argument('--legacy', required=True); p.add_argument('--out', required=True)
    run(p.parse_args())
