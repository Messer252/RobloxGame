"""Build original, script-free Roblox models, seamless PNGs, and contact sheets.

Python 3 + Pillow + NumPy. All geometry and image pixels are authored here;
no Creator Store downloads, external meshes, or third-party textures are used.
"""
from __future__ import annotations

import hashlib
import json
import math
import random
import re
from pathlib import Path
from xml.etree import ElementTree as ET

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets"
TEXTURES = OUT / "textures"
MODELS = OUT / "models"
PREVIEWS = OUT / "previews"
MATERIALS = {"SmoothPlastic": 272, "Wood": 512, "WoodPlanks": 528, "Marble": 784,
             "Slate": 800, "Concrete": 816, "Brick": 848, "Metal": 1088,
             "Grass": 1280, "Fabric": 1312, "Glass": 1568, "Neon": 288}
CREAM, COCOA, GOLD, STEEL = (249, 230, 195), (96, 59, 44), (255, 197, 58), (112, 132, 143)
recipes = []
for line in (ROOT / "src/shared/Recipes.luau").read_text().splitlines():
    match = re.search(r'Name = "([^"]+)".*Color = \{([^}]+)\}, Accent = \{([^}]+)\}', line)
    if match:
        recipes.append({"name": match[1], "color": tuple(map(int, match[2].split(","))),
                        "accent": tuple(map(int, match[3].split(",")))})
assert len(recipes) == 30, "Update the asset generator when changing the recipe catalog."


def tint(rgb, factor):
    return tuple(max(0, min(255, round(channel * factor))) for channel in rgb)


def model(name, category="Props"):
    result = {"name": name, "category": category, "parts": []}
    add(result, "Root", (.1, .1, .1), (0, 0, 0), CREAM, transparency=1)
    return result


def add(target, name, size, pos, rgb, shape="Block", material="SmoothPlastic", rotation=(0, 0, 0),
        transparency=0, collide=False):
    target["parts"].append({"name": name, "size": size, "pos": pos, "color": rgb,
                            "shape": shape, "material": material, "rotation": rotation,
                            "transparency": transparency, "collide": collide})


def disc(target, name, diameter, height, pos, rgb, material="SmoothPlastic"):
    add(target, name, (height, diameter, diameter), pos, rgb, "Cylinder", material, (0, 0, 90))


def anchor(target, y):
    add(target, "LabelAnchor", (.1, .1, .1), (0, y, 0), CREAM, transparency=1)


