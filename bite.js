(() => {
  'use strict';
  const pet = document.createElement('aside');
  pet.id = 'bite-pet';
  pet.setAttribute('aria-label', 'Bite coding companion');
  pet.innerHTML = `<div class="bite-bubble" hidden><p role="status" aria-live="polite">Hi! I’m Bite. Small steps, big ideas.</p><button class="bite-sound" aria-pressed="false">Enable voice</button><button class="bite-preview">Preview keyboard reaction</button><button class="bite-dismiss" aria-label="Close Bite’s message">Close</button></div><button class="bite-body" aria-label="Ask Bite for a coding tip" aria-expanded="false"><svg viewBox="0 0 24 26" shape-rendering="crispEdges" aria-hidden="true"><path fill="#9ce7cf" d="M10 0h4v4h-4z"/><path fill="#ffb394" d="M11 4h2v3h-2z"/><path fill="#bd705e" d="M4 9h16v2h2v12h-3v3h-4v-3H9v3H5v-3H2V11h2z"/><path fill="#ffb394" d="M4 7h16v2h2v12h-2v2H4v-2H2V9h2z"/><path fill="#ffe0c0" d="M4 7h16v2H4zM2 9h2v10H2z"/><path fill="#202b44" d="M6 10h12v2h2v5h-2v2H6v-2H4v-5h2z"/><g class="bite-eyes" fill="white"><path d="M7 12h3v3H7zM14 12h3v3h-3z"/></g><path class="bite-mouth" fill="#202b44" d="M10 20h4v1h-4z"/></svg><span>Bite</span></button>`;
  document.body.append(pet);
  const bubble=pet.querySelector('.bite-bubble'), face=pet.querySelector('.bite-body'), message=pet.querySelector('p'), sound=pet.querySelector('.bite-sound');
  let voiced=false, raised=false, previewTimer, baseline=window.innerHeight;
  const tips=['Read the code out loud, then predict what it does.', 'Try changing one value. What changes in the output?', 'A bug is a clue. Check one line at a time.', 'Make the example yours: change its name, color, or story.'];
  let tip=0;
  function show(text){message.textContent=text;bubble.hidden=false;face.setAttribute('aria-expanded','true');}
  function speak(){if(!voiced || !('speechSynthesis' in window))return;window.speechSynthesis.cancel();const line=new SpeechSynthesisUtterance('Oh no, what is happening');line.lang='en-US';line.pitch=1.65;line.rate=0.85;line.volume=0.65;window.speechSynthesis.speak(line);}
  function react(up){pet.classList.toggle('is-confused',up);if(up&&!raised){show('Oh no, what is happening');speak();}else if(!up&&raised){show('Oh! Your keyboard. Let’s make something!');}raised=up;}
  face.onclick=()=>show(tips[tip++%tips.length]);
  sound.onclick=()=>{voiced=!voiced;sound.setAttribute('aria-pressed',String(voiced));sound.textContent=voiced?'Mute voice':'Enable voice';if(voiced)speak();else if('speechSynthesis' in window)window.speechSynthesis.cancel();};
  pet.querySelector('.bite-dismiss').onclick=()=>{bubble.hidden=true;face.setAttribute('aria-expanded','false');};
  pet.querySelector('.bite-preview').onclick=()=>{clearTimeout(previewTimer);react(true);previewTimer=setTimeout(()=>react(false),3000);};
  function update(){
    const v=window.visualViewport;
    const focused=document.activeElement?.matches('textarea,input:not([type=checkbox]):not([type=radio]),[contenteditable="true"]');
    if(!focused)baseline=window.innerHeight;
    const occluded=v?Math.max(0,window.innerHeight-v.height-v.offsetTop):0;
    const shrink=v?baseline-v.height:baseline-window.innerHeight;
    const keyboard=Boolean(focused && (!v||Math.abs(v.scale-1)<0.05) && Math.max(occluded,shrink)>120);
    pet.style.setProperty('--bite-lift',`${keyboard?occluded:0}px`);
    react(keyboard);
  }
  window.visualViewport?.addEventListener('resize',update);
  window.visualViewport?.addEventListener('scroll',update);
  window.addEventListener('resize',update);
  document.addEventListener('focusin',update);
  document.addEventListener('focusout',()=>setTimeout(update,0));
  // Follow modal lessons into the top layer without blocking the rest of the page.
  new MutationObserver(()=>{const modal=document.querySelector('dialog[open]');const parent=modal||document.body;if(pet.parentElement!==parent)parent.append(pet);}).observe(document.body,{subtree:true,childList:true,attributes:true,attributeFilter:['open']});
})();
