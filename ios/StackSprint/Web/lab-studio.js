(() => {
  const key='stacksprint-studio-v1';
  const esc=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const day=(date=new Date())=>`${date.getFullYear()}-${String(date.getMonth()+1).padStart(2,'0')}-${String(date.getDate()).padStart(2,'0')}`;
  let saved;
  try{saved=JSON.parse(localStorage.getItem(key)||'{}');}catch{saved={};}
  if(!saved||typeof saved!=='object'||Array.isArray(saved))saved={};
  const data={projects:{},activity:{},quizzes:{},daily:{},selected:{design:0,building:0},cyberSeen:[],...saved};
  if(!Array.isArray(data.cyberSeen))data.cyberSeen=[];
  for(const name of ['projects','activity','quizzes','daily','selected'])if(!data[name]||typeof data[name]!=='object'||Array.isArray(data[name]))data[name]={};
  let currentMission,playing=false,running=false,runVersion=0,stopGame,logs=[],storageWarning=false;
  function persist(){try{localStorage.setItem(key,JSON.stringify(data));storageWarning=false;}catch{storageWarning=true;const e=document.getElementById('studioSaveStatus');if(e)e.textContent='Storage is full or unavailable. Download your source to keep it.';}}
  function recordActivity(type,id){const today=day();if(!Array.isArray(data.activity[today]))data.activity[today]=[];const event=type+':'+id;if(!data.activity[today].includes(event))data.activity[today].push(event);persist();renderHabit();}
  function record(mission){const id=mission.track+':'+mission.id;let r=data.projects[id];if(!r||typeof r!=='object')r=data.projects[id]={};if(typeof r.code!=='string')r.code=mission.starter;return r;}
  function complete(track,index){const p=gameProjectTracks[track].projects[index];return !!data.projects[track+':'+p.id]?.completed;}
  function frontier(track){const list=gameProjectTracks[track].projects;const first=list.findIndex((_,i)=>!complete(track,i));return first<0?list.length-1:first;}
  function selection(track){const n=data.selected[track];return Number.isInteger(n)?Math.max(0,Math.min(n,frontier(track))):frontier(track);}
  function log(message){logs.push(String(message));logs=logs.slice(-70);const output=document.getElementById('studioOutput');if(output){output.textContent=logs.join('\n');output.scrollTop=output.scrollHeight;}}
  function sync(){const editor=document.getElementById('studioCode');if(editor&&currentMission){record(currentMission).code=editor.value;persist();}}
  function sourceChanged(){sync();if(stopGame)stopGame();playing=false;const r=record(currentMission);document.getElementById('studioPlay').disabled=r.passedCode!==r.code;document.getElementById('studioExport').disabled=r.passedCode!==r.code;document.getElementById('studioSaveStatus').textContent=storageWarning?'Download your source to keep it.':'Draft saved · run checks to validate this edit';document.getElementById('studioPreview').hidden=true;document.getElementById('studioLocked').hidden=false;document.getElementById('studioLocked').textContent='Your code changed. Run checks to unlock this version.';}

  function renderMap(){
    const track=state.gameTrack,projects=gameProjectTracks[track].projects,count=projects.filter((_,i)=>complete(track,i)).length;
    gameTrackProgress.textContent=`${count} / 30`;
    gameRouteCopy.textContent='Complete the code checks to open the next project. Finished projects remain yours to play, revisit, and remix.';
    gameProjectMap.innerHTML=projects.map((p,i)=>`<button type="button" class="game-project-card ${i>frontier(track)?'is-locked':complete(track,i)?'is-completed':'is-current'}" data-studio-project="${i}" ${i>frontier(track)?'disabled':''} ${i===selection(track)?'aria-current="step"':''}><span class="game-project-card-number">${String(i+1).padStart(2,'0')}</span><span aria-hidden="true">${i>frontier(track)?'🔒':complete(track,i)?'✓':p.emoji}</span><span class="game-project-card-copy"><strong>${esc(p.title)}</strong><small>${complete(track,i)?'Built · replay or remix':p.level}</small></span><span class="game-project-card-status">${i>frontier(track)?'Locked':complete(track,i)?'Complete':'Build'}</span></button>`).join('');
    gameProjectMap.querySelectorAll('[data-studio-project]').forEach(button=>button.onclick=()=>selectProject(track,Number(button.dataset.studioProject)));
  }
  function selectProject(track,index){
    if(!gameProjectTracks[track]||!Number.isInteger(index)||index<0||index>frontier(track))return;
    sync();data.selected[track]=index;persist();setGameTrack(track);document.getElementById('gameProjectWorkspace').scrollIntoView({behavior:'smooth',block:'start'});
  }
  function renderStudio(){
    sync();runVersion++;running=false;if(stopGame)stopGame();playing=false;
    const track=state.gameTrack,index=selection(track),project=gameProjectTracks[track].projects[index];
    currentMission=StackSprintMissions.get(track,project.id);data.lastTrack=track;persist();const m=currentMission,r=record(m),valid=r.passedCode===r.code;
    logs=[`StackSprint Studio · ${m.title}`,track==='design'?'Edit styles.css to shape the game interface.':'Edit game.js. Your functions power the finished game.',"Commands: help · test · play · preview · hint · clear · export",'Finish all three code checks to unlock play and the next mission.'];
    gameProjectMission.innerHTML=`
      <div class="studio-heading"><div><p class="eyebrow">${track==='design'?'DESIGN STUDIO · CSS':'BUILD STUDIO · JAVASCRIPT'}</p><h3>${project.emoji} ${esc(m.title)}</h3></div><span class="studio-counter">${index+1} / 30</span></div>
      <p class="studio-intro">${esc(m.description)}</p>
      <div class="studio-flow" aria-label="Learning workflow"><span>01 Learn & edit</span><span>02 Run checks</span><span>03 Play & remix</span></div>
      <div class="studio-task-list">${m.tasks.map((task,i)=>`<details class="studio-task" ${i===0?'open':''}><summary><span class="studio-check-dot" id="studioCheck${i}">${valid?'✓':i+1}</span>${esc(task.title)}</summary><p>${esc(task.instructions)}</p><details class="studio-hint"><summary>Show a worked example</summary><p>Read it, close it, then write your version. The checks evaluate behavior, so equivalent code works.</p><pre>${esc(task.hint)}</pre></details></details>`).join('')}</div>
      <div class="studio-editor-shell"><div class="studio-filebar"><span><i></i> ${track==='design'?'styles.css':'game.js'}</span><span>${track==='design'?'CSS':'JavaScript'} · local workspace</span></div>
        <label class="sr-only" for="studioCode">${esc(m.title)} source code</label><textarea id="studioCode" class="studio-code" spellcheck="false" autocapitalize="off" autocomplete="off" aria-describedby="studioEditorHelp"></textarea>
        <p id="studioEditorHelp" class="studio-editor-help">Ctrl/⌘ + Enter runs checks. Tab indents; Escape then Tab leaves the editor.</p>
        <div class="studio-toolbar"><button id="studioTest" class="studio-primary" type="button">▶ Run checks</button><button id="studioPlay" type="button" ${valid?'':'disabled'}>Play my game</button>${track==='design'?'<button id="studioPreviewDesign" type="button">Preview design</button>':''}<button id="studioDownload" type="button">Save source ↓</button></div>
        <div class="studio-save" id="studioSaveStatus" role="status">${r.completed?'Completed once · your latest draft is saved': 'Drafts save on this device'}${valid?' · this version passed':''}</div>
      </div>
      <div class="studio-terminal"><div class="studio-terminal-head"><span>TERMINAL</span><span>Browser JavaScript & CSS workspace</span></div><pre id="studioOutput" role="log" aria-live="polite" aria-relevant="additions text"></pre><form id="studioCommandForm"><label for="studioCommand">sprint $</label><input id="studioCommand" autocomplete="off" spellcheck="false" placeholder="Type help, test, or play" aria-label="Studio terminal command"><button type="submit">Run</button></form></div>
      <div class="studio-preview-head"><h4>Your playable result</h4><button id="studioExport" type="button" ${valid?'':'disabled'}>Export game.html ↓</button></div>
      <div class="studio-locked" id="studioLocked"><span>◇</span><strong>${valid?'Your game is ready to play':'Build it. Then bring it to life.'}</strong><p>${valid?'Choose “Play my game” to run the code you wrote.':'Pass the three code checks to unlock your game. Design previews are available while you work.'}</p></div>
      <iframe id="studioPreview" class="studio-preview" title="${esc(m.title)} playable game" sandbox="allow-scripts" hidden></iframe>
      <div class="studio-bottom"><button type="button" id="studioPractice">Practice from memory</button><button type="button" id="studioRestore" ${r.lastGood?'':'disabled'}>Restore last passing code</button><button type="button" id="studioNext" class="studio-primary" ${r.completed&&index<29?'':'disabled'}>${index===29?'Final mission':'Next mission →'}</button></div>
      <p class="studio-note">${r.completed?'Mission complete. Rebuild it from memory, change a rule, or export a standalone game to keep.':'Short prototypes, real code. The app supplies the display and controls; you implement the rules or visual design.'}</p>`;
    document.getElementById('studioCode').value=r.code;
    let escapeTab=false;
    document.getElementById('studioCode').addEventListener('input',sourceChanged);
    document.getElementById('studioCode').addEventListener('keydown',e=>{
      if((e.metaKey||e.ctrlKey)&&e.key==='Enter'){e.preventDefault();runTests();}
      if(e.key==='Escape'){escapeTab=true;return;}
      if(e.key==='Tab'&&!e.shiftKey&&!escapeTab){e.preventDefault();const a=e.target.selectionStart,b=e.target.selectionEnd;e.target.setRangeText('  ',a,b,'end');sourceChanged();}else escapeTab=false;
    });
    document.getElementById('studioTest').onclick=runTests;
    document.getElementById('studioPlay').onclick=()=>playGame(false);
    document.getElementById('studioPreviewDesign')?.addEventListener('click',()=>playGame(true));
    document.getElementById('studioDownload').onclick=()=>download(false);
    document.getElementById('studioExport').onclick=()=>download(true);
    document.getElementById('studioPractice').onclick=()=>{sync();r.practiceBackup=r.code;r.code=m.starter;persist();document.getElementById('studioCode').value=r.code;sourceChanged();log('Fresh practice started. Your last passing version is kept; use Restore at any time.');};
    document.getElementById('studioRestore').onclick=()=>{if(!r.lastGood)return;r.code=r.lastGood;r.passedCode=r.lastGood;persist();document.getElementById('studioCode').value=r.code;renderStudio();};
    document.getElementById('studioNext').onclick=()=>{if(complete(track,index)&&index<29)selectProject(track,index+1);};
    document.getElementById('studioCommandForm').onsubmit=e=>{e.preventDefault();const field=document.getElementById('studioCommand'),command=field.value.trim().toLowerCase();field.value='';log('sprint $ '+command);switch(command){case 'test':case 'run':case 'build':runTests();break;case 'play':playGame(false);break;case 'preview':if(m.track==='design')playGame(true);else log('Run checks, then play to preview your JavaScript game.');break;case 'hint':log(m.tasks.map((t,i)=>`${i+1}. ${t.instructions}`).join('\n'));break;case 'clear':logs=[];log('');break;case 'export':download(true);break;case 'help':log('test / build — execute the three checks\nplay — launch your passing code\npreview — see your CSS before finishing\nhint — show task guidance\nexport — download your passing game\nclear — clear this terminal\nEdit JavaScript or CSS in the source editor above.');break;default:log('Unknown workspace command. Type help for available commands.');}};
    log('Ready.');renderMap();renderHabit();
  }
  async function runTests(){
    if(running)return;sync();const m=currentMission,r=record(m),code=r.code,version=runVersion;
    running=true;const button=document.getElementById('studioTest');button.disabled=true;button.textContent='Checking…';log('> Running your code against three behavior checks…');
    const result=await StackSprintRuntime.test(m,code);
    if(version!==runVersion)return;
    running=false;button.disabled=false;button.textContent='▶ Run checks';
    if(result.error){log('ERROR: '+result.error);return;}
    let consecutive=true;result.results.forEach((test,i)=>{const passed=consecutive&&test.passed;consecutive=passed;document.getElementById('studioCheck'+i).textContent=passed?'✓':'!';document.getElementById('studioCheck'+i).classList.toggle('is-passed',passed);log(`${test.passed?'PASS':'FIX '} ${i+1}. ${test.name}${test.error?' — '+test.error:''}`);});
    if(result.results.length===3&&result.results.every(t=>t.passed)){
      const first=!r.completed;r.completed=true;r.lastGood=code;r.passedCode=code;
      if(!r.reviewed||day(new Date(r.reviewed))!==day())r.reviews=(r.reviews||0)+1;
      r.reviewed=Date.now();r.due=Date.now()+Math.min(14,2**Math.min(r.reviews-1,4))*86400000;persist();recordActivity('code',m.track+':'+m.id);
      log(first?'✓ Mission built! Play is unlocked. Your next mission is ready.':'✓ Your remix passes. Play or export this version.');
      if(r.code===code){document.getElementById('studioPlay').disabled=false;document.getElementById('studioExport').disabled=false;document.getElementById('studioLocked').textContent='✓ Your code passed. Choose Play my game.';}
      document.getElementById('studioRestore').disabled=false;document.getElementById('studioNext').disabled=selection(m.track)===29;document.getElementById('studioSaveStatus').textContent='All checks passed · source saved';renderMap();renderHabit();
    }else log('Keep going. Open the matching lesson above, edit your code, then run checks again.');
  }
  function assembledGame(m){
    if(m.track==='design'){const built=data.projects['building:'+m.buildId];return {mission:{...m,gameCode:built?.lastGood||m.gameCode},options:{},note:built?.lastGood?'Your own JavaScript build is powering this design.':''};}
    const designs=StackSprintMissions.all().filter(d=>d.track==='design'&&d.buildId===m.id&&data.projects['design:'+d.id]?.lastGood);
    const design=designs.sort((a,b)=>(data.projects['design:'+b.id].reviewed||0)-(data.projects['design:'+a.id].reviewed||0))[0];
    return {mission:m,options:design?{css:data.projects['design:'+design.id].lastGood}:{},note:design?'Your '+design.title+' CSS is applied to this build.':''};
  }
  function playGame(preview){
    sync();const m=currentMission,r=record(m);
    if(!preview&&r.passedCode!==r.code){log('Play is locked for this draft. Pass all three code checks first.');return;}
    if(preview&&m.track!=='design')return;
    if(stopGame)stopGame();const iframe=document.getElementById('studioPreview');iframe.hidden=false;document.getElementById('studioLocked').hidden=true;
    const assembled=assembledGame(m);
    stopGame=StackSprintRuntime.play(iframe,assembled.mission,r.code,{...assembled.options,readOnly:preview});playing=!preview;log(preview?'Design preview updated. Play unlocks after the checks pass.':'Launching your code. Use the game controls below; Restart begins a new round.');if(assembled.note)log(assembled.note);
    iframe.scrollIntoView({behavior:'smooth',block:'nearest'});
  }
  function download(game){
    sync();const r=record(currentMission);if(game&&r.passedCode!==r.code){log('Pass the current draft before exporting a playable game.');return;}
    const assembled=assembledGame(currentMission);
    const contents=game?StackSprintRuntime.documentFor(assembled.mission,r.code,assembled.options):r.code;
    const url=URL.createObjectURL(new Blob([contents],{type:game?'text/html':'text/plain'}));const a=document.createElement('a');a.href=url;a.download=currentMission.id+(game?'.html':currentMission.track==='design'?'.css':'.js');a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);log('Downloaded '+a.download);
  }

  const dailyQuestions=[
    {q:'A coin counter starts at 2. Which update makes it 3?',options:['score = 1','score += 1','score = 3 + score'],answer:1,why:'+= adds to the existing value, so it works for every starting score.'},
    {q:'Which CSS rule gives every button a comfortable 48px minimum height?',options:['button { min-height: 48px; }','button { height: small; }','button { size: 48; }'],answer:0,why:'min-height sets a minimum while allowing room for longer labels.'},
    {q:'When should a matching game award a point?',options:['Whenever any card is clicked','Before checking the pair','When two distinct cards match'],answer:2,why:'Check the rule first, then change the score. Otherwise repeated clicks can score unfairly.'},
    {q:'Which function checks whether all letters have been guessed?',options:['letters.every(check)','letters.push(check)','letters.reverse(check)'],answer:0,why:'every() returns true only when the callback accepts every item.'},
    {q:'What should a restart restore?',options:['Only the button label','All starting game state','Only the score color'],answer:1,why:'Reset positions, counters, and flags so the next round starts consistently.'},
    {q:'Your input is "7". How do you convert it to a number?',options:['input + 0','Number(input)','input.toUpperCase()'],answer:1,why:'Input values are strings; Number() enables numeric comparisons and arithmetic.'},
    {q:'A player cannot distinguish two colors. What helps?',options:['Add labels and shapes','Make the colors brighter','Hide the instructions'],answer:0,why:'Redundant cues let players understand the state without depending on color alone.'},
    {q:'Which is the safer way to send an API key from a web app?',options:['Put it in browser JavaScript','Print it on the page','Keep the secret on the server'],answer:2,why:'Browser code is visible. Server-side code should handle secrets.'},
    {q:'A score must never be negative. Which expression clamps it at zero?',options:['Math.max(0, score - 1)','Math.min(0, score - 1)','score - 100'],answer:0,why:'Math.max selects the larger value, so the result cannot fall below zero.'},
    {q:'Which event should check a typed answer?',options:['Page load only','The form submit event','Every window resize'],answer:1,why:'Submit handles the user’s intent to send the answer, including Enter on the keyboard.'},
    {q:'Which statement returns a win condition?',options:['return score >= target;','score + target;','return "maybe";'],answer:0,why:'A comparison returns a boolean that the game can use to detect completion.'},
    {q:'Which CSS selector targets a class named tile?',options:['#tile','.tile','@tile'],answer:1,why:'A dot selects a class; a hash selects an ID.'}
  ];
  dailyQuestions.push(...[...quizQuestions,...cyberQuizQuestions].map(q=>({q:q.question,options:q.choices,answer:q.answer,why:q.explanation})));
  function todayReview(){const today=day();let r=data.daily[today];if(!r||!Array.isArray(r.done))r=data.daily[today]={done:[]};return r;}
  function renderHabit(){
    const host=document.getElementById('dailyStudio');if(!host)return;
    const today=day(),review=todayReview(),completed=Object.values(data.projects).filter(p=>p?.completed).length;
    const due=Object.entries(data.projects).filter(([,p])=>p?.completed&&p.due<=Date.now());
    let streak=0,date=new Date();if(!data.activity[day(date)]?.length)date.setDate(date.getDate()-1);
    for(let i=0;i<3660&&data.activity[day(date)]?.length;i++){streak++;date.setDate(date.getDate()-1);}
    const activityDays=Object.keys(data.activity).filter(d=>data.activity[d]?.length).length;
    const xp=completed*50+Object.values(data.daily).reduce((n,r)=>n+(r.done?.length||0)*5,0);
    document.getElementById('streakCount').textContent=streak;
    const webDone=cards.every(c=>{const p=progressFor(c.id);return p.read&&p.typed&&p.promptDone.every(Boolean);});
    const quizzesDone=(data.quizzes.web||0)>=20&&(data.quizzes.cyber||0)>=20&&data.cyberSeen.length>=cyberTerms.length;
    const graduated=completed===60&&webDone&&quizzesDone;
    const dateNumber=Math.floor(Date.UTC(new Date().getFullYear(),new Date().getMonth(),new Date().getDate())/86400000);
    const next=[0,1,2].find(i=>!review.done.includes(i));const q=next===undefined?null:dailyQuestions[(dateNumber*3+next)%dailyQuestions.length];
    host.innerHTML=`<div class="habit-heading"><div><p class="eyebrow">YOUR DAILY SHIPPING HABIT</p><h2>A little practice. Something real.</h2><p>Recall a concept, rebuild a skill, then make one small thing your own.</p></div><div class="habit-stats"><span><strong>${streak}</strong>day streak</span><span><strong>${xp}</strong>XP earned</span><span><strong>${completed}/60</strong>games built</span></div></div>
      <div class="habit-grid"><div class="habit-card"><span class="eyebrow">3 QUICK RECALL REPS · ${review.done.length}/3</span>${q?`<h3>${esc(q.q)}</h3><div class="daily-options">${q.options.map((o,i)=>`<button type="button" data-daily-answer="${i}">${esc(o)}</button>`).join('')}</div><p id="dailyFeedback" role="status">Get it right to keep today’s practice moving.</p>`:'<h3>Today’s recall is complete. ✦</h3><p>Come back tomorrow for a fresh set, or keep building today.</p>'}</div>
      <div class="habit-card"><span class="eyebrow">REBUILD & REMIX</span><h3>${due.length?due.length+' projects ready for a refresher':'Your next tiny build'}</h3><p>${due.length?'Retrieval gets easier with practice. Rebuild a completed mission from memory, then compare your code.':'Complete a mission, play it, then change a color or a rule. Every completed project stays available in the route.'}</p><button type="button" id="habitResume" class="studio-primary">${due.length?'Open a refresher':'Continue building →'}</button><p class="habit-small">${activityDays} active days · progress stored on this device</p></div></div>
      <div class="graduation ${graduated?'is-earned':''}"><span>${graduated?'✦':'◇'}</span><div><strong>${graduated?'You’re ready to get started shipping your own products and designs.':'Your path to shipping'}</strong><p>${graduated?'You completed the courses and built all 60 projects. Keep your daily habit, remix your favorites, and export your next idea.':`${webDone?'✓':'○'} Web vocabulary and AI prompts · ${(data.quizzes.web||0)>=20?'✓':'○'} Web quiz 20/25 · ${data.cyberSeen.length}/${cyberTerms.length} safety terms · ${(data.quizzes.cyber||0)>=20?'✓':'○'} Cyber quiz 20/25 · ${completed}/60 projects built`}</p></div></div>`;
    host.querySelectorAll('[data-daily-answer]').forEach(b=>b.onclick=()=>{const good=Number(b.dataset.dailyAnswer)===q.answer;if(!good){b.classList.add('daily-wrong');document.getElementById('dailyFeedback').textContent=q.why+' Try again.';return;}review.done.push(next);recordActivity('recall',String(next));renderHabit();});
    document.getElementById('habitResume').onclick=()=>{const id=due[0]?.[0];if(id){const [track,pid]=id.split(':');const i=gameProjectTracks[track].projects.findIndex(p=>p.id===pid);selectProject(track,i);}else selectProject('building',frontier('building'));};
  }
  // Preserve the original learning flows and record actual completion events.
  const oldQuiz=renderQuiz;renderQuiz=function(){oldQuiz();if(state.quizIndex>=quizQuestions.length){data.quizzes.web=Math.max(data.quizzes.web||0,state.quizScore);recordActivity('quiz','web');}};
  const oldCyber=renderCyberQuiz;renderCyberQuiz=function(){oldCyber();if(state.cyberQuizIndex>=cyberQuizQuestions.length){data.quizzes.cyber=Math.max(data.quizzes.cyber||0,state.cyberQuizScore);recordActivity('quiz','cyber');}};
  const oldCardPersist=persistCardProgress;persistCardProgress=function(){oldCardPersist();recordActivity('study',currentCard().id);};
  cyberVocabGrid.addEventListener('click',event=>{const button=event.target.closest('[data-cyber-term]');if(!button)return;const id=button.dataset.cyberTerm;if(state.cyberVocabRevealed.has(id)&&!data.cyberSeen.includes(id)){data.cyberSeen.push(id);recordActivity('vocabulary',id);}});
  renderGameProjectLab=renderStudio;renderGameProjectMap=renderMap;
  document.querySelector('#game-lab .game-lab-heading p:last-child').textContent='Write real code, test your ideas, and play what you build. 30 design missions and 30 game builds take you from your first edit to a pocket portfolio.';
  window.addEventListener('beforeunload',sync);
  if(gameProjectTracks[data.lastTrack])setGameTrack(data.lastTrack);else renderStudio();
})();
