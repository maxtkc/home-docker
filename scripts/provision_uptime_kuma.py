#!/usr/bin/env python3
"""
Uptime Kuma Provisioning Script

This script automatically provisions monitors for the home server stack.
Run this after setting up Uptime Kuma for the first time to create all monitors.

Usage:
    # Create new monitors only (default)
    python3 provision_uptime_kuma.py --url https://uptime.kcfam.us --username maxtkc --pass-name uptime-kuma/admin
    
    # Update existing monitors with new configuration
    python3 provision_uptime_kuma.py --url https://uptime.kcfam.us --username maxtkc --pass-name uptime-kuma/admin --update-existing
    
    # Delete monitors not managed by this script (with confirmation)
    python3 provision_uptime_kuma.py --url https://uptime.kcfam.us --username maxtkc --pass-name uptime-kuma/admin --delete-unmanaged
    
    # Update existing AND delete unmanaged monitors
    python3 provision_uptime_kuma.py --url https://uptime.kcfam.us --username maxtkc --pass-name uptime-kuma/admin --update-existing --delete-unmanaged
    
    # Full reset: Delete ALL monitors and recreate fresh (requires double confirmation)
    python3 provision_uptime_kuma.py --url https://uptime.kcfam.us --username maxtkc --pass-name uptime-kuma/admin --full-reset
    
    # With traditional password instead of pass:
    python3 provision_uptime_kuma.py --url https://uptime.kcfam.us --username maxtkc --password your_password
"""

import argparse
import subprocess
import sys
import time
from uptime_kuma_api import UptimeKumaApi, MonitorType, MonitorStatus


def get_existing_monitors(api):
    """Get all existing monitors and return them as a dict keyed by name."""
    monitors = api.get_monitors()
    return {monitor['name']: monitor for monitor in monitors}


def delete_all_monitors(api):
    """Delete all existing monitors and Docker hosts."""
    print("🗑️  Full reset: Deleting all existing monitors...")
    
    # Get all monitors directly from API (not as dict by name)
    try:
        all_monitors = api.get_monitors()
    except Exception as e:
        print(f"✗ Failed to get monitors list: {e}")
        return False
    
    if not all_monitors:
        print("No monitors found to delete")
        return True
    
    print(f"Found {len(all_monitors)} monitors to delete:")
    for monitor in all_monitors:
        monitor_name = monitor.get('name', f"Unnamed (ID: {monitor.get('id', 'Unknown')})")
        monitor_type = monitor.get('type', 'Unknown')
        print(f"  - {monitor_name} (ID: {monitor.get('id')}, Type: {monitor_type})")
    
    # Double confirmation for safety
    print(f"\n⚠️  WARNING: This will delete ALL {len(all_monitors)} monitors!")
    confirm1 = input("Are you sure you want to continue? [y/N]: ").lower().strip()
    if confirm1 not in ['y', 'yes']:
        print("❌ Full reset cancelled")
        return False
    
    confirm2 = input("Type 'DELETE ALL' to confirm: ").strip()
    if confirm2 != 'DELETE ALL':
        print("❌ Full reset cancelled - confirmation text did not match")
        return False
    
    # Delete all monitors by ID
    print("\n🗑️  Deleting monitors...")
    deleted_count = 0
    failed_count = 0
    
    for monitor in all_monitors:
        monitor_id = monitor.get('id')
        monitor_name = monitor.get('name', f"Unnamed (ID: {monitor_id})")
        
        if not monitor_id:
            print(f"⚠️  Skipping monitor with missing ID: {monitor_name}")
            continue
            
        try:
            api.delete_monitor(monitor_id)
            print(f"✓ Deleted monitor: {monitor_name} (ID: {monitor_id})")
            deleted_count += 1
            time.sleep(0.3)  # Small delay to avoid overwhelming the API
        except Exception as e:
            print(f"✗ Failed to delete monitor {monitor_name} (ID: {monitor_id}): {e}")
            failed_count += 1
    
    # Also try to delete Docker hosts
    try:
        docker_hosts = api.get_docker_hosts()
        if docker_hosts:
            print(f"\n🗑️  Deleting {len(docker_hosts)} Docker hosts...")
            for host in docker_hosts:
                host_name = host.get('name', f"Unnamed (ID: {host.get('id', 'Unknown')})")
                try:
                    api.delete_docker_host(host['id'])
                    print(f"✓ Deleted Docker host: {host_name}")
                    time.sleep(0.3)
                except Exception as e:
                    print(f"✗ Failed to delete Docker host {host_name}: {e}")
    except Exception as e:
        print(f"⚠️  Could not check Docker hosts: {e}")
    
    if failed_count > 0:
        print(f"\n⚠️  Full reset completed with issues - deleted {deleted_count}, failed {failed_count}")
    else:
        print(f"\n✓ Full reset completed successfully - deleted {deleted_count} monitors")
    
    return True


