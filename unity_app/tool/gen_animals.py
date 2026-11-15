# Original, simple animal faces built from basic shapes. Output: 256x256 transparent PNGs.
import os, sys, subprocess
def topng(svg, path, w):
    open(path+'.svg','w').write(svg)
    subprocess.run(['rsvg-convert','-w',str(w),path+'.svg','-o',path],check=True)
    os.remove(path+'.svg')
OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)
INK = "#1F2A44"
def eyes(y=118, dx=34, r=11):
    return "".join(f'<circle cx="{128+s*dx}" cy="{y}" r="{r}" fill="{INK}"/><circle cx="{128+s*dx-3}" cy="{y-4}" r="{r*0.32:.1f}" fill="#fff"/>' for s in (-1, 1))
def cheeks(y=150, dx=58, c="#FF8FB1"):
    return "".join(f'<ellipse cx="{128+s*dx}" cy="{y}" rx="13" ry="9" fill="{c}" opacity="0.55"/>' for s in (-1, 1))
def smile(y=160, w=16):
    return f'<path d="M{128-w},{y} Q128,{y+16} {128+w},{y}" stroke="{INK}" stroke-width="5" fill="none" stroke-linecap="round"/>'
A = {}
A["cat"] = f'''
<path d="M58,104 L66,34 L122,72 Z" fill="#FF9F43"/><path d="M198,104 L190,34 L134,72 Z" fill="#FF9F43"/>
<path d="M72,88 L76,54 L104,74 Z" fill="#FFD0B0"/><path d="M184,88 L180,54 L152,74 Z" fill="#FFD0B0"/>
<ellipse cx="128" cy="138" rx="86" ry="78" fill="#FF9F43"/>
<ellipse cx="128" cy="164" rx="44" ry="34" fill="#FFF3E6"/>
{eyes(124, 36, 12)}{cheeks(152, 62)}
<path d="M118,146 L138,146 L128,158 Z" fill="#FF6B8B"/>
<path d="M128,158 Q118,174 106,166 M128,158 Q138,174 150,166" stroke="{INK}" stroke-width="5" fill="none" stroke-linecap="round"/>
<g stroke="{INK}" stroke-width="3.5" stroke-linecap="round"><path d="M60,150 L22,142"/><path d="M60,162 L24,170"/><path d="M196,150 L234,142"/><path d="M196,162 L232,170"/></g>'''
A["dog"] = f'''
<ellipse cx="54" cy="122" rx="30" ry="62" fill="#8D5B3A" transform="rotate(14 54 122)"/>
<ellipse cx="202" cy="122" rx="30" ry="62" fill="#8D5B3A" transform="rotate(-14 202 122)"/>
<ellipse cx="128" cy="130" rx="80" ry="84" fill="#D9A066"/>
<ellipse cx="128" cy="168" rx="50" ry="40" fill="#FFF3E6"/>
<ellipse cx="94" cy="112" rx="22" ry="26" fill="#8D5B3A" opacity="0.55"/>
{eyes(114, 34, 12)}
<ellipse cx="128" cy="150" rx="17" ry="12" fill="{INK}"/>
<path d="M128,162 L128,176 M128,176 Q114,190 102,180 M128,176 Q142,190 154,180" stroke="{INK}" stroke-width="5" fill="none" stroke-linecap="round"/>
<ellipse cx="128" cy="196" rx="11" ry="13" fill="#FF6B8B"/>'''
mane = "".join(f'<circle cx="{128+92*__import__("math").cos(i*0.5236):.1f}" cy="{132+92*__import__("math").sin(i*0.5236):.1f}" r="28" fill="#C96A1B"/>' for i in range(12))
A["lion"] = f'''
{mane}<circle cx="128" cy="132" r="92" fill="#C96A1B"/>
<circle cx="76" cy="78" r="20" fill="#F7B844"/><circle cx="180" cy="78" r="20" fill="#F7B844"/>
<ellipse cx="128" cy="136" rx="68" ry="66" fill="#F7B844"/>
<ellipse cx="128" cy="166" rx="38" ry="28" fill="#FFF3E6"/>
{eyes(120, 30, 11)}{cheeks(150, 50)}
<path d="M114,148 L142,148 L128,164 Z" fill="#8D5B3A"/>
<path d="M128,164 Q116,180 104,172 M128,164 Q140,180 152,172" stroke="{INK}" stroke-width="5" fill="none" stroke-linecap="round"/>'''
A["elephant"] = f'''
<ellipse cx="50" cy="118" rx="46" ry="62" fill="#8FA3BF"/><ellipse cx="206" cy="118" rx="46" ry="62" fill="#8FA3BF"/>
<ellipse cx="52" cy="120" rx="28" ry="42" fill="#F6B7C9"/><ellipse cx="204" cy="120" rx="28" ry="42" fill="#F6B7C9"/>
<ellipse cx="128" cy="116" rx="70" ry="74" fill="#A9BAD3"/>
<path d="M108,150 Q104,214 132,226 Q156,232 160,208" stroke="#A9BAD3" stroke-width="36" fill="none" stroke-linecap="round"/>
<g stroke="#8FA3BF" stroke-width="4" stroke-linecap="round"><path d="M96,176 L124,176"/><path d="M98,194 L126,196"/></g>
{eyes(108, 34, 11)}{cheeks(138, 52)}'''
A["monkey"] = f'''
<circle cx="42" cy="124" r="34" fill="#7A4B2A"/><circle cx="214" cy="124" r="34" fill="#7A4B2A"/>
<circle cx="42" cy="124" r="19" fill="#F3C9A5"/><circle cx="214" cy="124" r="19" fill="#F3C9A5"/>
<ellipse cx="128" cy="126" rx="82" ry="84" fill="#7A4B2A"/>
<ellipse cx="100" cy="112" rx="34" ry="38" fill="#F3C9A5"/><ellipse cx="156" cy="112" rx="34" ry="38" fill="#F3C9A5"/>
<ellipse cx="128" cy="166" rx="54" ry="40" fill="#F3C9A5"/>
{eyes(112, 28, 11)}
<ellipse cx="121" cy="146" rx="3.5" ry="5" fill="{INK}"/><ellipse cx="135" cy="146" rx="3.5" ry="5" fill="{INK}"/>
{smile(172, 26)}'''
A["bird"] = f'''
<path d="M108,60 Q112,24 132,48 Q144,22 152,58 Z" fill="#FFC533"/>
<ellipse cx="128" cy="140" rx="84" ry="82" fill="#3D8BFF"/>
<ellipse cx="128" cy="178" rx="52" ry="40" fill="#CFE3FF"/>
<ellipse cx="52" cy="158" rx="22" ry="40" fill="#2A6FE0" transform="rotate(18 52 158)"/>
<ellipse cx="204" cy="158" rx="22" ry="40" fill="#2A6FE0" transform="rotate(-18 204 158)"/>
<circle cx="96" cy="118" r="23" fill="#fff"/><circle cx="160" cy="118" r="23" fill="#fff"/>
<circle cx="100" cy="120" r="11" fill="{INK}"/><circle cx="156" cy="120" r="11" fill="{INK}"/>
<circle cx="97" cy="116" r="3.5" fill="#fff"/><circle cx="153" cy="116" r="3.5" fill="#fff"/>
<path d="M108,142 L148,142 L128,172 Z" fill="#FF9F43"/><path d="M108,142 L148,142 L128,152 Z" fill="#FFB86B"/>'''
sheet = ['<svg xmlns="http://www.w3.org/2000/svg" width="768" height="512"><rect width="100%" height="100%" fill="#E6F8FF"/>']
for i, (name, body) in enumerate(A.items()):
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">{body}</svg>'
    topng(svg, os.path.join(OUT, name + '.png'), 256)
    sheet.append(f'<g transform="translate({(i%3)*256},{(i//3)*256})">{body}</g>')
sheet.append("</svg>")
topng(''.join(sheet), 'sheet.png', 768)
print("wrote", list(A))
