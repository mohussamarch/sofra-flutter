"""Use Blender geometry alpha, rather than selecting gray pixels by color."""
import ctypes,subprocess,json,hashlib
from ctypes import wintypes
from pathlib import Path
import numpy as np
from PIL import Image,ImageFilter
B=Path('E:/work/SOFRA/app/design-assets/blender/current/fridge-motion-r18')
def ensure_alpha():
 target=B/'alpha-manifest.json'
 if target.exists():
  existing=json.loads(target.read_text())
  if existing['rawManifestSha256']==hashlib.sha256((B/'raw-manifest.json').read_bytes()).hexdigest():return existing
 # Serialize native Blender jobs.2468 is the verified RGB renderer for this run.
 kernel=ctypes.WinDLL('kernel32',use_last_error=True);kernel.OpenProcess.restype=wintypes.HANDLE
 kernel.OpenProcess.argtypes=[wintypes.DWORD,wintypes.BOOL,wintypes.DWORD]
 kernel.WaitForSingleObject.argtypes=[wintypes.HANDLE,wintypes.DWORD];kernel.CloseHandle.argtypes=[wintypes.HANDLE]
 handle=kernel.OpenProcess(0x100000,False,2468)
 if handle:
  try:assert kernel.WaitForSingleObject(handle,60000)==0,'RGB renderer has not exited;do not run a second native job'
  finally:kernel.CloseHandle(handle)
 log=Path('C:/Users/atgs0/Documents/Codex/work/sofra-fridge-motion-r18/alpha.log')
 with log.open('w') as stream:subprocess.run(['C:/Program Files/Blender Foundation/Blender 5.2/blender.exe','--background','--python-exit-code','1','--python',str(B/'render-alpha.py')],stdout=stream,stderr=subprocess.STDOUT,check=True)
 return json.loads(target.read_text())

def apply_native_alpha(rgb,matte,backdrop):
 alpha=np.asarray(matte.getchannel('A'),dtype=np.float32)/255
 color=np.asarray(rgb.convert('RGB'),dtype=np.float32)
 # The render backdrop contains grain, so do not assume one flat corner color.
 # Estimate local backdrop ONLY from pixels proved exterior by native geometry.
 outside=alpha==0
 if outside.any():
  weight=np.asarray(Image.fromarray(outside.astype(np.uint8)*255).filter(ImageFilter.BoxBlur(3)),dtype=np.float32)/255
  weighted=np.asarray(Image.fromarray((color*outside[...,None]).astype(np.uint8)).filter(ImageFilter.BoxBlur(3)),dtype=np.float32)
  local=weighted/np.maximum(weight[...,None],1/255)
  median=np.median(color[outside],axis=0)
  backdrop=np.where(weight[...,None]>0,local,median)
 else:backdrop=np.zeros(3,dtype=np.float32)
 straight=np.clip((color-backdrop*(1-alpha[...,None]))/np.maximum(alpha[...,None],1/255),0,255).astype(np.uint8)
 rgba=np.concatenate([straight,np.rint(alpha[...,None]*255).astype(np.uint8)],axis=2)
 rgba[alpha==0,:3]=0
 return Image.fromarray(rgba,'RGBA')

def backdrop_for(mode):
 return None # Background is sampled per frame from native-alpha-zero neighbors.