def create_monitors(api, update_existing=False, delete_unmanaged=False, full_reset=False):
    """Create all monitors for the home server stack."""
    
    # Handle full reset first
    if full_reset:
        reset_successful = delete_all_monitors(api)
        if not reset_successful:
            print("❌ Full reset was cancelled - stopping here")
            return
        print("\n🚀 Proceeding to create fresh monitors...\n")
        # After full reset, we're creating everything fresh
        update_existing = False
        delete_unmanaged = False
    
    monitors_config = [
        # External services (HTTPS)
        {
            "name": "Nextcloud (External)",
            "type": MonitorType.HTTP,
            "url": "https://nc.kcfam.us",
            "interval": 60,
            "maxretries": 3,
            "maxredirects": 10,
            "accepted_statuscodes": ["200"],
            "keyword": "Nextcloud",
            "description": "Nextcloud file sharing and collaboration platform"
        },
        {
            "name": "Immich (External)",
            "type": MonitorType.HTTP,
            "url": "https://im.kcfam.us",
            "interval": 60,
            "maxretries": 3,
            "maxredirects": 10,
            "accepted_statuscodes": ["200"],
            "description": "Immich photo management and AI features"
        },
        {
            "name": "GrampsWeb (External)",
            "type": MonitorType.HTTP,
            "url": "https://gramps.kcfam.us",
            "interval": 60,
            "maxretries": 3,
            "maxredirects": 10,
            "accepted_statuscodes": ["200"],
            "description": "Family tree and genealogy application"
        },
        
        # Internal services (Port monitoring)
        {
            "name": "PostgreSQL (Main DB)",
            "type": MonitorType.PORT,
            "hostname": "db",
            "port": 5432,
            "interval": 30,
            "maxretries": 3,
            "description": "Main PostgreSQL database for Nextcloud and shared services"
        },
        {
            "name": "PostgreSQL (Immich)",
            "type": MonitorType.PORT,
            "hostname": "immich_postgres", 
            "port": 5432,
            "interval": 30,
            "maxretries": 3,
            "description": "PostgreSQL database for Immich with vector extensions"
        },
        {
            "name": "Redis Cache",
            "type": MonitorType.PORT,
            "hostname": "redis",
            "port": 6379,
            "interval": 30,
            "maxretries": 3,
            "description": "Redis cache for Nextcloud and shared services"
        },
        {
            "name": "GrampsWeb Redis",
            "type": MonitorType.PORT,
            "hostname": "grampsweb_redis",
            "port": 6379,
            "interval": 30,
            "maxretries": 3,
            "description": "Redis instance for GrampsWeb Celery and rate limiting"
        },
        
        # Internal HTTP services
        {
            "name": "Nextcloud App (Internal)",
            "type": MonitorType.PORT,
            "hostname": "app",
            "port": 9000,
            "interval": 60,
            "maxretries": 3,
            "description": "Internal Nextcloud PHP-FPM application"
        },
        {
            "name": "Nginx Web Server",
            "type": MonitorType.HTTP,
            "url": "http://web:80",
            "interval": 60,
            "maxretries": 3,
            "accepted_statuscodes": ["200", "301", "302", "400", "404"],
            "headers": {"Host": "nc.kcfam.us"},
            "description": "Nginx web server for Nextcloud"
        },
        {
            "name": "Immich Server (Internal)",
            "type": MonitorType.HTTP,
            "url": "http://immich_server:2283",
            "interval": 60,
            "maxretries": 3,
            "accepted_statuscodes": ["200", "404"],
            "description": "Internal Immich server API"
        },
        {
            "name": "GrampsWeb (Internal)",
            "type": MonitorType.HTTP,
            "url": "http://grampsweb:5000",
            "interval": 60,
            "maxretries": 3,
            "accepted_statuscodes": ["200", "404"],
            "description": "Internal GrampsWeb application server"
        },
        
        # Proxy and SSL
        {
            "name": "Nginx Proxy",
            "type": MonitorType.PORT,
            "hostname": "proxy",
            "port": 80,
            "interval": 30,
            "maxretries": 3,
            "description": "Main nginx reverse proxy (HTTP)"
        },
        {
            "name": "Nginx Proxy SSL",
            "type": MonitorType.PORT,
            "hostname": "proxy",
            "port": 443,
            "interval": 30,
            "maxretries": 3,
            "description": "Main nginx reverse proxy (HTTPS)"
        }
    ]
    
    # Docker container monitors
    docker_containers = [
        {"name": "Nextcloud App Container", "container": "app", "description": "Nextcloud PHP-FPM application container"},
        {"name": "Nextcloud Web Container", "container": "web", "description": "Nginx web server container"},  
        {"name": "Nextcloud Cron Container", "container": "cron", "description": "Nextcloud background job container"},
        {"name": "PostgreSQL Container", "container": "db", "description": "Main PostgreSQL database container"},
        {"name": "Redis Container", "container": "redis", "description": "Redis cache container"},
        {"name": "Immich Server Container", "container": "immich_server", "description": "Immich main server container"},
        {"name": "Immich Microservices Container", "container": "immich_microservices", "description": "Immich background processing container"},
        {"name": "Immich ML Container", "container": "immich_machine_learning", "description": "Immich machine learning container"},
        {"name": "Immich PostgreSQL Container", "container": "immich_postgres", "description": "Immich PostgreSQL with vector extensions"},
        {"name": "GrampsWeb Container", "container": "grampsweb", "description": "GrampsWeb main application container"},
        {"name": "GrampsWeb Celery Container", "container": "grampsweb_celery", "description": "GrampsWeb background worker container"},
        {"name": "GrampsWeb Redis Container", "container": "grampsweb_redis", "description": "GrampsWeb Redis container"},
        {"name": "Nginx Proxy Container", "container": "proxy", "description": "Main reverse proxy container"},
        {"name": "Let's Encrypt Container", "container": "letsencrypt-companion", "description": "SSL certificate management container"}
    ]
    
    # Get existing monitors if we need to update or delete
    existing_monitors = get_existing_monitors(api) if (update_existing or delete_unmanaged) else {}
    configured_names = {config['name'] for config in monitors_config}
    configured_names.update({f"{container['name']}" for container in docker_containers})
    
    action = "Creating/updating" if update_existing else "Creating"
    print(f"{action} {len(monitors_config)} HTTP/Port monitors...")
    
    # First, add a Docker host
    try:
        docker_host_result = api.add_docker_host(
            name="Local Docker Host",
            dockerDaemon="/var/run/docker.sock",
            dockerType=0  # Socket type
        )
        print(f"✓ Added Docker host (ID: {docker_host_result.get('dockerHostID', 'Unknown')})")
        docker_host_id = docker_host_result.get('dockerHostID')
    except Exception as e:
        if "already exists" in str(e).lower():
            print("- Docker host already exists")
            # Try to get existing docker host ID
            docker_hosts = api.get_docker_hosts()
            docker_host_id = docker_hosts[0]['id'] if docker_hosts else 1
        else:
            print(f"✗ Failed to add Docker host: {e}")
            docker_host_id = None
    
    for monitor_config in monitors_config:
        monitor_name = monitor_config['name']
        existing_monitor = existing_monitors.get(monitor_name)
        
        try:
            if existing_monitor and update_existing:
                # Update existing monitor
                result = api.edit_monitor(existing_monitor['id'], **monitor_config)
                print(f"✓ Updated monitor: {monitor_name} (ID: {existing_monitor['id']})")
            elif existing_monitor:
                # Monitor exists but we're not updating
                print(f"- Monitor already exists: {monitor_name}")
            else:
                # Create new monitor
                result = api.add_monitor(**monitor_config)
                print(f"✓ Created monitor: {monitor_name} (ID: {result['monitorID']})")
            time.sleep(0.5)  # Small delay to avoid overwhelming the API
        except Exception as e:
            if "already exists" in str(e).lower():
                print(f"- Monitor already exists: {monitor_name}")
            else:
                print(f"✗ Failed to create/update monitor {monitor_name}: {e}")
    
    # Add Docker container monitors if we have a Docker host
    if docker_host_id:
        print(f"\nCreating {len(docker_containers)} Docker container monitors...")
        for container_config in docker_containers:
            container_name = container_config["name"]
            existing_monitor = existing_monitors.get(container_name)
            
            try:
                if existing_monitor and update_existing:
                    # Update existing Docker monitor
                    result = api.edit_monitor(
                        existing_monitor['id'],
                        type=MonitorType.DOCKER,
                        name=container_name,
                        docker_container=container_config["container"],
                        docker_host=docker_host_id,
                        interval=60,
                        maxretries=3,
                        description=container_config["description"]
                    )
                    print(f"✓ Updated Docker monitor: {container_name} (ID: {existing_monitor['id']})")
                elif existing_monitor:
                    print(f"- Docker monitor already exists: {container_name}")
                else:
                    # Create new Docker monitor
                    result = api.add_monitor(
                        type=MonitorType.DOCKER,
                        name=container_name,
                        docker_container=container_config["container"],
                        docker_host=docker_host_id,
                        interval=60,
                        maxretries=3,
                        description=container_config["description"]
                    )
                    print(f"✓ Created Docker monitor: {container_name} (ID: {result['monitorID']})")
                time.sleep(0.5)
            except Exception as e:
                if "already exists" in str(e).lower():
                    print(f"- Docker monitor already exists: {container_name}")
                else:
                    print(f"✗ Failed to create/update Docker monitor {container_name}: {e}")
    else:
        print("\n⚠ Skipping Docker container monitors (no Docker host available)")
    
    # Delete unmanaged monitors if requested
    if delete_unmanaged and existing_monitors:
        print(f"\nChecking for unmanaged monitors to delete...")
        unmanaged_monitors = {name: monitor for name, monitor in existing_monitors.items() 
                            if name not in configured_names}
        
        if unmanaged_monitors:
            print(f"Found {len(unmanaged_monitors)} unmanaged monitors:")
            for name, monitor in unmanaged_monitors.items():
                print(f"  - {name} (ID: {monitor['id']})")
            
            confirm = input("\nDelete these unmanaged monitors? [y/N]: ").lower().strip()
            if confirm in ['y', 'yes']:
                for name, monitor in unmanaged_monitors.items():
                    try:
                        api.delete_monitor(monitor['id'])
                        print(f"✓ Deleted monitor: {name}")
                        time.sleep(0.3)
                    except Exception as e:
                        print(f"✗ Failed to delete monitor {name}: {e}")
            else:
                print("Skipped deletion of unmanaged monitors")
        else:
            print("No unmanaged monitors found")


