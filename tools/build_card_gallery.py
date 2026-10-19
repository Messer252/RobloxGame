"""Export the original TCG card gallery from CardCatalog; no image editing."""
from pathlib import Path
import html
import re
ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / "src/shared/CardCatalog.luau").read_text()
rows = re.findall(r'^\s*\{ "([^"]+)", "([^"]+)", "([^"]+)", "(\w+)", ([.\d]+)(?:, "(\w+)", ([.\d]+))? \},', source, re.M)
assert len(rows) == 40
labels = dict(Cash="income", Speed="production", Sales="sales", Crumbs="Star Crumbs", Mine="mining damage")
cards = []
for index, row in enumerate(rows):
    name, animal, quip, stat, amount, second, extra = row
    rarity = "Common" if index < 15 else "Uncommon" if index < 25 else "Rare" if index < 32 else "Legendary" if index < 35 else "Mythical"
    rank = ["Common", "Uncommon", "Rare", "Legendary", "Mythical"].index(rarity) + 1
    effects = []
    for key, value in [(stat, amount), (second, extra)]:
        if key:
            number = float(value)
            effects.append(f"+{number:g} {labels[key]}" if key == "Mine" else f"+{round(number * 100)}% {labels[key]}")
    cell = index % 10
    image = f"CookieTCG_{index // 10 + 1:02}.png"
    position = f"{cell % 5 * 25}% {cell // 5 * 100}%"
    cards.append(f'''<article class="{rarity}" data-name="{html.escape(name.lower())}" data-rarity="{rarity}"><div class="stock">
<header><h2>{html.escape(name)}</h2><span class="gem">◆</span></header>
<div class="type">{html.escape(animal.upper())} / BAKERY COMPANION <span>{'◆' * rank}</span></div>
<div class="art" role="img" aria-label="{html.escape(name)} illustration" style="background-image:url({image});background-position:{position}"></div>
<div class="ribbon">{rarity.upper()} · COOKIE CORNER</div><section class="ability"><b>BAKERY AURA</b><p>{html.escape(' • '.join(effects))}</p></section>
<blockquote>“{html.escape(quip)}”</blockquote><footer><span>CRUMBKIN / FIRST BATCH</span><span>{index + 1:03} / 040</span></footer></div></article>''')
page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Crumbkin — Cookie Animal TCG</title>
<style>:root{color-scheme:dark}*{box-sizing:border-box}body{margin:0;background:#151d25;color:#f6ecd3;font:15px system-ui}body>header,.filters,main{max-width:1500px;margin:auto;padding:24px}body>header{padding-bottom:0}h1{font-size:36px;letter-spacing:2px;margin-bottom:6px}.intro{color:#b8c4c8;max-width:740px;line-height:1.6}.filters{display:flex;gap:12px;flex-wrap:wrap}input,select{padding:12px;border:1px solid #465460;border-radius:6px;background:#202e37;color:#f6ecd3;font:inherit}input{min-width:260px}.count{padding:12px;color:#b8c4c8}main{display:grid;grid-template-columns:repeat(auto-fill,minmax(265px,1fr));gap:28px;padding-top:4px}article{--rarity:#b7b9ac;padding:6px;background:var(--rarity);border:5px solid #232732;border-radius:13px;box-shadow:0 10px 30px #0008;transition:transform .2s}article:hover{transform:translateY(-5px)}article[hidden]{display:none}.Uncommon{--rarity:#74bc8a}.Rare{--rarity:#73b7ed}.Legendary{--rarity:#e8be66}.Mythical{--rarity:#c895e5}.Legendary,.Mythical{background:linear-gradient(125deg,#f3cf7c,#9bd7e2,#cda0ed,#f3cf7c);background-size:250% 250%;animation:foil 7s linear infinite}@keyframes foil{50%{background-position:100% 100%}}.stock{padding:8px;background:linear-gradient(145deg,#f7ebcf,#cdb38b);color:#282a2c;border-radius:5px}.stock header{background:#29323d;color:#fff0ce;padding:8px 9px;display:flex;gap:8px;align-items:center}.stock h2{font-size:16px;letter-spacing:-.4px;margin:0;flex:1;min-height:38px;display:flex;align-items:center}.gem{color:var(--rarity)}.type{font-size:8px;font-weight:800;letter-spacing:.5px;margin:6px 1px;display:flex;justify-content:space-between}.art{aspect-ratio:1.2;background-color:#ddd1b8;background-size:500% 200%;border:3px solid #424746;outline:1px solid #927f5c}.ribbon{background:var(--rarity);font-size:9px;font-weight:900;letter-spacing:1px;padding:5px 7px;margin:6px 0}.ability{background:#f7efd9;border:1px solid #a98c63;padding:8px 7px;min-height:72px}.ability b{font-size:9px;letter-spacing:1px;color:#7a572f}.ability p{font-size:12px;font-weight:700;margin:8px 0 0;line-height:1.5}blockquote{font:italic 15px Georgia,serif;color:#665039;border-top:1px solid #af956f;min-height:52px;margin:8px 0;padding:8px 3px 0;line-height:1.3}footer{display:flex;justify-content:space-between;font-size:8px;font-weight:700;padding:3px 1px}@media(prefers-reduced-motion:reduce){article{animation:none!important;transition:none}}
</style><body><header><h1>CRUMBKIN</h1><p class="intro">Cookie Corner’s original trading-card collection. Forty cookie creatures, hand-drawn anime direction, dynamic illustrations, clear bakery abilities, and foil frames for legendary and mythical cards.</p></header><div class="filters"><input id="search" aria-label="Search cookie animals" placeholder="Find a cookie creature…"><select id="rarity" aria-label="Filter rarity"><option value="">All rarities</option><option>Common</option><option>Uncommon</option><option>Rare</option><option>Legendary</option><option>Mythical</option></select><span class="count" id="count">40 cards</span></div><main>'''
page += "\n".join(cards)
page += '''</main><script>const search=document.querySelector('#search'),rarity=document.querySelector('#rarity'),cards=[...document.querySelectorAll('article')];function filter(){let count=0;for(const card of cards){card.hidden=!(card.dataset.name.includes(search.value.toLowerCase())&&(!rarity.value||card.dataset.rarity===rarity.value));if(!card.hidden)count++;}document.querySelector('#count').textContent=count+' cards';}search.addEventListener('input',filter);rarity.addEventListener('change',filter);</script></body></html>'''
(ROOT / "assets/cards/Gallery.html").write_text(page)
print(f"Built gallery for {len(cards)} original TCG cards.")
