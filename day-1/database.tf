# Create the GCP Secret empty for postgres user
resource "google_secret_manager_secret" "postgres" {
  count     = length(var.environment_names)
  secret_id = "postgres_${var.environment_names[count.index]}_postgres"

  labels = {
    service  = "cloud_sql"
    database = var.environment_names[count.index]
    user     = "postgres"
  }

  replication {
    user_managed {
      replicas {
        location = var.google_region
      }
    }
  }
}

# Generates random password data for use as postgres user
resource "random_password" "postgres" {
  count       = length(var.environment_names)
  length      = 16
  special     = false
  min_numeric = 4
  min_upper   = 4
}

# Store postgres password in GCP Secret
resource "google_secret_manager_secret_version" "postgres_secret_version" {
  count       = length(var.environment_names)
  secret      = google_secret_manager_secret.postgres[count.index].id
  secret_data = random_password.postgres[count.index].result
}

# Create the GCP Secret empty for ctdapp user
resource "google_secret_manager_secret" "ctdapp" {
  count     = length(var.environment_names)
  secret_id = "postgres_${var.environment_names[count.index]}_${var.dbname}"

  labels = {
    service  = "cloud_sql"
    database = var.environment_names[count.index]
    user     = var.dbname
  }

  replication {
    user_managed {
      replicas {
        location = var.google_region
      }
    }
  }
}

# Generates random password data for use as ctdapp user
resource "random_password" "ctdapp" {
  count       = length(var.environment_names)
  length      = 16
  special     = false
  min_numeric = 4
  min_upper   = 4
}

# Store ctdapp password in GCP Secret
resource "google_secret_manager_secret_version" "ctdapp_secret_version" {
  count       = length(var.environment_names)
  secret      = google_secret_manager_secret.ctdapp[count.index].id
  secret_data = random_password.ctdapp[count.index].result
}

# Creates the Database Engine instance Postgres 15
resource "google_sql_database_instance" "postgres" {
  count            = length(var.environment_names)
  name             = var.environment_names[count.index]
  database_version = "POSTGRES_15"
  root_password    = random_password.postgres[count.index].result
  settings {
    tier              = "db-custom-2-7680"
    edition           = "ENTERPRISE"
    disk_size         = "100" # GB
    disk_autoresize   = "true"
    availability_type = "REGIONAL"
    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 10
      }
    }
    ip_configuration {
      ipv4_enabled = true
      require_ssl  = true
      authorized_networks {
        name  = "Full open"
        value = "0.0.0.0/0"
      }
    }
    maintenance_window {
      day  = 7
      hour = 1
    }
  }
  deletion_protection = "true"
}

# Creates a client certificate for establishing SSL connections
resource "google_sql_ssl_cert" "client_cert" {
  count       = length(var.environment_names)
  common_name = var.environment_names[count.index]
  instance    = google_sql_database_instance.postgres[count.index].name
}

# Create ctdapp Database
resource "google_sql_database" "ctdapp" {
  count           = length(var.environment_names)
  name            = var.dbname
  instance        = google_sql_database_instance.postgres[count.index].name
  charset         = "UTF8"
  deletion_policy = "ABANDON"
}

# Create user ctdapp
resource "google_sql_user" "ctdapp" {
  count           = length(var.environment_names)
  instance        = google_sql_database_instance.postgres[count.index].name
  name            = var.dbname
  password        = random_password.ctdapp[count.index].result
  type            = "BUILT_IN"
  deletion_policy = "ABANDON"
}

resource "google_secret_manager_secret" "client_cert_key" {
  count     = length(var.environment_names)
  secret_id = "postgres_${var.environment_names[count.index]}_client_cert_key"

  labels = {
    service  = "cloud_sql"
    database = var.environment_names[count.index]
  }

  replication {
    user_managed {
      replicas {
        location = var.google_region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "client_cert_key" {
  count       = length(var.environment_names)
  secret      = google_secret_manager_secret.client_cert_key[count.index].id
  secret_data = google_sql_ssl_cert.client_cert[count.index].private_key
}

resource "google_secret_manager_secret" "client_cert" {
  count     = length(var.environment_names)
  secret_id = "postgres_${var.environment_names[count.index]}_client_cert_key"

  labels = {
    service  = "cloud_sql"
    database = var.environment_names[count.index]
  }

  replication {
    user_managed {
      replicas {
        location = var.google_region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "client_cert" {
  count       = length(var.environment_names)
  secret      = google_secret_manager_secret.client_cert[count.index].id
  secret_data = google_sql_ssl_cert.client_cert[count.index].cert
}

resource "google_secret_manager_secret" "server_cert" {
  count     = length(var.environment_names)
  secret_id = "postgres_${var.environment_names[count.index]}_client_cert_key"

  labels = {
    service  = "cloud_sql"
    database = var.environment_names[count.index]
  }

  replication {
    user_managed {
      replicas {
        location = var.google_region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "server_cert" {
  count       = length(var.environment_names)
  secret      = google_secret_manager_secret.server_cert[count.index].id
  secret_data = google_sql_ssl_cert.client_cert[count.index].server_ca_cert
}

######### Outputs #########

# Store postgres password in terraform state
output "postgres_password_postgres" {
  description = "Postgres password for user postgres"
  value       = [for index, environment_name in var.environment_names : "{\"${environment_name}\":\"${random_password.postgres[index].result}\"}"]
  sensitive   = true
}

# Store ctdapp password in terraform state
output "postgres_password_ctdapp" {
  description = "Postgres password for user ctdapp"
  value       = [for index, environment_name in var.environment_names : "{\"${environment_name}\":\"${random_password.ctdapp[index].result}\"}"]
  sensitive   = true
}

# Stores a client certificate key in terraform state
output "postgres_client_cert_key" {
  description = "Client certificate private key"
  value       = [for index, environment_name in var.environment_names : "# ${environment_name}\n${google_sql_ssl_cert.client_cert[index].private_key}"]
  sensitive   = true
}

# Stores a client certificate in terraform state
output "postgres_client_cert" {
  description = "Client certificate"
  value       = [for index, environment_name in var.environment_names : "# ${environment_name}\n${google_sql_ssl_cert.client_cert[index].cert}"]
  sensitive   = true
}

# Stores a CA certificate key in terraform state
output "postgres_ca_cert" {
  description = "Root CA certificate"
  value       = [for index, environment_name in var.environment_names : "# ${environment_name}\n${google_sql_ssl_cert.client_cert[index].server_ca_cert}"]
  sensitive   = true
}