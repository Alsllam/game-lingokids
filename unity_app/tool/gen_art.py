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

# ---- Objects for the letters topic, and the colours icon ----
A["apple"] = f"""
<path d="M128,74 C96,52 44,72 44,134 C44,190 84,232 112,232 C120,232 124,228 128,228 C132,228 136,232 144,232 C172,232 212,190 212,134 C212,72 160,52 128,74 Z" fill="#F44336"/>
<ellipse cx="88" cy="118" rx="14" ry="24" fill="#fff" opacity="0.35" transform="rotate(20 88 118)"/>
<path d="M128,76 Q126,50 138,32" stroke="#7A4B2A" stroke-width="8" fill="none" stroke-linecap="round"/>
<path d="M138,50 Q170,26 196,44 Q172,70 138,50 Z" fill="#43A047"/>"""
A["ball"] = f"""
<circle cx="128" cy="132" r="92" fill="#3D8BFF"/>
<path d="M36,132 A92,92 0 0 1 128,40 L128,132 Z" fill="#FF5A5F"/>
<path d="M128,224 A92,92 0 0 0 220,132 L128,132 Z" fill="#FFC533"/>
<path d="M128,40 A92,92 0 0 1 220,132 L128,132 Z" fill="#fff"/>
<circle cx="128" cy="132" r="92" fill="none" stroke="{INK}" stroke-width="5" opacity="0.15"/>
<ellipse cx="96" cy="88" rx="18" ry="12" fill="#fff" opacity="0.5" transform="rotate(-30 96 88)"/>"""
A["duck"] = f"""
<path d="M112,52 Q120,22 138,46 Q150,26 150,58 Z" fill="#F5B301"/>
<circle cx="128" cy="134" r="86" fill="#FFD43B"/>
{eyes(118, 34, 11)}{cheeks(146, 60, "#FF9F43")}
<ellipse cx="128" cy="166" rx="46" ry="22" fill="#FF8A1F"/>
<path d="M84,164 Q128,180 172,164" stroke="#D96A0B" stroke-width="4" fill="none" stroke-linecap="round"/>"""
A["egg"] = f"""
<ellipse cx="128" cy="228" rx="62" ry="10" fill="{INK}" opacity="0.1"/>
<path d="M128,28 C82,28 54,96 54,150 C54,198 88,228 128,228 C168,228 202,198 202,150 C202,96 174,28 128,28 Z" fill="#FFF3E0"/>
<path d="M128,28 C82,28 54,96 54,150 C54,198 88,228 128,228 C168,228 202,198 202,150 C202,96 174,28 128,28 Z" fill="none" stroke="#E8CFA8" stroke-width="5"/>
<ellipse cx="100" cy="98" rx="14" ry="26" fill="#fff" transform="rotate(18 100 98)"/>"""
A["fish"] = f"""
<path d="M182,128 L242,78 L232,128 L242,178 Z" fill="#FF8A1F"/>
<path d="M112,62 Q140,30 168,70 Z" fill="#FF8A1F"/>
<ellipse cx="116" cy="128" rx="92" ry="64" fill="#FF9F43"/>
<path d="M150,76 Q176,128 150,180" stroke="#fff" stroke-width="12" fill="none" stroke-linecap="round" opacity="0.8"/>
<path d="M106,68 Q130,128 106,188" stroke="#fff" stroke-width="12" fill="none" stroke-linecap="round" opacity="0.8"/>
<circle cx="66" cy="112" r="16" fill="#fff"/><circle cx="63" cy="112" r="8" fill="{INK}"/>
<path d="M36,142 Q50,152 64,144" stroke="{INK}" stroke-width="5" fill="none" stroke-linecap="round"/>"""
A["fox"] = f"""
<path d="M44,112 L50,26 L116,72 Z" fill="#F26B1D"/><path d="M212,112 L206,26 L140,72 Z" fill="#F26B1D"/>
<path d="M62,92 L64,50 L98,76 Z" fill="{INK}" opacity="0.75"/><path d="M194,92 L192,50 L158,76 Z" fill="{INK}" opacity="0.75"/>
<path d="M128,230 C70,206 34,160 40,104 C70,70 186,70 216,104 C222,160 186,206 128,230 Z" fill="#F26B1D"/>
<path d="M128,230 C88,212 52,180 42,134 C74,134 104,150 128,186 C152,150 182,134 214,134 C204,180 168,212 128,230 Z" fill="#FFF3E6"/>
{eyes(124, 38, 11)}
<ellipse cx="128" cy="204" rx="13" ry="10" fill="{INK}"/>"""
A["carrot"] = f"""
<path d="M128,70 Q100,20 78,40 Q96,52 110,76 Z" fill="#43A047"/>
<path d="M128,70 Q128,12 150,18 Q146,46 140,74 Z" fill="#2E7D32"/>
<path d="M128,70 Q168,28 186,48 Q164,56 148,78 Z" fill="#43A047"/>
<path d="M86,84 Q128,56 170,84 Q160,170 128,240 Q96,170 86,84 Z" fill="#FF8A1F"/>
<g stroke="#D96A0B" stroke-width="5" stroke-linecap="round"><path d="M100,112 L124,116"/><path d="M134,144 L156,140"/><path d="M110,170 L128,174"/></g>
<ellipse cx="108" cy="100" rx="8" ry="16" fill="#fff" opacity="0.3" transform="rotate(12 108 100)"/>"""
A["whale"] = f"""
<path d="M118,58 Q104,30 86,34 M118,58 Q118,24 132,18 M118,58 Q136,34 154,40" stroke="#7CC8FF" stroke-width="8" fill="none" stroke-linecap="round"/>
<path d="M196,150 Q226,120 220,84 Q238,100 250,84 Q252,134 214,170 Z" fill="#2A6FE0"/>
<path d="M22,150 C22,96 70,72 124,72 C180,72 222,104 222,150 C222,190 180,212 124,212 C66,212 22,196 22,150 Z" fill="#3D8BFF"/>
<path d="M24,160 C40,196 80,212 124,212 C164,212 198,200 214,176 C170,190 80,190 24,160 Z" fill="#CFE3FF"/>
<circle cx="70" cy="134" r="11" fill="{INK}"/><circle cx="67" cy="130" r="3.5" fill="#fff"/>
<path d="M40,164 Q60,176 82,166" stroke="{INK}" stroke-width="5" fill="none" stroke-linecap="round"/>
<ellipse cx="92" cy="152" rx="12" ry="8" fill="#FF8FB1" opacity="0.55"/>"""
A["palette"] = f"""
<path d="M128,34 C66,34 22,78 22,132 C22,186 66,224 122,224 C146,224 150,206 140,192 C130,178 140,160 160,160 L192,160 C216,160 234,146 234,120 C234,70 186,34 128,34 Z" fill="#F3D9B1"/>
<path d="M128,34 C66,34 22,78 22,132 C22,186 66,224 122,224 C146,224 150,206 140,192 C130,178 140,160 160,160 L192,160 C216,160 234,146 234,120 C234,70 186,34 128,34 Z" fill="none" stroke="#D9B98A" stroke-width="5"/>
<circle cx="76" cy="104" r="19" fill="#F44336"/><circle cx="124" cy="76" r="19" fill="#FDD835"/>
<circle cx="176" cy="92" r="19" fill="#43A047"/><circle cx="72" cy="158" r="19" fill="#2196F3"/><circle cx="194" cy="128" r="14" fill="#8E24AA"/>"""

sheet = ['<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="768"><rect width="100%" height="100%" fill="#E6F8FF"/>']
for i, (name, body) in enumerate(A.items()):
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">{body}</svg>'
    topng(svg, os.path.join(OUT, name + '.png'), 256)
    sheet.append(f'<g transform="translate({(i%5)*256},{(i//5)*256})">{body}</g>')
sheet.append("</svg>")
topng(''.join(sheet), os.path.join(os.path.dirname(os.path.abspath(__file__)), 'sheet.png'), 1280)
print("wrote", list(A))
