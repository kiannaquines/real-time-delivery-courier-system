#!/usr/bin/env python3
"""
Import Stores, Categories, and Products from Google Sheets into M&S Delivery Database.

Supports:
- Google Sheets API authentication via service account (account.json)
- Direct Google Sheets CSV export fallback
- Idempotent upsert of Stores, MenuCategories, and MenuItems
"""

import os
import re
import sys
import uuid
import httpx
from decimal import Decimal
from typing import Dict, List, Any

# Ensure backend directory is in python path
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "backend"))

from app.core.database import SessionLocal
from app.models.store import Store, MenuCategory, MenuItem

SPREADSHEET_ID = "1RHI2cPntzhqTRZOGYml6KQvUynKfmd_rV-M2TdEfML0"
SERVICE_ACCOUNT_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "account.json")

# Default coordinates & metadata for Kabacan stores
STORE_METADATA = {
    "Waffle Time": {
        "description": "Freshly baked waffles with sweet and savory fillings, combo snacks, and refreshing fruit drinks in Kabacan.",
        "address": "Poblacion Public Market, Kabacan, Cotabato",
        "latitude": Decimal("7.1268"),
        "longitude": Decimal("124.8305"),
        "image_url": "https://images.unsplash.com/photo-1562376552-0d160a2f238d?w=800&q=80",
    },
    "Potato Corner": {
        "description": "World's best flavored fries with Cheese, BBQ, Sour Cream, Loopys, and Crunchy Chicken Pops.",
        "address": "USM Commercial Center, USM Avenue, Kabacan, Cotabato",
        "latitude": Decimal("7.1255"),
        "longitude": Decimal("124.8335"),
        "image_url": "https://images.unsplash.com/photo-1576107232684-1279f3908594?w=800&q=80",
    }
}


def fetch_sheet_text() -> str:
    """Fetch text from Google Sheet using Service Account or direct CSV export."""
    # 1. Try Google Sheets API with service account
    if os.path.exists(SERVICE_ACCOUNT_FILE):
        try:
            import gspread
            gc = gspread.service_account(filename=SERVICE_ACCOUNT_FILE)
            sh = gc.open_by_key(SPREADSHEET_ID)
            ws = sh.sheet1
            values = ws.get_all_values()
            lines = ["\t".join(row) for row in values]
            print(f"✔ Successfully loaded from Google Sheets API using service account!")
            return "\n".join(lines)
        except Exception as e:
            print(f"ℹ Google Sheets API notice ({e}). Falling back to direct export stream...")

    # 2. Fallback to direct export URL
    export_url = f"https://docs.google.com/spreadsheets/d/{SPREADSHEET_ID}/export?format=csv&gid=0"
    resp = httpx.get(export_url, follow_redirects=True, timeout=15.0)
    if resp.status_code == 200:
        print(f"✔ Successfully fetched Google Sheet data via live export!")
        return resp.text
    else:
        raise RuntimeError(f"Failed to fetch Google Sheet data (Status {resp.status_code})")


def parse_sheet_data(raw_text: str) -> List[Dict[str, Any]]:
    """
    Parses stores, categories, and menu items from the spreadsheet text.
    """
    lines = [line.strip() for line in raw_text.splitlines() if line.strip()]
    stores = []
    current_store = None
    current_category = None

    for line in lines:
        # Check if store header
        if "Waffle Time" in line:
            current_store = {
                "name": "Waffle Time",
                "categories": []
            }
            stores.append(current_store)
            current_category = None
            continue
        elif "Potato Corner" in line:
            current_store = {
                "name": "Potato Corner",
                "categories": []
            }
            stores.append(current_store)
            current_category = None
            continue

        if not current_store:
            continue

        # Check if item line (must contain price separator followed by digits, e.g. "— ₱52")
        item_match = re.search(r"^(.*?)\s*[—–-]\s*[₱P]?\s*(\d+(?:\.\d+)?)", line)

        if not item_match:
            # Clean emoji and leading punctuation from category name
            cat_name = re.sub(r'^[^\w\s]+', '', line).strip()
            if cat_name:
                current_category = {
                    "name": cat_name,
                    "items": []
                }
                current_store["categories"].append(current_category)
            continue

        # Parse Item & Price
        item_name = item_match.group(1).strip()
        price_val = Decimal(item_match.group(2))

        if not current_category:
            current_category = {
                "name": "General Menu",
                "items": []
            }
            current_store["categories"].append(current_category)

        current_category["items"].append({
            "name": item_name,
            "price": price_val,
            "description": f"{item_name} from {current_store['name']}",
        })

    return stores