def cookie(index, recipe):
    target = model(recipe["name"], "Cookies")
    rng = random.Random(800 + index)
    base, accent = recipe["color"], recipe["accent"]
    disc(target, "Baked Edge", 3.55, .48, (0, -.06, 0), tint(base, .84))
    disc(target, f"Texture_Cookie{index:02}", 3.35, .19, (0, .20, 0), base)
    for crumb in range(4):
        angle = crumb * math.pi / 2 + .2
        add(target, "Baked Crumb", (.35, .18, .28), (1.56 * math.cos(angle), -.05, 1.56 * math.sin(angle)), tint(base, .94), "Ball")
    frosted = index in (3, 11, 15, 17, 19, 23)
    if frosted:
        disc(target, "Vanilla Frosting", 2.75, .14, (0, .34, 0), (255, 244, 221))
    top = .49 if frosted else .39

    def scatter(count, style="chips", shades=None):
        for n in range(count):
            angle = n * 2.399963 + rng.random() * .25
            radius = .25 + math.sqrt((n + 1) / count) * 1.0
            rgb = (shades or [accent])[n % len(shades or [accent])]
            size = (.44, .22, .36)
            shape = "Block"
            if style == "sprinkles": size = (.12, .10, .42)
            elif style == "flakes": size = (.40, .08, .15)
            elif style == "berries": size, shape = (.43, .38, .43), "Ball"
            elif style == "nuts": size, shape = (.57, .23, .31), "Ball"
            elif style == "diamonds": size = (.35, .33, .35)
            add(target, style.title(), size, (radius * math.cos(angle), top, radius * math.sin(angle)), rgb,
                shape, rotation=(0, rng.uniform(0, 180), 0))

    def drizzle(rgb, count=3):
        for n in range(count):
            add(target, "Icing Drizzle", (.12, .10, 2.35 - abs(n - 1) * .35), ((n - (count - 1) / 2) * .58, top + .13, 0), rgb,
                rotation=(0, -26, 0))

    rainbow = [(255, 100, 139), (94, 217, 203), (255, 217, 79), (150, 132, 248)]
    if index == 2:
        scatter(5, "flakes", [(229, 197, 142)])
        scatter(4, "berries")
    elif index in (5, 23, 27):
        scatter(10, "sprinkles", rainbow)
        if index == 27: scatter(3, "diamonds", [(206, 244, 255)])
    elif index == 6:
        for axis in (0, 90):
            for n in (-1, 0, 1):
                add(target, "Peanut Butter Crosshatch", (.09, .06, 2.3), (n * .62 if axis == 0 else 0, top, n * .62 if axis else 0),
                    accent, rotation=(0, axis, 0))
    elif index in (7, 14, 21):
        scatter(9, "flakes")
        if index == 21: drizzle((248, 221, 178), 2)
    elif index in (9, 10):
        drizzle(accent)
        scatter(4, "berries", [accent])
    elif index in (8, 12, 18):
        scatter(7)
    elif index == 13:
        drizzle((148, 76, 30))
        scatter(5, "flakes", [(255, 250, 234)])
    elif index == 16:
        add(target, "Chocolate Square", (2.15, .18, 1.8), (0, .38, 0), (74, 42, 30))
        scatter(4, "berries", [(255, 247, 227)])
    elif index in (15, 19, 25):
        scatter(7, "berries", [(209, 64, 94)] if index == 15 else None)
        if index == 25: drizzle((235, 151, 177), 2)
    elif index == 20:
        scatter(7, "nuts")
    elif index == 22:
        scatter(5, "nuts", [(118, 144, 70)])
        scatter(4, "flakes", [accent])
    elif index == 24:
        for n in range(12):
            angle = n * math.pi / 6
            radius = .25 + n * .075
            add(target, "Cinnamon Swirl", (.43, .09, .13), (radius * math.cos(angle), top, radius * math.sin(angle)), accent,
                rotation=(0, -math.degrees(angle) + 90, 0))
    elif index == 26:
        scatter(6, "nuts")
        drizzle((237, 183, 103), 2)
    elif index == 28:
        for n in range(5):
            angle = n * math.pi * 2 / 5
            p = (.88 * math.cos(angle), top + .07, .88 * math.sin(angle))
            add(target, "Marshmallow", (.62, .45, .62), p, (255, 244, 214))
            add(target, "Toasted Top", (.48, .05, .48), (p[0], p[1] + .23, p[2]), accent)
    elif index == 29:
        scatter(8, "diamonds")
    elif index == 30:
        for n in range(6):
            angle = n * math.pi / 3
            x, z = math.cos(angle), math.sin(angle)
            disc(target, "Golden Chip Base", .45, .19, (x, top, z), accent, "Metal")
            disc(target, "Golden Chip Tip", .24, .16, (x, top + .16, z), GOLD, "Metal")
    else:
        scatter(8, "berries" if index == 3 else "chips")
    return target


