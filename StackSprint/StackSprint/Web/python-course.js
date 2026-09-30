/* Original StackSprint exercises. Topic inspiration: Asabeneh, 30 Days of Python, Day 2. */
(() => {
  'use strict';
  const cards = [
    ['Assignment', 'What does = do?', 'Bind a name to a value. Use == to compare.', 'stars = 6\nprint(stars)', '6'],
    ['Names', 'How do you name a score?', 'Use descriptive snake_case. Names are case-sensitive; avoid keywords and leading digits.', 'player_score = 8\nprint(player_score)', '8'],
    ['Built-ins', 'Do you import print?', 'No. Built-ins are available without imports. Avoid naming your variables print or len.', 'print("Launch", 2)', 'Launch 2'],
    ['Length', 'What does len count?', 'For a list, len counts items; for a simple string, characters.', 'print(len("orbit"))', '5'],
    ['Types', 'How can you inspect a value?', 'type reveals its type. Quoted digits are text, not numbers.', 'print(type("42").__name__)', 'str'],
    ['Input', 'Does input return a number?', 'input returns text. Convert numeric input before arithmetic.', 'tickets = int("4")\nprint(tickets + 2)', '6'],
    ['Casting', 'Can int parse decimal text?', 'int("6.8") raises ValueError. Parse with float first if truncation is intended.', 'print(int(float("6.8")))', '6'],
    ['Numbers', 'Does int round decimals?', 'No: conversion truncates toward zero. Python has int, float, and complex numbers.', 'print(int(-6.8))', '-6'],
    ['Text conversion', 'How do you join text and a number?', 'Convert the number with str, or use an f-string.', 'print("Level " + str(3))', 'Level 3'],
    ['Collections', 'How is a list different from a dictionary?', 'A list holds a sequence; a dictionary maps keys to values.', 'gear = ["map", "torch"]\nprint(len(gear))', '2'],
    ['Unpacking', 'Can one line assign two names?', 'Yes. Match the number of names and values.', 'wins, losses = 3, 1\nprint(wins + losses)', '4'],
    ['Number tools', 'How do you total a collection?', 'sum adds numeric items. min and max find extremes; sorted makes a sorted list.', 'print(sum([2, 4, 6]))', '12']
  ];
  // [mode, question, choices, correct index, explanation]
  const questions = [
    ['Output sprint','stars = 7; print(stars + 2)', ['7','9','72'],1,'Assignment supplies 7; addition produces 9.'],
    ['Output sprint','print(len("comet"))',['4','5','6'],1,'There are five characters.'],
    ['Output sprint','print("3" + "4")',['7','34','Error'],1,'Two strings concatenate.'],
    ['Output sprint','print(int("3") + 4)',['34','Error','7'],2,'Convert text to an integer before adding.'],
    ['Output sprint','print(int(5.9))',['6','5','5.9'],1,'int truncates; it does not round.'],
    ['Output sprint','print(int(-5.9))',['-6','-5','5'],1,'Truncation moves toward zero.'],
    ['Output sprint','print(float("2.5") * 2)',['5.0','2.52','Error'],0,'The converted float supports multiplication.'],
    ['Output sprint','a, b = 2, 5; print(a + b)',['25','7','2'],1,'Unpacking binds a and b separately.'],
    ['Output sprint','print(sum([3, 2, 4]))',['3','9','24'],1,'sum adds every item.'],
    ['Output sprint','print(sorted([3, 1, 2]))',['[1, 2, 3]','[3, 2, 1]','6'],0,'sorted returns a new ascending list.'],
    ['Type detective','What is the type of "9"?',['int','str','float'],1,'Quotes make this value text.'],
    ['Type detective','What is the type of 9.0?',['int','str','float'],2,'The decimal literal is a float.'],
    ['Type detective','What is the type of False?',['bool','str','list'],0,'False is a Boolean literal.'],
    ['Type detective','What does input return when someone types 9?',['int','str','float'],1,'input returns a string, even for digits.'],
    ['Type detective','Which value is a dictionary?',['[1, 2]','{"score": 2}','(1, 2)'],1,'A dictionary associates keys with values.'],
    ['Type detective','Which value is a tuple?',['(1, 2)','[1, 2]','{"x": 2}'],0,'The comma-separated parenthesized pair is a tuple.'],
    ['Type detective','Which value is complex?',['2.5','2 + 3j','"3j"'],1,'j marks the imaginary component of a numeric literal.'],
    ['Type detective','What does list("go") produce?',['["go"]','["g", "o"]','2'],1,'list collects each character from the string.'],
    ['Bug rescue','Which is a valid, readable variable name?',['2score','player-score','player_score'],2,'Underscores join words; a name cannot start with a digit.'],
    ['Bug rescue','What happens with int("6.8")?',['6','7','ValueError'],2,'Decimal text is not a valid integer string. Use float first when appropriate.'],
    ['Bug rescue','Which line compares two values?',['score = 4','score == 4','score => 4'],1,'== compares; = assigns.'],
    ['Bug rescue','Why avoid len = 8?',['It shadows a built-in','Digits are forbidden in values','It imports a module'],0,'The assignment replaces access to len through that name in the current scope.'],
    ['Bug rescue','Which version joins a label and a number?',['"HP " + 8','"HP " + str(8)','int("HP ") + 8'],1,'Concatenation requires two strings.'],
    ['Bug rescue','What happens with x, y = 1, 2, 3?',['x becomes 6','ValueError','y becomes 3'],1,'There are more values than target names.'],
    ['Bug rescue','Which call lists Python keywords interactively?',['help("keywords")','file("keywords")','print = keywords'],0,'help is built in. file() is not a Python 3 built-in.']
  ];
  const key = 'stacksprint-python-v1';
  const remixBriefs = ['Invent a name and value for something in your own game; print it.', 'Create a descriptive snake_case variable for your own project and print it.', 'Print your own launch message and a number.', 'Use len to measure your own word.', 'Use type to inspect a different value and print its type name.', 'Convert your own numeric string with int and calculate something.', 'Convert your own decimal string using float then int.', 'Convert your own decimal number with int. Predict truncation.', 'Join your own label with a number using str.', 'Create your own list of items and print its length.', 'Unpack your own pair of values into two names; print a result.', 'Use sum to total your own list of numbers.'];
  let saved = {};
  try { saved = JSON.parse(localStorage.getItem(key) || '{}') || {}; } catch (_) {}
  const learned = new Set(Array.isArray(saved.learned) ? saved.learned.filter(n => Number.isInteger(n) && n >= 0 && n < cards.length) : []);
  let best = saved.best && typeof saved.best === 'object' ? saved.best : {};
  const remixed = new Set(Array.isArray(saved.remixed) ? saved.remixed : []);
  const drafts = saved.drafts && typeof saved.drafts === 'object' ? saved.drafts : {};
  let busy = false;
  let index = 0, revealed = false, mode = 'Flashcards', queue = [], position = 0, score = 0, missed = [], answered = false, finished = false;
  const host = document.getElementById('python-course');
  const escape = value => String(value).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const button = (label, action) => `<button type="button" data-py="${action}">${label}</button>`;
  function save() { try { localStorage.setItem(key, JSON.stringify({learned:[...learned],remixed:[...remixed],drafts,best})); } catch (_) { host.querySelector('[role="status"]').textContent += ' Browser storage is unavailable; progress lasts for this session.'; } }
  function render() {
    host.innerHTML = `<p class="overline">Python essentials · Day 2 practice</p><h2>Small concepts. Big possibilities.</h2><p>Learn → recreate → create → run. ${learned.size}/${cards.length} cards practiced.</p><nav aria-label="Python practice modes">${['Flashcards','Output sprint','Type detective','Bug rescue','Full quiz'].map(m => `<button type="button" data-mode="${m}" aria-pressed="${m === mode}">${m}</button>`).join('')}</nav><div class="py-content"></div><p role="status" aria-live="polite"></p><details><summary>Lesson sources & Python 3 notes</summary><p>Original practice activities inspired by <a href="https://github.com/Asabeneh/30-Days-Of-Python/blob/master/02_Day_Variables_builtin_functions/02_variables_builtin_functions.md" target="_blank" rel="noopener">Asabeneh Yetayeh’s Day 2 lesson</a>. Checked against the <a href="https://docs.python.org/3/library/functions.html" target="_blank" rel="noopener">Python built-in reference</a>. Decimal text needs float conversion before int truncation; file() is not a Python 3 built-in. Recreate the example, then run a creative variation in the browser with Pyodide. Internet is required for the interpreter download.</p></details>`;
    const body = host.querySelector('.py-content');
    if (mode === 'Flashcards') {
      const c = cards[index];
      body.innerHTML = `<p>Card ${index + 1} / ${cards.length} ${learned.has(index) ? '· Practiced ✓' : ''}</p><h3>${escape(c[0])}</h3><p>${escape(c[1])}</p>${revealed ? `<p>${escape(c[2])}</p><pre><code>${escape(c[3])}</code></pre><p>Read it aloud, then type the example below. Spaces and newlines must match; outer whitespace is ignored.</p><label>Python code<textarea id="py-code" spellcheck="false" autocapitalize="off" autocomplete="off" rows="4"></textarea></label><label>Predict the printed output<input id="py-output" autocomplete="off"></label>${button('Check code & prediction','check')}` : button('Reveal & practice','reveal')}<div class="py-actions">${button('← Previous','previous')}${button('Next →','next')}</div><p>Complete both checkpoints: recreate the example, then run your own variation with a correct output prediction. Shift+Tab leaves the code editor.</p>`;
      body.querySelector('[data-py="previous"]').disabled = index === 0;
      if(revealed && learned.has(index)) {
        body.insertAdjacentHTML('beforeend', `<h3>2. Make it yours ${remixed.has(index) ? '✓' : ''}</h3><p>${escape(remixBriefs[index])}</p><p>Write a different example using the same concept. This runs real Python. Internet is needed to load the interpreter; simple expressions and lesson built-ins are supported, not imports or loops.</p><label>Your creative code<textarea id="py-remix" spellcheck="false" autocapitalize="off" rows="6">${escape(drafts[index] || '')}</textarea></label><label>Predict your output<textarea id="py-remix-output" rows="2"></textarea></label>${button('Run my Python & check','remix')}<pre id="py-console" aria-live="polite">Your output will appear here.</pre>`);
      }
      body.querySelector('[data-py="next"]').disabled = !remixed.has(index) || index === cards.length - 1;
    } else if (finished) {
      body.innerHTML = `<h3>${score === queue.length ? 'Perfect recall!' : 'Round complete — keep growing.'}</h3><p>${score} / ${queue.length} correct on the first try.</p><p>Best ${escape(mode)} score: ${Number(best[mode]) || 0}</p>${missed.length ? button(`Practice ${missed.length} missed questions`,'missed') : '<p>You answered every question correctly.</p>'}${button('Play again','restart')}`;
    } else {
      const q = questions[queue[position]];
      body.innerHTML = `<p>${escape(mode)} · ${position + 1} / ${queue.length} · Score ${score}</p><progress value="${position}" max="${queue.length}" aria-label="Round progress"></progress><h3>${escape(q[1])}</h3><div class="py-choices">${q[2].map((v,i) => `<button type="button" data-answer="${i}">${escape(v)}</button>`).join('')}</div>${button('Next question →','advance')}`;
      body.querySelector('[data-py="advance"]').disabled = true;
    }
  }
  function start(ids) {
    queue = [...ids];
    for (let i=queue.length-1;i>0;i--) { const j=Math.floor(Math.random()*(i+1)); [queue[i],queue[j]]=[queue[j],queue[i]]; }
    position=0;score=0;missed=[];answered=false;finished=false;render();
  }
  const ids = () => questions.map((q,i) => mode === 'Full quiz' || q[0] === mode ? i : -1).filter(i => i >= 0);
  host.addEventListener('input', event => { if(event.target.id === 'py-remix'){drafts[index]=event.target.value;save();} });
  host.addEventListener('keydown', event => {if(event.target.tagName==='TEXTAREA' && event.key==='Tab' && !event.shiftKey){event.preventDefault();event.target.setRangeText('    ',event.target.selectionStart,event.target.selectionEnd,'end');event.target.dispatchEvent(new Event('input',{bubbles:true}));} });
  host.addEventListener('click', async event => {
    const target = event.target.closest('button'); if (!target || target.disabled) return;
    if(busy) return;
    if (target.dataset.mode) { mode=target.dataset.mode; if(mode==='Flashcards')render();else start(ids()); return; }
    if (target.dataset.answer !== undefined && !answered) {
      answered=true; const q=questions[queue[position]], correct=Number(target.dataset.answer)===q[3];
      if(correct)score++;else missed.push(queue[position]);
      host.querySelectorAll('[data-answer]').forEach(b => { b.disabled=true; if(Number(b.dataset.answer)===q[3]) b.classList.add('py-correct'); });
      host.querySelector('[role="status"]').textContent = `${correct ? 'Correct!' : `Not quite. Answer: ${q[2][q[3]]}.`} ${q[4]}`;
      host.querySelector('[data-py="advance"]').disabled=false; return;
    }
    switch(target.dataset.py) {
      case 'reveal': revealed=true;render();break;
      case 'check': {
        const c=cards[index], code=host.querySelector('#py-code').value.trim().replace(/\r\n/g,'\n'), output=host.querySelector('#py-output').value.trim();
        if(code===c[3] && output===c[4]) { learned.add(index); render(); host.querySelector('[role="status"]').textContent='Example recreated! Now write and run your own version below to unlock the next lesson.';save(); }
        else host.querySelector('[role="status"]').textContent=code!==c[3]?'Match the example exactly, including quotes, spaces, and line breaks.':'Code matches. Trace each expression again to predict the printed output.';
        break;
      }
      case 'previous': if(index>0){index--;revealed=false;render();}break;
      case 'next': if(remixed.has(index)&&index<cards.length-1){index++;revealed=false;render();}break;
      case 'remix': {
        const code=host.querySelector('#py-remix').value.trim(), prediction=host.querySelector('#py-remix-output').value.trim();
        const log=host.querySelector('#py-console');
        if(!code || code===cards[index][3]){log.textContent='Change the values or names to make a genuinely different example.';break;}
        busy=true;target.disabled=true;log.textContent='Loading Python and running your code…';
        try {
          const result=await window.StackSprintPython(code,index);
          log.textContent=result.output || '(No output)';
          if(!result.concept) log.textContent+='\nKeep the lesson concept: '+remixBriefs[index];
          else if(result.output!==prediction) log.textContent+='\nYour prediction differs. Read the result, revise your prediction, and run again.';
          else {remixed.add(index);save();host.querySelector('[data-py="next"]').disabled=index===cards.length-1;log.textContent+='\nCreative checkpoint passed! '+(remixed.size===cards.length?'All 12 creative lessons complete!':'Next lesson unlocked.');}
        } catch(error){log.textContent=error.message;}
        finally{busy=false;target.disabled=false;}
        break;
      }
      case 'advance': if(!answered)return;position++;answered=false;if(position===queue.length){finished=true;best[mode]=Math.max(Number(best[mode])||0,score);render();save();}else render();break;
      case 'restart': start(ids());break;
      case 'missed': start(missed);break;
    }
  });
  render();
})();
