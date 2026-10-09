/* Learner JavaScript runs in disposable workers inside an opaque-origin frame. */
(() => {
  function workerMain() {
    let api;
    onmessage = (event) => {
      const {id,code,tests,action,state,command}=event.data;
      try {
        if(code !== undefined) api = new Function(code+'\nreturn {createState,update,isComplete};')();
        if(command==='test') {
          const results=tests.map(test=>{try {return {name:test.name,passed:new Function('createState','update','isComplete',test.body)(api.createState,api.update,api.isComplete)===true};} catch(error){return {name:test.name,passed:false,error:error.message};}});
          postMessage({id,results});
        } else {
          const next=command==='start' ? api.createState() : api.update(state,action);
          if(!next || typeof next !== 'object') throw Error('Return a state object from createState() and update().');
          postMessage({id,state:next,complete:api.isComplete(next)===true});
        }
      } catch(error) { postMessage({id,error:error.name+': '+error.message}); }
    };
  }

  const css=`*{box-sizing:border-box}body{margin:0;font:15px system-ui,sans-serif;background:#101a30;color:#e9efff}.arena{padding:20px;min-height:390px;background:#101a30;color:#e9efff;border-radius:12px}h1{font-size:23px;margin:0 0 8px;letter-spacing:0}.instructions{display:block;font-size:15px;line-height:23px;max-width:560px;color:inherit;opacity:.85;margin:8px 0}.hud{display:flex;align-items:center;justify-content:space-between;gap:14px;padding:9px;margin-bottom:12px}.score{font-size:19px;font-weight:600}.board{display:grid;gap:5px;padding:10px;background:#ffffff0a;border-radius:14px;min-height:135px;margin:12px 0}.tile{min-height:42px;border:1px solid #ffffff30;border-radius:6px;font-size:20px;background:#ffffff0e;display:grid;place-items:center;color:inherit;aspect-ratio:1}.target{background:#36a48a;font-size:25px;border:1px solid #aaffdf;border-radius:12px;min-height:50px;transition:none}.controls{display:flex;flex-wrap:wrap;gap:9px;justify-content:center;margin-top:14px}button{min-height:42px;min-width:42px;padding:9px 14px;border:1px solid #ffffff40;border-radius:9px;background:#264875;color:inherit;font:600 15px system-ui;cursor:pointer;outline:0 solid #fcd34d;outline-offset:2px}button:focus-visible{outline:3px solid #fcd34d;outline-offset:3px}button:disabled{opacity:.5;cursor:default}input{font:inherit;min-height:44px;max-width:100%;width:190px;border-radius:8px;padding:10px;background:white;color:#172554;border:1px solid #a0b4d4}.message{min-height:42px;font-size:15px;padding:10px;border:0 solid #62dfbe;border-radius:8px;background:#ffffff09;overflow-wrap:anywhere}.won{color:#a7f3d0;font-size:20px;font-weight:700}.wall{background:#68758c}.player{background:#217ab1}.food{background:#265e49}.dim{opacity:.5}.swatch0{background:#3b82f6}.swatch1{background:#ec775d}.swatch2{background:#29ab91}.swatch3{background:#9673df}.board button{padding:3px;min-width:0;width:100%}.canvas{touch-action:none;min-height:200px;position:relative;background:#edf5ff;color:#183252}.canvas i{position:absolute;width:13px;height:13px;background:#7160db;border-radius:50%;transform:translate(-50%,-50%)}@media(max-width:420px){.arena{padding:12px}.tile{min-height:30px}.hud{padding:4px}button{padding:8px}.instructions{font-size:14px}}@media(prefers-reduced-motion:reduce){*{transition:none!important;animation:none!important}}`;

  function frameMain(config,workerSource) {
    const arena=document.querySelector('.arena'), stage=document.getElementById('stage'),status=document.getElementById('status');
    let worker,blobURL,state,finished=false,serial=0,busy=false,timer,beatTimer;
    const pending=new Map();
    const node=(tag,text,cls)=>{const e=document.createElement(tag);if(text!==undefined)e.textContent=text;if(cls)e.className=cls;return e;};
    const inform=(data)=>parent.postMessage({channel:'stacksprint-runtime',token:config.token,...data},'*');
    function stop() {clearTimeout(timer);clearTimeout(beatTimer);if(worker)worker.terminate();if(blobURL)URL.revokeObjectURL(blobURL);}
    function fail(message) {stop();status.textContent=message;status.className='message';inform({error:message});}
    function send(command,extra={}) {
      return new Promise((resolve,reject)=>{
        const id=++serial;
        pending.set(id,{resolve,reject});
        clearTimeout(timer);timer=setTimeout(()=>{pending.delete(id);fail('Your code took too long. Check for an endless loop, then run it again.');reject(Error('Execution timed out'));},2000);
        worker.postMessage({id,command,...extra});
      });
    }
    function startWorker(){
      blobURL=URL.createObjectURL(new Blob(['('+workerSource+')()'],{type:'text/javascript'}));worker=new Worker(blobURL);
      worker.onmessage=e=>{const r=e.data,p=pending.get(r.id);if(!p)return;clearTimeout(timer);pending.delete(r.id);r.error?p.reject(Error(r.error)):p.resolve(r);};
      worker.onerror=e=>fail(e.message||'Could not run this code.');
    }
    function btn(label,action,cls='') {
      const b=node('button',label,cls);b.type='button';b.disabled=!!config.readOnly;b.dataset.action=JSON.stringify(action);b.onclick=()=>act(action);return b;
    }
    function controls(actions){const box=node('div',undefined,'controls');actions.forEach(([text,action])=>box.append(btn(text,action)));stage.append(box);return box;}
    function grid(size,paint){const b=node('div',undefined,'board');b.style.gridTemplateColumns=`repeat(${size},minmax(0,1fr))`;for(let i=0;i<size*size;i++)b.append(paint(i));stage.append(b);return b;}
    function submit(label,type,placeholder,maxLength){const form=node('form',undefined,'controls');const input=node('input');input.placeholder=placeholder;input.setAttribute('aria-label',placeholder);if(maxLength)input.maxLength=maxLength;const b=node('button',label);b.type='submit';b.disabled=!!config.readOnly;form.append(input,b);form.onsubmit=e=>{e.preventDefault();act({type,value:input.value});};stage.append(form);}
    function cell(text,cls){return node('div',text,'tile '+(cls||''));}
    const moves=[['←',{type:'move',dx:-1,dy:0}],['↑',{type:'move',dx:0,dy:-1}],['↓',{type:'move',dx:0,dy:1}],['→',{type:'move',dx:1,dy:0}]];
    function render() {
      const focus=document.activeElement?.dataset?.action;
      stage.replaceChildren();document.getElementById('score').textContent=`${state.score ?? 0} / ${state.target ?? '—'}`;
      status.textContent=finished?'You built it. You played it. Nicely done!':state.message||'Try your game. Every move runs your code.';status.className=finished?'message won':'message';
      if(finished){stage.append(node('p','✦ Game complete','won'));inform({won:true});return;}
      const m=config.mode;
      if(['tap','coins','accessible','save','showcase','reaction','rhythm'].includes(m)) {
        const board=node('div',undefined,'board');board.style.display=m==='tap'?'grid':'flex';board.style.justifyContent='center';
        if(m==='tap'){board.style.gridTemplateColumns='repeat(7,minmax(0,1fr))';board.style.gridTemplateRows='repeat(5,48px)';}
        const label=m==='reaction'||m==='rhythm'?(state.ready?'🟢 TAP!':'🟡 Wait…'):m==='coins'?'🪙 Collect coin':state.label||'⭐ Collect a star';
        const target=btn(label,{type:'tap'},'target');
        if(m==='tap'){target.textContent='⭐';target.setAttribute('aria-label','Collect a star');target.style.gridColumn=String((state.x||0)+1);target.style.gridRow=String((state.y||0)+1);target.style.padding='0';target.style.minWidth='0';target.style.width='100%';}
        board.append(target);stage.append(board);
        if(m==='coins')stage.append(node('p','Energy: '+state.energy));
        if(m==='save')controls([['Save checkpoint',{type:'save'}],['Restore checkpoint',{type:'restore'}]]);
        if(m==='showcase')controls([['🌱 Plant flower',{type:'plant'}]]);
      } else if(m==='guess')submit('Guess','guess','Number from 1 to 10');
      else if(m==='memory'){const b=node('div',undefined,'board');b.style.gridTemplateColumns='repeat(4,1fr)';state.cards.forEach((c,i)=>b.append(btn(state.open.includes(i)||state.matched.includes(i)?c:'?',{type:'flip',index:i},'tile')));stage.append(b);}
      else if(m==='rps')controls(['pebble','leaf','cloud'].map((value,i)=>[['🪨 Pebble','🌿 Leaf','☁ Cloud'][i],{type:'choose',value}]));
      else if(m==='gopher')grid(3,i=>btn(i===state.hole?'🐹':'·',{type:'hit',index:i},'tile'));
      else if(m==='quiz'){const q=[['Which language structures a page?',['CSS','HTML','SQL']],['Which language styles a page?',['CSS','SQL','HTML']],['Which language handles browser events?',['SQL','HTML','JavaScript']]][state.index];stage.append(node('h2',q[0]));controls(q[1].map((v,index)=>[v,{type:'answer',index}]));}
      else if(m==='story')controls([['Help the keeper →',{type:'choose',value:'help'}],['Pause and look around',{type:'choose',value:'wait'}]]);
      else if(m==='dice'){stage.append(cell(state.lastRoll?'🎲 '+state.lastRoll:'🎲'));controls([['Roll the die',{type:'roll'}]]);}
      else if(m==='typing'){stage.append(node('h2',state.words[state.index],'target'));submit('Clear word','type','Type the word');}
      else if(m==='garden'){stage.append(node('p',`Seeds: ${state.seeds} · Flowers: ${'🌻'.repeat(Math.min(state.flowers,20))}`));controls([['🌱 Plant',{type:'plant'}],['💧 Water',{type:'water'}]]);}
      else if(m==='sequence'){stage.append(node('p','Remember: Blue → Mint → Coral → Violet'));const c=controls(['Blue','Coral','Mint','Violet'].map((v,index)=>[v,{type:'tone',index}]));[...c.children].forEach((e,i)=>e.classList.add('swatch'+i));}
      else if(m==='color'){stage.append(node('h2','Catch '+state.colors[state.color]));controls(state.colors.map((v,index)=>[v,{type:'catch',index}]));}
      else if(m==='draw'){const canvas=node('div',undefined,'board canvas');canvas.tabIndex=0;canvas.setAttribute('aria-label','Drawing canvas. Click to draw or use the Add dot button.');state.points.forEach(p=>{const dot=node('i');dot.style.left=p.x+'%';dot.style.top=p.y+'%';canvas.append(dot);});canvas.onclick=e=>{const r=canvas.getBoundingClientRect();act({type:'draw',x:Math.round((e.clientX-r.left)/r.width*100),y:Math.round((e.clientY-r.top)/r.height*100)});};stage.append(canvas);controls([['Add dot',{type:'draw',x:(state.points.length*13+10)%90,y:(state.points.length*17+10)%90}],['Clear drawing',{type:'clear'}]]);}
      else if(m==='maze'){grid(5,i=>cell(i===state.y*5+state.x?'🧑‍🚀':i===state.goal?'🏁':state.walls.includes(i)?'▧':'·',state.walls.includes(i)?'wall':''));controls(moves);}
      else if(m==='snake'){grid(7,i=>cell(state.body.some(p=>p.y*7+p.x===i)?'🟩':state.food.y*7+state.food.x===i?'🍎':'·'));controls(moves);}
      else if(m==='pong'){grid(7,i=>cell(i===state.y*7+state.x?'⚪':Math.floor(i/7)===6&&Math.abs(i%7-state.paddle)<=1?'▬':'·'));controls([['← Paddle',{type:'paddle',dx:-1}],['Advance ball',{type:'tick'}],['Paddle →',{type:'paddle',dx:1}]]);}
      else if(m==='breakout'){const b=node('div',undefined,'board');b.style.gridTemplateColumns='repeat(5,1fr)';for(let i=0;i<5;i++)b.append(cell(state.bricks.includes(i)?'🧱':'·'));for(let i=0;i<5;i++)b.append(cell(i===state.aim?'🚀':'·'));stage.append(b);controls([['← Aim',{type:'aim',dx:-1}],['Launch',{type:'launch'}],['Aim →',{type:'aim',dx:1}]]);}
      else if(m==='platform'){const b=node('div',undefined,'board');b.style.gridTemplateColumns='repeat(9,1fr)';for(let i=0;i<9;i++)b.append(cell(i===state.x?(state.jumping?'🚀':'🧍'):state.coins.includes(i)?'⭐':'·'));stage.append(b);controls([['←',{type:'move',dx:-1}],['Jump',{type:'jump'}],['→',{type:'move',dx:1}]]);}
      else if(m==='runner'||m==='dodge'){const b=node('div',undefined,'board');b.style.gridTemplateColumns='repeat(3,1fr)';for(let i=0;i<3;i++)b.append(cell(i===state.obstacle?'🪨':'·'));for(let i=0;i<3;i++)b.append(cell(i===state.lane?'🚀':'·'));stage.append(b);controls([['← Lane',{type:'lane',dx:-1}],['Advance',{type:'tick'}],['Lane →',{type:'lane',dx:1}]]);}
      else if(m==='defense'){stage.append(node('p',`Energy: ${state.energy} · Shields: ${'🛡'.repeat(Math.min(state.shields,15))}`));controls([['🌿 Grow energy',{type:'grow'}],['🛡 Protect (2 energy)',{type:'protect'}]]);}
      else if(m==='slide'){const b=node('div',undefined,'board');b.style.gridTemplateColumns='repeat(3,1fr)';state.tiles.forEach((v,index)=>b.append(btn(v||'□',{type:'slide',index},'tile')));stage.append(b);}
      else if(m==='word'){stage.append(node('h2',[...state.word].map(c=>state.guessed.includes(c)?c:'_').join(' ')));stage.append(node('p','Tried: '+state.guessed.join(' ')));submit('Guess letter','letter','One letter',1);}
      else if(m==='coop'){stage.append(node('p',`${state.left?'✓':'○'} Player one  ·  ${state.right?'✓':'○'} Player two`));controls([['A · Player one',{type:'left'}],['L · Player two',{type:'right'}]]);}
      if(config.design && config.tests.some(t=>t.selector==='.target') && !stage.querySelector('.target'))stage.append(node('div','✦', 'target'));
      if(config.design && config.tests.some(t=>t.selector==='.tile') && !stage.querySelector('.tile')){const sample=cell('✦');sample.style.width='64px';stage.append(sample);}
      if(focus){[...stage.querySelectorAll('button')].find(e=>e.dataset.action===focus)?.focus({preventScroll:true});}
    }
    async function act(action){
      if(config.readOnly||busy||finished)return;
      if(action.type==='roll')action={...action,value:1+Math.floor(Math.random()*6)};
      if(config.mode==='rps')action={...action,opponent:['pebble','leaf','cloud'][Math.floor(Math.random()*3)]};
      busy=true;
      try {const r=await send('update',{state,action});state=r.state;finished=r.complete;render();if(['reaction','rhythm'].includes(config.mode)&&action.type==='tap'&&!finished)scheduleBeat();}catch(e){fail(e.message);}finally{busy=false;}
    }
    function scheduleBeat(){clearTimeout(beatTimer);beatTimer=setTimeout(()=>act({type:'ready'}),config.mode==='rhythm'?1100:900+Math.random()*1000);}
    document.getElementById('restart').onclick=async()=>{if(busy)return;busy=true;try{const r=await send('start');state=r.state;finished=r.complete;render();scheduleBeatIfNeeded();}catch(e){fail(e.message);}finally{busy=false;}};
    function scheduleBeatIfNeeded(){if(!config.readOnly&&['reaction','rhythm'].includes(config.mode))scheduleBeat();}
    document.addEventListener('keydown',e=>{
      if(e.target.matches('input,textarea')||config.readOnly)return;
      const directions={ArrowLeft:[-1,0],ArrowRight:[1,0],ArrowUp:[0,-1],ArrowDown:[0,1]};
      if(directions[e.key]&&['maze','snake','platform','runner','dodge','pong','breakout'].includes(config.mode)){e.preventDefault();const [dx,dy]=directions[e.key];const type=['runner','dodge'].includes(config.mode)?'lane':config.mode==='pong'?'paddle':config.mode==='breakout'?'aim':'move';act({type,dx,dy});}
      if(config.mode==='coop'&&['a','l'].includes(e.key.toLowerCase()))act({type:e.key.toLowerCase()==='a'?'left':'right'});
    });
    document.querySelector('h1').textContent=config.title;
    document.querySelector('.instructions').textContent=config.instructions;
    if(config.css){const style=document.createElement('style');style.textContent=config.css;document.head.append(style);}
    startWorker();
    (async()=>{try{
      if(config.test&&!config.design){const r=await send('test',{code:config.code,tests:config.tests});inform(r);stop();return;}
      const r=await send('start',{code:config.code});state=r.state;finished=r.complete;render();
      if(config.test&&config.design){
        const results=config.tests.map(t=>{
          const element=document.querySelector(t.selector),sample=document.createElement(element?.tagName||'span');sample.style.setProperty(t.property,t.value);sample.style.position='absolute';sample.style.visibility='hidden';document.body.append(sample);
          const actual=element?getComputedStyle(element).getPropertyValue(t.property):'',expected=getComputedStyle(sample).getPropertyValue(t.property);sample.remove();
          const passed=!!element && (actual===expected || actual===t.value);
          return {name:t.name,passed,error:passed?undefined:`Expected ${t.value}; browser computed ${actual||'no element'}.`};
        });inform({results});stop();
      }else {scheduleBeatIfNeeded();inform({ready:true});}
    }catch(e){fail(e.message);}})();
    window.addEventListener('pagehide',stop);
  }

  function documentFor(mission,code,options={}) {
    const config={mode:mission.mode,title:mission.title,instructions:mission.description,design:mission.track==='design',code:mission.track==='design'?mission.gameCode:code,css:mission.track==='design'?code:'',tests:mission.tests,...options};
    const safe=value=>JSON.stringify(value).replace(/</g,'\\u003c').replace(/\u2028/g,'\\u2028').replace(/\u2029/g,'\\u2029');
    return `<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'unsafe-inline' 'unsafe-eval'; style-src 'unsafe-inline'; worker-src blob:; connect-src 'none'; img-src data:; form-action 'none'; base-uri 'none'"><title>My StackSprint game</title><style>${css}</style><body><main class="arena"><h1></h1><p class="instructions"></p><div class="hud"><span class="score" id="score"></span><button id="restart" type="button">Restart</button></div><div id="stage"></div><p id="status" class="message" aria-live="polite"></p></main><script>(${frameMain.toString()})(${safe(config)},${safe(workerMain.toString())});<\/script></body></html>`;
  }
  function play(iframe,mission,code,options={}) {
    iframe.setAttribute('sandbox','allow-scripts');iframe.srcdoc=documentFor(mission,code,options);
    return ()=>{iframe.srcdoc='';};
  }
  function test(mission,code) {
    return new Promise(resolve=>{
      const iframe=document.createElement('iframe'),token=crypto.randomUUID();
      iframe.title='Code validation';iframe.style.cssText='position:fixed;left:-10000px;width:700px;height:600px;visibility:hidden';
      const finish=result=>{clearTimeout(timeout);window.removeEventListener('message',receive);iframe.remove();resolve(result);};
      const receive=e=>{if(e.source===iframe.contentWindow&&e.data?.channel==='stacksprint-runtime'&&e.data.token===token&&(e.data.results||e.data.error))finish(e.data);};
      const timeout=setTimeout(()=>finish({error:'Code execution timed out. Check for an endless loop and retry.'}),5000);
      window.addEventListener('message',receive);document.body.append(iframe);play(iframe,mission,code,{test:true,readOnly:true,token});
    });
  }
  window.StackSprintRuntime={test,play,documentFor};
})();
