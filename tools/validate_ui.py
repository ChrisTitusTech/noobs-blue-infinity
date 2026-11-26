#!/usr/bin/env python3
"""Check an EverQuest SUITE skin against the installed client's default UI."""
import argparse
from collections import defaultdict
from pathlib import Path
import xml.etree.ElementTree as ET


def read(path):
    return ET.parse(path).getroot()


def validate(skin, default, macroquest=False):
    includes = [e.text.strip() for e in read(default / "EQUI.xml").iter("Include")]
    # SIDL defines the element types and reference-valued fields.
    schema = read(default / "SIDL.xml")
    refs = defaultdict(set)
    for field in schema.iter("{EverQuestData}element"):
        kind = field.get("type", "")
        if kind.endswith(":item"):
            refs[field.get("name")].add(kind[:-5])
    files = {name: skin / name if (skin / name).is_file() else default / name
             for name in includes}
    definitions = defaultdict(list)
    textures = {}
    roots = {}
    errors = set()
    for name, path in files.items():
        try:
            roots[name] = read(path)
        except (ET.ParseError, OSError) as exc:
            errors.add(f"{name}: {exc}")
            continue
        for element in roots[name]:
            if element.get("item"):
                definitions[element.get("item")].append((name, element.tag))
                if element.tag == "TextureInfo":
                    textures[element.get("item")] = (
                        int(element.findtext("Size/CX", "0")),
                        int(element.findtext("Size/CY", "0")),
                    )

    if macroquest:
        # Plugin templates are looked up by item name at runtime, not by
        # ScreenID or an XML Pieces reference. Check those external consumers.
        required = {
            "Player_ManaLabel": "Label",
            "Player_FatigueLabel": "Label",
            "IDW_ModButton": "Button",
            "IDW_ModButtonLabel": "Label",
            "ADLW_CheckBoxTemplate": "Button",
            "GW_InviteButton": "Button",
            "HB_Button1": "HotButton",
            "HB_Button2": "HotButton",
            "HB_Button3": "HotButton",
        }
        for item, kind in required.items():
            if not any(tag == kind for _, tag in definitions.get(item, [])):
                errors.add(f"MacroQuest: missing {kind} template {item}")
        group = roots.get("EQUI_GroupWindow.xml")
        if group is not None:
            gauges = {g.get("item") for g in group.findall("Gauge")
                      if g.findtext("ScreenID") == "Gauge1"}
            window = group.find("./Screen[@item='GroupWindow']")
            if window is None or not gauges.intersection(
                    p.text.split(":")[-1] for p in window.findall("Pieces") if p.text):
                errors.add("MacroQuest: GroupWindow missing Gauge1 control")

    # Some item names are valid in separate types or files; only validate
    # references by name here, and use explicit type prefixes when supplied.
    available_textures = {p.name.casefold() for folder in (skin, default)
                          for p in folder.iterdir() if p.is_file()}
    for name, root in roots.items():
        for element in root.iter():
            value = (element.text or "").strip()
            if not value or len(element):
                continue
            if element.tag in refs:
                key = value.split(":", 1)[-1]
                if key not in definitions:
                    errors.add(f"{name}: unresolved {element.tag}: {value}")
                elif ":" in value:
                    prefix = value.split(":", 1)[0]
                    if prefix not in (kind for _, kind in definitions[key]):
                        errors.add(f"{name}: incorrect type for {value}")
            if element.tag == "Texture" and value.casefold() not in available_textures:
                errors.add(f"{name}: missing texture {value}")
        for animation in root.findall("Ui2DAnimation"):
            for frame in animation.findall("Frames"):
                texture = frame.findtext("Texture")
                if texture not in textures:
                    continue
                width, height = textures[texture]
                # Some shipped default frames deliberately stretch a small
                # solid-color texture. Existing default exceptions are
                # reported separately by the caller.
                x = int(frame.findtext("Location/X", "0"))
                y = int(frame.findtext("Location/Y", "0"))
                w = int(frame.findtext("Size/CX", "0"))
                h = int(frame.findtext("Size/CY", "0"))
                if x + w > width or y + h > height:
                    errors.add(f"{name}: out-of-bounds frame {animation.get('item')}")
    for path in skin.glob("*.xml"):
        if path.name not in files:
            try:
                read(path)
            except (ET.ParseError, OSError) as exc:
                errors.add(f"{path.name}: {exc}")
    return errors, sum(path.parent == skin for path in files.values())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("default", type=Path, help="Live client uifiles/default directory")
    parser.add_argument("--skin", type=Path,
                        default=Path(__file__).resolve().parents[1] / "Freq_di28889")
    parser.add_argument("--macroquest", action="store_true",
                        help="Also check external MacroQuest plugin templates")
    args = parser.parse_args()
    baseline, _ = validate(args.default, args.default)
    errors, count = validate(args.skin, args.default, macroquest=args.macroquest)
    introduced = errors - baseline
    for error in sorted(errors & baseline):
        print(f"Also present in stock UI: {error}")
    for error in sorted(introduced):
        print(error)
    print(f"{count} active overrides; {len(introduced)} additional issues "
          f"relative to default ({len(baseline)} default issues).")
    return bool(introduced)


if __name__ == "__main__":
    raise SystemExit(main())
