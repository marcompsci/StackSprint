(() => {
  'use strict';
  const host = document.getElementById('friends');
  host.innerHTML = `<div class="friends-heading"><div><p class="overline">BETTER WITH A BUDDY</p><h2>Small wins. Shared joy.</h2><p>Build a little. Cheer a lot. Invite someone to grow with you.</p></div><span class="friends-mascot" aria-hidden="true">{♥}</span></div>
  <div class="friends-grid"><article class="streak-ticket"><span class="overline">MY CODING STREAK</span><strong><span id="friendStreak">0</span> days</strong><p id="friendEncouragement"></p><div class="week-dots" id="friendWeek" aria-label="Last seven days of learning"></div><p>Real learning activity · saved on this device</p><button type="button" data-social="streak">Share my streak ↗</button></article>
  <article class="buddy-panel"><span class="overline">YOUR NEXT CO-OP QUEST</span><h3>Five minutes. Two curious minds.</h3><p>Invite a friend to practice today, then tell each other one thing you learned. No racing, no falling behind.</p><label for="friendQuest">Pick a friendly challenge</label><select id="friendQuest"><option>Learn one new coding concept today</option><option>Build a tiny game this week</option><option>Practice Python for five minutes</option><option>Explain one tricky concept to each other</option></select><button type="button" data-social="invite">Invite a coding buddy ♡</button><a href="#dailyStudio">Do my daily practice →</a></article></div>
  <div class="cheer-panel"><div><h3>Send a little encouragement</h3><p>Choose a message, then choose a friend in your device’s share menu.</p></div><div class="cheer-buttons"><button type="button" data-cheer="Tiny steps count. Proud of you for showing up to code today! 🌱">🌱 You showed up!</button><button type="button" data-cheer="That bug never stood a chance. Nice debugging! 🐛">🐛 Bug squashed!</button><button type="button" data-cheer="You made something that did not exist yesterday. Keep building! 🚀">🚀 Keep building!</button></div></div>
  <p id="socialStatus" role="status" aria-live="polite"></p><div id="socialFallback" hidden><label for="socialMessage">Your message — copy it into a conversation</label><textarea id="socialMessage" rows="5" readonly></textarea><button type="button" data-social="copy">Copy message</button></div>
  <details class="social-privacy"><summary>Your friends. Your choice. Your privacy.</summary><p>Sharing opens your device’s share menu when supported. You choose the app and recipient and confirm sending there. StackSprint does not read or upload your phone contacts. On unsupported browsers, copy the message instead.</p><p>This version does not have accounts, in-app chat, friend tracking, or leaderboards. Messages are shared through apps you already use. Local-file and localhost addresses are never included; a shareable app link requires a public deployment.</p></details>`;
  const status = host.querySelector('#socialStatus');
  let message = '';
  function dateKey(date) {return [date.getFullYear(),String(date.getMonth()+1).padStart(2,'0'),String(date.getDate()).padStart(2,'0')].join('-');}
  function stats() {
    let activity={};try{activity=JSON.parse(localStorage.getItem('stacksprint-studio-v1')||'{}').activity||{};}catch(_){}
    const active = date => Array.isArray(activity[dateKey(date)]) && activity[dateKey(date)].length>0;
    let date=new Date(),streak=0;if(!active(date))date.setDate(date.getDate()-1);
    while(streak<3660 && active(date)){streak++;date.setDate(date.getDate()-1);}
    host.querySelector('#friendStreak').textContent=streak;
    host.querySelector('#friendEncouragement').textContent=streak?'One small session at a time. Look how far you’ve come!':'Your first tiny win starts today. You belong here.';
    const week=host.querySelector('#friendWeek');week.replaceChildren();
    for(let i=6;i>=0;i--){const d=new Date();d.setDate(d.getDate()-i);const dot=document.createElement('span');dot.className=active(d)?'active':'';dot.textContent=active(d)?'✓':'·';dot.title=`${dateKey(d)}: ${active(d)?'Practiced':'No recorded practice'}`;dot.setAttribute('aria-label',dot.title);week.append(dot);}
    return streak;
  }
  function publicLink() {
    const url=new URL(location.href);
    if(url.protocol!=='https:' || /^(localhost|127\.|\[|0\.|10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.)/.test(url.hostname) || !url.hostname.includes('.'))return '';
    return `\nJoin me: ${url.origin}${url.pathname}`;
  }
  async function share(text) {
    message=text;host.querySelector('#socialMessage').value=text;
    host.querySelector('#socialFallback').hidden=false;
    if(!navigator.share){status.textContent='Copy this message and send it to a friend in your favorite messaging app.';return;}
    try{await navigator.share({title:'StackSprint · Better with a buddy',text});status.textContent='Share menu closed. Delivery is handled by your selected app.';}
    catch(error){status.textContent=error.name==='AbortError'?'Sharing canceled. Nothing was sent by StackSprint.':'Sharing is unavailable here. Copy the message below instead.';}
  }
  host.addEventListener('click',async event=>{
    const b=event.target.closest('button');if(!b)return;
    if(b.dataset.cheer){await share(b.dataset.cheer+' — Your StackSprint coding buddy');return;}
    if(b.dataset.social==='streak'){const n=stats();await share(n?`I’m on a ${n}-day coding streak in StackSprint! One small lesson at a time. Want to practice together?${publicLink()}`:`I’m starting my coding journey with StackSprint. Want to learn alongside me?${publicLink()}`);}
    if(b.dataset.social==='invite')await share(`Coding buddy quest: ${host.querySelector('#friendQuest').value}. Let’s practice with StackSprint and share one thing we learned!${publicLink()}`);
    if(b.dataset.social==='copy'){try{await navigator.clipboard.writeText(message);status.textContent='Copied! Paste it into a conversation when you’re ready.';}catch(_){host.querySelector('#socialMessage').focus();host.querySelector('#socialMessage').select();status.textContent='Message selected. Use your device’s Copy command.';}}
  });
  stats();window.addEventListener('focus',stats);window.addEventListener('storage',stats);
  const streak=document.getElementById('streakCount');if(streak)new MutationObserver(stats).observe(streak,{childList:true,characterData:true,subtree:true});
})();
