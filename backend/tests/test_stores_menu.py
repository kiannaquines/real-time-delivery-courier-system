def test_store_creation_and_listing(client, admin_headers, customer_headers):
    # Admin creates store
    store_payload = {
        "name": "M&S Central Kitchen",
        "description": "Premium fresh meals and artisan bakery",
        "address": "123 Bonifacio High Street, BGC, Taguig",
        "latitude": 14.5515,
        "longitude": 121.0505,
        "image_url": "https://example.com/store.jpg",
        "is_active": True
    }
    create_resp = client.post("/api/v1/stores", json=store_payload, headers=admin_headers)
    assert create_resp.status_code == 201
    store_id = create_resp.json()["id"]

    # Customer tries to create store -> 403 Forbidden
    cust_resp = client.post("/api/v1/stores", json=store_payload, headers=customer_headers)
    assert cust_resp.status_code == 403

    # Public list stores
    list_resp = client.get("/api/v1/stores")
    assert list_resp.status_code == 200
    assert len(list_resp.json()) >= 1

    # Admin creates menu item
    menu_item_payload = {
        "store_id": store_id,
        "name": "Artisan Roast Beef Sandwich",
        "description": "Slow cooked roast beef with mustard butter on sourdough",
        "price": 285.00,
        "image_url": "https://example.com/sandwich.jpg",
        "is_available": True
    }
    item_resp = client.post("/api/v1/menu-items", json=menu_item_payload, headers=admin_headers)
    assert item_resp.status_code == 201
    assert item_resp.json()["name"] == "Artisan Roast Beef Sandwich"

    # Store details contains item
    detail_resp = client.get(f"/api/v1/stores/{store_id}")
    assert detail_resp.status_code == 200
    assert len(detail_resp.json()["items"]) == 1
