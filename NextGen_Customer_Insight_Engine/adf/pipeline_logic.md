# ADF Pipeline Orchestration Logic

This document details the design and orchestration logic for the **NextGen Customer Insight Engine**. The pipeline is built to handle high-velocity ingestion and asynchronous GenAI enrichment.

## 🏗️ Architecture Overview
The orchestration is managed by **Azure Data Factory (ADF)** and follows a dependency-driven workflow across the Medallion layers.

### 1. Ingestion Layer (Source ➡️ Bronze)
*   **Activity Type:** `Copy Data`
*   **Source(s):** 
    *   **Structured:** Azure SQL Serverless (Support Ticket Metadata).
    *   **Unstructured:** ADLS Gen2 `external-source` (JSON Chat Logs).
*   **Logic:**
    -   **Incremental Load:** For SQL, we use a `Lookup` activity to fetch the `last_load_timestamp` to ensure only new tickets are ingested.
    -   **Blob Trigger:** The JSON ingestion is triggered automatically as new files land in the external container.
    -   **Sink:** Data is stored in its raw format in the `bronze` container as Delta files.

### 2. Transformation Layer (Bronze ➡️ Silver)
*   **Activity Type:** `Databricks Notebook` (Notebook: `01_bronze_to_silver`)
*   **Logic:**
    -   Performs **Schema Enforcement** to ensure data types match.
    -   **PII Masking Agent:** Uses a custom Python logic to redact emails and phone numbers. This is a "pre-processing" gate before data is sent to any LLM.
    -   **Joins:** Merges unstructured chat logs with structured SQL metadata into a unified Silver Delta table.

### 3. Enrichment Layer (Silver ➡️ Gold)
*   **Activity Type:** `Databricks Notebook` (Notebook: `02_silver_to_gold_ai`)
*   **The "Agentic" Logic:**
    -   This stage calls the **Azure OpenAI (GPT-4o-mini)** API.
    -   **Batch Processing:** Instead of row-by-row calls, it uses a **Pandas UDF** to batch 50 records at a time, optimizing API latency and cost.
    -   **Decision Gate:** If the LLM identifies a "High Frustration" sentiment AND "Cancellation" intent, it adds an `escalation_flag = 1`.

### 4. Post-Processing & Optimization
*   **Activity Type:** `SQL Script` / `Databricks SQL`
*   **Logic:**
    -   **Vacuum & Optimize:** Runs the `OPTIMIZE` command on the Gold table to compact small files and Z-Order data by `Region` for dashboard performance.
    -   **Metrics Logging:** ADF captures the `rows_processed` and `openai_tokens_used` and logs them to **Azure Monitor**.

---

## 🛠️ Error Handling & Retries
-   **Retry Policy:** Each Databricks activity is configured with **3 retries** and a **5-minute interval** to handle transient API rate limits from OpenAI.
-   **On Failure:** If the GenAI enrichment fails, an **Azure Logic App** is triggered via an ADF "On Failure" constraint to send an alert to the engineering team.

## ⚙️ Parameterization
The pipeline is fully parameterized to support our **Dev/Prod** environments:
-   `storage_account_url`: Dynamically switched between Dev and Prod storage.
-   `databricks_cluster_id`: Uses a cheap Single-Node cluster for Dev and an Autoscale Job cluster for Prod.
-   `openai_deployment`: Points to `gpt-4o-mini` for speed/cost in Dev.

---

## 📈 Monitoring & Observability
-   **Log Analytics:** All pipeline execution logs are sent to a **Log Analytics Workspace**.
-   **Custom Dashboards:** We use Kusto (KQL) queries to track:
    -   Pipeline Duration (Min vs. Max).
    -   Cost per Run (calculated by DBUs + OpenAI Tokens).
