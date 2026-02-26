# Azure-Data-Engineer-Projects

# NextGen Customer Insight Engine: End-to-End GenAI Data Pipeline

## 🚀 Project Overview
This POC demonstrates a modern, scalable data engineering pipeline designed to transform unstructured customer interactions (chats/transcripts) into actionable business intelligence. It leverages **Azure Data Engineering** for the core ETL/ELT and **Azure OpenAI (GPT-4o-mini)** for automated sentiment analysis, summarization, and agentic classification.

**Context:** Designed for a large-scale telecom or financial service provider to analyze customer churn and technical issues at scale.

## 🏗️ Architecture
The project follows the **Medallion Architecture** (Bronze, Silver, Gold) powered by Databricks and Delta Lake.

```mermaid
graph LR
    A[Source: Azure SQL & Blob] -->|ADF Copy| B(Bronze: Raw Delta)
    B -->|PySpark Cleaning| C(Silver: PII Masked)
    C -->|GenAI Agentic Enrichment| D(Gold: Sentiment & Insights)
    D -->|Vector Search| E[PowerBI / Semantic Search]
