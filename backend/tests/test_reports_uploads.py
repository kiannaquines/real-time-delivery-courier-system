def test_sales_report_and_csv(client, admin_headers):
    # JSON sales report
    json_resp = client.get("/api/v1/reports/sales", headers=admin_headers)
    assert json_resp.status_code == 200
    assert "total_orders" in json_resp.json()
    assert "total_sales" in json_resp.json()

    # CSV sales report
    csv_resp = client.get("/api/v1/reports/sales?format=csv", headers=admin_headers)
    assert csv_resp.status_code == 200
    assert "Order Number,Date,Customer,Store" in csv_resp.text


def test_rider_performance_report(client, admin_headers):
    resp = client.get("/api/v1/reports/riders", headers=admin_headers)
    assert resp.status_code == 200
    assert len(resp.json()["riders"]) >= 1


def test_signed_upload_url(client, admin_headers):
    payload = {
        "filename": "burger.png",
        "content_type": "image/png",
        "size_bytes": 1024 * 50
    }
    resp = client.post("/api/v1/uploads/signed-url", json=payload, headers=admin_headers)
    assert resp.status_code == 200
    assert "upload_url" in resp.json()
    assert "public_url" in resp.json()


def test_cron_outbox_processing(client):
    # Invalid cron secret
    unauth_resp = client.post("/api/v1/cron/process-outbox", headers={"x-cron-secret": "wrong"})
    assert unauth_resp.status_code == 401

    # Valid cron secret
    auth_resp = client.post("/api/v1/cron/process-outbox", headers={"x-cron-secret": "test-cron-secret"})
    assert auth_resp.status_code == 200
    assert "processed_count" in auth_resp.json()
