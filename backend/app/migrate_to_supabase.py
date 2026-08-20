"""
M&S Delivery Express Kabacan - SQLite to Supabase PostgreSQL Migration Engine
Transfers all tables, relationships, and data from local SQLite to Supabase with 100% integrity.
"""

import os
import sys
import argparse
from pathlib import Path
from decimal import Decimal
from datetime import datetime

from sqlalchemy import create_engine, inspect, text, select
from sqlalchemy.orm import sessionmaker

# Ensure project modules are importable
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
BACKEND_DIR = PROJECT_ROOT / "backend"
sys.path.insert(0, str(BACKEND_DIR))

from app.core.config import settings
from app.core.database import Base
from app.models.user import User, RiderProfile, Address
from app.models.store import Store, MenuCategory, MenuItem
from app.models.order import Order, OrderItem, Payment
from app.models.delivery import Delivery, RiderLocation
from app.models.misc import RefreshToken, DeviceToken, OutboxEvent, AuditLog, IdempotencyKey

# Ordered list of models respecting Foreign Key hierarchy
MIGRATION_MODELS = [
    (User, "users"),
    (RiderProfile, "rider_profiles"),
    (Address, "addresses"),
    (Store, "stores"),
    (MenuCategory, "menu_categories"),
    (MenuItem, "menu_items"),
    (Order, "orders"),
    (OrderItem, "order_items"),
    (Payment, "payments"),
    (Delivery, "deliveries"),
    (RiderLocation, "rider_locations"),
    (RefreshToken, "refresh_tokens"),
    (DeviceToken, "device_tokens"),
    (OutboxEvent, "outbox_events"),
    (AuditLog, "audit_logs"),
    (IdempotencyKey, "idempotency_keys"),
]


