import os
from pathlib import Path
import re

tp1_dir = Path(os.environ["TP1_PATH"])
tp2_dir = Path(os.environ["TP2_PATH"])
output_file = Path(os.environ["OUT_SPLIT"])

# ----------------------------
# helper: extract key
# ----------------------------
pattern = re.compile(r"(T\d+_L\d+)", re.IGNORECASE)

def extract_key(filename):
    match = pattern.search(filename)
    return match.group(1) if match else None

def is_tiff(path):
    return path.suffix.lower() in [".tif", ".tiff"]

# ----------------------------
# index TP1
# ----------------------------
tp1_map = {}
for f in tp1_dir.iterdir():
    if f.is_file() and is_tiff(f):
        key = extract_key(f.name)
        if key:
            tp1_map[key] = f

# ----------------------------
# index TP2
# ----------------------------
tp2_map = {}
for f in tp2_dir.iterdir():
    if f.is_file() and is_tiff(f):
        key = extract_key(f.name)
        if key:
            tp2_map[key] = f

# ----------------------------
# match
# ----------------------------
pairs = []
missing_tp1 = []
missing_tp2 = []

all_keys = sorted(set(tp1_map.keys()) | set(tp2_map.keys()))

for key in all_keys:
    if key in tp1_map and key in tp2_map:
        pairs.append((tp1_map[key], tp2_map[key]))
    elif key in tp1_map:
        missing_tp2.append(key)
    else:
        missing_tp1.append(key)

# ----------------------------
# write splitfile (FIXED)
# ----------------------------
with open(output_file, "w", encoding="utf-8") as f:
    for a, b in pairs:
        f.write(f"{a},{b}\n")   # <-- critical fix

# ----------------------------
# report
# ----------------------------
print("Pairs written:", len(pairs))
print("Missing in TP2:", missing_tp2)
print("Missing in TP1:", missing_tp1)
print("Output:", output_file)