/* Executable lessons. The same functions checked here power the finished game. */
(() => {
  const definitions = [];
  function add(mode, initial, body, win, checks, lesson) {
    definitions.push({ mode, initial, body, win, checks, lesson });
  }
  add('tap', {score:0,target:8,x:2,y:2},
    'if (action.type === "tap") { s.score += 1; s.x = (s.x + 3) % 7; s.y = (s.y + 2) % 5; }',
    'state.score >= state.target',
    ['s.score === 0 && s.target === 8','update(s,{type:"tap"}).score === 1 && update({...s,score:4},{type:"tap"}).score === 5'],
    'Connect one tap to one point. Move the star using remainder (%) so it stays inside the board.');
  add('guess', {score:0,target:1,secret:7,message:'Guess a number from 1 to 10.'},
    'if (action.type === "guess") { const n = Number(action.value); s.message = n < s.secret ? "Too low" : n > s.secret ? "Too high" : "Found it!"; if (n === s.secret) s.score = 1; }',
    'state.score === 1', ['s.secret === 7 && s.score === 0','update(s,{type:"guess",value:7}).score === 1 && update(s,{type:"guess",value:3}).message === "Too low" && update(s,{type:"guess",value:9}).message === "Too high"'],
    'Use Number() to read input and compare it with the secret. Use a fixed secret while learning; remix it with randomness later.');
  add('reaction', {score:0,target:3,ready:false,message:'Wait for green.'},
    'if (action.type === "ready") { s.ready = true; s.message = "GO!"; } if (action.type === "tap") { if (s.ready) { s.score += 1; s.message = "Nice reaction!"; } else { s.message = "Too soon!"; } s.ready = false; }',
    'state.score >= 3', ['s.ready === false && s.score === 0','update(s,{type:"tap"}).score === 0 && update(update(s,{type:"ready"}),{type:"tap"}).score === 1'],
    'A boolean protects the score: reward a tap only after the green signal. The game schedules the signal for you.');
  add('coins', {score:0,target:12,energy:12},
    'if (action.type === "tap" && s.energy > 0) { s.score += 1; s.energy -= 1; }',
    'state.score >= 12', ['s.energy === 12 && s.score === 0','update(s,{type:"tap"}).energy === 11 && update({...s,energy:0},{type:"tap"}).score === 0'],
    'Spend exactly one energy for one coin. Guard the action when the energy reaches zero.');
  add('maze', {score:0,target:1,x:0,y:0,size:5,walls:[6,7,11,17],goal:24},
    'if (action.type === "move") { const x = Math.max(0,Math.min(4,s.x + action.dx)); const y = Math.max(0,Math.min(4,s.y + action.dy)); if (!s.walls.includes(y*5+x)) { s.x=x; s.y=y; } if (s.y*5+s.x === s.goal) s.score=1; }',
    'state.score === 1', ['s.x === 0 && s.goal === 24 && s.walls.includes(6)','update(s,{type:"move",dx:-1,dy:0}).x === 0 && update({...s,x:1,y:0},{type:"move",dx:0,dy:1}).y === 0 && update({...s,x:3,y:4},{type:"move",dx:1,dy:0}).score === 1'],
    'Clamp the next position, reject walls, then check the exit. A position becomes a tile number with y * 5 + x.');
  add('memory', {score:0,target:4,cards:['🌙','⭐','🌿','☀️','⭐','☀️','🌙','🌿'],open:[],matched:[]},
    'if (action.type === "flip" && !s.matched.includes(action.index)) { if (s.open.length === 2) s.open=[]; if (!s.open.includes(action.index)) s.open.push(action.index); if (s.open.length === 2 && s.cards[s.open[0]] === s.cards[s.open[1]]) { s.matched.push(...s.open); s.open=[]; s.score += 1; } }',
    'state.score >= 4', ['s.cards.length === 8 && s.matched.length === 0','update(update(s,{type:"flip",index:0}),{type:"flip",index:6}).score === 1 && update(update(s,{type:"flip",index:0}),{type:"flip",index:1}).score === 0'],
    'Remember two selected indexes. A matching pair scores once and stays revealed. A mismatch clears on the next turn.');
  add('rps', {score:0,target:3,message:'Pebble beats leaf, leaf beats cloud, cloud beats pebble.'},
    'if (action.type === "choose") { const beats={pebble:"leaf",leaf:"cloud",cloud:"pebble"}; if (beats[action.value] === action.opponent) { s.score++; s.message="You win this round!"; } else { s.message=action.value === action.opponent ? "A tie!" : "Try the next round."; } }',
    'state.score >= 3', ['s.score === 0 && s.target === 3','update(s,{type:"choose",value:"pebble",opponent:"leaf"}).score === 1 && update(s,{type:"choose",value:"pebble",opponent:"cloud"}).score === 0'],
    'Model the rules with a lookup object. Score only a win, not a tie or a loss.');
  add('gopher', {score:0,target:6,hole:0},
    'if (action.type === "hit" && action.index === s.hole) { s.score++; s.hole=(s.hole+4)%9; }',
    'state.score >= 6', ['s.hole === 0 && s.target === 6','update(s,{type:"hit",index:0}).score === 1 && update(s,{type:"hit",index:1}).score === 0'],
    'Compare the clicked hole to the occupied hole. Move the gopher only after a valid hit.');
  add('quiz', {score:0,target:3,index:0,answers:[1,0,2],message:'Choose the correct web concept.'},
    'if (action.type === "answer") { if (action.index === s.answers[s.index]) { s.score++; s.index++; s.message="Correct!"; } else s.message="Try again — think about the job of each language."; }',
    'state.score >= 3', ['s.index === 0 && s.answers.length === 3','update(s,{type:"answer",index:1}).index === 1 && update(s,{type:"answer",index:0}).index === 0'],
    'Use the current question index to look up its answer. Advance the question only on a correct choice.');
  add('story', {score:0,target:3,node:0,message:'A lighthouse has gone dark. What will you do?'},
    'if (action.type === "choose") { if (action.value === "help") { s.node++; s.score++; s.message=["Find the keeper.","Carry the lantern upstairs.","The ships can see the shore again!"][Math.min(s.node-1,2)]; } else s.message="Take a breath. The lighthouse still needs you."; }',
    'state.node >= 3', ['s.node === 0 && s.score === 0','update(s,{type:"choose",value:"help"}).node === 1 && update(s,{type:"choose",value:"wait"}).node === 0'],
    'A story can be a state machine: a helpful decision moves to a new scene while waiting keeps the same scene.');
  add('dice', {score:0,target:20,lastRoll:0},
    'if (action.type === "roll" && action.value >= 1 && action.value <= 6) { s.lastRoll=action.value; s.score += action.value; }',
    'state.score >= state.target', ['s.score === 0 && s.target === 20','update(s,{type:"roll",value:6}).score === 6 && update(s,{type:"roll",value:0}).score === 0'],
    'Validate the die range before changing state. The renderer supplies a random roll; your function applies it.');
  add('typing', {score:0,target:3,words:['const','return','function'],index:0,message:'Type the highlighted word.'},
    'if (action.type === "type") { if (action.value.trim() === s.words[s.index]) { s.score++; s.index++; s.message="Word cleared!"; } else s.message="Check the spelling and try again."; }',
    'state.score >= 3', ['s.words[0] === "const" && s.index === 0','update(s,{type:"type",value:" const "}).score === 1 && update(s,{type:"type",value:"cost"}).score === 0'],
    'trim() tolerates accidental spaces. Exact word matching still protects the learning goal.');
  add('garden', {score:0,target:10,seeds:0,flowers:0},
    'if (action.type === "plant") s.seeds++; if (action.type === "water" && s.seeds > 0) { s.seeds--; s.flowers++; s.score += 2; }',
    'state.flowers >= 5', ['s.seeds === 0 && s.flowers === 0','update(s,{type:"water"}).score === 0 && update(update(s,{type:"plant"}),{type:"water"}).flowers === 1'],
    'Create a two-action loop. Planting adds inventory; watering consumes a seed and grows a flower.');
  add('sequence', {score:0,target:4,sequence:[0,2,1,3],index:0,message:'Repeat: blue, mint, coral, violet.'},
    'if (action.type === "tone") { if (action.index === s.sequence[s.index]) { s.index++; s.score++; s.message="Keep going!"; } else { s.index=0; s.score=0; s.message="Start the sequence again."; } }',
    'state.index === 4', ['s.sequence.join() === "0,2,1,3" && s.index === 0','update(s,{type:"tone",index:0}).index === 1 && update({...s,index:1,score:1},{type:"tone",index:3}).score === 0'],
    'Compare each press with the next expected item. Reset the sequence after a mistake so a win means a complete pattern.');
  add('color', {score:0,target:6,color:0,colors:['Blue','Coral','Mint']},
    'if (action.type === "catch") { if (action.index === s.color) { s.score++; s.color=(s.color+1)%3; } }',
    'state.score >= 6', ['s.colors.length === 3 && s.color === 0','update(s,{type:"catch",index:0}).score === 1 && update(s,{type:"catch",index:1}).score === 0'],
    'Cycle through three labeled colors. Match by index and include words so the game is not color dependent.');
  add('draw', {score:0,target:8,points:[]},
    'if (action.type === "draw") { s.points.push({x:action.x,y:action.y}); s.score=s.points.length; } if (action.type === "clear") { s.points=[]; s.score=0; }',
    'state.points.length >= 8', ['Array.isArray(s.points) && s.points.length === 0','update(s,{type:"draw",x:2,y:3}).points[0].x === 2 && update({...s,points:[{x:1,y:1}],score:1},{type:"clear"}).score === 0'],
    'Store coordinates in an array. The canvas draws your data, so clearing the array really clears the artwork.');
  add('snake', {score:0,target:4,size:7,body:[{x:1,y:1}],food:{x:2,y:1},message:'Arrow buttons move one tile.'},
    'if (action.type === "move") { const head={x:(s.body[0].x+action.dx+7)%7,y:(s.body[0].y+action.dy+7)%7}; if (s.body.some(p=>p.x===head.x && p.y===head.y)) { s.message="Oops! Restart to try again."; return s; } s.body.unshift(head); if (head.x===s.food.x && head.y===s.food.y) { s.score++; s.food={x:(s.food.x+2)%7,y:(s.food.y+3)%7}; } else s.body.pop(); }',
    'state.score >= 4', ['s.body.length === 1 && s.food.x === 2','update(s,{type:"move",dx:1,dy:0}).body.length === 2 && update(s,{type:"move",dx:0,dy:1}).body.length === 1'],
    'Prepend a head and remove a tail on normal moves. Keep the tail when food is collected to grow the snake.');
  add('pong', {score:0,target:5,x:3,y:1,dx:1,dy:1,paddle:3,size:7,message:'Move the paddle, then advance the ball.'},
    'if (action.type === "paddle") s.paddle=Math.max(0,Math.min(6,s.paddle+action.dx)); if (action.type === "tick") { s.x+=s.dx; s.y+=s.dy; if (s.x<=0 || s.x>=6) s.dx*=-1; if (s.y<=0) s.dy=1; if (s.y>=5) { if (Math.abs(s.x-s.paddle)<=1) { s.dy=-1; s.score++; } else { s.y=1; s.message="Missed — line up the paddle!"; } } }',
    'state.score >= 5', ['s.paddle === 3 && s.dy === 1','update({...s,x:5,dx:1},{type:"tick"}).dx === -1 && update({...s,x:2,y:4,dy:1,paddle:3},{type:"tick"}).score === 1'],
    'Reverse velocity at a wall. A paddle collision earns a point and sends the ball back up. This turn-based prototype makes each physics step visible.');
  add('breakout', {score:0,target:5,bricks:[0,1,2,3,4],aim:2},
    'if (action.type === "aim") s.aim=Math.max(0,Math.min(4,s.aim+action.dx)); if (action.type === "launch" && s.bricks.includes(s.aim)) { s.bricks=s.bricks.filter(n=>n!==s.aim); s.score++; }',
    'state.bricks.length === 0', ['s.bricks.length === 5 && s.aim === 2','update(s,{type:"launch"}).bricks.length === 4 && update({...s,bricks:[]},{type:"launch"}).score === 0'],
    'Build a turn-based Breakout prototype: aim, launch, and remove only the brick in that lane with filter().');
  add('platform', {score:0,target:4,x:0,jumping:false,coins:[1,3,5,7],message:'Jump before moving onto a coin.'},
    'if (action.type === "jump") s.jumping=true; if (action.type === "move") { s.x=Math.max(0,Math.min(8,s.x+action.dx)); if (s.jumping && s.coins.includes(s.x)) { s.coins=s.coins.filter(n=>n!==s.x); s.score++; } s.jumping=false; }',
    'state.coins.length === 0', ['s.coins.length === 4 && s.x === 0','update(update(s,{type:"jump"}),{type:"move",dx:1}).score === 1 && update(s,{type:"move",dx:1}).score === 0'],
    'Track jumping as state, then consume it on the next move. A coin disappears only when reached in the air.');
  add('runner', {score:0,target:10,lane:1,distance:0,obstacle:0,message:'Change lanes, then run a step.'},
    'if (action.type === "lane") s.lane=Math.max(0,Math.min(2,s.lane+action.dx)); if (action.type === "tick") { if (s.lane !== s.obstacle) { s.score++; s.distance++; s.obstacle=(s.obstacle+1)%3; } else s.message="Obstacle ahead! Change lanes."; }',
    'state.distance >= 10', ['s.lane === 1 && s.distance === 0','update(s,{type:"tick"}).distance === 1 && update({...s,lane:0},{type:"tick"}).distance === 0'],
    'Make a forgiving endless-runner prototype. A safe lane advances distance; a blocked lane asks the player to dodge.');
  add('dodge', {score:0,target:8,lane:1,obstacle:2,distance:0,message:'Avoid the asteroid lane.'},
    'if (action.type === "lane") s.lane=Math.max(0,Math.min(2,s.lane+action.dx)); if (action.type === "tick") { if (s.lane !== s.obstacle) { s.score++; s.distance++; s.obstacle=(s.obstacle+2)%3; } else { s.score=Math.max(0,s.score-1); s.message="Shield hit! Try another lane."; } }',
    'state.score >= 8', ['s.obstacle === 2 && s.score === 0','update(s,{type:"tick"}).score === 1 && update({...s,lane:2,score:2},{type:"tick"}).score === 1'],
    'Subtract one on a collision without allowing negative scores. Keep challenge readable with a visible asteroid lane.');
  add('defense', {score:0,target:5,energy:2,shields:0,message:'Grow energy, then protect a sprout.'},
    'if (action.type === "grow") s.energy++; if (action.type === "protect" && s.energy>=2) { s.energy-=2; s.shields++; s.score++; }',
    'state.shields >= 5', ['s.energy === 2 && s.shields === 0','update(s,{type:"protect"}).energy === 0 && update({...s,energy:1},{type:"protect"}).shields === 0'],
    'Model a tiny strategy economy. The cost check must happen before spending energy or awarding a shield.');
  add('slide', {score:0,target:1,tiles:[1,2,3,4,5,6,0,7,8]},
    'if (action.type === "slide") { const z=s.tiles.indexOf(0), i=action.index; const adjacent=Math.abs(Math.floor(z/3)-Math.floor(i/3))+Math.abs(z%3-i%3)===1; if (adjacent) [s.tiles[z],s.tiles[i]]=[s.tiles[i],s.tiles[z]]; if (s.tiles.join() === "1,2,3,4,5,6,7,8,0") s.score=1; }',
    'state.tiles.join() === "1,2,3,4,5,6,7,8,0"', ['s.tiles.length === 9 && s.tiles[6] === 0','update(s,{type:"slide",index:0}).tiles[0] === 1 && update(update(s,{type:"slide",index:7}),{type:"slide",index:8}).score === 1'],
    'Use Manhattan distance to allow only neighboring tiles. Swap the blank, then compare the full solved arrangement.');
  add('word', {score:0,target:1,word:'CODE',guessed:[],message:'Light up the four-letter coding word.'},
    'if (action.type === "letter") { const c=action.value.toUpperCase(); if (!s.guessed.includes(c)) s.guessed.push(c); if ([...s.word].every(c=>s.guessed.includes(c))) s.score=1; }',
    '[...state.word].every(c=>state.guessed.includes(c))', ['s.word === "CODE" && s.guessed.length === 0','update(s,{type:"letter",value:"c"}).guessed.includes("C") && update({...s,guessed:["C","O","D"]},{type:"letter",value:"e"}).score === 1'],
    'Normalize case and avoid duplicate guesses. every() checks whether all letters have been discovered.');
  add('rhythm', {score:0,target:5,ready:false,message:'Tap when the raindrop lights up.'},
    'if (action.type === "ready") { s.ready=true; s.message="BEAT!"; } if (action.type === "tap") { if (s.ready) { s.score++; s.message="On the beat!"; } else s.message="Listen to the visual rhythm."; s.ready=false; }',
    'state.score >= 5', ['s.ready === false && s.target === 5','update(update(s,{type:"ready"}),{type:"tap"}).score === 1 && update(s,{type:"tap"}).score === 0'],
    'Use the visual beat as a timing window. A valid tap consumes the beat so it cannot score twice.');
  add('coop', {score:0,target:4,left:false,right:false,message:'Player one: A. Player two: L.'},
    'if (action.type === "left") s.left=true; if (action.type === "right") s.right=true; if (s.left && s.right) { s.score++; s.left=false; s.right=false; }',
    'state.score >= 4', ['s.left === false && s.right === false','update(s,{type:"left"}).score === 0 && update(update(s,{type:"left"}),{type:"right"}).score === 1'],
    'Two players contribute to one shared turn. Award a point only when both signals arrive, then reset the pair.');
  add('save', {score:0,target:3,savedScore:0,message:'Collect, save a checkpoint, then restore it.'},
    'if (action.type === "tap") s.score++; if (action.type === "save") { s.savedScore=s.score; s.message="Checkpoint saved for this play session."; } if (action.type === "restore") s.score=s.savedScore;',
    'state.savedScore >= 3', ['s.savedScore === 0 && s.score === 0','update({...s,score:2},{type:"save"}).savedScore === 2 && update({...s,score:4,savedScore:2},{type:"restore"}).score === 2'],
    'Separate live state from a saved snapshot. This exercise teaches the model before persistent storage; the app saves your source separately.');
  add('accessible', {score:0,target:5,label:'Collect a star',message:'Use Tab and Enter or tap the star.'},
    'if (action.type === "tap") { s.score++; s.message="Collected "+s.score+" of "+s.target+" stars."; }',
    'state.score >= 5', ['s.label === "Collect a star" && s.target === 5','update(s,{type:"tap"}).message === "Collected 1 of 5 stars." && update({...s,score:3},{type:"tap"}).score === 4'],
    'A semantic button already supports keyboard activation. Update readable status after every action for the live region.');
  add('showcase', {score:0,target:3,stars:0,flowers:0,title:'My Pocket Arcade',message:'Collect stars and grow flowers.'},
    'if (action.type === "tap") { s.stars++; s.score++; } if (action.type === "plant") { s.flowers++; s.score++; }',
    'state.stars >= 2 && state.flowers >= 1', ['s.title === "My Pocket Arcade" && s.stars === 0','update(s,{type:"tap"}).stars === 1 && update(s,{type:"plant"}).flowers === 1'],
    'Combine two interactions into your first showcase. The finish condition must check both features, not just the total score.');

  const designRules = [
    [['.arena','background-color','#172554'],['.target','background-color','#facc15'],['.arena','color','#ffffff']],
    [['button','min-height','48px'],['button','border-radius','16px'],['button','font-weight','700']],
    [['.controls','gap','12px'],['button','font-size','16px'],['.instructions','display','block']],
    [['.arena','background-color','#2e1065'],['.target','border-radius','50%'],['h1','letter-spacing','2px']],
    [['.hud','display','flex'],['.hud','justify-content','space-between'],['.board','padding','16px']],
    [['h1','font-size','28px'],['.instructions','line-height','24px'],['.score','font-weight','700']],
    [['.instructions','font-size','18px'],['.instructions','padding','16px'],['button','min-height','48px']],
    [['.arena','color','#ffffff'],['.arena','background-color','#111827'],['button','outline-width','3px']],
    [['.controls','display','flex'],['.controls','flex-wrap','wrap'],['.controls','gap','16px']],
    [['.score','font-size','24px'],['.score','font-weight','700'],['.hud','padding','16px']],
    [['.tile','border-radius','8px'],['.board','gap','8px'],['.tile','min-height','48px']],
    [['.target','font-size','32px'],['.target','border-radius','24px'],['.target','border-width','3px']],
    [['.message','font-size','18px'],['.message','padding','16px'],['.message','border-left-width','4px']],
    [['.target','transition-duration','0.2s'],['.target','border-radius','50%'],['.target','min-height','56px']],
    [['.instructions','max-width','480px'],['.instructions','line-height','28px'],['button','text-align','left']],
    [['.board','gap','12px'],['.tile','font-size','24px'],['.tile','border-width','2px']],
    [['.board','padding','24px'],['.tile','min-height','44px'],['.hud','margin-bottom','16px']],
    [['.instructions','font-weight','700'],['button','min-height','52px'],['.controls','gap','16px']],
    [['.score','color','#facc15'],['.score','font-size','28px'],['.message','font-weight','700']],
    [['.board','gap','10px'],['.tile','border-radius','50%'],['.tile','border-width','3px']],
    [['.hud','display','flex'],['.hud','gap','20px'],['.score','font-size','24px']],
    [['.message','border-width','3px'],['.message','padding','20px'],['.target','min-height','64px']],
    [['.score','padding','12px'],['.score','border-radius','12px'],['.controls','gap','12px']],
    [['.controls','justify-content','space-around'],['button','min-width','64px'],['button','min-height','56px']],
    [['button','min-height','56px'],['.controls','gap','16px'],['.arena','padding','16px']],
    [['button','outline-width','3px'],['button','outline-offset','4px'],['.instructions','font-size','18px']],
    [['.instructions','line-height','26px'],['.message','font-size','16px'],['button','min-height','48px']],
    [['.message','font-size','18px'],['.controls','gap','20px'],['button','font-weight','700']],
    [['.instructions','padding','20px'],['.score','font-size','24px'],['.target','min-height','56px']],
    [['h1','font-size','30px'],['.arena','background-color','#172554'],['button','min-height','48px']]
  ];

  function source(d, complete) {
    return `// Your functions power this game. Change one function at a time.\n// ${d.lesson}\n\nfunction createState() {\n  ${complete ? 'return '+JSON.stringify(d.initial,null,2).replace(/\n/g,'\n  ')+';' : '// TODO 1: return the starting state shown in the lesson.\n  return {};'}\n}\n\nfunction update(state, action) {\n  const s = structuredClone(state);\n  ${complete ? d.body : '// TODO 2: update s when the player sends an action.'}\n  return s;\n}\n\nfunction isComplete(state) {\n  ${complete ? 'return '+d.win+';' : '// TODO 3: return true only when the winning condition is met.\n  return false;'}\n}\n`;
  }
  function build(index, project) {
    const d=definitions[index];
    const finishSamples = [structuredClone(d.initial), {...structuredClone(d.initial),score:999,target:d.initial.target,node:3,distance:10,flowers:5,shields:5,index:4,stars:2,savedScore:3,points:Array.from({length:8},()=>({x:1,y:1})),bricks:[],coins:[],tiles:[1,2,3,4,5,6,7,8,0],guessed:['C','O','D','E']}];
    if (index===1 || index===4) finishSamples[1].score=1;
    return {id:project.id,track:'building',title:project.title,mode:d.mode,description:d.lesson,starter:source(d,false),solution:source(d,true),
      tasks:[
        {title:'Create the starting state',instructions:'Return this object from createState(). It holds the data your game needs before the first move.',hint:'return '+JSON.stringify(d.initial,null,2)+';'},
        {title:'Code the player interaction',instructions:d.lesson+' Add this logic inside update(), before return s. Read it, type it, and try changing a value after passing.',hint:d.body},
        {title:'Define the finish line',instructions:'Return a boolean from isComplete(). A fresh game must be unfinished and a winning state must be finished.',hint:'return '+d.win+';'}
      ],tests:[{name:'Starting state',body:'const s=createState(), expected='+JSON.stringify(d.initial)+'; return Object.keys(expected).every(key => JSON.stringify(s[key]) === JSON.stringify(expected[key])) && ('+d.checks[0]+');'},
        {name:'Interaction and edge case',body:'const s=createState(); return '+d.checks[1]+';'},
        {name:'Win and not-yet-win states',body:'return isComplete('+JSON.stringify(finishSamples[0])+') === false && isComplete('+JSON.stringify(finishSamples[1])+') === true;'}]};
  }
  function get(track,id) {
    const projects=gameProjectTracks[track].projects,index=projects.findIndex(p=>p.id===id),project=projects[index];
    if (!project) throw Error('Unknown mission');
    if(track==='building') return build(index,gameProjectTracks.building.projects[index]);
    const designPartners=[0,0,8,21,4,11,12,28,9,10,23,19,13,12,9,23,4,20,0,4,20,22,12,26,20,28,1,12,5,29];
    const game=build(designPartners[index],gameProjectTracks.building.projects[designPartners[index]]);
    const rules=designRules[index];
    return {id,track,title:project.title,mode:game.mode,buildId:game.id,description:project.brief+' Style a playable '+game.title+' prototype. Your CSS changes the actual game interface.',
      starter:'/* Design '+project.title+' with real CSS. */\n/* Implement each of the three studio requirements below. */\n\n'+rules.map(([selector,prop])=>selector+' {\n  /* TODO: '+prop+' */\n}').join('\n\n'),
      solution:rules.map(([selector,prop,value])=>selector+' { '+prop+': '+value+'; }').join('\n'),gameCode:game.solution,
      tasks:rules.map(([selector,prop,value],i)=>({title:['Set the visual foundation','Shape the interaction','Polish for the player'][i],instructions:`Select ${selector} and set ${prop} to ${value}. Then run the checks to see the change in the design preview.`,hint:selector+' { '+prop+': '+value+'; }'})),
      tests:rules.map(([selector,property,value])=>({name:selector+' · '+property,selector,property,value}))};
  }
  window.StackSprintMissions={get,all:()=>['design','building'].flatMap(track=>gameProjectTracks[track].projects.map(p=>get(track,p.id)))};
})();
