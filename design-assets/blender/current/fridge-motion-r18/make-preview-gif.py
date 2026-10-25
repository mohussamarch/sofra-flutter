from pathlib import Path
from PIL import Image
BASE=Path('E:/work/SOFRA/app/design-assets/blender/current/fridge-motion-r18')
frames=[]
for phase,count in [('approach',30),('door',14)]:
 for i in range(count):
  with Image.open(BASE/f'frames/morning/{phase}_{i:03d}.webp') as source:
   backdrop=Image.new('RGBA',source.size,(238,228,209,255));backdrop.alpha_composite(source.convert('RGBA'))
   frames.append(backdrop.convert('RGB').resize((360,780),Image.Resampling.LANCZOS).quantize(colors=128))
durations=[80]*30+[100]*14;durations[0]=600;durations[-1]=1600
target=BASE/'fridge-morning-preview.gif'
frames[0].save(target,save_all=True,append_images=frames[1:],duration=durations,loop=0,optimize=False,disposal=2)
with Image.open(target) as check:assert check.n_frames>=43 and check.size==(360,780)
print('ANIMATED_PREVIEW_READY',target.stat().st_size)
