const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.join(__dirname,'..');
const data=JSON.parse(fs.readFileSync(path.join(root,'StackSprint/curriculum.json')));
assert.equal(data.lessons.length,36);assert.equal(data.questions.length,50);
assert.equal(new Set(data.lessons.map(l=>l.id)).size,36);
for(const lesson of data.lessons){assert.ok(lesson.term);assert.ok(lesson.definition);assert.equal(typeof lesson.code,'string');}
for(const q of data.questions){assert.ok(q.answer>=0&&q.answer<q.choices.length);assert.ok(q.explanation);}
const html=fs.readFileSync(path.join(root,'StackSprint/Web/index.html'),'utf8');
for(const match of html.matchAll(/(?:src|href)="\.\/([^"#]+)"/g))assert.ok(fs.existsSync(path.join(root,'StackSprint/Web',match[1])),match[1]);
const config=JSON.parse(fs.readFileSync(path.join(root,'StackSprint/BackendConfig.json')));
assert.ok(config.publishableKey.includes('YOUR_'),'Do not distribute a configured credential file.');
console.log('PASS: 36 lessons, 50 valid questions, bundled web resources, placeholder-only backend configuration.');
