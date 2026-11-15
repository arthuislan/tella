"""Gera as ilustrações do README do Tella (HTML -> PNG em alta resolução).

Uso:  python3 docs/src/gen.py docs/images
Requer: playwright (chromium) e a fonte Inter.

Todo texto em português traz, logo abaixo, a legenda em inglês.
As imagens saem em 2x (ex.: 2560 px de largura) para ficarem nítidas em telas Retina no GitHub.
"""
import base64, pathlib, sys
from playwright.sync_api import sync_playwright

OUT = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "out")
OUT.mkdir(parents=True, exist_ok=True)
HERE = pathlib.Path(__file__).resolve().parent
ICON_B64 = base64.b64encode((HERE.parent / "images" / "icon.png").read_bytes()).decode()

RED, GREEN, AMBER, BLUE = "#FF5A67", "#3DDC97", "#FFB547", "#6EA8FF"
VERSION = "1.4"

CSS = """
*{box-sizing:border-box;margin:0;padding:0}
html,body{background:transparent}
body{font-family:Inter,sans-serif;-webkit-font-smoothing:antialiased;color:#fff}
.card{position:relative;overflow:hidden;border-radius:36px;
 background:
  radial-gradient(900px 520px at 8% -10%, rgba(110,92,255,.38), transparent 60%),
  radial-gradient(800px 520px at 105% 10%, rgba(0,190,255,.22), transparent 60%),
  radial-gradient(900px 600px at 60% 130%, rgba(255,70,160,.20), transparent 60%),
  linear-gradient(180deg,#0E1020 0%,#090A14 100%);
 box-shadow:inset 0 0 0 1px rgba(255,255,255,.07)}
.grain{position:absolute;inset:0;pointer-events:none;opacity:.5;
 background-image:radial-gradient(rgba(255,255,255,.035) 1px, transparent 1px);background-size:22px 22px}
.disp{font-family:'Inter Display',Inter,sans-serif}

/* Etiquetas bilíngues */
.en{display:inline-flex;align-items:center;gap:8px;color:#9AA1BB}
.en i{font-style:normal;font-size:.62em;font-weight:700;letter-spacing:.09em;color:#C9CEE3;
 border:1px solid rgba(255,255,255,.22);border-radius:5px;padding:1px 5px;line-height:1.35}

.badge{display:inline-flex;align-items:center;gap:12px;border-radius:999px;padding:7px 16px 7px 12px;
 font-weight:700;font-size:14px;letter-spacing:.09em}
.badge .dot{width:9px;height:9px;border-radius:50%}
.badge .sep{opacity:.35;font-weight:400}
.badge .b{opacity:.65;font-weight:600}

.h1{font-family:'Inter Display',Inter,sans-serif;font-size:44px;font-weight:700;letter-spacing:-.022em;line-height:1.08}
.h1en{font-size:21px;font-weight:600;margin-top:8px}
.sub{font-size:18px;color:#C8CCDD;margin-top:16px;line-height:1.45;max-width:1080px}
.suben{font-size:15px;margin-top:4px;line-height:1.45}

/* Telas */
.monitor{position:absolute;background:linear-gradient(160deg,#2A2C38,#15161E);border-radius:18px;padding:10px;
 box-shadow:0 0 0 1px rgba(255,255,255,.10),0 40px 80px rgba(0,0,0,.55)}
.neck{position:absolute;background:linear-gradient(90deg,#5B5E6E,#9A9DAD 45%,#5B5E6E)}
.foot{position:absolute;border-radius:8px;background:linear-gradient(#A7AABA,#6D7080);box-shadow:0 14px 26px rgba(0,0,0,.5)}
.mac{position:absolute;background:linear-gradient(160deg,#2A2C38,#15161E);border-radius:14px 14px 3px 3px;padding:9px;
 box-shadow:0 0 0 1px rgba(255,255,255,.10),0 30px 60px rgba(0,0,0,.55)}
.macbase{position:absolute;border-radius:2px 2px 14px 14px;background:linear-gradient(#C9CCD8,#7E8192);
 box-shadow:0 16px 30px rgba(0,0,0,.5)}
.macbase:after{content:"";position:absolute;left:50%;transform:translateX(-50%);top:0;width:70px;height:5px;border-radius:0 0 6px 6px;background:#6A6D7D}
.screen{position:relative;width:100%;height:100%;border-radius:8px;overflow:hidden;
 background:
  radial-gradient(120% 90% at 0% 0%, #4F6BFF 0%, transparent 55%),
  radial-gradient(110% 90% at 100% 20%, #B160FF 0%, transparent 55%),
  radial-gradient(120% 100% at 60% 110%, #FF6FA9 0%, transparent 60%),
  #6B5CE8}
.mac .screen{border-radius:5px}
.menubar{position:absolute;left:0;right:0;top:0;height:20px;background:rgba(255,255,255,.42);backdrop-filter:blur(8px);
 display:flex;align-items:center;gap:12px;padding-left:12px}
.mac .menubar{height:15px;gap:9px;padding-left:9px}
.mb{height:6px;border-radius:3px;background:rgba(20,20,30,.38)}
.mac .mb{height:5px}
.mbapp{width:12px;height:12px;border-radius:3px}
.mac .mbapp{width:9px;height:9px;border-radius:2px}

.win{position:absolute;background:#FBFBFD;border-radius:10px;overflow:hidden;box-shadow:0 14px 34px rgba(10,10,40,.38)}
.mac .win{border-radius:7px}
.tb{height:28px;background:#EEEEF3;border-bottom:1px solid #DEDEE6;display:flex;align-items:center;padding:0 10px;gap:6px;position:relative}
.mac .tb{height:19px;padding:0 7px;gap:4px}
.tl{width:11px;height:11px;border-radius:50%;background:#CFCFD7}
.mac .tl{width:7px;height:7px}
.on .tl:nth-child(1){background:#FF5F57}.on .tl:nth-child(2){background:#FEBC2E}.on .tl:nth-child(3){background:#28C840}
.glyph{position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);width:14px;height:14px;border-radius:4px}
.mac .glyph{width:10px;height:10px;border-radius:3px}
.gt{position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);display:flex;align-items:center;gap:6px}
.gt .bar2{width:52px;height:6px;border-radius:3px;background:#C9C9D3}
.mac .gt .bar2{width:34px;height:4px}
.on .gt .bar2{background:#8E8EA0}
.body{padding:16px}
.mac .body{padding:9px}
.bar{height:10px;border-radius:5px;background:#E7E8EF;margin-bottom:10px}
.mac .bar{height:6px;margin-bottom:6px;border-radius:3px}
.field{height:36px;border:1.5px solid #DCDDE6;border-radius:10px;margin-bottom:18px;display:flex;align-items:center;padding:0 12px;font-size:16px;font-weight:500}
.ph{width:46%;height:8px;border-radius:4px;background:#E2E3EA}
.caret{display:inline-block;width:2px;height:1.05em;background:currentColor;vertical-align:-2px;margin-left:2px}
.grid{display:grid;grid-template-columns:repeat(4,1fr);gap:9px}
.mac .grid{gap:6px}
.tile{aspect-ratio:1/1;border-radius:7px;background:#ECEEF6}
.mac .tile{border-radius:4px}
.typed{font-size:12.5px;font-weight:600;margin-bottom:7px}

/* Balões */
.pill{position:absolute;z-index:20;display:flex;align-items:center;gap:12px;
 background:rgba(18,20,34,.86);backdrop-filter:blur(14px);border-radius:16px;padding:11px 16px 11px 12px;
 box-shadow:0 0 0 1px rgba(255,255,255,.12),0 18px 40px rgba(0,0,0,.45);white-space:nowrap}
.pill .ic{flex:none;width:32px;height:32px;border-radius:10px;display:grid;place-items:center}
.pill .pt{font-size:15.5px;font-weight:650;color:#fff}
.pill .en{font-size:12.5px;margin-top:2px}
.lbl{position:absolute;font-size:11.5px;font-weight:700;letter-spacing:.1em;color:#B9BED3}
.lbl .en{font-weight:600;letter-spacing:.06em;margin-left:8px}

.footer{position:absolute;left:64px;right:64px;bottom:26px;display:flex;align-items:center;justify-content:space-between;
 padding-top:16px;border-top:1px solid rgba(255,255,255,.09)}
.brand{display:flex;align-items:center;gap:10px;font-weight:700;font-size:15px}
.brand img{width:24px;height:24px;border-radius:6px}
.brand span{color:#8D93AC;font-weight:600}
.chips{display:flex;gap:8px}
.chip{font-size:12.5px;font-weight:600;color:#C9CEE3;border-radius:999px;padding:5px 11px;background:rgba(255,255,255,.07);
 box-shadow:inset 0 0 0 1px rgba(255,255,255,.10)}
svg.ov{position:absolute;left:0;top:0;pointer-events:none;z-index:15}
"""

