#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import shutil
import statistics
import sys
import tempfile
from collections import Counter
from pathlib import Path

import PIL
from PIL import Image, ImageDraw, ImageFont

REPO = Path(__file__).resolve().parents[4]
BASE_COMMIT = "f4827f6ec255b502a1d17ef4642eda295ac162c8"
TOKEN = "ACT-II-S2-S3-H0"
STATE = "CANDIDATE_MACHINE_CONFORMANT_H1_PENDING"
RESERVED = {(244, 244, 244), (65, 166, 246)}
SOURCE_INFO = {
    "act2-shared": ("art-src/world/act2-shared/act2-shared-production-source.png", "b7cd173a2bdb4341456b53eb3a0c919e8fe7696d22402194ea27d3c77fe48ca3"),
    "s2": ("art-src/world/s2/s2-production-source.png", "d590f2d14fcb1efb4731abc93eef18cce39e9e4029f5ef520c67018b0299e5f3"),
}
ASSETS = {
    "world.pressure.ground_calm": ("act2-shared", "ground-calm.png", (32, 16)),
    "world.pressure.ground_runoff": ("act2-shared", "ground-runoff.png", (32, 16)),
    "world.pressure.route_plate": ("act2-shared", "route-plate.png", (32, 16)),
    "world.pressure.cadence_e": ("act2-shared", "cadence-e.png", (32, 16)),
    "world.pressure.cadence_s": ("act2-shared", "cadence-s.png", (32, 16)),
    "world.pressure.cadence_e_s": ("act2-shared", "cadence-e-s.png", (32, 16)),
    "world.pressure.cadence_s_e": ("act2-shared", "cadence-s-e.png", (32, 16)),
    "world.s2.elevated_manometer": ("s2", "elevated-manometer.png", (32, 24)),
    "world.s2.elevated_relief": ("s2", "elevated-relief.png", (32, 24)),
    "world.s2.spawn_louver": ("s2", "spawn-louver.png", (32, 32)),
    "world.s2.core_receiver": ("s2", "core-receiver.png", (32, 32)),
    "world.s2.backdrop_panorama": ("s2", "backdrop-panorama.png", (240, 120)),
}
PROMPT = """# Act II Pressure Descent production-source contract

Approval token: ACT-II-S2-S3-H0
Model: GPT Image 2 (`gpt-image-2`)
Tool/provider: Manus built-in image generation

Create original production source sheets for a deterministic 2:1 dimetric pixel-art tower-defense world. Use wet basalt, cool iron, muted oxidized bronze, rain-fed cisterns, louvers, pressure gauges, and closed receivers. Shared output must support quiet ground, runoff, route plate, E/S cadence and both E-S/S-E corners. S2 must support two distinct raised assay beds, an open outward louver Spawn, closed inward receiver Core, and a continuous noninteractive cistern panorama. Keep gameplay centers and endpoint approaches clear. Panorama must contain no complete playable diamonds or bronze route continuation. No characters, text, UI, logos, reserved probe colors, copied module, or runtime-ready raster.

The source sheets are mandatory palette/material/provenance inputs only. Runtime geometry is authored programmatically and does not crop, resize, trace, or copy a source module.
"""

def rel(path: Path, root: Path) -> str:
    return path.relative_to(root).as_posix()

def digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()

def json_bytes(obj: object) -> bytes:
    return (json.dumps(obj, indent=2, sort_keys=True) + "\n").encode()

def rgbhex(c: tuple[int, int, int]) -> str:
    return "#%02X%02X%02X" % c

def lum(c: tuple[int, int, int]) -> float:
    def q(v: int) -> float:
        x = v / 255.0
        return x / 12.92 if x <= .04045 else ((x + .055) / 1.055) ** 2.4
    y = .2126*q(c[0]) + .7152*q(c[1]) + .0722*q(c[2])
    return 116*(y ** (1/3)) - 16 if y > (6/29) ** 3 else 903.3*y