def props():
    result = []
    def create(name):
        obj = model(name)
        result.append(obj)
        return obj

    oven = create("Oven")
    add(oven, "Texture_OvenBrick", (14.5, 1.2, 11.5), (0, .7, 0), (178, 95, 63), material="Brick")
    add(oven, "Texture_BrushedMetal", (14, 8, 11), (0, 4.5, 0), STEEL, material="Metal", collide=True)
    add(oven, "Oven Door", (11, 5.5, .4), (0, 4.5, 5.7), (45, 49, 54), material="Metal")
    add(oven, "Window", (9, 3.6, .3), (0, 4.7, 5.95), (246, 151, 61), material="Neon")
    add(oven, "Handle", (8, .45, .55), (0, 7.1, 6.2), (219, 222, 213), material="Metal")
    add(oven, "RecipeBadge", (12, 1.3, 2), (0, 9.15, 3), GOLD, material="Metal")
    for x in (-4, 4):
        add(oven, "Temperature Dial", (.85, .85, .4), (x, 8, 5.8), (238, 221, 188), "Cylinder", rotation=(0, 90, 0))
    for x in (-5, 5):
        add(oven, "Foot", (1.2, 1, 8), (x, .5, 0), (49, 55, 60), material="Metal")
    add(oven, "Chimney", (2.2, 2.5, 2.2), (4, 9.5, -3), STEEL, material="Metal")

    conveyor = create("Conveyor")
    add(conveyor, "Texture_ConveyorRubber", (11.8, .5, 25), (0, 1, 0), (49, 55, 61), collide=True)
    for x in (-6.1, 6.1):
        add(conveyor, "Safety Rail", (.45, .55, 25), (x, 1.3, 0), STEEL, material="Metal")
    for z in (-10, -5, 0, 5, 10):
        add(conveyor, "Belt Seam", (11.5, .045, .12), (0, 1.28, z), (76, 83, 88))
    for x in (-4.5, 4.5):
        for z in (-10, 10): add(conveyor, "Leg", (.8, 1, .8), (x, .5, z), STEEL, material="Metal")

    register = create("CollectionRegister")
    add(register, "Texture_WoodWarm", (16, 3, 8), (0, 1.5, 0), COCOA, material="WoodPlanks", collide=True)
    add(register, "Texture_CounterMarble", (17, .6, 9), (0, 3.3, 0), CREAM, material="Marble")
    add(register, "Register", (4, 2, 3.5), (2, 4.6, 0), (76, 130, 109), material="Metal")
    add(register, "Screen", (3, 1.2, .2), (2, 5, 1.85), (148, 244, 177), material="Neon")
    for x in (-3, -1.5): disc(register, "Coin Stack", 1.1, .6, (x, 3.9, 0), GOLD, "Metal")
    anchor(register, 7)

    console = create("UpgradeConsole")
    add(console, "Base", (13, 1, 7), (0, .5, 0), (106, 82, 153), material="Metal")
    add(console, "Pedestal", (7, 3.5, 4), (0, 2.7, 0), STEEL, material="Metal", collide=True)
    add(console, "Control Panel", (9, 3, .5), (0, 5, 2), (51, 39, 76), rotation=(-15, 0, 0))
    for x in (-2.5, 0, 2.5): add(console, "Upgrade Light", (.8, .8, .3), (x, 5, 2.4), (188, 156, 255), "Ball", "Neon")
    anchor(console, 7)

    pedestal = create("RebirthPedestal")
    disc(pedestal, "Marble Base", 12, 1, (0, .5, 0), (251, 226, 170), "Marble")
    disc(pedestal, "Gold Rim", 9, .6, (0, 1.3, 0), GOLD, "Metal")
    for tier in range(6):
        disc(pedestal, "Texture_GoldenChip" if tier == 0 else "Golden Chocolate Chip", 6 - tier * .9, .85, (0, 2.1 + tier * .65, 0), GOLD, "Metal")
    anchor(pedestal, 8)

    claim = create("ClaimPad")
    add(claim, "Frame", (16, .55, 8), (0, .28, 0), (59, 111, 85))
    add(claim, "Claim Surface", (14.5, .2, 6.5), (0, .65, 0), (110, 212, 160), material="Neon")
    anchor(claim, 2)

    sign = create("BakerySign")
    for x in (-17, 17): add(sign, "Post", (1.5, 15, 1.5), (x, 7.5, 0), COCOA, material="Wood")
    add(sign, "Texture_WoodWarm", (35, 5, 1.5), (0, 13, 0), COCOA, material="WoodPlanks")
    add(sign, "Sign Trim", (36, .5, 2), (0, 15.5, 0), GOLD, material="Metal")
    anchor(sign, 13)

    floor = create("BakeryFloor")
    add(floor, "Texture_BakeryFloor", (164, 1, 244), (0, 0, 0), (241, 222, 189), material="WoodPlanks", collide=True)
    for x in (-81, 81): add(floor, "Floor Border", (2, .15, 244), (x, .55, 0), COCOA, material="Wood")

    shell = create("BakeryShell")
    add(shell, "Texture_WallTile", (164, 12, 1.5), (0, 6.5, -121), (237, 220, 191), material="Brick", collide=True)
    for x in (-81, 81):
        add(shell, "Texture_WallTile", (1.5, 8, 244), (x, 4.5, 0), (237, 220, 191), material="Brick", collide=True)
        add(shell, "Wall Cap", (2, .5, 244), (x, 8.8, 0), COCOA, material="Wood")
    add(shell, "Back Trim", (164, .6, 2), (0, 12.7, -121), COCOA, material="Wood")

    awning = create("BakeryAwning")
    for stripe in range(14):
        add(awning, "Texture_AwningStripe" if stripe == 0 else "Canopy Stripe", (10, .4, 11), (-65 + stripe * 10, 16, 0),
            (186, 85, 72) if stripe % 2 else CREAM, material="Fabric", rotation=(-10, 0, 0))
    for x in (-70, 70): add(awning, "Canopy Post", (1, 16, 1), (x, 8, 4), COCOA, material="Wood")

    bins = create("IngredientBins")
    for x, ingredient in zip((-4, 0, 4), ((240, 223, 185), (87, 51, 38), (239, 194, 114))):
        add(bins, "Ingredient Bin", (3.5, 3, 4), (x, 1.5, 0), STEEL, material="Metal", collide=True)
        add(bins, "Ingredient Fill", (3, .35, 3.5), (x, 3.05, 0), ingredient)
        add(bins, "Scoop", (.8, .2, 1.7), (x, 3.4, .4), (210, 217, 214), material="Metal", rotation=(0, 20, 0))

    mixer = create("DoughMixer")
    add(mixer, "Base", (5, .6, 5), (0, .3, 0), (177, 85, 75), material="Metal", collide=True)
    add(mixer, "Stand", (1, 5, 1), (-1.8, 3, -1.5), (177, 85, 75), material="Metal")
    add(mixer, "Mixer Head", (5, 1.4, 2.4), (0, 5.4, -1), (177, 85, 75), material="Metal")
    disc(mixer, "Mixing Bowl", 4, 2.2, (0, 1.8, 0), (193, 205, 207), "Metal")
    disc(mixer, "Cookie Dough", 3.5, .2, (0, 2.95, 0), (218, 173, 112))
    add(mixer, "Whisk", (.3, 2.1, .3), (0, 4, 0), (216, 223, 221), material="Metal")

    rack = create("CoolingRack")
    for x in (-3, 3):
        for z in (-2, 2): add(rack, "Upright", (.35, 9, .35), (x, 4.5, z), STEEL, material="Metal")
    for y in (1.5, 4, 6.5, 9):
        add(rack, "Texture_Parchment", (6, .2, 4), (0, y, 0), (225, 211, 176))
        for x in (-1.5, 1.5): disc(rack, "Cooling Cookie", 1.4, .2, (x, y + .25, 0), (202, 148, 85))

    counter = create("PrepCounter")
    add(counter, "Texture_WoodWarm", (13, 4, 6), (0, 2, 0), COCOA, material="WoodPlanks", collide=True)
    add(counter, "Texture_CounterMarble", (14, .5, 7), (0, 4.3, 0), CREAM, material="Marble")
    add(counter, "Texture_Parchment", (7, .08, 4.2), (-1, 4.6, 0), (239, 224, 186))
    add(counter, "Rolling Pin", (7, .65, .65), (0, 5.0, .4), (192, 143, 88), "Cylinder", "Wood")

    fence = create("WoodenFence")
    for x in (-6, 6): add(fence, "Post", (1, 5, 1), (x, 2.5, 0), COCOA, material="Wood")
    for y in (1.5, 3.7): add(fence, "Rail", (13, .65, .65), (0, y, 0), (181, 133, 83), material="WoodPlanks")

    lamp = create("Lamppost")
    disc(lamp, "Base", 3, .6, (0, .3, 0), COCOA, "Metal")
    add(lamp, "Post", (.6, 12, .6), (0, 6.5, 0), COCOA, material="Metal")
    add(lamp, "Lamp", (2.2, 2.7, 2.2), (0, 12.5, 0), (255, 225, 146), material="Neon")
    add(lamp, "Cap", (3, .5, 3), (0, 14, 0), COCOA, material="Metal")

    tree = create("CookieTree")
    add(tree, "Trunk", (2.4, 13, 2.4), (0, 6.5, 0), (137, 92, 58), material="Wood", collide=True)
    for x, y, z in ((0, 15, 0), (-3, 12, 0), (3, 12, 0), (0, 12, 3)):
        add(tree, "Canopy", (10, 9, 10), (x, y, z), (106, 158, 98), "Ball", "Grass")
    for x in (-4, 4): disc(tree, "Cookie Fruit", 2.5, .5, (x, 11, 3), (209, 158, 98))

    planter = create("Planter")
    add(planter, "Planter Box", (8, 2.5, 4), (0, 1.25, 0), COCOA, material="WoodPlanks", collide=True)
    for x in (-2.5, 0, 2.5):
        add(planter, "Leaves", (2.5, 2.2, 3), (x, 3, 0), (107, 163, 98), "Ball", "Grass")
        add(planter, "Flower", (1.2, .7, 1.2), (x, 4, 0), (241, 162, 161), "Ball")

    plaza = create("SpawnPlaza")
    disc(plaza, "Texture_PathPavers", 27, .6, (0, 0, 0), (207, 184, 146), "Concrete")
    disc(plaza, "Cookie Inlay", 18, .08, (0, .35, 0), (215, 169, 108))
    for n in range(8):
        angle = n * math.pi / 4
        disc(plaza, "Chocolate Inlay", 1.5, .08, (6 * math.cos(angle), .41, 6 * math.sin(angle)), COCOA)

    path = create("PathSegment")
    add(path, "Texture_PathPavers", (28, .3, 40), (0, 0, 0), (211, 190, 153), material="Concrete", collide=True)
    return result


