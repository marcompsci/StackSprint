const {readFileSync}=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
async function test(url,withShare){
  const elements=new Map();let click,shared;
  const get=k=>{if(!elements.has(k))elements.set(k,{value:'Practice Python',textContent:'',hidden:true,replaceChildren(){},append(){},focus(){},select(){}});return elements.get(k);};
  const host={querySelector:get,addEventListener:(type,fn)=>click=fn};
  const context={URL,Date,localStorage:{getItem:()=>'{"activity":{}}'},location:{href:url},navigator:withShare?{share:async value=>shared=value}:{},document:{getElementById:id=>id==='friends'?host:null,createElement:()=>({setAttribute(){}})},window:{addEventListener(){}}};
  vm.runInNewContext(readFileSync(require('node:path').join(__dirname,'../social.js'),'utf8'),context);
  const press=action=>click({target:{closest:()=>({dataset:{social:action}})}});
  await press('streak');assert.equal(get('#friendStreak').textContent,0);assert.match(get('#socialMessage').value,/starting my coding journey/);
  if(url.startsWith('file:')||url.includes('localhost'))assert.ok(!get('#socialMessage').value.includes('Join me:'));
  else assert.match(get('#socialMessage').value,/Join me: https/);
  await press('invite');assert.match(get('#socialMessage').value,/Coding buddy quest/);
  if(withShare)assert.match(shared.text,/Coding buddy quest/);else assert.equal(get('#socialFallback').hidden,false);
  await press('copy');assert.match(get('#socialStatus').textContent,/Copy command/);
}
(async()=>{await test('file:///app/index.html',false);await test('http://localhost:4176/',false);await test('https://example.com/stacksprint/?private=secret#friends',true);console.log('Social sharing: zero-streak honesty, local URL exclusion, public sharing, invites and clipboard fallback passed.');})();
