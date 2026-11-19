"""Package a built app with ditto; verify extracted executable modes and signature."""
from pathlib import Path
import plistlib,subprocess,tempfile,zipfile,hashlib
out=Path(__file__).resolve().parent.parent
app=out/'Brushes Preview.app'
info=plistlib.loads((app/'Contents/Info.plist').read_bytes())
version=info['CFBundleShortVersionString']
executables=['Contents/MacOS/BrushPreview','Contents/PlugIns/Preview.appex/Contents/MacOS/Preview','Contents/PlugIns/Thumbnail.appex/Contents/MacOS/Thumbnail']
for name in executables:
 if not (app/name).stat().st_mode & 0o111:raise RuntimeError('Missing executable permission: '+name)
subprocess.run(['codesign','--verify','--deep','--strict',str(app)],check=True)
dest=out/f'Brushes Preview-macOS-{version}.zip'
subprocess.run(['ditto','-c','-k','--keepParent','--norsrc',str(app),str(dest)],check=True)
with zipfile.ZipFile(dest) as archive:
 for name in executables:
  if not (archive.getinfo(app.name+'/'+name).external_attr>>16)&0o111:raise RuntimeError('ZIP lost executable permission: '+name)
with tempfile.TemporaryDirectory(prefix='brushes-preview-package-')as folder:
 subprocess.run(['ditto','-x','-k',str(dest),folder],check=True)
 extracted=Path(folder)/app.name
 for name in executables:
  if not (extracted/name).stat().st_mode&0o111:raise RuntimeError('Extraction lost executable permission: '+name)
 subprocess.run(['codesign','--verify','--deep','--strict',str(extracted)],check=True)
print(dest)
print('SHA256',hashlib.sha256(dest.read_bytes()).hexdigest())
