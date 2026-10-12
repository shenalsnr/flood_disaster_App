#!/usr/bin/env python3
"""
WeSafe - wrap every screen's English text with tr() so the whole app follows
the language the user picked (English / Sinhala / Tamil).

Usage (project root, the folder that contains lib/):
    python tools/wesafe_translate.py lib

What it does
  * Text('...'), hintText / labelText / label / title / tooltip / message ...,
    SnackBar helper calls, validator messages  ->  tr('...')
  * Text(someVariable)  ->  Text(tr(someVariable))   (looked up in the dictionary)
  * removes `const` where needed, adds the import, never touches data/,
    controllers/, services/ or the localization folder.
  * Safe to run again after you merge teammates' code: already wrapped text is
    left alone and only the NEW text is wrapped.
  * Writes untranslated_strings.txt = English texts that are not in
    lib/core/localization/app_strings_auto.dart yet (they show in English
    until a translation line is added there).
"""
import re,sys,os,json
NAMED={'label','labelText','hint','hintText','title','subtitle','tooltip','helperText','errorText','message','semanticLabel','buttonText','heading','caption','emptyText','confirmText','cancelText','sublabel','badgeText','prefixText','suffixText','counterText','content','detail','details','badge','unit'}
ASSIGN=re.compile(r'\b(title|subtitle|label|message|notice|button|cardTitle|badgeText|statusText|text|hint|heading|caption|body|msg|_error|error|errorText|buttonText|subText|headline)\s*=\s*$')
HELPERS=re.compile(r'^_?(snack\w*|toast\w*|showSnack\w*|showToast\w*|showMsg\w*|showMessage|showError|showSuccess|notify\w*|flash\w*)$',re.I)

def lex_string(s,i):
    """s[i] is a quote. returns (end_index_exclusive, raw_body, quote, is_raw, triple)"""
    raw = i>0 and s[i-1]=='r' and not (i>1 and (s[i-2].isalnum() or s[i-2]=='_'))
    q=s[i]
    triple = s[i:i+3]==q*3
    j=i+3 if triple else i+1
    qq=q*3 if triple else q
    start=j
    while j<len(s):
        if s[j]=='\\' and not raw: j+=2;continue
        if not raw and s[j]=='$' and s[j+1:j+2]=='{':
            depth=1;j+=2
            while j<len(s) and depth:
                if s[j]in"'\"":
                    _e,_b,_q,_r,_t=lex_string(s,j); j=_e;continue
                if s[j]=='{':depth+=1
                elif s[j]=='}':depth-=1
                j+=1
            continue
        if s.startswith(qq,j):
            return j+len(qq),s[start:j],q,raw,triple
        j+=1
    return len(s),s[start:],q,raw,triple

def split_interp(body):
    """returns (template with {p0}.., [exprs]) or None if too complex"""
    out='';exprs=[];i=0
    while i<len(body):
        c=body[i]
        if c=='\\':
            out+=body[i:i+2];i+=2;continue
        if c=='$':
            if body[i+1:i+2]=='{':
                depth=1;j=i+2
                while j<len(body) and depth:
                    if body[j]=='{':depth+=1
                    elif body[j]=='}':depth-=1
                    j+=1
                e=body[i+2:j-1]
                exprs.append(e);out+='{p%d}'%(len(exprs)-1);i=j;continue
            m=re.match(r"\$([A-Za-z_]\w*)",body[i:])
            if m:
                exprs.append(m.group(1));out+='{p%d}'%(len(exprs)-1);i+=len(m.group(0));continue
        out+=c;i+=1
    return out,exprs

def unesc(t):
    t=re.sub(r"\\u\{([0-9A-Fa-f]+)\}",lambda m:chr(int(m.group(1),16)),t)
    t=re.sub(r"\\u([0-9A-Fa-f]{4})",lambda m:chr(int(m.group(1),16)),t)
    t=re.sub(r"\\x([0-9A-Fa-f]{2})",lambda m:chr(int(m.group(1),16)),t)
    return t.replace("\\'","'").replace('\\"','"').replace('\\n','\n').replace('\\t','\t').replace('\\$','$').replace('\\\\','\\')

def is_ui(tmpl):
    if re.search(r'[\u0D80-\u0DFF\u0B80-\u0BFF]',tmpl): return False
    plain=re.sub(r'\{p\d+\}','',tmpl)
    letters=re.findall(r'[A-Za-z]',plain)
    if len(letters)<2: return False
    if re.search(r'(https?://|\.dart|assets/|\.png|\.jpg|\.json)',plain): return False
    if re.fullmatch(r'[a-z]+(_[a-z0-9]+)+',plain.strip()): return False  # snake_case id
    if re.fullmatch(r'[a-z]+[A-Z]\w*',plain.strip()): return False       # camelCase id
    return True

def escape_for_dart(t):
    return t.replace('\\','\\\\').replace("'","\\'").replace('\n','\\n').replace('$','\\$')

