Langa Workspace - EdTech AI Infrastructure
Langa Workspace is an AI-native educational SaaS platform engineered to automate South African Department of Basic Education (DBE) CAPS-aligned lesson plans and assessments. Built as a decoupled microservices application on Google Cloud Platform (GCP), the platform combines a Next.js 14 presentation tier with a FastAPI containerized backend engine.
This architecture integrates generative AI models and retrieval-augmented generation (RAG) while seamlessly enforcing domestic POPIA data residency across serverless cloud infrastructure.

🏗️ Architecture Overview & "The Location Paradox"

Langa Workspace utilizes a Decoupled Dual-Client Routing Pattern in its AI service to separate knowledge discovery from generative reasoning. This explicitly resolves the GCP "Location Paradox" to guarantee strict POPIA data sovereignty:
 • All educator profiles and personally identifiable information (PII) are stored strictly within the africa-south1 (Johannesburg) region.
 • Non-PII search vectors and context prompts are routed to multi-regional Vertex AI engines in Europe under a strict Zero-Learner-Data policy.

✨ Key Engineering Features
 • Monolith-to-Microservices Modernization: The platform operates on a decoupled, highly responsive microservices stack featuring a Next.js React frontend and a FastAPI backend hosted on Google Cloud Run.
 • Zero-Trust IAM & Keyless Security: The backend infrastructure is secured using Google Cloud Service Account impersonation via the impersonated_credentials wrapper, impersonating the langa-executor account at runtime. This completely eliminates static private JSON keys from the code repositories.
 • Compliance Audit Matrix Engine: A multi-stage RAG pipeline programmatically evaluates retrieved policy paragraphs and forces the generative AI models to calculate and adhere to national CAPS cognitive mark distributions (30% Lower Order, 50% Routine, 20% Higher Order) before drafting assessments.
 • FastAPI In-Memory Storage Proxy: Replaced brittle client-side signed URLs with a secure FastAPI proxy that buffers incoming administrative policy PDFs (10MB+) in-memory and streams them directly to Cloud Storage using native SDKs.
 • Autonomous Agent Nano Worker: An event-driven background worker (agent.py) is triggered by Google Cloud Scheduler via OIDC-authenticated calls every Friday at 1:00 PM to pre-draft weekly curriculum lesson plans based on teacher timetables.
 • WeasyPrint LaTeX PDF Engine: Includes a recursive bracket-matching engine (get_matching_brace) built to parse deeply nested LaTeX math strings into native HTML/CSS for seamless A4 PDF compilation.

☁️ Google Cloud Service Catalog
| GCP Component | Deployment Region | Technical Role & Responsibility | Security/Governance Policy |

| Cloud Run | africa-south1 | Serverless microservices engine for Next.js frontend and FastAPI backend containers. | Public invoker with JWT bearer token verification. |
| Cloud Firestore | africa-south1 | Named NoSQL instances storing user profiles, timetables, and chats. | Strict POPIA 100% domestic data residency. |
| Cloud Storage | africa-south1 | Object bucket (langa-policy-vault) for heavy policy PDFs. | Virtual directory isolation. |
| Vertex AI Search | eu (Multi-region) | Curriculum-as-Code RAG retrieval engine (Discovery Engine datastores). | Hosts CAPS Policy, 333 ATPs, and PanSALB Orthography vaults. |
| Vertex AI Models | europe-west1 / west4 | Foundation LLMs (gemini-2.5-flash and gemini-2.5-pro) for content drafting and complex reasoning. | Zero-Learner-Data policy; isolated from training. |
| Cloud Build | Global/Host | 2nd Gen Repositories CI/CD build automation pipeline connected to GitLab V2. | Authenticated via GitLab PAT tokens in Secret Manager. |

🔄 End-to-End Request Lifecycle
 • Client Request & Dynamic Routing: An educator initiates a generation request on the Next.js frontend. A runtime browser hostname parser (getApiBase) dynamically targets the correct backend (Localhost, Staging, or Production) and routes the request to Cloud Run while sanitizing trailing slashes to prevent CORS 307 Redirects.
 • Security & Session Interception: FastAPI dependency interceptors extract the JWT session token, verify the signature using the Firebase Admin SDK, and extract the cryptographically verified user identity and role without trusting body payloads.
 • RAG Retrieval (The Librarian Phase): System tokenizers optimize the query (e.g., stripping "Grade" labels and mapping subject acronyms) to build a structured SEARCH_HINT. It then queries the Quad-Vault datastores in Europe to retrieve exact CAPS rules, Annual Teaching Plan (ATP) pacing, and orthography constraints.
 • Model Generation (The Brain Phase): Retrieved context is bundled and sent to Gemini 2.5 Flash/Pro in europe-west1, where the model strictly enforces the Compliance Audit Matrix (30/50/20 cognitive split) before generating content.
 • Storage & Telemetry: Generated documents pass through the LaTeX cleaning parsers for PDF compilation and are saved to Firestore in africa-south1 under isolated tenant paths, automatically updating user metrics via real-time Firebase listeners.
