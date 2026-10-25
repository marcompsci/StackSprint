/* Real Python via Pyodide; deliberately limited to beginner expressions. */
window.StackSprintPython = (code, lesson) => new Promise((resolve, reject) => {
  const workerSource = `
    import {loadPyodide} from 'https://cdn.jsdelivr.net/pyodide/v314.0.7/full/pyodide.mjs';
    self.onmessage = async ({data}) => {
      try {
        const py = await loadPyodide();
        self.postMessage({ready:true});
        py.globals.set('source', data.code);
        py.globals.set('lesson', data.lesson);
        const result = py.runPython(${JSON.stringify(`
import ast, io, contextlib, json
tree = ast.parse(source)
allowed = (ast.Module, ast.Assign, ast.Expr, ast.Name, ast.Load, ast.Store, ast.Constant, ast.Call, ast.List, ast.Tuple, ast.Dict, ast.BinOp, ast.UnaryOp, ast.Add, ast.Sub, ast.Mult, ast.Div, ast.USub, ast.UAdd, ast.Attribute)
functions = dict(print=print, len=len, type=type, int=int, float=float, str=str, list=list, sum=sum, min=min, max=max, sorted=sorted)
for node in ast.walk(tree):
    if not isinstance(node, allowed):
        raise ValueError('Use simple assignments, lists, arithmetic and lesson built-ins here; imports and loops are not enabled.')
    if isinstance(node, ast.Name) and node.id.startswith('_'):
        raise ValueError('Use a descriptive name without a leading underscore.')
    if isinstance(node, ast.Attribute) and not (node.attr == '__name__' and isinstance(node.value, ast.Call) and isinstance(node.value.func, ast.Name) and node.value.func.id == 'type'):
        raise ValueError('Only type(value).__name__ is supported for attributes.')
    if isinstance(node, ast.Call) and not (isinstance(node.func, ast.Name) and node.func.id in functions):
        raise ValueError('Use only the built-in functions introduced in these lessons.')
calls = {n.func.id for n in ast.walk(tree) if isinstance(n, ast.Call) and isinstance(n.func, ast.Name)}
assigns = [n for n in ast.walk(tree) if isinstance(n, ast.Assign)]
required = [None, None, 'print', 'len', 'type', 'int', 'float', 'int', 'str', 'len', None, 'sum'][lesson]
concept = 'print' in calls and (required is None or required in calls)
if lesson in (0, 1): concept = concept and bool(assigns)
if lesson == 1: concept = concept and any('_' in n.id for a in assigns for n in ast.walk(a.targets[0]) if isinstance(n, ast.Name))
if lesson == 6: concept = concept and 'int' in calls
if lesson == 9: concept = concept and any(isinstance(n, ast.List) for n in ast.walk(tree))
if lesson == 10: concept = concept and any(isinstance(a.targets[0], ast.Tuple) for a in assigns)
buffer = io.StringIO()
with contextlib.redirect_stdout(buffer):
    exec(compile(tree, '<your-code>', 'exec'), {'__builtins__': functions})
json.dumps(dict(output=buffer.getvalue()[:4000].strip(), concept=bool(concept)))
`)});
        self.postMessage({result:JSON.parse(result)});
      } catch(error) { self.postMessage({error:String(error)}); }
    };`;
  const url = URL.createObjectURL(new Blob([workerSource], {type:'text/javascript'}));
  const worker = new Worker(url, {type:'module'});
  let timer;
  const finish = (error, result) => { clearTimeout(timer); worker.terminate(); URL.revokeObjectURL(url); error ? reject(new Error(error)) : resolve(result); };
  timer = setTimeout(() => finish('Python could not load. Check your internet connection and try again.'), 45000);
  worker.onerror = () => finish('Python could not start. Try serving the app on localhost and check your connection.');
  worker.onmessage = ({data}) => {
    if(data.ready) {clearTimeout(timer);timer=setTimeout(()=>finish('Execution stopped after 3 seconds. Try a smaller expression.'),3000);return;}
    finish(data.error, data.result);
  };
  worker.postMessage({code,lesson});
});
