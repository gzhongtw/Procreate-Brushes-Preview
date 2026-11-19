const assets = require('./gallery.json');
const escape = value => String(value).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;').replaceAll("'",'&#39;');
function replace(template,values){return template.replace(/__(SET_NAME|COUNT|HINT|BRUSH_NAME|INDEX|IMAGE_SRC|BRUSH_CARDS)__/g,(m,key)=>values[key] ?? m);}
exports.render = (doc,interactive=true) => {
 const cards=doc.brushes.map((brush,index)=> {
   let template=interactive?assets.card:assets.staticCard;
   template=template.replace(/<link[^>]*rel="preload"[^>]*\/>/g,'');
   if(!brush.png) template=template.replace(/<img[^>]*\/>/g,'<p>此筆刷沒有內建筆觸預覽</p>');
   return replace(template,{BRUSH_NAME:escape(brush.name),INDEX:String(index+1).padStart(2,'0'),IMAGE_SRC:brush.png?'data:image/png;base64,'+brush.png:''});
 }).join('');
 return replace(assets.frame,{SET_NAME:escape(doc.name),COUNT:doc.brushes.length,HINT:'筆觸總覽',BRUSH_CARDS:cards});
};
exports.css=assets.css;
