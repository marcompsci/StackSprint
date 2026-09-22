const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const elements = new Map();
const get = key => { if (!elements.has(key)) elements.set(key, {value:'',textContent:'',disabled:false,querySelector:get,insertAdjacentHTML(){},classList:{add(){}}}); return elements.get(key); };
let click;
const host = {innerHTML:'',querySelector:get,querySelectorAll:()=>[],addEventListener:(type, fn)=>{if(type==='click')click=fn;}};
const storage = {};
const context = {document:{getElementById:()=>host},localStorage:{getItem:k=>storage[k]||null,setItem:(k,v)=>storage[k]=v}};
vm.createContext(context);
const source = fs.readFileSync(require('node:path').join(__dirname,'../python-course.js'),'utf8');
vm.runInContext(source.replace('  render();\n})();','  globalThis.testData = {cards,questions,remixed};\n  render();\n})();'),context);
function press(dataset) {click({target:{closest:()=>({dataset,disabled:false})}});}
assert.equal(context.testData.cards.length,12);
assert.equal(context.testData.questions.length,25);
press({py:'next'});
assert.match(get('.py-content').innerHTML,/Card 1 \/ 12/);
for (const card of context.testData.cards) {
  press({py:'reveal'});
  get('#py-code').value=card[3];get('#py-output').value='wrong';press({py:'check'});
  assert.match(get('[role="status"]').textContent,/Trace/);
  get('#py-output').value=card[4];press({py:'check'});
  assert.equal(get('[data-py="next"]').disabled,true);
  context.testData.remixed.add(context.testData.cards.indexOf(card));press({py:'next'});
}
assert.equal(JSON.parse(storage['stacksprint-python-v1']).learned.length,12);
press({mode:'Full quiz'});
press({py:'advance'});
assert.match(get('.py-content').innerHTML,/1 \/ 25/);
for(let i=0;i<25;i++) {press({answer:'0'});press({answer:'0'});press({py:'advance'});}
assert.match(get('.py-content').innerHTML,/Round complete/);
assert.ok(JSON.parse(storage['stacksprint-python-v1']).best['Full quiz'] < 25);
press({py:'missed'});
assert.match(get('.py-content').innerHTML,/Score 0/);
vm.runInContext(source,context);
assert.match(host.innerHTML,/12\/12 cards practiced/);
console.log('Python course: content counts, card locks, typing/output validation, quiz completion, retry, and persistence passed.');