def process(s, collect, apply=True):
    """Walk the source; wrap literals found in whitelisted positions."""
    edits=[]  # (start,end,replacement)
    L=len(s);i=0
    stack=[]  # (char, call_name)
    def prev_ident(pos):
        m=re.search(r'([A-Za-z_]\w*)\s*$',s[max(0,pos-60):pos])
        return m.group(1) if m else ''
    while i<L:
        c=s[i]
        if s.startswith('//',i):
            j=s.find('\n',i);i=L if j<0 else j;continue
        if s.startswith('/*',i):
            j=s.find('*/',i);i=L if j<0 else j+2;continue
        if c in "'\"":
            e,body,q,raw,tri=lex_string(s,i)
            if not raw and not tri:
                while True:
                    m=re.compile(r'(?:\s|//[^\n]*\n)*').match(s,e)
                    j=m.end()
                    if j<L and s[j] in "'\"" and not s.startswith(s[j]*3,j) and not (s[j-1:j]=='r'):
                        e2,b2,q2,r2,t2=lex_string(s,j)
                        if r2 or t2: break
                        body=body+b2;e=e2
                        if q2!=q: q=q2
                    else: break
            # find literal-run (adjacent strings)
            # decide context
            ctx=None
            if stack and stack[-1][0]=='(':
                call=stack[-1][1]
                # text of preceding tokens inside this paren
                open_pos=stack[-1][2]
                before=s[open_pos+1:i]
                # strip ternary/concat context: take the last "segment" start
                seg=re.split(r'[,]',before)[-1] if False else before
                # last top-level arg start within `before` (depth-0 comma)
                d=0;last=0
                for k,ch in enumerate(before):
                    if ch in '([{':d+=1
                    elif ch in ')]}':d-=1
                    elif ch==',' and d==0:last=k+1
                argpre=before[last:]
                name=None
                mm=re.match(r'\s*([A-Za-z_]\w*)\s*:',argpre)
                if mm: name=mm.group(1)
                positional=name is None
                # allowed leading operators for ternary: ? : && ||
                lead=argpre[mm.end():] if mm else argpre
                lead_ok=re.fullmatch(r'[\s?:\w.!=<>()&|]*',lead) is not None and True
                if call in('Text','SelectableText','AutoSizeText') and positional and not argpre.strip().startswith('//'):
                    ctx='text'
                elif call=='TextSpan' and name=='text': ctx='text'
                elif name in NAMED and call not in('TextEditingController','Exception','Error','StateError','ArgumentError','FormatException','showBroadcastDialog'):
                    ctx='named'
                elif positional and HELPERS.match(call or '') and not argpre.strip():
                    ctx='helper'
                elif call=='Exception' or call in ('ArgumentError',):
                    ctx=None
            def _is_param_default(pos):
                pre=s[max(0,pos-80):pos]
                m=ASSIGN.search(pre)
                if not m: return False
                head=pre[:m.start()]
                head=re.sub(r'(this\.|final\s+|String\??\s+|required\s+)\s*$','',head)
                head=head.rstrip()
                c1=head[-1:]
                if c1 in '(,': return True
                if c1=='{':
                    h2=head[:-1].rstrip()
                    return h2[-1:] in '(,'
                return False
            if ctx is None and ASSIGN.search(s[max(0,i-40):i]) and not _is_param_default(i) and not re.search(r'[=!<>]=\s*$',s[max(0,i-4):i]):
                ctx='assign'
            if ctx is None and not tri and re.match(r'\s*:\s*null',s[e:e+12]) and re.search(r'\?\s*$',s[max(0,i-3):i]):
                ctx='validator'
            if ctx is None and not tri and re.search(r'\breturn\s+$',s[max(0,i-9):i]) and re.match(r'\s*;',s[e:e+3]) and re.search(r'validator|validate',s[max(0,i-400):i]) and body[:1].isupper():
                ctx='validator'
            if ctx and not tri:
                # require the literal to be directly an operand: not followed by [ or . member access
                after=s[e:e+3].lstrip()
                prevc=s[:i].rstrip()[-1:]
                if after[:1]=='[' or re.match(r'\.\s*(length|\[|codeUnits)',s[e:e+12]): ctx=None
                if prevc in('$',) : ctx=None
            if ctx and not raw and not tri:
                sp=split_interp(body)
                tmpl,exprs=sp
                tmpl=unesc(tmpl)
                if is_ui(tmpl) and not re.search(r'\{p\d+\}',tmpl.replace('{p0}','',0)) or is_ui(tmpl):
                    # skip text that is only placeholders around trivial words
                    key=tmpl
                    if exprs:
                        rep="tr('%s', {%s})"%(escape_for_dart(key),', '.join("'p%d': (%s).toString()"%(n,x) for n,x in enumerate(exprs)))
                    else:
                        rep="tr('%s')"%escape_for_dart(key)
                    # skip if already inside tr(
                    if not (stack and stack[-1][1]=='tr'):
                        edits.append((i,e,rep));collect.add(key)
            i=e;continue
        if c in '([{':
            nm=prev_ident(i) if c=='(' else ''
            if nm=='Text' and c=='(' and not re.search(r'\.\s*Text\s*$',s[max(0,i-20):i]):
                d=0;j=i+1
                while j<L:
                    if s[j] in "'\"":
                        j=lex_string(s,j)[0];continue
                    if s[j] in '([{':d+=1
                    elif s[j] in ')]}':
                        if d==0:break
                        d-=1
                    elif s[j]==',' and d==0:break
                    j+=1
                arg=s[i+1:j].strip()
                if re.fullmatch(r'[A-Za-z_][\w]*(\.[A-Za-z_]\w*)*!?',arg) and arg not in('null','true','false','this') and not arg.startswith('tr'):
                    a0=i+1+len(s[i+1:j])-len(s[i+1:j].lstrip())
                    edits.append((a0,a0+len(arg),'tr(%s)'%arg))
            stack.append((c,nm,i));i+=1;continue
        if c in ')]}':
            if stack:stack.pop()
            i+=1;continue
        i+=1
    if apply:
        for a,b,r in sorted(edits,reverse=True):
            s=s[:a]+r+s[b:]
    return s,len(edits)


