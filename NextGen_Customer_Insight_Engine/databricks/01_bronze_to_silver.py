# Notebook: 01_bronze_to_silver
from pyspark.sql.functions import col, regexp_replace, current_timestamp, broadcast

# 1. SETUP
storage_acc = "stnextgendev20c0e1d8" 

# 2. DEFINE PATHS (Updated to use wasbs:// and .blob)
# Protocol: wasbs://container@account.blob.core.windows.net/path
chats_path = f"wasbs://external-source@{storage_acc}.blob.core.windows.net/sample_chats.json"
metadata_path = f"wasbs://external-source@{storage_acc}.blob.core.windows.net/ticket_metadata.json"

# Writing to the 'silver' container
silver_path = f"wasbs://silver@{storage_acc}.blob.core.windows.net/chat_cleaned"

# 3. READ DATA
print("Reading raw files from Bronze...")
chats_df = spark.read.json(chats_path)
metadata_df = spark.read.json(metadata_path)

# 4. TRANSFORM: JOIN & PII MASKING
print("Applying PII Masking and joining metadata...")
silver_df = chats_df.join(broadcast(metadata_df), "cust_id", "inner") \
    .withColumn(
        "chat_masked", 
        regexp_replace(col("chat_history"), r"[\w\.-]+@[\w\.-]+", "[EMAIL_REDACTED]")
    ) \
    .withColumn("ingestion_ts", current_timestamp())

# 5. WRITE TO SILVER LAYER (DELTA)
print(f"Writing Silver Delta table to {silver_path}...")
silver_df.write.format("delta").mode("overwrite").save(silver_path)

print("SUCCESS: Silver Layer Created.")
display(silver_df.limit(5))