CURSOR = ('<path d="M0 0 L0 24 L6 18 L10.4 27.4 L14.4 25.6 L10.2 16.4 L18.2 16.4 Z" fill="#0B0B12" stroke="#fff" '
          'stroke-width="1.8" stroke-linejoin="round"/>')

ICONS = {
    "kbd": '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="{c}" stroke-width="2" stroke-linecap="round"><rect x="2.5" y="6" width="19" height="12" rx="2.5"/><path d="M6.5 10h.01M10 10h.01M13.5 10h.01M17 10h.01M7.5 14h9"/></svg>',
    "x": '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="{c}" stroke-width="2.6" stroke-linecap="round"><path d="M6 6l12 12M18 6L6 18"/></svg>',
    "check": '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="{c}" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg>',
    "warn": '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="{c}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3.5L2.8 19.5h18.4z"/><path d="M12 10v4.5M12 17.2h.01"/></svg>',
    "lock": '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="{c}" stroke-width="2.2" stroke-linecap="round"><rect x="5" y="10.5" width="14" height="10" rx="2.5"/><path d="M8.5 10.5V7.5a3.5 3.5 0 0 1 7 0"/></svg>',
    "move": '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="{c}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="4" width="16" height="16" rx="3"/><path d="M9 12h6"/></svg>',
    "chip": '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="{c}" stroke-width="2" stroke-linecap="round"><rect x="6" y="6" width="12" height="12" rx="2"/><path d="M9 2.5v3M15 2.5v3M9 18.5v3M15 18.5v3M2.5 9h3M2.5 15h3M18.5 9h3M18.5 15h3"/></svg>',
    "bolt": '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="{c}" stroke-width="2.2" stroke-linejoin="round"><path d="M13 2.5L4.5 13.5H11l-1 8 8.5-11H12z"/></svg>',
    "box": '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="{c}" stroke-width="2.1" stroke-linejoin="round"><path d="M12 2.8l8.5 4.6v9.2L12 21.2l-8.5-4.6V7.4z"/><path d="M3.5 7.4L12 12l8.5-4.6M12 12v9.2"/></svg>',
    "mac": '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="{c}" stroke-width="2.1" stroke-linecap="round"><rect x="3" y="4.5" width="18" height="12" rx="2"/><path d="M1.5 19.5h21"/></svg>',
}