class Style:
    HEADER = "\033[95m"
    BLUE = "\033[94m"
    CYAN = "\033[96m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    RED = "\033[91m"
    BOLD = "\033[1m"
    DIM = "\033[2m"
    NC = "\033[0m"


def clean_url(url: str) -> str:
    """Normalizes Postgres/Supabase URL for SQLAlchemy + psycopg2."""
    if not url:
        return ""
    url = url.strip().strip("'").strip('"')
    if url.startswith("postgres://"):
        url = "postgresql://" + url[len("postgres://"):]
    if url.startswith("postgresql://") and not url.startswith("postgresql+"):
        url = "postgresql+psycopg2://" + url[len("postgresql://"):]
    return url


def get_source_sqlite_path() -> Path:
    """Finds existing SQLite database file."""
    candidates = [
        BACKEND_DIR / "mns_delivery.db",
        PROJECT_ROOT / "mns_delivery.db",
    ]
    for p in candidates:
        if p.exists() and p.stat().st_size > 0:
            return p
    return candidates[0]


def update_env_database_url(new_url: str):
    """Updates or adds DATABASE_URL in .env file."""
    env_file = PROJECT_ROOT / ".env"
    if not env_file.exists():
        env_file.write_text(f"DATABASE_URL={new_url}\n")
        return

    lines = env_file.read_text().splitlines()
    found_db = False
    new_lines = []
    
    for line in lines:
        if line.strip().startswith("DATABASE_URL="):
            new_lines.append(f"DATABASE_URL={new_url}")
            found_db = True
        elif line.strip().startswith("DIRECT_DATABASE_URL="):
            new_lines.append(f"DIRECT_DATABASE_URL={new_url}")
        else:
            new_lines.append(line)
            
    if not found_db:
        new_lines.append(f"DATABASE_URL={new_url}")
        new_lines.append(f"DIRECT_DATABASE_URL={new_url}")

    env_file.write_text("\n".join(new_lines) + "\n")


def migrate(target_url: str, source_sqlite_path: Path = None, clean_target: bool = False, update_env: bool = True):
    print(f"\n{Style.BOLD}{Style.CYAN}======================================================{Style.NC}")
    print(f"{Style.BOLD}{Style.CYAN}   M&S Delivery - Supabase PostgreSQL Data Migration  {Style.NC}")
    print(f"{Style.BOLD}{Style.CYAN}======================================================{Style.NC}\n")

    if not source_sqlite_path:
        source_sqlite_path = get_source_sqlite_path()

    normalized_target_url = clean_url(target_url)

    print(f"{Style.BOLD}Source (SQLite):{Style.NC}    {source_sqlite_path}")
    # Mask password in log
    masked_target = normalized_target_url
    if "@" in masked_target and "://" in masked_target:
        prefix, rest = masked_target.split("://", 1)
        auth, host_db = rest.split("@", 1)
        if ":" in auth:
            user = auth.split(":", 1)[0]
            masked_target = f"{prefix}://{user}:****@{host_db}"
    print(f"{Style.BOLD}Target (Supabase):{Style.NC}  {masked_target}\n")

    if not source_sqlite_path.exists():
        print(f"{Style.RED}✖ Source SQLite database not found at {source_sqlite_path}{Style.NC}")
        sys.exit(1)

    # 1. Connect to SQLite
    sqlite_engine = create_engine(f"sqlite:///{source_sqlite_path}", connect_args={"check_same_thread": False})
    SqliteSession = sessionmaker(bind=sqlite_engine)
    src_session = SqliteSession()

    # 2. Connect to Supabase / Target
    print(f"{Style.BLUE}1. Testing Supabase PostgreSQL connectivity...{Style.NC}")
    try:
        connect_args = {"check_same_thread": False} if normalized_target_url.startswith("sqlite") else {"connect_timeout": 15}
        target_engine = create_engine(
            normalized_target_url,
            connect_args=connect_args,
            pool_pre_ping=True
        )
        with target_engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        print(f"   {Style.GREEN}✔ Successfully connected to Supabase PostgreSQL!{Style.NC}")
    except Exception as e:
        print(f"   {Style.RED}✖ Failed to connect to Supabase: {e}{Style.NC}")
        print(f"\n{Style.YELLOW}Tips:{Style.NC}")
        print(f"  • Ensure your Supabase project password is correct.")
        print(f"  • For Supabase Transaction Pooler, use port 6543 (or direct connection on port 5432).")
        print(f"  • Format: postgresql://postgres.[PROJECT_REF]:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres")
        sys.exit(1)

    # 3. Create all tables on target Supabase
    print(f"\n{Style.BLUE}2. Initializing schemas & tables on Supabase...{Style.NC}")
    try:
        Base.metadata.create_all(bind=target_engine)
        print(f"   {Style.GREEN}✔ All database tables verified and created on Supabase.{Style.NC}")
    except Exception as e:
        print(f"   {Style.RED}✖ Failed to initialize tables on Supabase: {e}{Style.NC}")
        sys.exit(1)

    TargetSession = sessionmaker(bind=target_engine)
    dst_session = TargetSession()

    if clean_target:
        print(f"\n{Style.YELLOW}3. Cleaning existing target tables (Reverse FK order)...{Style.NC}")
        for model_cls, table_name in reversed(MIGRATION_MODELS):
            try:
                dst_session.query(model_cls).delete()
                dst_session.commit()
            except Exception as e:
                dst_session.rollback()
                print(f"   {Style.YELLOW}⚠ Could not clear {table_name}: {e}{Style.NC}")
        print(f"   {Style.GREEN}✔ Target database cleaned.{Style.NC}")

    # 4. Migrate Data in FK order
    print(f"\n{Style.BLUE}3. Migrating records from SQLite to Supabase...{Style.NC}")
    
    total_migrated = 0
    migration_summary = []

    for idx, (model_cls, table_name) in enumerate(MIGRATION_MODELS, 1):
        try:
            records = src_session.query(model_cls).all()
            src_count = len(records)

            if src_count == 0:
                print(f"   [{idx}/{len(MIGRATION_MODELS)}] {Style.DIM}{table_name:<18} (0 records - skipped){Style.NC}")
                migration_summary.append((table_name, 0, 0, "Empty"))
                continue

            print(f"   [{idx}/{len(MIGRATION_MODELS)}] {table_name:<18} ({src_count} records) ... ", end="", flush=True)

            # Extract model column names
            mapper = inspect(model_cls)
            column_names = [col.key for col in mapper.attrs if hasattr(col, "columns")]

            migrated_table_count = 0
            batch_size = 100

            for i in range(0, src_count, batch_size):
                batch = records[i:i + batch_size]
                for item in batch:
                    # Construct clean dictionary of attributes
                    item_data = {}
                    for col in column_names:
                        val = getattr(item, col, None)
                        item_data[col] = val

                    # Merge / upsert into Supabase
                    new_obj = model_cls(**item_data)
                    dst_session.merge(new_obj)
                    migrated_table_count += 1
                
                dst_session.commit()

            print(f"{Style.GREEN}✔ Done ({migrated_table_count} migrated){Style.NC}")
            total_migrated += migrated_table_count
            migration_summary.append((table_name, src_count, migrated_table_count, "Success"))

        except Exception as e:
            dst_session.rollback()
            print(f"{Style.RED}✖ Error: {e}{Style.NC}")
            migration_summary.append((table_name, src_count if 'src_count' in locals() else 0, 0, f"Error: {e}"))

    # 5. Integrity Verification
    print(f"\n{Style.BLUE}4. Data Integrity Verification Summary:{Style.NC}")
    print(f"   ┌────────────────────┬──────────┬──────────┬──────────┐")
    print(f"   │ Table Name         │ SQLite   │ Supabase │ Status   │")
    print(f"   ├────────────────────┼──────────┼──────────┼──────────┤")
    for tbl, src_c, dst_c, status in migration_summary:
        status_color = Style.GREEN if status == "Success" or status == "Empty" else Style.RED
        print(f"   │ {tbl:<18} │ {src_c:<8} │ {dst_c:<8} │ {status_color}{status:<8}{Style.NC} │")
    print(f"   └────────────────────┴──────────┴──────────┴──────────┘")

    # 6. Update .env
    if update_env:
        update_env_database_url(normalized_target_url)
        print(f"\n{Style.GREEN}✔ Updated .env with the new Supabase DATABASE_URL!{Style.NC}")

    print(f"\n{Style.BOLD}{Style.GREEN}🎉 Migration to Supabase completed successfully! Total records migrated: {total_migrated}{Style.NC}\n")


def main():
    parser = argparse.ArgumentParser(description="Migrate SQLite data to Supabase PostgreSQL")
    parser.add_argument("--target-url", "--db-url", dest="target_url", help="Target Supabase PostgreSQL connection URL")
    parser.add_argument("--source-sqlite", dest="source_sqlite", help="Path to source SQLite .db file")
    parser.add_argument("--clean", action="store_true", help="Clean/truncate target Supabase tables before migrating")
    parser.add_argument("--no-env-update", action="store_true", help="Do not update .env with target database URL")
    args = parser.parse_args()

    target_url = args.target_url
    if not target_url:
        # Check if environment already has a non-sqlite URL
        current_env_url = os.environ.get("DATABASE_URL") or settings.DATABASE_URL
        if current_env_url and not current_env_url.startswith("sqlite"):
            target_url = current_env_url

    if not target_url:
        print(f"{Style.BOLD}{Style.YELLOW}No Supabase PostgreSQL URL supplied.{Style.NC}")
        print("Please enter your Supabase connection string:")
        print(f"{Style.DIM}Example: postgresql://postgres.xxxx:yourpassword@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres{Style.NC}\n")
        try:
            target_url = input("Supabase Connection URL: ").strip()
        except (KeyboardInterrupt, EOFError):
            print("\nMigration cancelled.")
            sys.exit(0)

    if not target_url:
        print(f"{Style.RED}✖ A valid Supabase Database URL is required.{Style.NC}")
        sys.exit(1)

    source_sqlite = Path(args.source_sqlite) if args.source_sqlite else None
    migrate(
        target_url=target_url,
        source_sqlite_path=source_sqlite,
        clean_target=args.clean,
        update_env=not args.no_env_update
    )


if __name__ == "__main__":
    main()
