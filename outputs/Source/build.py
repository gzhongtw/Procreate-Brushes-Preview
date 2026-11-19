from pathlib import Path
import subprocess,plistlib,shutil
ROOT=Path(__file__).resolve().parent.parent
SRC=ROOT/'Source/native'
CACHE=ROOT.parent/'work/swift-cache'
APP=ROOT/'Brushes Preview.app'
def run(*args): subprocess.run([str(a) for a in args],check=True)
def plist(path,obj):
 path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(plistlib.dumps(obj))
def compile(out,files,library=False):
 out.parent.mkdir(parents=True,exist_ok=True)
 parts=[]
 for arch in ['arm64','x86_64']:
  part=ROOT.parent/f'work/{out.name}-{arch}';parts.append(part)
  run('xcrun','swiftc','-module-cache-path',CACHE,'-O','-target',f'{arch}-apple-macosx12.0',*(['-parse-as-library','-application-extension','-Xlinker','-e','-Xlinker','_NSExtensionMain'] if library else []),*[SRC/f for f in files],'-o',part)
 run('lipo','-create',*parts,'-output',out)
base={'CFBundleInfoDictionaryVersion':'6.0','CFBundleDevelopmentRegion':'zh_TW','CFBundleShortVersionString':'1.0.0','CFBundleVersion':'2','LSMinimumSystemVersion':'12.0','CFBundleSupportedPlatforms':['MacOSX']}
utis=['com.procreate.brush','com.procreate.brushset']
types=[{'UTTypeIdentifier':t,'UTTypeDescription':'Procreate '+ext,'UTTypeConformsTo':['public.data','public.archive'],'UTTypeTagSpecification':{'public.filename-extension':[ext]}} for t,ext in zip(utis,['brush','brushset'])]
plist(APP/'Contents/Info.plist',base|{'CFBundleIdentifier':'tw.zon.BrushPreview','CFBundleExecutable':'BrushPreview','CFBundleName':'Brushes Preview','CFBundleDisplayName':'Brushes Preview','NSPrincipalClass':'NSApplication','CFBundlePackageType':'APPL','NSHighResolutionCapable':True,'UTImportedTypeDeclarations':types,'CFBundleDocumentTypes':[{'CFBundleTypeName':'Procreate Brushes','CFBundleTypeRole':'Viewer','LSHandlerRank':'Alternate','LSItemContentTypes':utis}]})
(APP/'Contents/Resources').mkdir(parents=True,exist_ok=True)
shutil.copy2(ROOT/'Source/ui/gallery.json',APP/'Contents/Resources/gallery.json')
icon_out=ROOT.parent/'work/icon-build'
icon_out.mkdir(parents=True,exist_ok=True)
icon_info=ROOT.parent/'work/icon-info-build.plist'
run('xcrun','actool','--compile',icon_out,'--platform','macosx','--minimum-deployment-target','12.0','--app-icon','BrushesPreview','--output-partial-info-plist',icon_info,'--target-device','mac',ROOT/'Source/assets/BrushesPreview.icon')
app_info=plistlib.loads((APP/'Contents/Info.plist').read_bytes())
app_info.update(plistlib.loads(icon_info.read_bytes()))
plist(APP/'Contents/Info.plist',app_info)
for resource in icon_out.iterdir():
 if resource.is_file():shutil.copy2(resource,APP/'Contents/Resources'/resource.name)
compile(APP/'Contents/MacOS/BrushPreview',['BrushCore.swift','GalleryTemplate.swift','main.swift'])
plist(ROOT/'Source/extension.entitlements',{'com.apple.security.app-sandbox':True,'com.apple.security.files.user-selected.read-only':True})
for name,source,point,principal in [('Preview','Preview.swift','com.apple.quicklook.preview','PreviewProvider'),('Thumbnail','Thumbnail.swift','com.apple.quicklook.thumbnail','ThumbnailProvider')]:
 ext=APP/f'Contents/PlugIns/{name}.appex'
 attrs={'QLSupportedContentTypes':utis}
 if name=='Thumbnail':attrs['QLThumbnailMinimumDimension']=0
 if name=='Preview':attrs['QLIsDataBasedPreview']=True
 plist(ext/'Contents/Info.plist',base|{'CFBundleIdentifier':'tw.zon.BrushPreview.'+name,'CFBundleExecutable':name,'CFBundleName':name,'CFBundleDisplayName':name,'CFBundlePackageType':'XPC!','NSExtension':{'NSExtensionPointIdentifier':point,'NSExtensionPrincipalClass':principal,'NSExtensionAttributes':attrs}})
 compile(ext/f'Contents/MacOS/{name}',['BrushCore.swift',*(['BrushView.swift','GalleryTemplate.swift'] if name=='Preview' else []),source],True)
 if name=='Preview':
  (ext/'Contents/Resources').mkdir(parents=True,exist_ok=True)
  shutil.copy2(ROOT/'Source/ui/gallery.json',ext/'Contents/Resources/gallery.json')
 run('xattr','-cr',ext)
 run('codesign','--force','--sign','-','--entitlements',ROOT/'Source/extension.entitlements',ext)
run('xattr','-cr',APP)
run('codesign','--force','--sign','-',APP)
plugin=ROOT/'BrushPreview.eagleplugin-src'
(plugin/'bin').mkdir(parents=True,exist_ok=True)
shutil.copy2(APP/'Contents/MacOS/BrushPreview',plugin/'bin/brush-preview')
run('codesign','--force','--sign','-',plugin/'bin/brush-preview')
print('Built',APP)