def icon(name, color):
    return ICONS[name].replace("{c}", color)


def en(text):
    return f'<span class="en"><i>EN</i>{text}</span>'


def pill(x, y, ic, color, pt, en_text, extra=""):
    return (f'<div class="pill" style="left:{x}px;top:{y}px;{extra}"><span class="ic" style="background:{color}26">{icon(ic, color)}</span>'
            f'<div><div class="pt">{pt}</div><div>{en(en_text)}</div></div></div>')


def badge(kind):
    if kind == "sem":
        c, pt, e = RED, "SEM O TELLA", "WITHOUT TELLA"
    else:
        c, pt, e = GREEN, "COM O TELLA", "WITH TELLA"
    return (f'<span class="badge" style="background:{c}1F;color:{c};box-shadow:inset 0 0 0 1px {c}40">'
            f'<span class="dot" style="background:{c};box-shadow:0 0 12px {c}"></span>{pt}'
            f'<span class="sep">|</span><span class="b">{e}</span></span>')


def header(kind, pt, en_t, sub, sub_en, step=""):
    st = (f'<span style="font-size:13px;font-weight:700;color:#8D93AC;letter-spacing:.09em;margin-left:14px">{step}</span>' if step else "")
    return (f'<div style="position:absolute;left:64px;top:52px;right:64px">{badge(kind)}{st}'
            f'<div class="h1" style="margin-top:20px">{pt}</div><div class="h1en">{en(en_t)}</div>'
            f'<div class="sub">{sub}</div><div class="suben">{en(sub_en)}</div></div>')


def footer():
    return (f'<div class="footer"><div class="brand"><img src="data:image/png;base64,{ICON_B64}">Tella <span>{VERSION}</span></div>'
            '<div class="chips"><span class="chip">Apple Silicon + Intel</span><span class="chip">macOS 13+</span>'
            '<span class="chip">36 idiomas · 36 languages</span></div></div>')


def glyph(color, shape="r"):
    rad = "50%" if shape == "c" else ""
    return f'<span class="glyph" style="background:{color};{"border-radius:" + rad if rad else ""}"></span>'