def rotation(angles):
    x, y, z = map(math.radians, angles)
    rx = np.array([[1, 0, 0], [0, math.cos(x), -math.sin(x)], [0, math.sin(x), math.cos(x)]])
    ry = np.array([[math.cos(y), 0, math.sin(y)], [0, 1, 0], [-math.sin(y), 0, math.cos(y)]])
    rz = np.array([[math.cos(z), -math.sin(z), 0], [math.sin(z), math.cos(z), 0], [0, 0, 1]])
    return rz @ ry @ rx


def write_models(objects):
    xml = ET.Element("roblox", version="4")
    for value in ("null", "nil"): ET.SubElement(xml, "External").text = value
    root = ET.SubElement(xml, "Item", {"class": "Model", "referent": "Pack"})
    ET.SubElement(ET.SubElement(root, "Properties"), "string", name="Name").text = "CookieCornerAssets"
    counter = 0
    for category in ("Cookies", "Props"):
        folder = ET.SubElement(root, "Item", {"class": "Folder", "referent": category})
        ET.SubElement(ET.SubElement(folder, "Properties"), "string", name="Name").text = category
        for obj in (o for o in objects if o["category"] == category):
            counter += 1
            node = ET.SubElement(folder, "Item", {"class": "Model", "referent": f"Model{counter}"})
            properties = ET.SubElement(node, "Properties")
            ET.SubElement(properties, "string", name="Name").text = obj["name"]
            ET.SubElement(properties, "Ref", name="PrimaryPart").text = f"Part{counter}_0"
            for index, primitive in enumerate(obj["parts"]):
                node_part = ET.SubElement(node, "Item", {"class": "Part", "referent": f"Part{counter}_{index}"})
                p = ET.SubElement(node_part, "Properties")
                ET.SubElement(p, "string", name="Name").text = primitive["name"]
                for name, value in (("Anchored", True), ("CanCollide", primitive["collide"]), ("CanTouch", False), ("CanQuery", primitive["collide"]), ("CastShadow", primitive["transparency"] == 0)):
                    ET.SubElement(p, "bool", name=name).text = str(value).lower()
                ET.SubElement(p, "float", name="Transparency").text = str(primitive["transparency"])
                ET.SubElement(p, "token", name="Material").text = str(MATERIALS[primitive["material"]])
                ET.SubElement(p, "token", name="shape").text = str({"Ball": 0, "Block": 1, "Cylinder": 2}[primitive["shape"]])
                for surface in ("TopSurface", "BottomSurface"):
                    ET.SubElement(p, "token", name=surface).text = "0"
                r, g, b = primitive["color"]
                ET.SubElement(p, "Color3uint8", name="Color3uint8").text = str(0xFF000000 | r << 16 | g << 8 | b)
                size = ET.SubElement(p, "Vector3", name="size")
                for axis, value in zip("XYZ", primitive["size"]): ET.SubElement(size, axis).text = str(value)
                transform = ET.SubElement(p, "CoordinateFrame", name="CFrame")
                for axis, value in zip("XYZ", primitive["pos"]): ET.SubElement(transform, axis).text = str(value)
                matrix = rotation(primitive["rotation"])
                for row in range(3):
                    for column in range(3): ET.SubElement(transform, f"R{row}{column}").text = f"{matrix[row, column]:.9f}"
    ET.indent(xml)
    ET.ElementTree(xml).write(MODELS / "CookieCornerAssets.rbxmx", encoding="utf-8", xml_declaration=True)


