from datetime import datetime, timezone


def test_order_creation_delivery_lifecycle(client, admin_headers, rider_headers, customer_headers):
    # 1. Admin creates store & menu item
    store_payload = {
        "name": "M&S Delivery Hub",
        "description": "Artisan bakery and ready meals",
        "address": "123 BGC Taguig",
        "latitude": 14.5515,
        "longitude": 121.0505,
        "is_active": True
    }
    store_resp = client.post("/api/v1/stores", json=store_payload, headers=admin_headers)
    assert store_resp.status_code == 201
    store = store_resp.json()

    item_payload = {
        "store_id": store["id"],
        "name": "M&S Classic Roast Beef",
        "price": 320.00,
        "is_available": True
    }
    item_resp = client.post("/api/v1/menu-items", json=item_payload, headers=admin_headers)
    assert item_resp.status_code == 201
    menu_item = item_resp.json()

    # 2. Customer creates an address
    addr_payload = {
        "label": "Apartment",
        "address_line": "Unit 24B, Grand Tower, Makati",
        "latitude": 14.5585,
        "longitude": 121.0255,
        "is_default": True
    }
    addr_resp = client.post("/api/v1/customers/addresses", json=addr_payload, headers=customer_headers)
    assert addr_resp.status_code == 201
    address_id = addr_resp.json()["id"]

    # 3. Preview fee
    fee_resp = client.post(
        "/api/v1/orders/preview-fee",
        json={"store_id": store["id"], "delivery_latitude": 14.5585, "delivery_longitude": 121.0255},
        headers=customer_headers
    )
    assert fee_resp.status_code == 200
    assert fee_resp.json()["total_delivery_fee"] > 0

    # 4. Place COD Order with Idempotency Key
    order_payload = {
        "store_id": store["id"],
        "address_id": address_id,
        "items": [{"menu_item_id": menu_item["id"], "quantity": 2}],
        "notes": "Ring doorbell twice please."
    }
    order_resp = client.post(
        "/api/v1/orders",
        json=order_payload,
        headers={**customer_headers, "Idempotency-Key": "unique-order-key-1"}
    )
    assert order_resp.status_code == 201
    order_data = order_resp.json()
    order_id = order_data["id"]
    assert order_data["status"] == "pending"
    assert order_data["payment_status"] == "unpaid"

    # Idempotent retry returns identical payload
    order_retry_resp = client.post(
        "/api/v1/orders",
        json=order_payload,
        headers={**customer_headers, "Idempotency-Key": "unique-order-key-1"}
    )
    assert order_retry_resp.status_code == 201
    assert order_retry_resp.json()["id"] == order_id

    # 5. Admin assigns order to Rider
    assign_resp = client.post(
        f"/api/v1/orders/{order_id}/assign",
        json={"rider_id": "rider-uuid-1"},
        headers=admin_headers
    )
    assert assign_resp.status_code == 200
    delivery_id = assign_resp.json()["delivery"]["id"]

    # 6. Rider views active delivery
    active_resp = client.get("/api/v1/riders/active-delivery", headers=rider_headers)
    assert active_resp.status_code == 200
    assert active_resp.json()["order"]["id"] == order_id

    # 7. Rider marks picked_up
    status_resp = client.post(
        f"/api/v1/deliveries/{delivery_id}/status",
        json={"status": "picked_up"},
        headers=rider_headers
    )
    assert status_resp.status_code == 200
    assert status_resp.json()["status"] == "picked_up"

    # 8. Rider marks on_the_way
    status_resp2 = client.post(
        f"/api/v1/deliveries/{delivery_id}/status",
        json={"status": "on_the_way"},
        headers=rider_headers
    )
    assert status_resp2.status_code == 200

    # 9. Rider streams GPS locations
    loc_payload = {
        "locations": [
            {
                "latitude": 14.5530,
                "longitude": 121.0450,
                "accuracy": 5.0,
                "heading": 90.0,
                "speed": 6.5,
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
        ]
    }
    loc_resp = client.post(f"/api/v1/deliveries/{delivery_id}/location", json=loc_payload, headers=rider_headers)
    assert loc_resp.status_code == 200

    # Customer checks snapshot
    snap_resp = client.get(f"/api/v1/deliveries/{delivery_id}/snapshot", headers=customer_headers)
    assert snap_resp.status_code == 200
    assert snap_resp.json()["last_rider_location"]["latitude"] == 14.5530

    # 10. Rider completes delivery and confirms COD collection
    delivered_resp = client.post(
        f"/api/v1/deliveries/{delivery_id}/status",
        json={"status": "delivered", "cod_collected": True},
        headers=rider_headers
    )
    assert delivered_resp.status_code == 200
    assert delivered_resp.json()["status"] == "delivered"

    # Verify Order is delivered and Payment is paid
    final_order = client.get(f"/api/v1/orders/{order_id}", headers=customer_headers).json()
    assert final_order["order"]["status"] == "delivered"
    assert final_order["payment"]["status"] == "paid"