def window(cls, style, gcolor, body, gshape="r"):
    return (f'<div class="win {cls}" style="{style}"><div class="tb"><span class="tl"></span><span class="tl"></span><span class="tl"></span>'
            f'<span class="gt"><span class="glyph" style="position:static;transform:none;background:{gcolor};'
            f'{"border-radius:50%" if gshape == "c" else ""}"></span><span class="bar2"></span></span></div>'
            f'<div class="body">{body}</div></div>')


def ring(c):
    return f"box-shadow:0 0 0 2.5px {c},0 0 0 9px {c}2E,0 0 46px {c}66,0 14px 34px rgba(10,10,40,.38);"


def browser_body(typed=None):
    inner = (f'<span style="color:{RED}">{typed}<span class="caret"></span></span>' if typed else '<span class="ph"></span>')
    return (f'<div class="field">{inner}</div>'
            '<div class="bar" style="width:62%"></div><div class="bar" style="width:86%"></div><div class="bar" style="width:72%"></div>'
            '<div class="bar" style="width:40%;margin-bottom:16px"></div>'
            '<div class="grid">' + '<div class="tile"></div>' * 4 + '</div>')


def notes_body(typed=None, color=GREEN):
    t = f'<div class="typed" style="color:{color}">{typed}<span class="caret"></span></div>' if typed else ''
    return (t + '<div class="bar" style="width:90%"></div><div class="bar" style="width:68%"></div>'
            '<div class="bar" style="width:82%"></div><div class="bar" style="width:55%"></div><div class="bar" style="width:74%"></div>')


def files_body():
    return '<div class="grid">' + '<div class="tile"></div>' * 8 + '</div>'


# Geometria (px CSS do cartão 1280 x 800)
MON = dict(x=64, y=300, w=640, h=340)
MAC = dict(x=792, y=414, w=412, h=258)
B_BLUE, N_YELL, F_BLUE = "#3B82F6", "#F5B400", "#2E9BFF"


def scene(*, mon_on=False, mon_typed=None, mon_ring=None, files_front=False, files_on=False, files_ring=None,
          notes_on=False, notes_ring=None, notes_typed=None, app_mon=None, app_mac=None):
    def mb(app, big=True):
        w = (34, 28, 44, 30, 26) if big else (24, 20, 30, 22, 18)
        a = f'<span class="mbapp" style="background:{app}"></span>' if app else '<span class="mbapp" style="background:rgba(20,20,30,.38)"></span>'
        return a + "".join(f'<span class="mb" style="width:{x}px"></span>' for x in w)

    mon_win = window("on" if mon_on else "", "left:40px;top:42px;width:540px;height:256px;" + (ring(mon_ring) if mon_ring else ""),
                     B_BLUE, browser_body(mon_typed), "c")
    fz = 3 if files_front else 1
    files = window("on" if files_on else "",
                   f"left:12px;top:26px;width:262px;height:196px;z-index:{fz};" + (ring(files_ring) if files_ring else ""),
                   F_BLUE, files_body())
    notes = window("on" if notes_on else "",
                   f"left:202px;top:40px;width:186px;height:144px;z-index:2;" + (ring(notes_ring) if notes_ring else ""),
                   N_YELL, notes_body(notes_typed))
    m, k = MON, MAC
    return f'''
<div class="monitor" style="left:{m['x']}px;top:{m['y']}px;width:{m['w']}px;height:{m['h']}px"><div class="screen">
<div class="menubar">{mb(app_mon)}</div>{mon_win}</div></div>
<div class="neck" style="left:{m['x'] + m['w']//2 - 46}px;top:{m['y'] + m['h']}px;width:92px;height:34px"></div>
<div class="foot" style="left:{m['x'] + m['w']//2 - 120}px;top:{m['y'] + m['h'] + 32}px;width:240px;height:11px"></div>
<div class="lbl" style="left:{m['x']}px;top:{m['y'] + m['h'] + 62}px">MONITOR EXTERNO{en("EXTERNAL DISPLAY")}</div>
<div class="mac" style="left:{k['x']}px;top:{k['y']}px;width:{k['w']}px;height:{k['h']}px"><div class="screen">
<div class="menubar">{mb(app_mac, False)}</div>{files}{notes}</div></div>
<div class="macbase" style="left:{k['x'] - 30}px;top:{k['y'] + k['h']}px;width:{k['w'] + 60}px;height:14px"></div>
<div class="lbl" style="left:{k['x']}px;top:{k['y'] + k['h'] + 34}px">MACBOOK</div>'''


