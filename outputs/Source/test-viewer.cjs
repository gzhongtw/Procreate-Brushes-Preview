const {JSDOM}=require('jsdom'),fs=require('fs'),path=require('path'),assert=require('assert/strict');const {createRequire}=require('module');
const root=path.resolve(__dirname,'..'),html=path.join(root,'BrushPreview.eagleplugin-src/viewer/index.html');
async function check(file,count){
 const dom=new JSDOM(fs.readFileSync(html,'utf8'),{url:'file://'+html+'?path='+encodeURIComponent(file),runScripts:'dangerously',beforeParse(w){w.require=createRequire(html)}});
 const d=dom.window.document,deadline=Date.now()+35000;
 while(!d.querySelector('.gallery')&&d.querySelector('#status')?.textContent==='正在讀取筆刷…'&&Date.now()<deadline)await new Promise(r=>setTimeout(r,20));
 if(count){assert.equal(d.querySelectorAll('.brush-card').length,count);assert.equal(d.images.length,count);for(const i of d.images)assert.ok(i.alt);const button=d.querySelector('[data-brush-zoom]');button.click();assert.equal(button.getAttribute('aria-pressed'),'true');assert.ok(button.closest('.brush-card').classList.contains('is-expanded'));button.click();assert.equal(button.getAttribute('aria-pressed'),'false');assert.ok(d.title.includes('筆刷預覽'));}
 else assert.match(d.querySelector('#status').textContent,/無法預覽/);
 dom.window.close();
}
(async()=>{await check(process.env.BRUSHSET_TEST_FILE,7);await check(process.env.BRUSH_TEST_FILE,1);await check('/nonexistent.brush',0);console.log('Astryx viewer: brushset, single brush, expansion state, names, error PASS')})().catch(e=>{console.error(e);process.exitCode=1});
