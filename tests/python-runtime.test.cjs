const fs=require('node:fs'),{spawnSync}=require('node:child_process'),assert=require('node:assert/strict');
const file=fs.readFileSync(require('node:path').join(__dirname,'../python-runtime.js'),'utf8');
const validator=file.split('JSON.stringify(`')[1].split('`)});')[0].trim();
const code=validator.replace('json.dumps(dict(output=buffer.getvalue()[:4000].strip(), concept=bool(concept)))','print(json.dumps(dict(output=buffer.getvalue()[:4000].strip(), concept=bool(concept))))');
const examples=['coins = 9\nprint(coins)','pet_age = 4\nprint(pet_age)','print("Ready", 7)','print(len("moon"))','print(type(7).__name__)','print(int("8") + 1)','print(int(float("4.2")))','print(int(-2.8))','print("XP " + str(9))','items = ["hat"]\nprint(len(items))','a, b = 4, 8\nprint(a + b)','print(sum([5, 6]))'];
examples.forEach((source,lesson)=>{const r=spawnSync('python3',['-c',`source=${JSON.stringify(source)}\nlesson=${lesson}\n${code}`],{encoding:'utf8'});assert.equal(r.status,0,r.stderr);assert.equal(JSON.parse(r.stdout).concept,true);});
for(const source of ['import os','while True: pass','print((1).__class__)','print(int("6.8"))']){const r=spawnSync('python3',['-c',`source=${JSON.stringify(source)}\nlesson=0\n${code}`]);assert.notEqual(r.status,0);}
console.log('12 creative Python examples execute and pass concept checks; imports, loops, unsupported attributes and invalid conversions fail.');
