const fs = require('fs');
const bridge = require('./lib/bridge');
module.exports = async ({src,dest,item}) => {
  await bridge.thumbnail(src,dest);
  const png = fs.readFileSync(dest);
  if (png.length < 24 || png.toString('hex',0,8) !== '89504e470d0a1a0a') throw new Error('筆刷縮圖產生失敗');
  item.width = png.readUInt32BE(16); item.height = png.readUInt32BE(20);
  item.noPreview = false;
  return item;
};
