from pyspark.sql.functions import col, regexp_replace, current_timestamp

# Read raw chats from Landing Zone
df = spark.read.json("abfss://external-source@stnextgendev.dfs.core.windows.net/chats.json")

# Mask PII (Emails) for Security Compliance
# Interview Tip: Explain you redact PII before sending data to LLMs
silver_df = df.withColumn(
    "chat_masked", 
    regexp_replace(col("chat_history"), r"[\w\.-]+@[\w\.-]+", "[REDACTED_EMAIL]")
).withColumn("processed_at", current_timestamp())

# Write to Silver Delta Table
silver_df.write.format("delta").mode("overwrite").save("abfss://silver@stnextgendev.dfs.core.windows.net/chat_cleaned")
