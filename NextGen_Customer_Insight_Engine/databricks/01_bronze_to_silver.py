from pyspark.sql.functions import col, regexp_replace, current_timestamp, broadcast

# 1. Setup - Get storage account name from your Terraform output
storage_acc = "stnextgendevabcd" # Replace with your actual name

# 2. Ingest Unstructured Chat Logs
chats_path = f"abfss://external-source@{storage_acc}.dfs.core.windows.net/sample_chats.json"
df_chats = spark.read.json(chats_path)

# 3. Ingest Structured Metadata (The 'SQL Replacement' file)
meta_path = f"abfss://external-source@{storage_acc}.dfs.core.windows.net/ticket_metadata.json"
df_meta = spark.read.json(meta_path)

# 4. Join & Mask PII (The "Senior" Engineering Part)
# We use a broadcast join because the metadata file is small
enriched_df = df_chats.join(broadcast(df_meta), "cust_id", "inner") \
    .withColumn("chat_masked", regexp_replace(col("chat_history"), r"[\w\.-]+@[\w\.-]+", "[EMAIL_REDACTED]")) \
    .withColumn("ingestion_timestamp", current_timestamp())

# 5. Write to Silver Delta Table
silver_path = f"abfss://silver@{storage_acc}.dfs.core.windows.net/chat_cleaned"
enriched_df.write.format("delta").mode("overwrite").save(silver_path)

print("Bronze to Silver complete. PII Masked and Data Enriched.")
