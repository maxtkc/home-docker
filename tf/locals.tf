# Local values shared across resources.

locals {
  domain = "kcfam.us"
  ttl    = 600

  dns_subdomains = toset([
    "ssh", "nc", "im", "gramps", "gf", "uptime", "op", "git", "status",
  ])

  # Non-sensitive database config (mirrors .env)
  nextcloud_db_name = "nextcloud"
  nextcloud_db_user = "nextcloud"
  immich_db_name    = "immich"
  immich_db_user    = "immich"

  # Immich connection config (mirrors .env)
  immich_redis_hostname = "redis"
  immich_host           = "0.0.0.0"
  immich_port           = "2283"
  immich_ml_host        = "immich_machine_learning"
  immich_ml_url         = "http://immich_machine_learning:2283"

  # Shared environment variables for grampsweb and grampsweb_celery
  grampsweb_env = [
    "GRAMPSWEB_TREE=Kamenetsky-Meek Family",
    "GRAMPSWEB_CELERY_CONFIG__broker_url=redis://grampsweb_redis:6379/0",
    "GRAMPSWEB_CELERY_CONFIG__result_backend=redis://grampsweb_redis:6379/0",
    "GRAMPSWEB_RATELIMIT_STORAGE_URI=redis://grampsweb_redis:6379/1",
  ]
}
