from pyspark.sql.functions import col, regexp_replace, current_timestamp

# Read Raw JSON Chats
df = spark.read.json("abfss://external-source@stnextgendev.dfs.core.windows.net/sample_chats.json")

# Mask PII (Emails)
silver_df = df.withColumn(
    "chat_masked", 
    regexp_replace(col("chat_history"), r"[\w\.-]+@[\w\.-]+", "[REDACTED_EMAIL]")
).withColumn("processed_at", current_timestamp())

# Write to Silver Delta
silver_df.write.format("delta").mode("overwrite").save("abfss://silver@stnextgendev.dfs.core.windows.net/chat_cleaned")