def texture(key, base, accent, style, seed):
    rng = np.random.default_rng(seed)
    t = np.linspace(0, 1, 512)
    u, v = np.meshgrid(t, t)
    grain = np.zeros(u.shape)
    for _ in range(22):
        a, b = rng.integers(1, 38, 2)
        grain += np.sin(2 * math.pi * (a * u + b * v) + rng.uniform(0, 2 * math.pi)) * .42
    image = np.zeros((512, 512, 3)) + base
    image += grain[:, :, None] * 1.8
    if style == "cookie":
        image += (np.sin(2 * math.pi * u * 3) * np.cos(2 * math.pi * v * 4))[:, :, None] * 4
        for _ in range(26):
            cx, cy = rng.random(2)
            dx, dy = np.abs(u - cx), np.abs(v - cy)
            dx, dy = np.minimum(dx, 1 - dx), np.minimum(dy, 1 - dy)
            mask = dx ** 2 + dy ** 2 < rng.uniform(.007, .026) ** 2
            image[mask] = np.asarray(accent) + rng.uniform(-8, 8)
    elif style == "tile":
        checker = ((np.floor(u * 8) + np.floor(v * 8)) % 2) == 0
        image[checker] = accent
        grout = (np.mod(u * 8, 1) < .035) | (np.mod(v * 8, 1) < .035)
        image[grout] = (219, 203, 177)
    elif style in ("brick", "pavers"):
        row = np.floor(v * 8)
        seams = (np.mod(v * 8, 1) < .07) | (np.mod(u * 4 + np.mod(row, 2) * .5, 1) < .035)
        image[seams] = accent
    elif style == "wood":
        lines = np.sin(2 * math.pi * (u * 16 + .10 * np.sin(v * 2 * math.pi))) * 7
        image += lines[:, :, None]
        image[np.mod(u * 4, 1) < .025] = accent
    elif style == "metal":
        image += np.sin(2 * math.pi * u * 150)[:, :, None] * 8
    elif style == "rubber":
        image += np.cos(2 * math.pi * v * 32)[:, :, None] * 5
        image[np.mod(v * 8, 1) < .035] = accent
    elif style == "stripe":
        image[np.floor(u * 8) % 2 == 0] = accent
    elif style == "marble":
        vein = np.sin(2 * math.pi * (u * 3 + .3 * np.sin(v * 4 * math.pi)))
        mask = np.abs(vein) < .10
        image[mask] = accent
    elif style == "gold":
        image += (np.sin(2 * math.pi * (u + v)) * 13)[:, :, None]
    elif style == "grass":
        image += (np.sin(2 * math.pi * (u * 54 + v * 13)) * 5)[:, :, None]
    array = np.clip(image, 0, 255).astype(np.uint8)
    # Match both borders exactly, including painted mix-ins crossing the tile boundary.
    array[-1, :, :] = array[0, :, :]
    array[:, -1, :] = array[:, 0, :]
    path = TEXTURES / f"{key}.png"
    Image.fromarray(array).save(path, optimize=True)
    return {"key": key, "file": str(path.relative_to(OUT)), "size": [512, 512], "tileable": True}