def overlay(cx, cy, *, start=(556, 470), extra="", path_color="#FFFFFF", w=1280, h=800):
    sx, sy = start
    mx = (sx + cx) / 2
    d = f"M {sx + 8} {sy + 6} C {mx - 40} {sy - 150}, {cx - 40} {cy - 190}, {cx - 4} {cy - 8}"
    return f'''<svg class="ov" width="{w}" height="{h}" viewBox="0 0 {w} {h}"><defs>
<filter id="s" x="-50%" y="-50%" width="200%" height="200%"><feDropShadow dx="0" dy="2" stdDeviation="2.2" flood-opacity=".5"/></filter>
<linearGradient id="g" x1="0" x2="1"><stop offset="0" stop-color="{path_color}" stop-opacity=".15"/><stop offset="1" stop-color="{path_color}" stop-opacity=".9"/></linearGradient></defs>
<path d="{d}" fill="none" stroke="url(#g)" stroke-width="2.6" stroke-dasharray="1 9" stroke-linecap="round"/>
<g transform="translate({sx},{sy})" opacity=".32">{CURSOR}</g>{extra}
<g transform="translate({cx},{cy})" filter="url(#s)">{CURSOR}</g></svg>'''


def page(body, w, h):
    return (f"<!doctype html><html><head><meta charset='utf-8'><style>{CSS}</style></head>"
            f"<body><div class='card' style='width:{w}px;height:{h}px'><div class='grain'></div>{body}</div></body></html>")


pages = {}

# 1 — Sem o Tella: o teclado fica preso na outra tela
pages["1-without-tella-keyboard"] = (page(
    header("sem", "O teclado fica preso na outra tela", "The keyboard gets stuck on the other display",
           "Você leva o cursor para o MacBook e começa a digitar, mas o texto vai parar na janela do monitor externo.",
           "You move the pointer to your MacBook and start typing, but the text lands in the window on the external display.",
           "PROBLEMA 1 · PROBLEM 1")
    + scene(mon_on=True, mon_typed="Hello, world", mon_ring=RED, app_mon=B_BLUE, app_mac=B_BLUE)
    + overlay(1048, 520)
    + pill(390, 520, "kbd", RED, "O texto vai para cá", "The text goes here")
    + pill(926, 316, "x", RED, "Aqui nada acontece", "Nothing happens here")
    + footer(), 1280, 800), (1280, 800))

# 2 — Sem o Tella: o clique traz a janela de trás para a frente
CX2, CY2 = 902, 566
burst = (f'<g transform="translate({CX2 + 1},{CY2 + 1})" fill="none" stroke="{RED}" stroke-width="2.4">'
         '<circle r="13" opacity=".95"/><circle r="25" opacity=".5"/><circle r="37" opacity=".22"/></g>')
pages["2-without-tella-click"] = (page(
    header("sem", "Clicar para ativar pode atrapalhar", "Clicking to activate can get in the way",
           "Para digitar, você precisa clicar. Se o clique cai numa janela de trás, ela pula para a frente e esconde a sua.",
           "To type, you have to click first. If the click lands on a window in the back, it jumps forward and hides yours.",
           "PROBLEMA 2 · PROBLEM 2")
    + scene(files_front=True, files_on=True, files_ring=RED, app_mon=F_BLUE, app_mac=F_BLUE)
    + overlay(CX2, CY2, extra=burst)
    + pill(842, 318, "warn", RED, "A janela de trás cobriu a sua", "The back window covered yours")
    + footer(), 1280, 800), (1280, 800))

# 3 — Com o Tella: a janela livre fica ativa quando o cursor entra
pages["3-with-tella-activate"] = (page(
    header("com", "A janela fica ativa quando o cursor entra", "A window becomes active when the pointer enters it",
           "Se nada cobre a janela (flutuando ou lado a lado), ela fica ativa sozinha, em qualquer tela ou mesa. Sem clique.",
           "If nothing covers the window (floating or side by side), it activates on its own, on any display or desktop. No click.",
           "NOVO NA 1.4 · NEW IN 1.4")
    + scene(notes_on=True, notes_ring=GREEN, notes_typed="Hello, world", app_mon=N_YELL, app_mac=N_YELL)
    + overlay(1084, 538)
    + pill(840, 316, "kbd", GREEN, "Ativa ao entrar, pronta para digitar", "Active on entry, ready to type")
    + pill(330, 560, "check", GREEN, "Nenhum clique, nada muda de lugar", "No click, nothing moves")
    + footer(), 1280, 800), (1280, 800))

