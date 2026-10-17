const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = 'C:/Users/liuyu/Desktop/小红书APP/课件/redbookserver';
const target = path.resolve(__dirname, '..', 'assets');
fs.mkdirSync(path.join(target, 'images'), { recursive: true });
function readData(file, variable) {
  const source = fs.readFileSync(path.join(root, 'config', file), 'utf8')
    .replace(/const (\w+): [\w\[\]]+ =/g, 'const $1 =')
    .replace(/export default \w+;/g, '').replace(/export const/g, 'const');
  return vm.runInNewContext(source + `;JSON.stringify(${variable})`, {}, {timeout: 1000});
}
function asset(source) {
  const name = source.slice(1).replaceAll('/', '_');
  const dest = path.join(target, 'images', name);
  fs.copyFileSync(path.join(root, 'app', 'public', source), dest);
  return 'assets/images/' + name;
}
const categories = ['萌宠','美食','生活','摄影','摄影','生活','读书','读书','旅行','家居','生活','穿搭','家居','读书','萌宠'];
const notes = JSON.parse(readData('articles.ts', 'articles')).map((n,i) => ({
  id: String(n.id), title:n.title, body:n.desc, tags:n.tag,
  category:categories[i % categories.length], author:n.userName,
  authorId: String(n.userId), avatar:asset(n.avatarUrl),
  images:n.images.map(asset), likes:n.favoriteCount, saves:n.collectionCount,
  location:n.location, date:n.dateTime,
  comments:(n.comments || []).map((c,j)=>({id:`seed-${i}-${j}`,author:c.userName,avatar:asset(c.avatarUrl),text:c.message})),
}));
const products = JSON.parse(readData('goods.ts','goods')).map(g => ({...g,image:asset(g.image)}));
fs.writeFileSync(path.join(target,'notes.json'), JSON.stringify(notes,null,2));
fs.writeFileSync(path.join(target,'products.json'), JSON.stringify(products,null,2));
console.log(`Imported ${notes.length} notes and ${products.length} products.`);