def font(size, bold=False):
    path = Path("/usr/share/fonts/truetype/dejavu/DejaVuSans" + ("-Bold" if bold else "") + ".ttf")
    return ImageFont.truetype(str(path), size) if path.exists() else ImageFont.load_default()


def mesh(primitive):
    if primitive["shape"] == "Block":
        points = np.array([[-1, -1, -1], [1, -1, -1], [1, 1, -1], [-1, 1, -1],
                           [-1, -1, 1], [1, -1, 1], [1, 1, 1], [-1, 1, 1]], dtype=float)
        faces = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (3, 7, 6, 2), (1, 2, 6, 5), (0, 4, 7, 3)]
    elif primitive["shape"] == "Cylinder":
        count = 20
        points = np.array([(x, math.cos(n * math.pi * 2 / count), math.sin(n * math.pi * 2 / count))
                           for x in (-1, 1) for n in range(count)])
        faces = [tuple(range(count - 1, -1, -1)), tuple(range(count, count * 2))]
        faces += [(n, (n + 1) % count, (n + 1) % count + count, n + count) for n in range(count)]
    else:
        rings, count = 8, 12
        points = np.array([(math.sin(r * math.pi / rings) * math.cos(n * math.pi * 2 / count),
                            math.cos(r * math.pi / rings), math.sin(r * math.pi / rings) * math.sin(n * math.pi * 2 / count))
                           for r in range(rings + 1) for n in range(count)])
        faces = [(r * count + n, r * count + (n + 1) % count,
                  (r + 1) * count + (n + 1) % count, (r + 1) * count + n)
                 for r in range(rings) for n in range(count)]
    points *= np.asarray(primitive["size"]) / 2
    return points @ rotation(primitive["rotation"]).T + primitive["pos"], faces


