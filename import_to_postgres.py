from pathlib import Path
from getpass import getpass

import pandas as pd
from sqlalchemy import URL, create_engine, text

# 1. Find the project and cleaned CSV folder
BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data" / "processed"

# 2. Define the nine CSV files and their PostgreSQL table names
FILES = {
    "customers": "customers_clean.csv",
    "orders": "orders_clean.csv",
    "order_items": "order_items_clean.csv",
    "payments": "payments_clean.csv",
    "reviews": "reviews_clean.csv",
    "products": "products_clean.csv",
    "sellers": "sellers_clean.csv",
    "geolocation": "geolocation_clean.csv",
    "category_translation": "category_translation_clean.csv",
}

# 3. Parse date columns so PostgreSQL can store them as timestamps
DATE_COLUMNS = {
    "orders": [
        "order_purchase_timestamp",
        "order_approved_at",
        "order_delivered_carrier_date",
        "order_delivered_customer_date",
        "order_estimated_delivery_date",
    ],
    "order_items": ["shipping_limit_date"],
    "reviews": ["review_creation_date", "review_answer_timestamp"],
}

# 4. Ask for the PostgreSQL password securely
password = getpass("Enter your PostgreSQL postgres-user password: ")

db_url = URL.create(
    drivername="postgresql+psycopg",
    username="postgres",
    password=password,
    host="localhost",
    port=5432,
    database="ecommerce_analytics",
)

engine = create_engine(db_url)

try:
    # 5. Test the connection before importing files
    with engine.connect() as connection:
        database_name = connection.execute(
            text("SELECT current_database()")
        ).scalar_one()

    print(f"\nConnected successfully to: {database_name}")

    # 6. Check that all nine files exist before importing anything
    missing_files = [
        filename
        for filename in FILES.values()
        if not (DATA_DIR / filename).is_file()
    ]

    if missing_files:
        raise FileNotFoundError(
            f"These files were not found in {DATA_DIR}:\n"
            + "\n".join(missing_files)
        )

    print(f"CSV folder: {DATA_DIR}")

    # 7. Import each CSV into its PostgreSQL table
    for table_name, filename in FILES.items():
        file_path = DATA_DIR / filename
        print(f"\nImporting {filename}...")

        parse_dates = DATE_COLUMNS.get(table_name, [])
        df = pd.read_csv(file_path, parse_dates=parse_dates)

        # Replace a same-named table if it already exists.
        # This makes a rerun possible, but overwrites that table's contents.
        df.to_sql(
            name=table_name,
            con=engine,
            if_exists="replace",
            index=False,
            chunksize=2000,
            method="multi",
        )

        print(f"Imported {len(df):,} rows into '{table_name}'.")

    print("\nSUCCESS: All nine CSV files have been imported!")

except Exception as error:
    print(f"\nIMPORT FAILED: {error}")
    print(
        "\nCheck the database password, PostgreSQL service, "
        "file paths, and error message above."
    )

finally:
    engine.dispose()