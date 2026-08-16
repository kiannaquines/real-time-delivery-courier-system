import math
from typing import Tuple
import httpx
from app.core.config import settings


def haversine_distance_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculates the great-circle distance between two points in km."""
    R = 6371.0 # Earth radius in kilometers
    dLat = math.radians(lat2 - lat1)
    dLon = math.radians(lon2 - lon1)
    a = (math.sin(dLat / 2) ** 2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dLon / 2) ** 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return round(R * c, 2)


async def get_route_distance_and_duration(
    origin_lat: float, origin_lon: float, dest_lat: float, dest_lon: float
) -> Tuple[float, int]:
    """
    Calls Mapbox Directions API for driving-traffic route distance (km) and duration (mins).
    Falls back gracefully to Haversine calculation if Mapbox token is dummy or call fails.
    """
    if not settings.MAPBOX_SECRET_TOKEN or settings.MAPBOX_SECRET_TOKEN.startswith("dummy"):
        dist_km = haversine_distance_km(origin_lat, origin_lon, dest_lat, dest_lon)
        # Assume average urban speed of 25 km/h + 5 mins buffer
        duration_mins = max(5, int((dist_km / 25.0) * 60) + 5)
        return dist_km, duration_mins

    try:
        url = f"https://api.mapbox.com/directions/v5/mapbox/driving/{origin_lon},{origin_lat};{dest_lon},{dest_lat}"
        params = {
            "access_token": settings.MAPBOX_SECRET_TOKEN,
            "geometries": "geojson",
            "overview": "simplified"
        }
        async with httpx.AsyncClient(timeout=5.0) as client:
            resp = await client.get(url, params=params)
            if resp.status_code == 200:
                data = resp.json()
                if "routes" in data and len(data["routes"]) > 0:
                    distance_meters = data["routes"][0]["distance"]
                    duration_seconds = data["routes"][0]["duration"]
                    dist_km = round(distance_meters / 1000.0, 2)
                    duration_mins = max(1, int(duration_seconds / 60.0))
                    return dist_km, duration_mins
    except Exception:
        pass

    dist_km = haversine_distance_km(origin_lat, origin_lon, dest_lat, dest_lon)
    duration_mins = max(5, int((dist_km / 25.0) * 60) + 5)
    return dist_km, duration_mins


def calculate_delivery_fee(distance_km: float) -> float:
    fee = settings.BASE_DELIVERY_FEE + (distance_km * settings.PER_KM_DELIVERY_FEE)
    return round(fee, 2)