def unconst(s):
    i=0;L=len(s);stack=[];rm=set()
    def constbefore(pos,ch):
        tail=s[max(0,pos-80):pos]
        if ch=='(':
            mm=re.search(r"\bconst\s+[A-Za-z_][\w.]*(<[^()]*>)?\s*$",tail)
        else:
            mm=re.search(r"\bconst\s*(<[^<>]*(<[^<>]*>)?[^<>]*>)?\s*$",tail)
        return (max(0,pos-80)+mm.start()) if mm else None
    while i<L:
        c=s[i]
        if c=='/' and s[i:i+2]=='//':
            i=s.index('\n',i) if '\n' in s[i:] else L; continue
        if c in "'\"":
            q=c;i+=1
            while i<L and s[i]!=q:
                if s[i]=='\\': i+=1
                i+=1
            i+=1;continue
        if c in '([{':
            stack.append(constbefore(i,c)); i+=1; continue
        if c in ')]}':
            if stack: stack.pop()
            i+=1;continue
        if c=='t' and s[i:i+3]=='tr(' and not (s[i-1].isalnum() or s[i-1] in '_.'):
            for p in stack:
                if p is not None: rm.add(p)
        i+=1
    for p in sorted(rm,reverse=True):
        s=s[:p]+re.sub(r"^const\s*","",s[p:],count=1)
    return s

import json

def run(root):
    LOC=os.path.join(root,'core','localization','app_strings.dart')
    if not os.path.exists(LOC):
        print('ERROR: %s not found - copy lib/core/localization first.'%LOC); sys.exit(1)
    changed=[]
    for d,_,fs in os.walk(root):
        for f in fs:
            p=os.path.join(d,f); pp=p.replace('\\','/')
            if not f.endswith('.dart') or '/core/localization/' in pp: continue
            if ('/data/' in pp or '/controllers/' in pp or '/services/' in pp
                or ('/core/' in pp and not pp.endswith('core/theme/appearance.dart'))
                or pp.endswith('/main.dart') or 'firebase_options' in pp): continue
            s=open(p,encoding='utf8').read()
            ns,n=process(s,set(),apply=True)
            if 'splash_screen.dart' in pp:
                for t in ('Starting safety services\u2026','Loading early-warning alerts\u2026','Preparing offline maps\u2026'):
                    ns=ns.replace("return '%s';"%t,"return tr('%s');"%t)
                ns=ns.replace("return 'Ready';","return tr('Ready');")
                if ns!=s: n=max(n,1)
            if not n and ns==s: continue
            ns=unconst(ns)
            if 'app_strings.dart' not in ns:
                rel=os.path.relpath(LOC,os.path.dirname(p)).replace('\\','/')
                m=list(re.finditer(r"^(import|export) .*;\s*$",ns,re.M))
                imp="import '%s';"%rel
                ns=(ns[:m[-1].end()]+"\n"+imp+ns[m[-1].end():]) if m else imp+"\n"+ns
            open(p,'w',encoding='utf8').write(ns)
            changed.append(p)
    print('files changed:',len(changed))
    # ---- which wrapped texts have no translation yet?
    auto=os.path.join(root,'core','localization','app_strings_auto.dart')
    have=set()
    if os.path.exists(auto):
        have={unesc(k) for k in re.findall(r"^  '((?:[^'\\]|\\.)*)': \[",open(auto,encoding='utf8').read(),re.M)}
    used=set()
    for d,_,fs in os.walk(root):
        for f in fs:
            if not f.endswith('.dart') or '/core/localization/' in os.path.join(d,f).replace('\\','/'): continue
            t=open(os.path.join(d,f),encoding='utf8').read()
            for k in re.findall(r"\btr\('((?:[^'\\]|\\.)*)'",t):
                k=unesc(k)
                if re.search('[A-Za-z]{2}',k) and not re.fullmatch(r'[a-z0-9_]+',k): used.add(k)
    miss=sorted(k for k in used if k not in have)
    with open('untranslated_strings.txt','w',encoding='utf8') as fh:
        fh.write('\n'.join(miss))
    print('texts without Sinhala/Tamil yet: %d (see untranslated_strings.txt)'%len(miss))

if __name__=='__main__':
    run(sys.argv[1] if len(sys.argv)>1 else 'lib')
