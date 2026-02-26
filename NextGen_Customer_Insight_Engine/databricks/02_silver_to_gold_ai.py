import pandas as pd
from pyspark.sql.functions import pandas_udf, col, when
from azure.ai.textanalytics import TextAnalyticsClient
from azure.core.credentials import AzureKeyCredential

# 1. Update these from your Terraform Output
storage_acc = "stnextgendevfce0" # <--- UPDATE THIS from terraform output storage_account_name
endpoint = "REPLACE_WITH_YOUR_AI_ENDPOINT" 
key = "REPLACE_WITH_YOUR_AI_KEY"

def authenticate_client():
    return TextAnalyticsClient(endpoint=endpoint, credential=AzureKeyCredential(key))

# 2. Optimized Batch UDF (vectorized API calls)
@pandas_udf("string")
def get_ai_insights(batch_ser: pd.Series) -> pd.Series:
    client = authenticate_client()
    results = []
    
    # Azure Text Analytics allows batching up to 10 docs at once
    batch_list = batch_ser.tolist()
    
    try:
        sentiment_responses = client.analyze_sentiment(documents=batch_list)
        phrase_responses = client.extract_key_phrases(documents=batch_list)
        
        for i in range(len(batch_list)):
            sentiment = sentiment_responses[i].sentiment
            phrases = ", ".join(phrase_responses[i].key_phrases[:3])
            results.append(f"Sentiment: {sentiment} | Key Issues: {phrases}")
    except Exception as e:
        # Fallback for errors
        return pd.Series(["Error in AI Processing"] * len(batch_list))
        
    return pd.Series(results)

# 3. Read Silver Data
silver_path = f"abfss://silver@{storage_acc}.dfs.core.windows.net/chat_cleaned"
silver_df = spark.read.format("delta").load(silver_path)

# 4. Apply AI Enrichment
enriched_df = silver_df.withColumn("ai_insights", get_ai_insights(col("chat_masked")))

# 5. Agentic Logic (The "Senior" touch)
# Automatically flag records where sentiment is negative for executive review
gold_df = enriched_df.withColumn(
    "is_high_risk", 
    when(col("ai_insights").contains("negative"), True).otherwise(False)
)

# 6. Save to Gold & Optimize
gold_path = f"abfss://gold@{storage_acc}.dfs.core.windows.net/customer_insights"
gold_df.write.format("delta").mode("overwrite").save(gold_path)

# Optimization for the interview demo
spark.sql(f"OPTIMIZE delta.`{gold_path}` ZORDER BY (cust_id)")
