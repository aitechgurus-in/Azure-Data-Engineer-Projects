import pandas as pd
from pyspark.sql.functions import pandas_udf, col
from openai import AzureOpenAI

# Pandas UDF for optimized batch API calls
@pandas_udf("string")
def get_ai_insight(batch_ser: pd.Series) -> pd.Series:
    client = AzureOpenAI(api_key="KEY", azure_endpoint="URL", api_version="2024-02-01")
    results = []
    for text in batch_ser:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "system", "content": "Classify sentiment 1-10 and root cause."},
                      {"role": "user", "content": text}]
        )
        results.append(response.choices[0].message.content)
    return pd.Series(results)

# Apply AI Enrichment
silver_df = spark.read.format("delta").load("abfss://silver@stnextgen.dfs.core.windows.net/chats_cleaned")
gold_df = silver_df.withColumn("ai_insight", get_ai_insight(col("chat_masked")))

# Final Write & Optimization
gold_df.write.format("delta").mode("overwrite").save("abfss://gold@stnextgen.dfs.core.windows.net/ai_insights")
spark.sql("OPTIMIZE delta.`abfss://gold@stnextgen.dfs.core.windows.net/ai_insights` ZORDER BY (Region)")
