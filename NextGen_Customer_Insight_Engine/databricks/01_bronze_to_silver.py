from pyspark.sql.functions import col, regexp_replace

# Read Raw JSON Chats from Bronze
raw_df = spark.read.json("abfss://bronze@stnextgen.dfs.core.windows.net/chats/*.json")

# Masking emails for PII compliance before sending to LLM
cleaned_df = raw_df.withColumn(
    "chat_masked", 
    regexp_replace(col("chat_history"), r"[\w\.-]+@[\w\.-]+", "[REDACTED_EMAIL]")
)

# Save to Silver Layer
cleaned_df.write.format("delta").mode("overwrite").save("abfss://silver@stnextgen.dfs.core.windows.net/chats_cleaned")