def create_notification_channels(api):
    """Create notification channels (optional)."""
    # Add notification configurations here if desired
    # Example:
    # notifications = [
    #     {
    #         "name": "Slack Alerts",
    #         "type": "slack",
    #         "slackwebhookURL": "YOUR_SLACK_WEBHOOK_URL",
    #         "slackchannel": "#alerts",
    #         "slackusername": "Uptime Kuma"
    #     }
    # ]
    pass


def get_password_from_pass(pass_name):
    """Retrieve password from pass password manager."""
    try:
        result = subprocess.run(['pass', pass_name], capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"✗ Failed to retrieve password from pass: {e}")
        sys.exit(1)
    except FileNotFoundError:
        print("✗ 'pass' command not found. Please install pass or use --password flag instead.")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description='Provision Uptime Kuma monitors')
    parser.add_argument('--url', required=True, help='Uptime Kuma URL (e.g., http://uptime.kcfam.us)')
    parser.add_argument('--username', required=True, help='Admin username')
    
    # Password options - either from pass or direct
    password_group = parser.add_mutually_exclusive_group(required=True)
    password_group.add_argument('--password', help='Admin password (not recommended - use --pass-name instead)')
    password_group.add_argument('--pass-name', help='Password entry name in pass (e.g., uptime-kuma/admin)')
    
    parser.add_argument('--skip-existing', action='store_true', help='Skip monitors that already exist (default behavior)')
    parser.add_argument('--update-existing', action='store_true', help='Update existing monitors with new configuration')
    parser.add_argument('--delete-unmanaged', action='store_true', help='Delete monitors not defined in this script (with confirmation)')
    parser.add_argument('--full-reset', action='store_true', help='Delete ALL existing monitors and recreate fresh (requires double confirmation)')
    
    args = parser.parse_args()
    
    # Get password from pass or use provided password
    if args.pass_name:
        password = get_password_from_pass(args.pass_name)
    else:
        password = args.password
    
    try:
        print(f"Connecting to Uptime Kuma at {args.url}...")
        api = UptimeKumaApi(args.url)
        api.login(args.username, password)
        print("✓ Successfully connected and authenticated")
        
        # Validate conflicting arguments
        if args.full_reset and (args.update_existing or args.delete_unmanaged):
            print("⚠️  Warning: --full-reset overrides --update-existing and --delete-unmanaged flags")
        
        # Create monitors
        create_monitors(api, 
                       update_existing=args.update_existing, 
                       delete_unmanaged=args.delete_unmanaged,
                       full_reset=args.full_reset)
        
        # Optionally create notification channels
        create_notification_channels(api)
        
        print("\n✓ Provisioning completed successfully!")
        print(f"Visit {args.url} to view your monitors")
        
    except Exception as e:
        print(f"✗ Error: {e}")
        sys.exit(1)
    
    finally:
        try:
            api.disconnect()
        except:
            pass


if __name__ == "__main__":
    main()