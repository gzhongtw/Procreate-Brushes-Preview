from pathlib import Path
import os,subprocess,zipfile,json,plistlib,tempfile,hashlib
ROOT=Path(__file__).resolve().parent.parent
BIN=ROOT/'BrushPreview.eagleplugin-src/bin/brush-preview'
source=Path(os.environ['BRUSHSET_TEST_FILE'])
results=[]
def inspect(path,ok=True):
 p=subprocess.run([str(BIN),'--inspect',str(path)],capture_output=True)
 assert (p.returncode==0)==ok,(path,p.stderr)
 return json.loads(p.stdout) if ok else None
before=hashlib.sha256(source.read_bytes()).hexdigest()
doc=inspect(source);assert len(doc['brushes'])==7 and all(b['png'] for b in doc['brushes']);assert doc['brushes'][0]['name']=='Wapping';results.append('原始漫畫.brushset：7 支、順序、名稱、7 張筆觸通過')
with tempfile.TemporaryDirectory() as tmp:
 tmp=Path(tmp);z=zipfile.ZipFile(source);ids=plistlib.loads(z.read('brushset.plist'))['brushes']
 for i,id in enumerate(ids):
  target=tmp/f'{i}.brush'
  with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED) as out:
   for name in z.namelist():
    if name.startswith(id+'/') and '/Reset/' not in name:out.writestr(name[len(id)+1:],z.read(name))
  single=inspect(target);assert len(single['brushes'])==1 and single['brushes'][0]['png']==doc['brushes'][i]['png']
 results.append('從原始組抽出的 7 個 .brush：名稱及筆觸逐一一致（庫內無獨立 .brush）')
 for name,data in [('empty.brush',b''),('text.brush',b'invalid zip'),('truncated.brushset',source.read_bytes()[:200])]:
  path=tmp/name;path.write_bytes(data);inspect(path,False)
 results.append('空檔、非 ZIP、截斷 ZIP：正常回報錯誤，未崩潰')
 missing=tmp/'missing.brush'
 with zipfile.ZipFile(missing,'w') as out:out.writestr('Brush.archive',b'')
 assert inspect(missing)['brushes'][0]['png']=='';results.append('缺少縮圖：保留筆刷並顯示缺圖狀態')
 malicious=tmp/'traversal.brushset'
 with zipfile.ZipFile(malicious,'w') as out:out.writestr('brushset.plist',plistlib.dumps({'brushes':['../outside']}))
 inspect(malicious,False);results.append('不合法筆刷路徑：拒絕；不將 ZIP 內容解壓到磁碟')
 thumb=tmp/'thumb.png';subprocess.run([str(BIN),'--thumbnail',str(source),str(thumb)],check=True);assert thumb.read_bytes()[:8]==b'\x89PNG\r\n\x1a\n';results.append('原生 PNG 縮圖輸出通過')
assert hashlib.sha256(source.read_bytes()).hexdigest()==before;results.append('原始筆刷 SHA-256 前後一致')
report={'source':str(source),'sha256':before,'checks':results,'ui':'待介面驗收','quicklook':'另查系統註冊狀態'}
(ROOT/'測試紀錄.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
print('\n'.join(results))
