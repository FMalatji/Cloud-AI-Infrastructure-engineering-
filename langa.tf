# ------------------------------------------------------------------------------
# LANGA WORKSPACE - CORE INFRASTRUCTURE (main.tf)
# ------------------------------------------------------------------------------

provider "google" {
  project = var.project_id
  region  = "africa-south1"
}

# 1. Zero-Trust Security: Service Account
# Engineered for keyless impersonation, eliminating static JSON keys.
resource "google_service_account" "langa_executor" {
  account_id   = "langa-executor"
  display_name = "Langa Workspace Zero-Trust Executor SA"
}

# 2. Artifact Registry: Container Image Storage
# Docker image repository storing compiled Next.js and FastAPI container images[cite: 4].
resource "google_artifact_registry_repository" "docker_repo" {
  location      = "africa-south1"
  repository_id = "langa-workspace-repo"
  description   = "Docker image repository for Langa Workspace microservices"
  format        = "DOCKER"
}

# 3. Data Residency: Cloud Storage Policy Vault
# Strict POPIA 100% domestic data residency for heavy policy PDFs (10MB+).
resource "google_storage_bucket" "policy_vault" {
  name                        = "langa-policy-vault"
  location                    = "africa-south1"
  force_destroy               = false
  uniform_bucket_level_access = true
}

# 4. Serverless Compute: Backend API Engine (FastAPI)
# Runs the decoupled microservices stack in the Johannesburg region[cite: 3].
resource "google_cloud_run_v2_service" "backend" {
  name     = "langa-backend"
  location = "africa-south1"

  template {
    # Injects the keyless service account at runtime[cite: 3, 4]
    service_account = google_service_account.langa_executor.email
    
    containers {
      image = "${google_artifact_registry_repository.docker_repo.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.repository_id}/backend:latest"
      
      # Environment variables injected from Secret Manager[cite: 4]
      env {
        name = "ENVIRONMENT"
        value = "production"
      }
    }
  }
}

# 5. Serverless Compute: Frontend Runtime (Next.js)
resource "google_cloud_run_v2_service" "frontend" {
  name     = "langa-frontend"
  location = "africa-south1"

  template {
    containers {
      image = "${google_artifact_registry_repository.docker_repo.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.repository_id}/frontend:latest"
    }
  }
}

# Allow public access to the Next.js Frontend[cite: 3]
resource "google_cloud_run_service_iam_member" "public_frontend" {
  location = google_cloud_run_v2_service.frontend.location
  project  = google_cloud_run_v2_service.frontend.project
  service  = google_cloud_run_v2_service.frontend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# 6. Autonomous Automation: Agent Nano Scheduler
# Event-driven cron heartbeat issuing OIDC calls every Friday at 1:00 PM[cite: 3, 4].
resource "google_cloud_scheduler_job" "agent_nano" {
  name             = "agent-nano-weekly-prep"
  description      = "Pre-drafts weekly lesson plans for South African school calendars[cite: 3]"
  schedule         = "0 13 * * 5" # Friday 1:00 PM
  time_zone        = "Africa/Johannesburg"
  region           = "africa-south1"

  http_target {
    http_method = "POST"
    uri         = "${google_cloud_run_v2_service.backend.uri}/api/v1/agent/cron/weekly-prep"
    
    # Secures the endpoint using the executor service account
    oidc_token {
      service_account_email = google_service_account.langa_executor.email
    }
  }
}