# 4 — Com o Tella: ao sair para um vão, o teclado é solto
CX4, CY4 = 1122, 618
gap = (f'<rect x="1000" y="613" width="194" height="49" rx="6" fill="{AMBER}14" stroke="{AMBER}" stroke-width="1.6" stroke-dasharray="5 5"/>'
       f'<rect x="806" y="446" width="186" height="190" rx="8" fill="{AMBER}10" stroke="{AMBER}" stroke-opacity=".55" stroke-width="1.4" stroke-dasharray="5 5"/>')
pages["4-with-tella-release"] = (page(
    header("com", "Saiu da janela? O teclado fica livre", "Left the window? The keyboard is released",
           "Ao ir para um vão (a mesa ou uma janela de trás), nenhuma janela fica ativa até o cursor escolher outra.",
           "Move into a gap (the desktop or a window in the back) and no window stays active until the pointer picks another.",
           "NOVO NA 1.4 · NEW IN 1.4")
    + scene(app_mon=None, app_mac=None)
    + overlay(CX4, CY4, start=(1084, 538), extra=gap, path_color=AMBER)
    + pill(330, 560, "lock", AMBER, "Nada recebe o que você digita por engano", "Nothing gets your typing by mistake")
    + pill(840, 316, "move", AMBER, "Vão: a mesa ou uma janela de trás", "Gap: the desktop or a window in the back")
    + footer(), 1280, 800), (1280, 800))


# 5 — Universal: Apple Silicon + Intel
def chip_card(x, title, sub, arch, color):
    pins = "".join(f'<span style="position:absolute;{side}:-7px;{axis}:{18 + i * 16}px;width:{w}px;height:{hh}px;border-radius:2px;background:{color}88"></span>'
                   for side, axis, w, hh in (("left", "top", 7, 4), ("right", "top", 7, 4), ("top", "left", 4, 7), ("bottom", "left", 4, 7))
                   for i in range(5))
    return f'''<div style="position:absolute;left:{x}px;top:310px;width:330px;height:190px;border-radius:24px;padding:26px 28px;
 background:linear-gradient(160deg,rgba(255,255,255,.08),rgba(255,255,255,.02));box-shadow:inset 0 0 0 1px rgba(255,255,255,.12),0 30px 60px rgba(0,0,0,.35)">
 <div style="position:absolute;right:28px;top:30px;width:102px;height:102px;border-radius:16px;background:linear-gradient(145deg,{color}55,{color}18);
  box-shadow:inset 0 0 0 1.5px {color}AA,0 0 40px {color}44">{pins}
  <div style="position:absolute;inset:18px;border-radius:9px;box-shadow:inset 0 0 0 1px {color}88;display:grid;place-items:center;
   font-family:'Inter Display';font-weight:700;font-size:15px;color:#fff;letter-spacing:.02em">{arch}</div></div>
 <div class="disp" style="font-size:28px;font-weight:700;letter-spacing:-.01em">{title}</div>
 <div style="font-size:14px;color:#AEB4CC;margin-top:8px;line-height:1.5;max-width:150px">{sub}</div>
 <div style="position:absolute;left:28px;bottom:24px;display:inline-flex;align-items:center;gap:8px;font-size:13px;font-weight:650;color:{color}">
  {icon("check", color)}Nativo{en("Native")}</div></div>'''


def feat(x, ic, color, pt, en_text):
    return (f'<div style="position:absolute;left:{x}px;top:560px;width:356px;display:flex;gap:14px;align-items:center;'
            f'padding:16px 18px;border-radius:18px;background:rgba(255,255,255,.05);box-shadow:inset 0 0 0 1px rgba(255,255,255,.09)">'
            f'<span style="flex:none;width:40px;height:40px;border-radius:12px;display:grid;place-items:center;background:{color}26">{icon(ic, color)}</span>'
            f'<div><div style="font-size:15.5px;font-weight:650">{pt}</div><div style="font-size:12.5px;margin-top:3px">{en(en_text)}</div></div></div>')


