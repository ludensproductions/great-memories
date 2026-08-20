data "terraform_remote_state" "api_keys_state" {
  backend = "pg"

  config = {
    conn_str = var.tf_state_postgres_conn_str
    schema_name = "prod_cloudflare_api_keys"
  }
}

data "terraform_remote_state" "cloudflare_account" {
  backend = "pg"

  config = {
    conn_str = var.tf_state_postgres_conn_str
    schema_name = "prod_cloudflare_account"
  }
}

data "terraform_remote_state" "cloudflare_great_memories_app_docs" {
  backend = "pg"

  config = {
    conn_str = var.tf_state_postgres_conn_str
    schema_name = "prod_cloudflare_great_memories_app_docs_${var.prefix_name}"
  }
}

