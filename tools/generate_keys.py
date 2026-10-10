#!/usr/bin/env python3
"""
مولّد مفاتيح البريميوم | صنع من قبل محمد TN

يضيف بصمات SHA-256 للمفاتيح في keys.json (المفاتيح نفسها ما تنحفظ في الملف).
انسخ المفاتيح اللي يطبعها وأعطها للمشتركين، وبعدها ارفع keys.json على GitHub.

أمثلة:
    python3 tools/generate_keys.py --count 5             # 5 مفاتيح مدى الحياة
    python3 tools/generate_keys.py --count 3 --days 30   # 3 مفاتيح لمدة 30 يوم
    python3 tools/generate_keys.py --revoke MTN-AB12-CD34-EF56
    python3 tools/generate_keys.py --list
"""

import argparse
import hashlib
import json
import secrets
import time
from pathlib import Path

# لازم يطابق CONFIG.Keys.Salt في السكربت
SALT = "MohammedTN"
ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"  # بدون حروف تتلخبط (O/0, I/1)
KEYS_FILE = Path(__file__).resolve().parent.parent / "keys.json"


def key_hash(key: str) -> str:
    normalized = "".join(key.upper().split())
    return hashlib.sha256(f"{SALT}:{normalized}".encode()).hexdigest()


def new_key() -> str:
    groups = ["".join(secrets.choice(ALPHABET) for _ in range(4)) for _ in range(3)]
    return "MTN-" + "-".join(groups)


def load() -> dict:
    if KEYS_FILE.exists():
        data = json.loads(KEYS_FILE.read_text(encoding="utf-8"))
        data.setdefault("keys", {})
        return data
    return {"keys": {}}


def save(data: dict) -> None:
    data["keys"] = dict(sorted(data["keys"].items()))
    KEYS_FILE.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description="مولّد مفاتيح البريميوم")
    parser.add_argument("--count", type=int, default=0, help="عدد المفاتيح الجديدة")
    parser.add_argument("--days", type=int, default=0, help="مدة المفتاح بالأيام (0 = مدى الحياة)")
    parser.add_argument("--revoke", metavar="KEY", help="إلغاء مفتاح")
    parser.add_argument("--list", action="store_true", help="عرض عدد المفاتيح وتواريخ انتهائها")
    args = parser.parse_args()

    data = load()

    if args.revoke:
        removed = data["keys"].pop(key_hash(args.revoke), None)
        save(data)
        print("تم إلغاء المفتاح" if removed is not None else "المفتاح مو موجود")

    if args.count > 0:
        expiry = int(time.time()) + args.days * 86400 if args.days > 0 else 0
        label = f"{args.days} يوم" if args.days > 0 else "مدى الحياة"
        print(f"مفاتيح جديدة ({label}):")
        for _ in range(args.count):
            key = new_key()
            data["keys"][key_hash(key)] = expiry
            print("  " + key)
        save(data)

    if args.list:
        now = int(time.time())
        keys = data["keys"]
        lifetime = sum(1 for e in keys.values() if e == 0)
        active = sum(1 for e in keys.values() if e > now)
        expired = sum(1 for e in keys.values() if 0 < e <= now)
        print(f"الكل: {len(keys)}  •  مدى الحياة: {lifetime}  •  فعّال بمدة: {active}  •  منتهي: {expired}")


if __name__ == "__main__":
    main()
