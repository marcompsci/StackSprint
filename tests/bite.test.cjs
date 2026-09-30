const vm=require('node:vm'),fs=require('node:fs'),assert=require('node:assert/strict');
const events={},nodes={};
function node(){return {hidden:true,textContent:'',setAttribute(k,v){this[k]=v;},style:{setProperty(k,v){this[k]=v;}},classList:{toggle(k,v){this[k]=v;}}};}
const pet=node();pet.querySelector=s=>nodes[s]??=node();
let focused=false,spoken=0;
const window={innerHeight:800,visualViewport:{height:800,offsetTop:0,scale:1,addEventListener(k,f){events[k]=f;}},addEventListener(){},speechSynthesis:{cancel(){},speak(){spoken++;}}};
const document={createElement:()=>pet,body:{append(){}},activeElement:{matches:()=>focused},addEventListener(){}};
vm.runInNewContext(fs.readFileSync('bite.js','utf8'),{window,document,SpeechSynthesisUtterance:function(t){this.text=t;},MutationObserver:class{observe(){}},setTimeout,clearTimeout});
focused=true;window.visualViewport.height=480;events.resize();
assert.equal(pet.style['--bite-lift'],'320px');assert.equal(pet.classList['is-confused'],true);assert.equal(nodes.p.textContent,'Oh no, what is happening');assert.equal(spoken,0);
nodes['.bite-sound'].onclick();assert.equal(spoken,1);events.resize();assert.equal(spoken,1);
window.visualViewport.height=800;events.resize();assert.equal(pet.classList['is-confused'],false);assert.equal(pet.style['--bite-lift'],'0px');
window.visualViewport.scale=2;window.visualViewport.height=400;events.resize();assert.equal(pet.classList['is-confused'],false);
nodes['.bite-body'].onclick();assert.match(nodes.p.textContent,/Read the code/);
console.log('PASS: keyboard lift, confused message, opt-in voice, no repeated speech, keyboard dismissal, zoom exclusion, and tips.');
