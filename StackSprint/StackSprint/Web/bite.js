(() => {
  'use strict';
  const pet = document.createElement('aside');
  pet.id = 'bite-pet';
  pet.setAttribute('aria-label', 'Bite coding companion');
  pet.innerHTML = `<div class="bite-bubble" hidden><p role="status" aria-live="polite">Hi! I’m Bite. Small steps, big ideas.</p><button class="bite-sound" aria-pressed="false">Enable voice</button><button class="bite-preview">Preview keyboard reaction</button><button class="bite-dismiss" aria-label="Close Bite’s message">Close</button></div><button class="bite-body" aria-label="Ask Bite for a coding tip" aria-expanded="false"><svg viewBox="0 0 11 15" shape-rendering="crispEdges" aria-hidden="true"><path fill="#9ce6d1" d="M4 0h2v2H4z"/><path fill="#ffa88a" d="M5 2h1v2H5z"/><path fill="#ffd6b8" d="M1 4h8v1H1zM0 6h1v5H0z"/><path fill="#ffa88a" d="M0 5h11v7H0z"/><path fill="#ffd6b8" d="M0 6h1v5H0z"/><path fill="#ba6452" d="M0 11h1v1H0zM10 11h1v1h-1zM2 12h2v2H2zM7 12h2v2H7z"/><path fill="#1a263f" d="M1 6h9v4H1z"/><g class="bite-eyes" fill="#fff"><path d="M2 7h2v2H2zM7 7h2v2H7z"/></g><path class="bite-mouth" fill="#1a263f" d="M4 11h2v1H4z"/></svg><span>Bite</span></button>`;
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