def import_stores_to_db(stores_data: List[Dict[str, Any]]):
    """Inserts or updates stores, categories, and menu items in the database."""
    db = SessionLocal()
    total_stores = 0
    total_categories = 0
    total_items = 0

    try:
        for s_data in stores_data:
            s_name = s_data["name"]
            meta = STORE_METADATA.get(s_name, {
                "description": f"{s_name} in Kabacan",
                "address": "Poblacion, Kabacan, Cotabato",
                "latitude": Decimal("7.1265"),
                "longitude": Decimal("124.8300"),
                "image_url": None,
            })

            # Check if store already exists
            store = db.query(Store).filter(Store.name == s_name).first()
            if not store:
                store = Store(
                    id=str(uuid.uuid4()),
                    name=s_name,
                    description=meta["description"],
                    address=meta["address"],
                    latitude=meta["latitude"],
                    longitude=meta["longitude"],
                    image_url=meta.get("image_url"),
                    is_active=True,
                )
                db.add(store)
                db.flush()
                print(f"\n🏬 Created Store: {store.name} ({store.address})")
            else:
                store.description = meta["description"]
                store.address = meta["address"]
                store.latitude = meta["latitude"]
                store.longitude = meta["longitude"]
                if meta.get("image_url"):
                    store.image_url = meta.get("image_url")
                db.flush()
                print(f"\n🏬 Updated Store: {store.name}")

            total_stores += 1

            for cat_order, c_data in enumerate(s_data["categories"], start=1):
                c_name = c_data["name"]
                cat = db.query(MenuCategory).filter(
                    MenuCategory.store_id == store.id,
                    MenuCategory.name == c_name
                ).first()

                if not cat:
                    cat = MenuCategory(
                        id=str(uuid.uuid4()),
                        store_id=store.id,
                        name=c_name,
                        display_order=cat_order,
                    )
                    db.add(cat)
                    db.flush()
                    print(f"   📂 Added Category: {cat.name}")
                else:
                    cat.display_order = cat_order
                    db.flush()
                    print(f"   📂 Existing Category: {cat.name}")

                total_categories += 1

                for i_data in c_data["items"]:
                    i_name = i_data["name"]
                    price = i_data["price"]
                    desc = f"{i_name} ({c_name}) from {store.name}"

                    item = db.query(MenuItem).filter(
                        MenuItem.store_id == store.id,
                        MenuItem.category_id == cat.id,
                        MenuItem.name == i_name
                    ).first()

                    if not item:
                        item = MenuItem(
                            id=str(uuid.uuid4()),
                            store_id=store.id,
                            category_id=cat.id,
                            name=i_name,
                            description=desc,
                            price=price,
                            is_available=True,
                        )
                        db.add(item)
                        print(f"      • Added Item: [{c_name}] {item.name:<25} ₱{item.price:.2f}")
                    else:
                        item.price = price
                        item.description = desc
                        item.is_available = True
                        print(f"      • Updated Item: [{c_name}] {item.name:<23} ₱{item.price:.2f}")

                    total_items += 1

        db.commit()
        print(f"\n🎉 Database Import Complete!")
        print(f"   • Total Stores:     {total_stores}")
        print(f"   • Total Categories: {total_categories}")
        print(f"   • Total Menu Items: {total_items}")

    except Exception as e:
        db.rollback()
        print(f"✖ Error importing data: {e}")
        raise e
    finally:
        db.close()


def main():
    print("======================================================")
    print("  M&S Delivery - Google Sheets Store Data Importer    ")
    print("======================================================")
    print(f"Target Spreadsheet: {SPREADSHEET_ID}\n")

    raw_text = fetch_sheet_text()
    parsed_stores = parse_sheet_data(raw_text)

    print(f"Parsed {len(parsed_stores)} stores from spreadsheet:")
    for s in parsed_stores:
        print(f"  - {s['name']}: {len(s['categories'])} categories, {sum(len(c['items']) for c in s['categories'])} items")

    import_stores_to_db(parsed_stores)


if __name__ == "__main__":
    main()
