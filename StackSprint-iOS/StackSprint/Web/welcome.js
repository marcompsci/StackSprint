(() => {
  if(window.stackSprintNative)return;
  const key='stacksprint-welcome-v1';
  let saved={};try{saved=JSON.parse(localStorage.getItem(key)||'{}')||{};}catch{}
  let step=0,goal=['Build a website','Make games','Refresh my skills'].includes(saved.goal)?saved.goal:'Build a website',minutes=[3,5,10].includes(saved.minutes)?saved.minutes:5,correct=false;
  const dialog=document.createElement('dialog');dialog.className='welcome-adventure';dialog.setAttribute('aria-label','Welcome adventure');document.body.append(dialog);
  const replay=document.createElement('button');replay.textContent='Replay welcome adventure';replay.className='welcome-replay';document.querySelector('.sidebar').append(replay);
  function save(done=false){try{localStorage.setItem(key,JSON.stringify({goal,minutes,done}));}catch{}}
  function finish(){save(true);dialog.close();replay.focus();}
  function render(){
    const titles=['Your first “I made that!” starts here.','What will you make?','A little time. A real habit.','Your first tiny win.'];
    const descriptions=['I’m Bite, your coding buddy. Learn it, type it, then make it yours.','Choose an intention. Every course stays available.','Pick a daily intention. No timers. No penalties.','What will Python print? Try a prediction.'];
    dialog.innerHTML=`<header><span>YOUR FIRST SPARK · ${step+1}/4</span><button data-skip>Skip welcome</button></header><progress max="4" value="${step+1}" aria-label="Welcome progress"></progress><h1 tabindex="-1">${titles[step]}</h1><p>${descriptions[step]}</p><div class="welcome-choices">${step===0?'<p>① Learn a small idea</p><p>② Type it. Remix it.</p><p>③ Play what you build</p>':step===1?['Build a website','Make games','Refresh my skills'].map(v=>`<button data-goal="${v}" aria-pressed="${goal===v}">${v}</button>`).join(''):step===2?[3,5,10].map(v=>`<button data-minutes="${v}" aria-pressed="${minutes===v}">${v} minutes · ${v===3?'Tiny spark':v===5?'Steady builder':'Curious explorer'}</button>`).join(''):'<pre>print(2 + 3)</pre>'+['23','5','Hello'].map(v=>`<button data-answer="${v}">${v}</button>`).join('')}</div><p role="status">${correct&&step===3?'You got it! Numbers add together.':'Mistakes are welcome here.'}</p><footer>${step>0?'<button data-back>Back</button>':''}<button data-next ${step===3&&!correct?'disabled':''}>${step===3?'Let’s start building':'Continue →'}</button></footer>`;
    dialog.querySelector('[data-skip]').onclick=finish;
    dialog.querySelector('[data-next]').onclick=()=>{if(step<3){step++;render();}else finish();};
    const back=dialog.querySelector('[data-back]');if(back)back.onclick=()=>{step--;render();};
    dialog.querySelectorAll('[data-goal]').forEach(b=>b.onclick=()=>{goal=b.dataset.goal;save();render();});
    dialog.querySelectorAll('[data-minutes]').forEach(b=>b.onclick=()=>{minutes=Number(b.dataset.minutes);save();render();});
    dialog.querySelectorAll('[data-answer]').forEach(b=>b.onclick=()=>{correct=b.dataset.answer==='5';dialog.querySelector('[role=status]').textContent=correct?'You got it! Numbers add together. Ready for the next tiny win?':'Without quotes, these are numbers. Add 2 and 3 and try again.';dialog.querySelector('[data-next]').disabled=!correct;});
    dialog.querySelector('h1').focus();
  }
  function open(){step=0;correct=false;render();dialog.showModal();dialog.querySelector('h1').focus();}
  replay.onclick=open;
  dialog.addEventListener('cancel',()=>save(true));
  if(!saved.done)open();
})();
