# How We Train Models at Clado

_03 Nov, 2025_

**TLDR:** reinforcement learning cut our monthly inference costs by 98.32%, improved performance on our internal benchmark, and reduced latency by 66%.

## 1) Context

Clado builds people search infrastructure, which involves indexing hundreds of millions of LinkedIn profiles and training models to first query and then filter through the rest to find the best matches for a natural language prompt. This is done with three models.

1. **Prompt → Criteria** (e.g., find me software engineers in sf → is software engineer && is in sf)
2. **Criteria → DSL** (Elasticsearch Query)
   - Our summer intern wrote a [great blog](https://ahamidi.me/clado/) on why the DSL step was necessary instead of just text2sql.
3. **Filtering.** Given a profile, does it fulfill each criterion? Why or why not?

We trained custom models for each step, but I will ignore the first and third for the rest of this, since they were just simple fine-tuning on a GPT OpenSource model.

## 2) Constructing a Golden Dataset

We collect training data by mining real user prompts and turning them into trusted (prompt → DSL) pairs. A large "oracle" model (GPT-5) drafts the DSL, we run it against the database, and throw away anything that errors or returns obviously useless results. What's left are labelled examples with the prompt, the accepted DSL, and a few basic stats (did it run, how many rows came back).

From there, we do a straightforward train-test split (70% for training, 30% held out to watch for overfitting), then fine-tune a GPT OSS 120B model with LoRA adapters. We rerun this workflow whenever the schema or user behavior changes, so the dataset stays fresh without manual labeling. The only metrics we track at this stage are simple: "does it run," "is the result size reasonable," and "did we include the obvious filters?" This gives us a labelled "golden dataset" to evaluate our search model against.

**Side note:** The better alternative to this synthetic approach is a human-labelled dataset. The risk of this approach is that we are blindly trusting the oracle model, with a bit of scaffolding, as the ground truth for this task. Unfortunately, we did not have the resources or time to generate a high-quality human-labeled dataset.

## 3) Supervised Fine Tuning (Cold-Start)

Our RL loop is simple: for each prompt, we sample a few query → dsl pairs, run them, and rank the outputs. That costs real compute: every bad sample still hits the judge and often the database. If we start from an untrained model, most candidates don't even run, so we burn cycles scoring garbage and get noisy learning signals.

Luckily, we can learn from Deepseeks' training runs for the R1; they found huge cost/compute savings by doing light supervised fine-tuning on a base model before starting RL.

![Diagram explaining the concept](https://i.imgur.com/uwSpHam.png)

_Diagram from [this article](https://makingaieasy.substack.com/p/why-i-think-deepseek-r1-just-revealed) explains this concept._

By first getting the model to produce mostly runnable, intent-matching DSL (via the golden set), RL spends its budget separating "good" from "better," not "broken" from "barely usable." That means fewer samples per prompt, fewer failed executions, more stable rewards, and faster convergence. Essentially, warming up the model so RL can focus on precision and coverage rather than syntax.

![Rented 8xH100 on Runpod for all training](https://i.imgur.com/gbDdg2R.png)

_Rented 8xH100 on Runpod for all training_

## 4) RL: Openpipe ART + RULER for rewards

In a nutshell: sample a few DSLs for a prompt, judge/rank them by how well they run and how well they match the intent, then nudge the model toward the better ones next time.

In practice (with OpenPipe ART), we train on small batches of real prompts (3 prompts/step). For each prompt, the model proposes 8 possible DSLs. For each DSL, we execute it and also collect LLM-as-judge feedback. OpenPipe's RULER combines these signals to rank candidates, and GRPO (group relative preference optimization) updates the model to prefer the higher-ranked ones.

![Sample Trajectory](https://i.imgur.com/9o8IsYj.png)

_Sample Trajectory_

The reward is practical: it would take into account whether the DSL was executed (since we solved the cold start problem with SFT, this should mostly be in the clear), whether the results are relevant, and the quantity of results returned during the rollout. The following equation represents the prompt entered in RULER to calculate DSL quality.

```
final_score = (quantity_weight · quantity_value) + (1 − quantity_weight) · quality_value

quality_value = total_score / max_possible_score

quantity_value = tanh(profiles_above_threshold / 25)
```

### Why RULER:

RULER basically does the boring parts for you. It takes multiple signals (execution success, whether required filters were present, whether the query seems too broad, and an LLM-as-judge score) and combines them into a single ranking between "candidate A" and "candidate B." That plugs directly into the policy optimization algorithm, and in our case, GRPO.

You can skip RULER and just define a numeric reward yourself as a formula that mixes result count, coverage, penalties, etc. That gives you more direct control, and it's nice because you can tune weights and see exactly why a query was rewarded. The downside is you end up rebuilding logic the judge is already doing ("is this actually relevant?"), and you still have to deal with edge cases like "query runs but is useless."

In our case, most of the signal is already "prompt + LLM as a judge." We're not doing something like robotic control where the reward is purely numeric. So, letting RULER bundle those judge signals and rank candidates got us similar performance vs the hand-tuned formula.

![Loss over Training Steps](https://i.imgur.com/rsYhdzW.png)

_Loss over Training Steps_

We keep the loop honest with lightweight observability in Weights & Biases: per-step win rate vs. the baseline, execution success rate, histograms of result-set sizes (to catch overly broad queries), and simple regex/AST checks for missing WHERE clauses or bad joins.

## 5) Evals: Judgment Labs

We use an LLM as a judge to scale the non-deterministic part of evaluation (i.e., whether the final results match the user query) because obtaining labeled pairs is time-consuming. But every candidate also has to pass hard checks: the SQL must execute, obey the schema, and return a reasonable number of rows relative to the requested number.

The premise of LLM-as-judge seemed sketchy to us at first, since we are basically asking the completions model to grade itself on the task. Initially, you'd expect this to lead to hallucinations, but it never did during our experiments. This is largely explained by the asymmetry of verification: just like in P vs NP problems, where checking a candidate solution is easier than discovering it, it's easier for a model to grade whether an answer is strong than to produce the best response itself. This mirrors the same natural property humans possess - e.g., it is easier for you to check whether a Sudoku solution is valid than to produce it from scratch (credit to Andrew Li from Judgment Labs for this explanation)!

Therefore, an eval is something we run that is powered by an LLM, along with quantitative equations that judge how good the results we returned are, combined with the number of results returned. For each model trained for a different purpose, a separate test is designed to provide a quantitative measure of its performance. This algorithm/scorer can be used in production as well as with a testing set. At the end of every query, we would run a judge on the first five results and combine it with the total hits to understand how well we did for that specific query, then put it into buckets for further development and reference.

In addition, the scorer could also be used in conjunction with a testing set. To construct our evaluation testing set, we embedded all our customer queries, clustered them, and used the centroid of each cluster as our evaluation set to ensure the widest variety of results. This would help us decide whether to run RL on a newer model, since the scorer can also be applied to the base model to assess its performance. Furthermore, the eval can also help us determine whether the post-RL model actually performs better, since, due to inaccurate tuning, the resultant model can sometimes perform worse for reasons such as entropy collapse, KL collapse, or general reward hacking.

![A snapshot of eval scores in Judgment Labs](https://i.imgur.com/YDdJVCP.png)

_A snapshot of eval scores in Judgment Labs_

We found that keeping a handful of "failed prompts" that once broke the system and plotting their pass rates across SFT → RL → APO was extremely helpful for catching drift.

## 6) Auto Prompt Optimization (DSPy)

After RL, we do a quick clean-up pass with DSPy to tune the system prompt for the Criteria→DSL model. We treat the prompt like parameters: compile new prompts, score them with the same signals we already trust (does the SQL execute, do we cover the required fields, what's the RULER/judge score), and keep changes only if they help. We iterate until the gains plateau, with guardrails to prevent APO from drifting into behaviors RL has already fixed (e.g., re-introducing overly broad queries).

## 7) Results

| Model | Quality Score | Avg Tokens | Avg Response Time | Avg Run Cost ($) |
|-------|--------------|------------|------------------|------------------|
| GPT 120B Raw | 0.65 | 639 | 10s | 0.00016 |
| GPT 120B SFT + RL | 0.81 | 448 | 7s | 0.000112 |
| O3 Raw | 0.72 | 832 | 20.8s | 0.006656 |

For 300k runs, O3 costs $1996.8; our trained GPT 120B costs $33.6, a **98.32% monthly cost reduction** while improving performance on our internal benchmark and reducing latency by 66%.

---

Written by: Eric Mao, David Shan

Originally when Clado was first started when it was still called Linkd, there was one database for each school with approximately 10k profiles per school. That means that there is a lot of room for inefficiency. However, when we decided to build people search for the entire world and started working with a data provider with over 800M profiles, in order to keep the quality, the standard was a lot higher in terms of optimization.

In this blog, I’ll go over all the decisions behind our infra to create the SOTA people search engine.

Some interesting stuff:

- Scaling from local to global: how we went from per-school databases of ~10k profiles to a unified architecture indexing 800M+ people and 30M companies worldwide.
- From FAISS to OpenSearch: why dense-only retrieval broke down at scale and how we evolved toward a multi-layer retrieval stack (MySQL + OpenSearch).
- Cost vs. latency trade-offs: lessons from using BigQuery (great indexing, terrible cost per TB scanned) and the iterative optimizations that made real-time search feasible.
- Parallel ingestion at extreme scale: engineering a two-stage sequential pipeline that ingested 1.6 billion records in < 24 hours with atomic checkpointing and zero data loss.
- Agentic orchestration: building a prompt-to-SQL agent swarm capable of evaluating candidates and scraping additional signals with asyncio + Firecrawl.
- Embeddings at scale: self-hosting Qwen Embedding 0.6 on a distributed Runpod + NGINX cluster to generate hundreds of millions of embeddings at 12–15k EPS per GPU.
- Agentic chunking experiments: using LLMs to summarize each profile into multiple semantic facets.
- Hybrid retrieval (sparse + dense): evaluating Milvus BM25 + vector hybrid search, and why query-term explosion and large-scale union merges became prohibitively expensive at 800M profiles.
- Final architecture: a 8 TB OpenSearch index backed by a 25 TB Aurora MySQL store, achieving ~4 s end-to-end query latency for global-scale people search.

You can play around with a deployed instance of this search engine on clado.ai/dashboard.

## MVP

![MVP](https://i.imgur.com/F8AyB4n.png)

The initial version of Linkd was built using a combination of Voyage embeddings and FAISS with a simple thresholding system. For small datasets (~1,000 profiles per school), the search quality was acceptable. However, as we scaled to larger datasets, two key issues emerged. First, the cost of generating and storing embeddings grew linearly with the number of profiles crawled, quickly becoming unsustainable. Second, even a 4,028-dimensional embedding wasn’t expressive enough to fully represent a person’s professional background. A single vector simply couldn’t capture the richness of multiple roles, skills, and experiences.

We also noticed semantic drift in ranking. For example, name-based searches like “David Shan” often prioritized sparse or incomplete profiles over those with more detailed information. Similarly, a search such as “FAANG engineer” would surface candidates who merely used to work at a FAANG company or were employed at adjacent firms like Microsoft, rather than those currently fitting the precise criteria. While embeddings offered decent recall, they lacked precision and context-awareness, which became a critical limitation once we began emphasizing accuracy and relevance at scale.

## Database + Agent

![Database + Agent](https://i.imgur.com/jNztE7u.png)

Afterward, we experimented with a prompt-to-SQL architecture by loading our data into BigQuery. The goal was to let an LLM interpret natural language queries and translate them into SQL, enabling structured filtering across hundreds of millions of profiles. To make this work, we built an agent swarm capable of handling high concurrency, scraping additional context from the web, and evaluating candidate relevance against user-defined criteria. We used Asyncio to orchestrate thousands of concurrent requests, while Firecrawl handled large-scale web enrichment for profiles with urls.

However, this approach quickly became cost-prohibitive. BigQuery’s pricing model charges by data scanned, and with roughly 200 million profiles (~1 TB of data), even a single query could cost upwards of $1 per search, which doesn’t scale for real-time applications. Despite its strong built-in inverted indexing, the economics and latency made BigQuery unviable for our use case.

We then migrated to MySQL to take greater control over indexing and query performance. While this significantly reduced cost, we found that MySQL’s native full-text indexing still wasn’t sufficient, search latency for 200 million profiles hovered around one minute per query, far above our real-time target. To address this, we introduced OpenSearch as a dedicated retrieval layer: MySQL became the system of record, storing full entity data, while OpenSearch indexed only the searchable fields. This hybrid architecture finally gave us the balance between speed, scalability, and precision that we had been searching for.

## Data Pipeline

![Data Pipeline](https://i.imgur.com/SnjKirt.png)

During the transition to OpenSearch, we made the decision to expand our dataset from 200 million profiles to over 800 million. This presented a significant engineering challenge: any ingestion pipeline would now need to be at least four times faster, or the team would be blocked for days without fresh data to test. To maintain iteration velocity, we set an ambitious goal, to design a pipeline that would complete in one day.

A second challenge emerged as we worked to enrich each profile with company data. Our datasets for people and companies existed in separate Parquet files, meaning the ingestion pipeline had to merge them before indexing. The resulting pipeline flow became: S3 → MySQL → OpenSearch, where MySQL served as the intermediate layer for joining and normalizing records before OpenSearch built the inverted index.

This dependency chain meant we couldn’t run the MySQL and OpenSearch ingestions in parallel — the OpenSearch step depended on fully written and joined data from MySQL. The sequential nature of this architecture introduced serious coordination and throughput challenges, forcing us to optimize every stage to sustain our one-day ingestion target.

### Stage 1: Parallel Data Ingestion to MySQL

![Step 1: Parallel Data Ingestion to MySQL](https://i.imgur.com/vbfnHDn.png)

We split the ingestion into two parallel streams - people and companies - each optimized differently:

People Ingestion Architecture:

1. 375 parallel worker processes - We pushed Python's multiprocessing to its limits, spawning hundreds of workers that could each handle their own parquet file independently
2. Subprocess isolation - Each worker ran as a separate Python process to avoid GIL contention and memory leaks
3. Atomic checkpointing - Workers appended completed files to a checkpoint file atomically, allowing us to resume from failures without data loss
4. Retry mechanism - Failed files got up to 3 retries before being logged to an error file for manual inspection

Company Ingestion Optimization:

1. 64 parallel workers with larger batch sizes (50,000 records)
2. Vectorized DataFrame transformations - Instead of row-by-row processing, we used pandas vectorized operations to transform entire columns at once
3. Bulk INSERT with ON DUPLICATE KEY UPDATE - MySQL's bulk insert with upsert semantics meant we could handle duplicates efficiently
4. Temporary file optimization - We used /mnt/dumps/ on high-speed NVMe drives for temporary parquet storage, falling back to system temp only when needed

### Stage 2: The MySQL to OpenSearch Challenge

The real complexity came in the second stage - joining 800M people records with company data and indexing into OpenSearch while the data was still flowing in:

#### Two-Phase Parallel Architecture:

1. Extraction Phase (MySQL → Parquet):
   - 128 parallel extraction workers each assigned a specific ID range using MySQL partition pruning
   - ID-based sharding - Each worker scanned a range like id > 100M AND id <= 107M, ensuring no overlap
   - LEFT JOIN optimization - We pre-joined people with companies in MySQL, avoiding the need for lookups during indexing
   - 50,000 record batches - Large enough for efficiency, small enough to fit in memory
2. Processing Phase (Parquet → OpenSearch):
   - File-based queueing system - We used atomic file operations (rename) to coordinate between extraction and processing stages
   - 24 concurrent processors - Each handling document transformation and bulk indexing
   - 10,000 document bulk operations - OpenSearch's sweet spot for bulk indexing performance
   - Continuous processing - Processors started working as soon as the first parquet files appeared, no waiting for extraction to complete

#### Critical Optimizations That Made It Possible

1. Memory Management:
   - Garbage collection every 10 batches to prevent memory bloat
   - Worker process recycling to avoid long-term memory leaks
   - Streaming processing - never loading the full dataset into memory
2. I/O Optimization:
   - NVMe SSDs for temporary storage with automatic fallback to system temp
   - Snappy compression for parquet files - fast compression with reasonable ratios
   - Cleanup of processed files to prevent disk exhaustion
3. Error Recovery:
   - Checkpoint files tracked both completed batches and continuous progress
   - Failed batches moved to a "failed" queue for retry or manual inspection
   - Graceful degradation - if one worker failed, others continued
4. Document Transformation Pipeline:
   - Pre-compiled regex patterns for date extraction
   - Cached JSON parsing and currency conversion
   - Efficient handling of nested structures (experiences, education, etc.)

#### The Result

With these optimizations, we achieved:

- 22 hours total ingestion time for 800M profiles
- ~10,100 profiles/second sustained throughput
- Zero data loss through atomic checkpointing
- 4-second end-to-end query latency on the final index

## Thoughts on Embeddings

![Embeddings](https://i.imgur.com/6d1HVoU.png)

Throughout this process, we kept revisiting the idea of embeddings since they had always seemed promising for improving semantic matching and relevance. Our earlier experiments, however, revealed a major limitation: a single embedding per profile wasn’t expressive enough to represent all of a person’s professional information. Profiles are inherently very complicated and compressing all that into one 4,000-dimensional vector loses too much nuance.

Still, with our dataset now expanded to over 800 million profiles, we decided to revisit embeddings to see whether scale could offset that loss in precision. Instead of relying on commercial APIs (which would’ve been prohibitively expensive at this scale), we self-hosted the Qwen Embedding 0.6 model on Runpod, giving us full control over throughput and cost.

To maximize GPU utilization, we configured each pod with a dedicated H100 GPU and deployed a lightweight FastAPI + PyTorch inference server on each one. On top of that, we used NGINX as a network load balancer, which routed incoming embedding requests across all active pods in a round-robin fashion. Each Runpod instance registered itself with NGINX using its internal IP, so the balancer could automatically distribute load evenly and retry failed pods without downtime. This setup allowed us to scale horizontally, thus adding new pods to the pool would immediately expand total throughput without requiring code changes or restarts.

Inside each pod, we built a custom dynamic batching system that grouped incoming embedding requests by token length rather than item count. This approach minimized padding overhead and fully saturated the GPU even under uneven workloads. Each pod processed around 40k–60k tokens per batch, and we maintained near 100% GPU utilization, sustaining roughly 12–15k embeddings per second per pod.

Qwen’s Matryoshka embedding design made it especially attractive for our use case, we were able to truncate embeddings to 512 dimensions, significantly reducing storage and memory usage without a major loss in semantic signal. In total, the distributed Runpod + NGINX cluster delivered the throughput we needed to handle hundreds of millions of profiles efficiently, at a fraction of the cost of hosted APIs.

![Embeddings](https://i.imgur.com/QPQ4yBF.png)

Despite the efficient setup, the results were underwhelming. The reduced dimensionality led to significant loss in granularity, and the smaller model struggled to capture deeper relational signals (e.g., role hierarchy, company prestige, or temporal job transitions).

We then explored agentic chunking, where an LLM summarizes each profile into 6–8 descriptive sentences before generating embeddings. The idea was that each sentence could represent a specific quality of a person and “criteria chunks” would later be matched against subcomponents of a user query. In practice, though, this required running multiple embedding similarity searches (one per criterion), then merging the top results. While theoretically elegant, it quickly became computationally infeasible at scale: memory usage ballooned, and merging thousands of similarity results added seconds of latency per query.

Afterwards, we tried a hybrid approach with Milvus by combining sparse and dense embeddings. However, with Milvus, the issue that we ran into is the fact that as the number of keywords increased, query latency grew significantly and exponentially. Moreover, the fusion stage between the sparse and dense retrieval results became extremely resource-intensive, since for a corpus of over 800 million profiles, the hybrid search requires retrieving and merging a large number of candidates from both the BM25 (sparse) and vector (dense) indexes. This meant that even with parallel execution, the union and re-ranking process ballooned in cost, making it difficult to sustain real-time latency at scale.

## Conclusion & What’s Next

![Conclusion](https://i.imgur.com/3Hk4rVL.png)

Building Clado’s people search engine has been a constant cycle of iteration: from small, school-level databases to a globally distributed 8 TB OpenSearch index and a 25 TB MySQL data warehouse powering more than 800 million profiles and 30 million companies. Each stage revealed new bottlenecks: not just in compute or storage, but in how data freshness, semantic depth, and infrastructure coordination ultimately determine real-world search quality.

Looking ahead, our focus is on both expanding data breadth and advancing retrieval intelligence. On the data side, we’re integrating new sources such as organizational charts, academic research via OpenAlex, and richer company datasets like org charts to add more structure and context to each profile. We’re also deepening our cross-platform graph, linking GitHub repositories, LinkedIn profiles, and other professional identifiers to better capture true professional relationships.

At the same time, we’re continuing to improve our in-house retrieval model, a small, RL-trained system built specifically for ranking and relevance optimization. The next major essay will dive into how we trained and reinforced this model, how it learns from user interactions, and how it helps Clado balance precision, recall, and latency across billions of data points.

Finally, we’re investing heavily in data freshness. Purpose-built crawlers and incremental sync pipelines are being deployed to keep profiles continuously up to date, ensuring that search results reflect the real-time professional world rather than a static dataset.

Thanks for reading!

Written by: David Shan, Eric Mao, Tom Zheng, Rohin Arya
