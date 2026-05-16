terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

module "app_config" {
  source   = "./modules/config-file"
  filename = "/home/coolboy/labs/day16-terraform/config/app.conf"
  content  = "APP_ENV=production\nAPP_PORT=8080"
}

module "db_config" {
  source   = "./modules/config-file"
  filename = "/home/coolboy/labs/day16-terraform/config/db.conf"
  content  = "DB_HOST=localhost\nDB_PORT=5432"
}

module "cache_config" {
  source   = "./modules/config-file"
  filename = "/home/coolboy/labs/day16-terraform/config/cache.conf"
  content  = "CACHE_HOST=localhost\nCACHE_PORT=6379\nCACHE_TTL=3600"
}

output "all_configs" {
  value = {
    app   = module.app_config.file_path
    db    = module.db_config.file_path
    cache = module.cache_config.file_path
  }
}