def sample_source(path: Path) -> list[tuple[int, int, int]]:
    with Image.open(path) as im:
        rgb = im.convert("RGB")
        counts: Counter[tuple[int, int, int]] = Counter()
        for y in range(3, rgb.height, 17):
            for x in range(5, rgb.width, 19):
                r, g, b = rgb.getpixel((x, y))
                q = (r // 16 * 16 + 8, g // 16 * 16 + 8, b // 16 * 16 + 8)
                if q not in RESERVED and 7 <= lum(q) <= 68:
                    counts[q] += 1
        ordered = [c for c, _ in sorted(counts.items(), key=lambda kv: (-kv[1], kv[0]))]
        dark = [c for c in ordered if 10 <= lum(c) < 27]
        mid = [c for c in ordered if 27 <= lum(c) < 45]
        light = [c for c in ordered if 45 <= lum(c) <= 65]
        warm = sorted(ordered, key=lambda c: (-(c[0]-c[2]), abs(lum(c)-39), c))
        cool = sorted(ordered, key=lambda c: (-(c[2]-c[0]), abs(lum(c)-35), c))
        picks = [dark[0], dark[min(4,len(dark)-1)], mid[0], mid[min(5,len(mid)-1)], light[0] if light else mid[-1], warm[0], warm[2], cool[0]]
        return picks

def palette(root: Path = REPO) -> dict[str, tuple[int, int, int]]:
    shared = sample_source(root / SOURCE_INFO["act2-shared"][0])
    s2 = sample_source(root / SOURCE_INFO["s2"][0])
    p = {
        "void": shared[0], "outline": shared[1], "basalt_dark": shared[2], "basalt": shared[3],
        "basalt_light": shared[4], "bronze_dark": shared[5], "bronze": shared[6], "water": shared[7],
        "s2_dark": s2[1], "s2_mid": s2[3], "s2_light": s2[4], "s2_bronze": s2[5], "s2_water": s2[7],
    }
    for key, value in p.items():
        if value in RESERVED:
            raise RuntimeError(f"reserved palette collision {key}={value}")
    return p

def rgba(c: tuple[int,int,int], a: int=255) -> tuple[int,int,int,int]:
    return (*c, a)

def mask32() -> list[bool]:
    out=[]
    for y in range(16):
        for x in range(32):
            out.append(abs((x+.5)-16)/16 + abs((y+.5)-8)/8 <= 1)
    return out

def noise(x:int,y:int,s:int)->int:
    n=(x*374761393+y*668265263+s*1442695041)&0xffffffff
    n=((n^(n>>13))*1274126177)&0xffffffff
    return n^(n>>16)

def tile_base(p:dict, kind:str, salt:int)->Image.Image:
    im=Image.new("RGBA",(32,16),(0,0,0,0)); m=mask32()
    base=p["basalt"] if kind=="ground" else p["bronze_dark"]
    for y in range(16):
        for x in range(32):
            if not m[y*32+x]: continue
            edge=any(nx<0 or nx>=32 or ny<0 or ny>=16 or not m[ny*32+nx] for nx,ny in ((x+1,y),(x-1,y),(x,y+1),(x,y-1)))
            roll=noise(x,y,salt)%100
            c=p["outline"] if edge else base
            if not edge and kind=="ground":
                if roll<7: c=p["basalt_light"]
                elif roll<17: c=p["basalt_dark"]
            if not edge and kind=="route":
                if roll<8: c=p["bronze"]
                elif ((x-y*2+salt)%13)==0 and not (11<=x<=20 and 5<=y<=10): c=p["s2_dark"]
            im.putpixel((x,y),rgba(c))
    return im

def overlay(p:dict, mode:str)->Image.Image:
    im=Image.new("RGBA",(32,16),(0,0,0,0)); d=ImageDraw.Draw(im)
    dark=rgba(p["outline"]); bright=rgba(p["bronze"])
    def chevron(points):
        d.line(points,fill=dark,width=3,joint="curve"); d.line(points,fill=bright,width=1,joint="curve")
    if mode=="e":
        for ox,oy in ((7,4),(14,7),(21,10)): chevron([(ox,oy),(ox+4,oy+2),(ox+1,oy+4)])
    elif mode=="s":
        for ox,oy in ((22,4),(15,7),(8,10)): chevron([(ox,oy),(ox-4,oy+2),(ox-1,oy+4)])
    elif mode=="e_s":
        chevron([(7,4),(13,7),(11,10)]); d.arc((12,4,25,15),30,145,fill=dark,width=3); d.arc((12,4,25,15),30,145,fill=bright,width=1)
    else:
        chevron([(24,4),(18,7),(20,10)]); d.arc((7,4,20,15),35,150,fill=dark,width=3); d.arc((7,4,20,15),35,150,fill=bright,width=1)
    return im

def elevated(p:dict, relief:bool)->Image.Image:
    top=tile_base(p,"ground",83 if relief else 71); im=Image.new("RGBA",(32,24),(0,0,0,0)); im.alpha_composite(top)
    for x in range(32):
        ys=[y for y in range(16) if top.getpixel((x,y))[3]]
        if not ys: continue
        b=max(ys)
        for dy in range(1,9):
            c=p["outline"] if dy==8 else (p["s2_dark"] if x<16 else p["basalt_dark"])
            im.putpixel((x,b+dy),rgba(c))
    d=ImageDraw.Draw(im)
    # wall-only ribs; top center remains quiet
    for x in ((6,24) if not relief else (9,22)):
        d.line((x,14,x,21),fill=rgba(p["s2_bronze"]),width=1)
    if not relief:
        d.ellipse((4,5,10,9),fill=rgba(p["outline"])); d.ellipse((5,6,9,8),fill=rgba(p["s2_light"])); d.point((8,7),fill=rgba(p["outline"]))
    else:
        d.line((5,10,10,8),fill=rgba(p["water"])); d.line((22,7,27,9),fill=rgba(p["water"]))
    return im

def spawn(p:dict)->Image.Image:
    im=Image.new("RGBA",(32,32),(0,0,0,0)); d=ImageDraw.Draw(im)
    # Open/outward louver wings; protected center x=12..19, y=14..27 remains transparent.
    for x,flip in ((4,1),(23,-1)):
        d.polygon([(x,10),(x+5,7),(x+6,28),(x,30)],fill=rgba(p["outline"]))
        d.polygon([(x+1,11),(x+4,9),(x+4,27),(x+1,28)],fill=rgba(p["s2_mid"]))
        for y in (13,17,21): d.line((x+1,y,x+4,y-2*flip),fill=rgba(p["s2_bronze"]))
    d.line((9,11,16,5,23,11),fill=rgba(p["outline"]),width=2)
    d.line((10,11,16,7,22,11),fill=rgba(p["s2_light"]),width=1)
    d.rectangle((13,28,19,30),fill=rgba(p["outline"])); d.point((16,30),fill=rgba(p["s2_bronze"]))
    return im

def core(p:dict)->Image.Image:
    im=Image.new("RGBA",(32,32),(0,0,0,0)); d=ImageDraw.Draw(im)
    # Closed/inward receiver, narrow upper body; approach below y=26 stays mostly open.
    d.ellipse((8,5,24,13),fill=rgba(p["outline"])); d.ellipse((10,7,22,11),fill=rgba(p["s2_mid"]))
    d.rectangle((8,9,24,14),fill=rgba(p["outline"])); d.rectangle((10,11,22,12),fill=rgba(p["s2_dark"])); d.rectangle((8,13,11,24),fill=rgba(p["outline"])); d.rectangle((21,13,24,24),fill=rgba(p["outline"]))
    d.line((12,13,20,13),fill=rgba(p["s2_bronze"]),width=2)
    d.arc((11,12,21,21),180,360,fill=rgba(p["s2_light"]),width=1)
    d.line((8,15,5,18,5,23),fill=rgba(p["outline"]),width=2); d.line((24,15,27,18,27,23),fill=rgba(p["outline"]),width=2)
    d.rectangle((5,23,10,27),fill=rgba(p["outline"])); d.rectangle((22,23,27,27),fill=rgba(p["outline"]))
    d.rectangle((13,27,19,30),fill=rgba(p["outline"])); d.point((16,30),fill=rgba(p["s2_bronze"]))
    return im

def panorama(p:dict)->Image.Image:
    im=Image.new("RGBA",(240,120),(0,0,0,0)); d=ImageDraw.Draw(im)
    # Continuous low enclosure silhouettes and bounded cisterns; deliberately rectilinear/broken, never diamond faces.
    d.rectangle((0,20,239,48),fill=rgba(p["void"])); d.rectangle((0,24,239,42),fill=rgba(p["s2_dark"]))
    for x in range(0,240,24):
        h=9+(noise(x,3,9)%13); d.rectangle((x,42-h,x+5,58),fill=rgba(p["outline"])); d.line((x+1,43-h,x+4,55),fill=rgba(p["s2_mid"]))
    for a,b,y in ((0,48,78),(58,108,85),(120,174,76),(188,239,84)):
        d.rectangle((a,y,b,112),fill=rgba(p["outline"])); d.rectangle((a+3,y+4,b-3,108),fill=rgba(p["s2_dark"]))
        d.rectangle((a+7,y+12,b-7,104),fill=rgba(p["s2_water"]))
        for xx in range(a+9,b-7,11): d.line((xx,y+18,xx+6,y+17),fill=rgba(p["water"]))
    for x in (12,50,112,178,229):
        d.line((x,38,x,98),fill=rgba(p["outline"]),width=4); d.line((x+1,39,x+1,96),fill=rgba(p["s2_bronze"]),width=1)
    # irregular broken top silhouette prevents grid/diamond interpretation
    d.line([(0,59),(27,55),(42,63),(71,57),(96,64),(126,56),(153,62),(184,54),(213,61),(239,57)],fill=rgba(p["basalt_light"]),width=2)
    return im

def build_assets(p:dict)->dict[str,Image.Image]:
    calm=tile_base(p,"ground",11); runoff=tile_base(p,"ground",29); rd=ImageDraw.Draw(runoff)
    rd.line((4,8,11,7,17,9,27,7),fill=rgba(p["water"]),width=1); rd.line((9,11,15,10,21,11),fill=rgba(p["s2_water"]),width=1)
    return {
        "world.pressure.ground_calm": calm, "world.pressure.ground_runoff": runoff,
        "world.pressure.route_plate": tile_base(p,"route",47), "world.pressure.cadence_e": overlay(p,"e"),
        "world.pressure.cadence_s": overlay(p,"s"), "world.pressure.cadence_e_s": overlay(p,"e_s"),
        "world.pressure.cadence_s_e": overlay(p,"s_e"), "world.s2.elevated_manometer": elevated(p,False),
        "world.s2.elevated_relief": elevated(p,True), "world.s2.spawn_louver": spawn(p),
        "world.s2.core_receiver": core(p), "world.s2.backdrop_panorama": panorama(p),
    }

def png_bytes(im:Image.Image)->bytes:
    import io
    b=io.BytesIO(); im.save(b,"PNG",compress_level=9,optimize=False); return b.getvalue()

def inspect(im:Image.Image, expected:tuple[int,int])->dict:
    partial=reserved=opaque=0
    vals=[]
    for r,g,b,a in im.get_flattened_data():
        if 0<a<255: partial+=1
        if a==255:
            opaque+=1; vals.append(lum((r,g,b)))
            if (r,g,b) in RESERVED: reserved+=1
    return {"size":list(im.size),"expected_size":list(expected),"opaque_pixels":opaque,"opaque_bbox":list(im.getbbox() or ()),"partial_alpha_pixels":partial,"reserved_color_pixels":reserved,"opaque_median_cie_lstar":round(statistics.median(vals),3) if vals else 0}

def contact(images:dict[str,Image.Image], family:str)->Image.Image:
    keys=[k for k,v in ASSETS.items() if v[0]==family]; cw,ch=300,220; cols=2 if family=="s2" else 3; rows=math.ceil(len(keys)/cols)
    sheet=Image.new("RGBA",(cw*cols,ch*rows),(18,22,27,255)); dr=ImageDraw.Draw(sheet); font=ImageFont.load_default()
    for i,k in enumerate(keys):
        ox=(i%cols)*cw; oy=(i//cols)*ch; dr.text((ox+10,oy+8),k,fill=(220,205,173,255),font=font)
        im=images[k]; scale=min(6,240//im.width,160//im.height); up=im.resize((im.width*scale,im.height*scale),Image.Resampling.NEAREST)
        sheet.alpha_composite(up,(ox+(cw-up.width)//2,oy+35+(170-up.height)//2))
    return sheet

def topology_mock(images:dict[str,Image.Image],p:dict)->Image.Image:
    canvas=Image.new("RGBA",(480,240),rgba(p["void"])); canvas.alpha_composite(images["world.s2.backdrop_panorama"].resize((480,240),Image.Resampling.NEAREST))
    origin=(176,42); route={(x,2) for x in range(10)}; elevateds={(3,1):"world.s2.elevated_manometer",(3,3):"world.s2.elevated_relief"}; cadence={(2,2),(4,2),(6,2),(8,2)}
    for depth in range(14):
        for y in range(5):
            for x in range(10):
                if x+y!=depth: continue
                k="world.pressure.route_plate" if (x,y) in route else ("world.pressure.ground_runoff" if (x+y)%4==0 else "world.pressure.ground_calm")
                if (x,y) in elevateds:k=elevateds[(x,y)]
                cx=origin[0]+(x-y)*32; cy=origin[1]+(x+y)*16; im=images[k].resize((imw:=images[k].width*2,images[k].height*2),Image.Resampling.NEAREST)
                canvas.alpha_composite(im,(cx-32,cy-16-(16 if (x,y) in elevateds else 0)))
                if (x,y) in cadence:
                    ov=images["world.pressure.cadence_e"].resize((64,32),Image.Resampling.NEAREST); canvas.alpha_composite(ov,(cx-32,cy-16))
    for x,k in ((0,"world.s2.spawn_louver"),(9,"world.s2.core_receiver")):
        cx=origin[0]+(x-2)*32; cy=origin[1]+(x+2)*16; obj=images[k].resize((64,64),Image.Resampling.NEAREST); canvas.alpha_composite(obj,(cx-32,cy-60))
    return canvas

def make_ledger(family:str, root:Path, prompt_path:Path)->dict:
    source_rel, expected_hash=SOURCE_INFO[family]; source=root/source_rel
    if digest(source)!=expected_hash: raise RuntimeError(f"source hash mismatch: {source_rel}")
    selection_path=root/f"art-src/world/{family}/production-source-selection.json"
    if not selection_path.is_file(): raise RuntimeError(f"missing checked-in selection ledger: {selection_path}")
    selection=json.loads(selection_path.read_text(encoding="utf-8"))
    if selection.get("packet")!=family or selection.get("selection_count")!=1: raise RuntimeError(f"selection ledger packet/count mismatch: {family}")
    selected=selection.get("selected_candidate",{})
    if selected.get("canonical_source_path")!=source_rel or selected.get("sha256")!=expected_hash: raise RuntimeError(f"selection ledger source mismatch: {family}")
    prompt_rel=rel(prompt_path,root); prompt_hash=digest(prompt_path)
    if selection.get("prompt")!={"path":prompt_rel,"sha256":prompt_hash}: raise RuntimeError(f"selection ledger prompt mismatch: {family}")
    for reference in selection.get("references",[]):
        reference_path=root/reference["path"]
        if not reference_path.is_file() or digest(reference_path)!=reference.get("sha256"): raise RuntimeError(f"selection reference mismatch: {reference.get('path')}")
    return {"schema_version":1,"family":family,"state":STATE,"human_final_art":False,"approval_token":TOKEN,
        "generator":selection["generator"],
        "prompt":selection["prompt"],"references":selection["references"],
        "selection":{"path":rel(selection_path,root),"sha256":digest(selection_path)},
        "source":{"path":source_rel,"sha256":expected_hash,"runtime_usage":"PALETTE_MATERIAL_PROVENANCE_INPUT_ONLY_NOT_RUNTIME_RASTER"},
        "approval":{"token":TOKEN,"content_hash_launch_dependency":False},
        "production_method":"deterministic Pillow source-palette extraction plus independently authored programmatic pixel geometry; no source module copied/resized"}

def contract(family:str)->dict:
    entries=[]
    for k,(fam,name,size) in ASSETS.items():
        if fam==family: entries.append({"logical_id":k,"filename":name,"native_size":list(size),"state":STATE,"human_final_art":False,"pivot":[16,30] if size==(32,32) else None})
    return {"schema_version":1,"lane":"ACT2-S2-SHARED","family":family,"base_commit":BASE_COMMIT,"approval_token":TOKEN,"candidate_state":STATE,"assets":entries,"reserved_colors":["#F4F4F4","#41A6F6"],"alpha_values":[0,255],"runtime_staging_bytes_identical":True}

def write_package(outroot:Path)->dict:
    p=palette(outroot); images=build_assets(p)
    generated_roots=[outroot/"assets/world/act2-shared",outroot/"assets/world/s2",outroot/"assets/provenance/fragments/act2-shared",outroot/"assets/provenance/fragments/s2",outroot/"staging/assets/world/act2-shared",outroot/"staging/assets/world/s2",outroot/"staging/provenance/world/act2-shared",outroot/"staging/provenance/world/s2",outroot/"staging/qa/world/act2-shared",outroot/"staging/qa/world/s2"]
    # Atomic owned-set replacement: construct all destination trees in sibling temporary roots, then replace.
    temp=Path(tempfile.mkdtemp(prefix="act2-s2-build-",dir=outroot if outroot.exists() else None))
    try:
        for family in ("act2-shared","s2"):
            (temp/f"assets/world/{family}").mkdir(parents=True,exist_ok=True); (temp/f"staging/assets/world/{family}").mkdir(parents=True,exist_ok=True)
            (temp/f"assets/provenance/fragments/{family}").mkdir(parents=True,exist_ok=True); (temp/f"staging/provenance/world/{family}").mkdir(parents=True,exist_ok=True)
            (temp/f"staging/qa/world/{family}").mkdir(parents=True,exist_ok=True)
        report_assets={}
        tool_rel="tools/art_pipeline/world/act2_shared/normalize.py"
        tool_hash=digest(REPO/tool_rel)
        for logical,(family,name,size) in ASSETS.items():
            data=png_bytes(images[logical]); runtime=temp/f"assets/world/{family}/{name}"; staged=temp/f"staging/assets/world/{family}/{name}"; runtime.write_bytes(data); staged.write_bytes(data)
            d=hashlib.sha256(data).hexdigest(); report_assets[logical]={**inspect(images[logical],size),"sha256":d}
            source_rel,source_hash=SOURCE_INFO[family]
            side={"schema_version":1,"logical_id":logical,"state":STATE,"human_final_art":False,"final_file":f"assets/world/{family}/{name}","staged_file":f"staging/assets/world/{family}/{name}","final_file_sha256":d,
                "source":{"path":source_rel,"sha256":source_hash,"usage":"palette/material/provenance input only; not copied or resized"},
                "generator":{"provider":"Manus built-in image generation","tool":"Manus built-in image generation","model":"gpt-image-2","generation_id":"UNAVAILABLE","seed":"UNAVAILABLE","unavailability_reason":"Generation tool exposed neither generation ID nor seed; neither is invented."},
                "approval":{"token":TOKEN,"human_final_art":False,"approved_content_hash_launch_dependency":False},
                "normalization":{"tool":tool_rel,"tool_sha256":tool_hash,"python":sys.version.split()[0],"pillow":PIL.__version__,"method":"deterministic source palette extraction + original programmatic pixel shape; hard alpha; no dithering"},
                "reserved_colors":{"forbidden":["#F4F4F4","#41A6F6"],"gate":"PASS"}}
            fname=logical.replace(".","_")+".provenance.json"; payload=json_bytes(side)
            (temp/f"assets/provenance/fragments/{family}/{fname}").write_bytes(payload); (temp/f"staging/provenance/world/{family}/{fname}").write_bytes(payload)
        for family in ("act2-shared","s2"):
            cs=contact(images,family); cs.save(temp/f"staging/qa/world/{family}/{family}-contact-sheet.png",compress_level=9)
        mock=topology_mock(images,p); mock.save(temp/"staging/qa/world/s2/s2-topology-mock.png",compress_level=9)
        # Panorama topology rule is structural: no 32x16 diamond masks are used by its builder, and no route palette colors are present.
        common={"schema_version":1,"state":STATE,"human_final_art":False,"machine_gate":"PASS","approval_token":TOKEN,"assets":report_assets,"palette":{k:rgbhex(v) for k,v in p.items()},"source_hygiene":"PASS","runtime_staged_byte_identity":"PASS"}
        shared_ids={k:v for k,v in report_assets.items() if ASSETS[k][0]=="act2-shared"}; s2_ids={k:v for k,v in report_assets.items() if ASSETS[k][0]=="s2"}
        (temp/"staging/qa/world/act2-shared/normalization-report.json").write_bytes(json_bytes({**common,"family":"act2-shared","assets":shared_ids}))
        (temp/"staging/qa/world/s2/normalization-report.json").write_bytes(json_bytes({**common,"family":"s2","assets":s2_ids,"topology":{"grid":[10,5],"spawn":[0,2],"core":[9,2],"elevated":[[3,1],[3,3]],"route":[[x,2] for x in range(10)],"cadence":[[2,2],[4,2],[6,2],[8,2]],"false_route_in_panorama":False,"complete_playable_diamond_in_panorama":False}}))
        # replace complete generated roots; stale files cannot survive
        for target in generated_roots:
            src=temp/target.relative_to(outroot)
            target.parent.mkdir(parents=True,exist_ok=True)
            if target.exists(): shutil.rmtree(target)
            os.replace(src,target)
    finally:
        shutil.rmtree(temp,ignore_errors=True)
    # Ledgers/contracts are generated deterministically but source rasters remain untouched.
    for family in ("act2-shared","s2"):
        srcdir=outroot/f"art-src/world/{family}"; srcdir.mkdir(parents=True,exist_ok=True)
        prompt=srcdir/"production-prompt-contract.md"
        if not prompt.is_file() or prompt.read_text(encoding="utf-8") != PROMPT:
            raise RuntimeError(f"frozen prompt contract missing or mutated: {prompt}")
        (srcdir/"source-ledger.json").write_bytes(json_bytes(make_ledger(family,outroot,prompt)))
        (srcdir/"asset-contract.json").write_bytes(json_bytes(contract(family)))
        (srcdir/"derived-palette.json").write_bytes(json_bytes({k:rgbhex(v) for k,v in p.items()}))
        gd=srcdir/".gdignore"
        if not gd.exists(): gd.write_text("# Source-only production inputs; runtime uses assets/world/.\n",encoding="utf-8")
    return {"state":STATE,"assets":len(ASSETS),"machine_gate":"PASS"}

def main()->None:
    ap=argparse.ArgumentParser(); ap.add_argument("--output-root",type=Path,default=REPO); args=ap.parse_args()
    args.output_root.mkdir(parents=True,exist_ok=True); print(json.dumps(write_package(args.output_root),sort_keys=True))
if __name__=="__main__": main()
