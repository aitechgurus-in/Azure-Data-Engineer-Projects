import pandas as pd
from pyspark.sql.functions import pandas_udf, col
from openai import AzureOpenAI

# Optimized Batch Processing via Pandas UDF
@pandas_udf("string")
def get_sentiment_agent(batch_ser: pd.Series) -> pd.Series:
    # In production, keys are fetched via dbutils.secrets.get()
    client = AzureOpenAI(api_key="YOUR_KEY", azure_endpoint="YOUR_URL", api_version="2024-02-01")
    results = []
    for text in batch_ser:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "system", "content": "Classify: Sentiment(1-10)|Category|Summary"},
                      {"role": "user", "content": text}]
        )
        results.append(response.choices[0].message.content)
    return pd.Series(results)

# Load Silver Data
silver_df = spark.read.format("delta").load("abfss://silver@stnextgendev.dfs.core.windows.net/chat_cleaned")

# AI Enrichment
gold_df = silver_df.withColumn("ai_insights", get_sentiment_agent(col("chat_masked")))

# Optimization: Z-Ordering for analytical performance
gold_df.write.format("delta").mode("overwrite").save("abfss://gold@stnextgendev.dfs.core.windows.net/customer_insights")
spark.sql("OPTIMIZE delta.`abfss://gold@stnextgendev.dfs.core.windows.net/customer_insights` ZORDER BY (cust_id)")
