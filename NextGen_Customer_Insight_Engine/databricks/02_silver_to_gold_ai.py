import pandas as pd
from pyspark.sql.functions import pandas_udf, col
from azure.ai.textanalytics import TextAnalyticsClient
from azure.core.credentials import AzureKeyCredential

# 1. Configuration (Copy these from Terraform Outputs or Portal)
# In production, use dbutils.secrets.get()
endpoint = "https://aisvc-nextgen-dev.cognitiveservices.azure.com/"
key = "YOUR_LANGUAGE_SERVICE_KEY"

def authenticate_client():
    return TextAnalyticsClient(endpoint=endpoint, credential=AzureKeyCredential(key))

# 2. Optimized Batch UDF
@pandas_udf("string")
def get_ai_insights(batch_ser: pd.Series) -> pd.Series:
    client = authenticate_client()
    results = []
    
    # Text Analytics supports batching up to 10 docs per call
    batch_list = batch_ser.tolist()
    
    # 1. Analyze Sentiment
    sentiment_responses = client.analyze_sentiment(documents=batch_list)
    
    # 2. Extract Key Phrases (Acts as 'Reason' or 'Root Cause')
    phrase_responses = client.extract_key_phrases(documents=batch_list)
    
    for i in range(len(batch_list)):
        sentiment = sentiment_responses[i].sentiment
        phrases = ", ".join(phrase_responses[i].key_phrases[:3]) # Get top 3
        
        # Format output for the Delta table
        results.append(f"Sentiment: {sentiment} | Key Issues: {phrases}")
        
    return pd.Series(results)

# 3. Read Silver Data
silver_path = "abfss://silver@stnextgendev.dfs.core.windows.net/chat_cleaned"
silver_df = spark.read.format("delta").load(silver_path)

# 4. Apply AI (Agentic Reasoning)
# We send the masked chat to the AI Service
gold_df = silver_df.withColumn("ai_insights", get_ai_insights(col("chat_masked")))

# 5. Save to Gold & Z-Order
gold_path = "abfss://gold@stnextgendev.dfs.core.windows.net/customer_insights"
gold_df.write.format("delta").mode("overwrite").save(gold_path)

# Optimization for the interview demo
spark.sql(f"OPTIMIZE delta.`{gold_path}` ZORDER BY (cust_id)")
