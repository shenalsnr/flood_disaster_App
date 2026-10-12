"""WeSafe overflow fixer (pass 2): nested Row / pill Row overflow.
Usage: python rowfix2.py <lib dir>   (idempotent)"""
import re,sys,os
def skip_str(s,j):
    q=s[j]
    if s[j:j+3]==q*3:
        k=s.index(q*3,j+3); return k+3
    raw = j>0 and s[j-1]=='r'
    j+=1
    while s[j]!=q:
        if s[j]=='\\' and not raw: j+=2; continue
        if s[j]=='$' and s[j+1]=='{' and not raw:
            d=0; j+=1
            while True:
                if s[j]=='{': d+=1
                elif s[j]=='}':
                    d-=1
                    if d==0: break
                elif s[j] in '\'"': j=skip_str(s,j)-1
                j+=1
        j+=1
    return j+1
def close(s,p):  # p at an opener, return index after matching closer
    d=0;j=p
    while j<len(s):
        c=s[j]
        if c in '\'"': j=skip_str(s,j); continue
        if c=='/' and s[j:j+2]=='//': j=s.index('\n',j); continue
        if c in '([{': d+=1
        elif c in ')]}':
            d-=1
            if d==0: return j+1
        j+=1
    raise ValueError
def elems(s,a,b):  # top-level comma elements in s[a:b] -> (start,end) stripped
    out=[];d=0;st=a;j=a
    while j<b:
        c=s[j]
        if c in '\'"': j=skip_str(s,j); continue
        if c=='/' and s[j:j+2]=='//': j=s.index('\n',j); continue
        if c in '([{': d+=1
        elif c in ')]}': d-=1
        elif c==',' and d==0:
            out.append((st,j)); st=j+1
        j+=1
    out.append((st,b))
    r=[]
    for x,y in out:
        while x<y and s[x] in ' \t\r\n': x+=1
        while y>x and s[y-1] in ' \t\r\n': y-=1
        # skip leading comments
        while s.startswith('//',x):
            x=s.index('\n',x)+1
            while x<y and s[x] in ' \t\r\n': x+=1
        if x<y: r.append((x,y))
    return r
SKIP=('Expanded','Flexible','Spacer','SizedBox','Icon(','const Icon','const SizedBox','const Spacer','const Expanded','Divider','const Divider')
def process(src):
    edits=[]  # (pos, text)
    wrapped=set(); mins=set()
    for m in re.finditer(r'(?<![\w.])Row\(',src):
        p=m.end()-1
        try: e=close(src,p)
        except Exception: continue
        pre=src[max(0,m.start()-900):m.start()]
        if 'Axis.horizontal' in pre[-600:]: continue
        args=elems(src,p+1,e-1)
        ch=None; mainmin=False
        for x,y in args:
            t=src[x:y]
            if t.startswith('mainAxisSize') and 'min' in t: mainmin=True
            if t.startswith('children:'):
                ch=(x,y)
        if ch is None or mainmin: continue
        lb=src.index('[',ch[0])
        le=close(src,lb)
        kids=elems(src,lb+1,le-1)
        if len(kids)<2: continue
        for x,y in kids:
            k=src[x:y]
            if k.startswith(SKIP): continue
            if (x) in wrapped: continue
            isText=re.match(r'(const\s+)?Text(\.rich)?\(',k)
            isRow=re.match(r'(const\s+)?Row\(',k)
            hasRow=re.search(r'(?<![\w.])Row\(',k) and re.match(r'(const\s+)?(Container|Padding|Column|DecoratedBox|Align|Center)\(',k)
            if isText or isRow or hasRow:
                wrapped.add(x)
                edits.append((x,'Flexible(child: ')); edits.append((y,')'))
                if isRow or hasRow:
                    rm=re.search(r'(?<![\w.])Row\(',k)
                    rp=x+rm.end()
                    inner_args=src[rp:rp+400]
                    if 'MainAxisSize' not in inner_args.split('children:')[0]:
                        mins.add(rp)
    for rp in mins: edits.append((rp,'mainAxisSize: MainAxisSize.min, '))
    for pos,t in sorted(edits,key=lambda z:(-z[0], 0 if z[1]==')' else 1)):
        src=src[:pos]+t+src[pos:]
    return src,len(wrapped)
root=sys.argv[1]; tot=0
for d,_,fs in os.walk(root):
    for f in fs:
        if not f.endswith('.dart') or 'localization' in d: continue
        p=os.path.join(d,f); s=open(p,encoding='utf8').read()
        try: n,c=process(s)
        except Exception as ex: print('ERR',p,ex); continue
        if c: open(p,'w',encoding='utf8').write(n); tot+=c; print(c,p)
print('wrapped',tot)