hub = f'''<div style="position:absolute;left:532px;top:352px;width:216px;height:106px;border-radius:26px;display:grid;place-items:center;text-align:center;
 background:linear-gradient(160deg,#1C1F35,#121427);box-shadow:inset 0 0 0 1px rgba(255,255,255,.16),0 0 0 8px rgba(120,110,255,.08),0 0 60px rgba(120,110,255,.35)">
 <div><img src="data:image/png;base64,{ICON_B64}" style="width:44px;height:44px;border-radius:11px;display:block;margin:0 auto 6px">
 <div style="font-size:14px;font-weight:700">App universal</div><div style="font-size:11.5px">{en("Universal app")}</div></div></div>'''
links = f'''<svg class="ov" width="1280" height="720"><defs>
<linearGradient id="l1" x1="0" x2="1"><stop offset="0" stop-color="{BLUE}" stop-opacity=".2"/><stop offset="1" stop-color="#9C8CFF"/></linearGradient>
<linearGradient id="l2" x1="1" x2="0"><stop offset="0" stop-color="{AMBER}" stop-opacity=".2"/><stop offset="1" stop-color="#9C8CFF"/></linearGradient></defs>
<path d="M 426 405 C 480 405, 480 405, 532 405" stroke="url(#l1)" stroke-width="2.6" fill="none" stroke-dasharray="2 7" stroke-linecap="round"/>
<path d="M 854 405 C 800 405, 800 405, 748 405" stroke="url(#l2)" stroke-width="2.6" fill="none" stroke-dasharray="2 7" stroke-linecap="round"/></svg>'''
pages["5-universal"] = (page(
    f'<div style="position:absolute;left:64px;top:52px;right:64px">'
    f'<span class="badge" style="background:#9C8CFF22;color:#B9AEFF;box-shadow:inset 0 0 0 1px #9C8CFF55">'
    f'<span class="dot" style="background:#9C8CFF;box-shadow:0 0 12px #9C8CFF"></span>NOVO NA 1.4<span class="sep">|</span><span class="b">NEW IN 1.4</span></span>'
    f'<div class="h1" style="margin-top:20px">Um app, dois processadores</div><div class="h1en">{en("One app, two processors")}</div>'
    f'<div class="sub">O mesmo instalador roda nativo em Macs com Apple Silicon e com Intel. Sem Rosetta, sem versões separadas.</div>'
    f'<div class="suben">{en("The same installer runs natively on Apple Silicon and Intel Macs. No Rosetta, no separate builds.")}</div></div>'
    + chip_card(96, "Apple Silicon", "M1 · M2 · M3 · M4<br>e mais novos<br><span style='font-size:12px;color:#8D93AC'>and newer</span>", "arm64", BLUE)
    + chip_card(854, "Intel", "Core i5 · i7 · i9<br>e outros<br><span style='font-size:12px;color:#8D93AC'>and others</span>", "x86_64", AMBER)
    + links + hub
    + feat(64, "box", "#9C8CFF", "Um único arquivo: Tella-1.4.dmg", "One single file: Tella-1.4.dmg")
    + feat(462, "mac", BLUE, "macOS 13 (Ventura) ou mais novo", "macOS 13 (Ventura) or later")
    + feat(860, "bolt", AMBER, "Leve na bateria", "Light on battery")
    + footer().replace('bottom:26px', 'bottom:22px'), 1280, 720), (1280, 720))


