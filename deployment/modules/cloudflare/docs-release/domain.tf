resource "cloudflare_pages_domain" "great_memories_app_release_domain" {
  account_id   = var.cloudflare_account_id
  project_name = data.terraform_remote_state.cloudflare_account.outputs.great_memories_app_archive_pages_project_name
  domain       = "docs.immich.app"
}

resource "cloudflare_record" "great_memories_app_release_domain" {
  name = "docs.immich.app"
  proxied = true
  ttl = 1
  type = "CNAME"
  content = data.terraform_remote_state.cloudflare_great_memories_app_docs.outputs.great_memories_app_branch_pages_hostname
  zone_id = data.terraform_remote_state.cloudflare_account.outputs.great_memories_app_zone_id
}
