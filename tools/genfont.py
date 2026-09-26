#!/usr/bin/env python3
# Bitmap font generator (BMFont .fnt + .png) for the Rune Ring watch face.
# Run from the project root:  python3 tools/genfont.py   (needs Pillow: pip3 install pillow)
# Afterwards copy the printed 'time' metrics into the CT_* constants in RuneRingView.mc,
# and the printed VCENTER correction for 'date' into CD_VDY. Do this every time: a different
# Pillow version rasterises slightly differently even when the character set is unchanged.
from PIL import Image, ImageDraw, ImageFont
import json, os
HERE=os.path.dirname(os.path.abspath(__file__))
OUT=os.path.join(HERE,'..','resources','fonts')
FONTS=os.path.join(HERE,'fonts')
def load(path, size, wght=None):
    f = ImageFont.truetype(path, size)
    if wght: f.set_variation_by_axes([wght])
    return f
def ink(f, c):
    O=300; im=Image.new('L',(900,900),0)
    ImageDraw.Draw(im).text((O,O),c,font=f,fill=255,anchor='ls')
    bb=im.getbbox()
    return None if bb is None else (bb[0]-O,bb[1]-O,bb[2]-O,bb[3]-O)
def gen(name, parts, digits_for_metrics='0123456789'):
    # parts: list of (chars, font)
    glyphs={}
    for chars,f in parts:
        for c in chars:
            glyphs[c]=(f, ink(f,c), round(f.getlength(c)))
    inks=[g[1] for g in glyphs.values() if g[1]]
    top=min(i[1] for i in inks); bot=max(i[3] for i in inks)
    pad=2; base=-top+pad; lineh=bot-top+2*pad
    W=sum((g[1][2]-g[1][0]+4) if g[1] else 4 for g in glyphs.values())+4
    img=Image.new('RGBA',(W,lineh),(0,0,0,0)); d=ImageDraw.Draw(img)
    x=2; lines=[]; L={}; R={}
    for c,(f,bb,adv) in glyphs.items():
        if bb is None:
            lines.append(f'char id={ord(c)} x={x} y=0 width=1 height=1 xoffset=0 yoffset=0 xadvance={adv} page=0 chnl=15'); x+=4; continue
        l,t,r,b=bb; w=r-l
        d.text((x-l,base),c,font=f,fill=(255,255,255,255),anchor='ls')
        lines.append(f'char id={ord(c)} x={x} y=0 width={w} height={lineh} xoffset={l} yoffset=0 xadvance={adv} page=0 chnl=15')
        L[c]=l; R[c]=adv-r; x+=w+4
    img.save(f'{OUT}/{name}.png')
    hdr=[f'info face="{name}" size={lineh} bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=1 aa=1 padding=0,0,0,0 spacing=1,1',
         f'common lineHeight={lineh} base={base} scaleW={W} scaleH={lineh} pages=1 packed=0',
         f'page id=0 file="{name}.png"', f'chars count={len(glyphs)}']
    open(f'{OUT}/{name}.fnt','w').write('\n'.join(hdr+lines)+'\n')
    dg=[glyphs[c][1] for c in digits_for_metrics if c in glyphs]
    it=base+min(i[1] for i in dg); ib=base+max(i[3] for i in dg)
    return dict(lineh=lineh, inkTop=it, inkBot=ib,
                L=[L.get(c,0) for c in '0123456789'], R=[R.get(c,0) for c in '0123456789'],
                adv=[glyphs[c][2] for c in '0123456789' if c in glyphs], W=W)


D='0123456789'
# Cyrillic comes from resources-rus/strings/strings.xml, Latin from resources/strings/strings.xml.
# Only the letters listed here end up in the font; anything else renders as nothing on the watch.
days=["ВС","ПН","ВТ","СР","ЧТ","ПТ","СБ"]
months=["ЯНВАРЯ","ФЕВРАЛЯ","МАРТА","АПРЕЛЯ","МАЯ","ИЮНЯ","ИЮЛЯ","АВГУСТА","СЕНТЯБРЯ","ОКТЯБРЯ","НОЯБРЯ","ДЕКАБРЯ"]
cyr=''.join(sorted(set(''.join(days+months))))
# English locale: the Latin letters come from Cinzel itself, where they are native,
# so Forum is not involved. Keep these lists in step with Days and Months in the resources.
en_days=["SUN","MON","TUE","WED","THU","FRI","SAT"]
en_months=["JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"]
lat=''.join(sorted(set(''.join(en_days+en_months))))

res={}
cz=lambda s,w=500: load(os.path.join(FONTS,'Cinzel-wght.ttf'),s,w)
res['time']=gen('cinzel_time',[(D,cz(105,500))])
# cinzel_night was dropped: the night and always-on screens reuse cinzel_time. The separate
# font differed by 1 px and cost the same memory.
# To bring it back: res['night']=gen('cinzel_night',[(D,cz(104,500))])
res['stats']=gen('cinzel_stats',[(D+'%-',cz(30,600))])
# date font: Cinzel digits and Latin, Forum Cyrillic scaled to the same cap height
dig=cz(32,600); dh=ink(dig,'0'); dH=dh[3]-dh[1]
fo=load(os.path.join(FONTS,'Forum-Regular.ttf'),40); fh=ink(fo,'Н'); fs=round(40*dH/(fh[3]-fh[1]))
res['date']=gen('cinzel_date',[(D+' :%'+lat,dig),(cyr,load(os.path.join(FONTS,'Forum-Regular.ttf'),fs))])
print('latin:',lat)
print('forum size',fs)
for k,v in res.items():
    print(k,v)
    # Fonts drawn with VCENTER (the date) need a correction: VCENTER centres the line box,
    # and the visible digits do not sit in the middle of it.
    print('   VCENTER correction (CD_VDY, for date):', round(v['lineh']/2-(v['inkTop']+v['inkBot'])/2))
json.dump(res,open(os.path.join(HERE,'fontmetrics.json'),'w'),indent=1)
