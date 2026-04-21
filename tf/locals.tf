# Local values shared across resources.

locals {
  domain = "kcfam.us"
  ttl    = 600

  dns_subdomains = toset([
    "ssh", "nc", "im", "gramps", "gf", "uptime", "op", "git", "status", "tgtg", "ha", "ma", "penpot",
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
  immich_ml_url         = "http://immich_machine_learning:3003"

  # OpenProject shared environment variables (web, worker, cron, seeder)
  openproject_hocuspocus_app_env = var.openproject_hocuspocus_enabled ? [
    "OPENPROJECT_ADDITIONAL__HOST__NAMES=[openproject-web]",
    "OPENPROJECT_COLLABORATIVE__EDITING__HOCUSPOCUS__URL=wss://op.kcfam.us/hocuspocus",
    "OPENPROJECT_COLLABORATIVE__EDITING__HOCUSPOCUS__SECRET=${var.openproject_hocuspocus_secret}",
  ] : []

  openproject_env = concat([
    "OPENPROJECT_HTTPS=true",
    "OPENPROJECT_HOST__NAME=op.kcfam.us",
    "OPENPROJECT_HSTS=true",
    "OPENPROJECT_RAILS__CACHE__STORE=memcache",
    "OPENPROJECT_CACHE__MEMCACHE__SERVER=openproject-cache:11211",
    "DATABASE_URL=postgresql://openproject:${urlencode(var.openproject_db_password)}@openproject-db/openproject?pool=20&encoding=unicode&reconnect=true",
    "SECRET_KEY_BASE=${var.openproject_secret_key_base}",
    "OPENPROJECT_MIGRATION__CHECK__ON__EXCEPTIONS=false",
    "OPENPROJECT_EMAIL__DELIVERY__METHOD=smtp",
    "OPENPROJECT_MAIL__FROM=${var.smtp_email}",
    "OPENPROJECT_SMTP__ADDRESS=smtp.gmail.com",
    "OPENPROJECT_SMTP__PORT=587",
    "OPENPROJECT_SMTP__DOMAIN=kcfam.us",
    "OPENPROJECT_SMTP__AUTHENTICATION=plain",
    "OPENPROJECT_SMTP__USER__NAME=${var.smtp_email}",
    "OPENPROJECT_SMTP__PASSWORD=${var.smtp_password}",
    "OPENPROJECT_SMTP__ENABLE__STARTTLS__AUTO=true",
  ], local.openproject_hocuspocus_app_env)

  penpot_flags = join(" ", compact([
    "enable-smtp",
    "enable-prepl-server",
    var.penpot_registration_enabled ? null : "disable-registration",
  ]))

  # Shared environment variables for grampsweb and grampsweb_celery
  grampsweb_env = [
    "GRAMPSWEB_TREE=Kamenetsky-Meek Family",
    "GRAMPSWEB_CELERY_CONFIG__broker_url=redis://grampsweb_redis:6379/0",
    "GRAMPSWEB_CELERY_CONFIG__result_backend=redis://grampsweb_redis:6379/0",
    "GRAMPSWEB_RATELIMIT_STORAGE_URI=redis://grampsweb_redis:6379/1",
  ]
}