# Capa
cover_art = f'''
<div style="position:absolute;left:770px;top:118px;width:420px;height:250px;border-radius:14px;padding:8px;background:linear-gradient(160deg,#2A2C38,#15161E);
 box-shadow:0 0 0 1px rgba(255,255,255,.10),0 40px 80px rgba(0,0,0,.55)"><div class="screen">
 <div class="menubar" style="height:14px"></div>
 <div class="win" style="left:24px;top:30px;width:290px;height:170px"><div class="tb" style="height:20px"><span class="tl" style="width:8px;height:8px"></span><span class="tl" style="width:8px;height:8px"></span><span class="tl" style="width:8px;height:8px"></span></div>
 <div class="body" style="padding:12px"><div class="bar" style="width:70%"></div><div class="bar" style="width:90%"></div><div class="bar" style="width:55%"></div></div></div>
 </div></div>
<div style="position:absolute;left:932px;top:368px;width:96px;height:26px;background:linear-gradient(90deg,#5B5E6E,#9A9DAD 45%,#5B5E6E)"></div>
<div style="position:absolute;left:890px;top:392px;width:180px;height:9px;border-radius:6px;background:linear-gradient(#A7AABA,#6D7080)"></div>
<div style="position:absolute;left:1010px;top:262px;width:226px;height:142px;border-radius:11px 11px 3px 3px;padding:7px;background:linear-gradient(160deg,#2A2C38,#15161E);
 box-shadow:0 0 0 1px rgba(255,255,255,.12),0 30px 60px rgba(0,0,0,.6)"><div class="screen" style="border-radius:4px">
 <div class="menubar" style="height:10px"></div>
 <div class="win on" style="left:40px;top:20px;width:130px;height:96px;border-radius:6px;{ring(GREEN)}"><div class="tb" style="height:15px;padding:0 6px;gap:4px">
 <span class="tl" style="width:6px;height:6px"></span><span class="tl" style="width:6px;height:6px"></span><span class="tl" style="width:6px;height:6px"></span></div>
 <div class="body" style="padding:8px"><div style="font-size:9px;font-weight:700;color:{GREEN};margin-bottom:5px">Hello<span class="caret"></span></div>
 <div class="bar" style="height:5px;margin-bottom:5px;width:85%"></div><div class="bar" style="height:5px;margin-bottom:5px;width:60%"></div></div></div>
 </div></div>
<div style="position:absolute;left:996px;top:404px;width:254px;height:10px;border-radius:2px 2px 10px 10px;background:linear-gradient(#C9CCD8,#7E8192)"></div>
<svg class="ov" width="1280" height="560"><defs><filter id="s" x="-50%" y="-50%" width="200%" height="200%"><feDropShadow dx="0" dy="2" stdDeviation="2" flood-opacity=".5"/></filter></defs>
<path d="M 1004 200 C 1080 150, 1120 220, 1104 318" fill="none" stroke="#fff" stroke-opacity=".7" stroke-width="2.4" stroke-dasharray="1 8" stroke-linecap="round"/>
<g transform="translate(996,192)" opacity=".3">{CURSOR}</g><g transform="translate(1106,322) scale(.9)" filter="url(#s)">{CURSOR}</g></svg>'''


def cchip(pt, en_text=None, color="#C9CEE3"):
    e = f'<div style="font-size:11.5px;margin-top:2px">{en(en_text)}</div>' if en_text else ""
    return (f'<div style="padding:10px 16px;border-radius:14px;background:rgba(255,255,255,.07);box-shadow:inset 0 0 0 1px rgba(255,255,255,.12)">'
            f'<div style="font-size:15px;font-weight:700;color:{color}">{pt}</div>{e}</div>')


pages["cover"] = (page(
    f'''<div style="position:absolute;left:72px;top:96px;width:150px;height:150px;border-radius:36px;
      filter:drop-shadow(0 0 40px rgba(120,110,255,.55)) drop-shadow(0 24px 40px rgba(0,0,0,.5))">
      <img src="data:image/png;base64,{ICON_B64}" style="width:150px;height:150px;display:block"></div>
    <div style="position:absolute;left:262px;top:84px;width:520px">
      <span class="badge" style="background:#3DDC971F;color:{GREEN};box-shadow:inset 0 0 0 1px #3DDC9740;font-size:12.5px">
      <span class="dot" style="background:{GREEN};box-shadow:0 0 12px {GREEN}"></span>VERSÃO {VERSION}<span class="sep">|</span><span class="b">VERSION {VERSION}</span></span>
      <div class="disp" style="font-size:92px;font-weight:800;letter-spacing:-.04em;line-height:1;margin-top:14px">Tella</div>
    </div>
    <div style="position:absolute;left:72px;top:282px;width:680px">
      <div style="font-size:27px;font-weight:600;line-height:1.3;letter-spacing:-.01em">O teclado acompanha o seu cursor entre o MacBook e a tela extra.</div>
      <div style="font-size:16.5px;margin-top:8px">{en("The keyboard follows your pointer between your MacBook and your extra display.")}</div>
    </div>
    <div style="position:absolute;left:72px;top:418px;display:flex;gap:10px">
      {cchip("Apple Silicon + Intel", None, "#fff")}{cchip("App universal", "Universal app")}{cchip("macOS 13 ou mais novo", "macOS 13 or later")}{cchip("36 idiomas", "36 languages")}
    </div>''' + cover_art, 1280, 560), (1280, 560))


with sync_playwright() as p:
    b = p.chromium.launch()
    for name, (html, (w, h)) in pages.items():
        pg = b.new_page(viewport={"width": w, "height": h}, device_scale_factor=2)
        pg.set_content(html)
        pg.wait_for_timeout(300)
        pg.locator(".card").screenshot(path=str(OUT / f"{name}.png"), omit_background=True)
        pg.close()
        print("ok", name)
    b.close()