def thumbnail(obj, size=(230, 125)):
    background = (255, 248, 233)
    image = Image.new("RGB", size, background)
    draw = ImageDraw.Draw(image)
    camera = np.array([.50, .70, .51])
    camera /= np.linalg.norm(camera)
    right = np.cross(np.array([0., 1., 0.]), camera)
    right /= np.linalg.norm(right)
    up = np.cross(camera, right)
    polygons = []
    all_points = []
    for primitive in obj["parts"]:
        if primitive["transparency"] >= 1: continue
        vertices, faces = mesh(primitive)
        projected = np.column_stack((vertices @ right, -vertices @ up))
        all_points.extend(projected)
        for face in faces:
            positions = vertices[list(face)]
            normal = np.cross(positions[1] - positions[0], positions[2] - positions[0])
            length = np.linalg.norm(normal)
            if length < .000001: continue
            normal /= length
            brightness = .72 + .28 * abs(float(normal @ np.array([-.3, .8, .5])))
            shade = tint(primitive["color"], brightness)
            polygons.append((projected[list(face)], positions @ camera, shade))
    bounds = np.asarray(all_points)
    low, high = bounds.min(axis=0), bounds.max(axis=0)
    scale = min((size[0] - 20) / max(high[0] - low[0], .1), (size[1] - 12) / max(high[1] - low[1], .1))
    offset = (np.asarray(size) - (high - low) * scale) / 2 - low * scale
    # Orthographic triangle depth rendering keeps distant toppings visible above
    # the broad cookie surface; sorting whole polygons by their centers cannot.
    pixels = np.asarray(image).copy()
    depth_buffer = np.full((size[1], size[0]), -np.inf)
    for points, depths, shade in polygons:
        points = points * scale + offset
        for n in range(1, len(points) - 1):
            a, b, c = points[[0, n, n + 1]]
            z0, z1, z2 = depths[[0, n, n + 1]]
            left = max(0, int(math.floor(min(a[0], b[0], c[0]))))
            right_edge = min(size[0] - 1, int(math.ceil(max(a[0], b[0], c[0]))))
            top = max(0, int(math.floor(min(a[1], b[1], c[1]))))
            bottom = min(size[1] - 1, int(math.ceil(max(a[1], b[1], c[1]))))
            divisor = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
            if abs(divisor) < .000001 or left > right_edge or top > bottom: continue
            yy, xx = np.mgrid[top:bottom + 1, left:right_edge + 1]
            w0 = ((b[1] - c[1]) * (xx + .5 - c[0]) + (c[0] - b[0]) * (yy + .5 - c[1])) / divisor
            w1 = ((c[1] - a[1]) * (xx + .5 - c[0]) + (a[0] - c[0]) * (yy + .5 - c[1])) / divisor
            w2 = 1 - w0 - w1
            depths_here = w0 * z0 + w1 * z1 + w2 * z2
            old_depths = depth_buffer[top:bottom + 1, left:right_edge + 1]
            mask = (w0 >= -.00001) & (w1 >= -.00001) & (w2 >= -.00001) & (depths_here > old_depths)
            old_depths[mask] = depths_here[mask]
            pixels[top:bottom + 1, left:right_edge + 1][mask] = shade
    return Image.fromarray(pixels)


