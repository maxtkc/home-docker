resource "docker_container" "tgtg" {
  name    = "nextcloud_tgtg_1"
  image   = "derhenning/tgtg:${var.tgtg_version}"
  restart = "always"

  env = compact([
    "TGTG_USERNAME=${var.tgtg_username}",
    "PORT=${var.tgtg_port}",
    var.tgtg_sleep_time != null ? "SLEEP_TIME=${var.tgtg_sleep_time}" : "",
    var.tgtg_tz != null ? "TZ=${var.tgtg_tz}" : "",
    var.tgtg_locale != null ? "LOCALE=${var.tgtg_locale}" : "",
    var.tgtg_metrics != null ? "METRICS=${var.tgtg_metrics}" : "",
    var.tgtg_metrics_port != null ? "METRICS_PORT=${var.tgtg_metrics_port}" : "",
    var.tgtg_disable_tests != null ? "DISABLE_TESTS=${var.tgtg_disable_tests}" : "",
    var.tgtg_quiet != null ? "QUIET=${var.tgtg_quiet}" : "",
    var.tgtg_schedule_cron != null ? "SCHEDULE_CRON=${var.tgtg_schedule_cron}" : "",
    var.tgtg_price_monitoring != null ? "PRICE_MONITORING=${var.tgtg_price_monitoring}" : "",
    # Telegram notifier
    var.tgtg_telegram != null ? "TELEGRAM=${var.tgtg_telegram}" : "",
    var.tgtg_telegram_token != null ? "TELEGRAM_TOKEN=${var.tgtg_telegram_token}" : "",
    var.tgtg_telegram_chat_ids != null ? "TELEGRAM_CHAT_IDS=${var.tgtg_telegram_chat_ids}" : "",
    var.tgtg_telegram_body != null ? "TELEGRAM_BODY=${var.tgtg_telegram_body}" : "",
    var.tgtg_telegram_disable_commands != null ? "TELEGRAM_DISABLE_COMMANDS=${var.tgtg_telegram_disable_commands}" : "",
    var.tgtg_telegram_only_reservations != null ? "TELEGRAM_ONLY_RESERVATIONS=${var.tgtg_telegram_only_reservations}" : "",
    var.tgtg_telegram_cron != null ? "TELEGRAM_CRON=${var.tgtg_telegram_cron}" : "",
  ])

  volumes {
    volume_name    = docker_volume.tgtg_tokens.name
    container_path = "/tokens"
  }

  networks_advanced {
    name = docker_network.proxy_tier.name
  }

  networks_advanced {
    name = docker_network.default.name
  }
}