def previews(objects, texture_records):
    width, cell_w, cell_h = 1500, 246, 176
    height = 140 + math.ceil(len(objects) / 6) * cell_h + 65
    page = Image.new("RGB", (width, height), (255, 248, 233))
    draw = ImageDraw.Draw(page)
    draw.rectangle((0, 0, width, 120), fill=COCOA)
    draw.text((30, 20), "COOKIE CORNER • ORIGINAL ASSET PACK", font=font(31, True), fill=CREAM)
    draw.text((30, 69), "30 cookie models + 20 bakery props  |  42 seamless textures  |  CC0", font=font(21), fill=(255, 210, 111))
    for i, obj in enumerate(objects):
        x, y = 12 + (i % 6) * cell_w, 140 + (i // 6) * cell_h
        page.paste(thumbnail(obj), (x + 6, y))
        title = obj["name"]
        label_font = font(14, True)
        while draw.textlength(title, font=label_font) > 230:
            title = title[:-2] + "…"
        draw.text((x + 9, y + 133), title, font=label_font, fill=COCOA)
        draw.text((x + 9, y + 153), f"{len(obj['parts']) - 1} visible parts", font=font(11), fill=(138, 105, 83))
    draw.text((30, height - 40), "Script-free Roblox Parts • No external meshes or image IDs required for the models", font=font(17), fill=COCOA)
    page.save(PREVIEWS / "Models.png", optimize=True)

    tile = 180
    texture_page = Image.new("RGB", (7 * tile, 6 * (tile + 34) + 80), (255, 248, 233))
    draw = ImageDraw.Draw(texture_page)
    draw.text((18, 15), "42 ORIGINAL TILEABLE TEXTURES • 512 × 512 PNG", font=font(25, True), fill=COCOA)
    for i, record in enumerate(texture_records):
        x, y = (i % 7) * tile, 70 + (i // 7) * (tile + 34)
        swatch = Image.open(OUT / record["file"]).resize((tile - 10, tile - 10))
        texture_page.paste(swatch, (x + 5, y))
        draw.text((x + 5, y + tile - 4), record["key"], font=font(12, True), fill=COCOA)
    texture_page.save(PREVIEWS / "Textures.png", optimize=True)


def main():
    for directory in (TEXTURES, MODELS, PREVIEWS): directory.mkdir(parents=True, exist_ok=True)
    objects = [cookie(i, recipe) for i, recipe in enumerate(recipes, 1)] + props()
    assert len(objects) == 50
    write_models(objects)
    records = [texture(f"Cookie{i:02}", recipe["color"], recipe["accent"], "cookie", i)
               for i, recipe in enumerate(recipes, 1)]
    surfaces = [
        ("BakeryFloor", (245, 228, 199), (187, 140, 96), "tile"),
        ("WallTile", (246, 236, 216), (211, 225, 212), "tile"),
        ("WoodWarm", (167, 112, 65), (108, 66, 43), "wood"),
        ("BrushedMetal", (163, 178, 186), (105, 120, 132), "metal"),
        ("ConveyorRubber", (46, 52, 59), (82, 89, 98), "rubber"),
        ("OvenBrick", (172, 97, 68), (224, 204, 171), "brick"),
        ("Parchment", (242, 226, 188), (224, 201, 155), "paper"),
        ("GoldenChip", (235, 180, 48), (255, 223, 114), "gold"),
        ("AwningStripe", (185, 81, 67), (251, 235, 202), "stripe"),
        ("CounterMarble", (244, 231, 210), (191, 158, 126), "marble"),
        ("MeadowGrass", (113, 163, 101), (85, 134, 80), "grass"),
        ("PathPavers", (206, 183, 146), (151, 132, 108), "pavers"),
    ]
    records += [texture(key, base, accent, style, 200 + i) for i, (key, base, accent, style) in enumerate(surfaces)]
    previews(objects, records)
    manifest = {
        "name": "Cookie Corner Original Assets", "license": "CC0-1.0", "version": 1,
        "models": [{"name": obj["name"], "category": obj["category"], "parts": len(obj["parts"]),
                    "textureKeys": sorted({p["name"][8:] for p in obj["parts"] if p["name"].startswith("Texture_")})}
                   for obj in objects],
        "textures": records,
    }
    for record in records:
        record["sha256"] = hashlib.sha256((OUT / record["file"]).read_bytes()).hexdigest()
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Generated {len(objects)} script-free models and {len(records)} seamless textures.")


if __name__ == "__main__":
    main()
