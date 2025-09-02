#!/bin/bash
# Setup script for Uptime Kuma monitoring

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Setting up Uptime Kuma monitoring..."

# Install Python dependencies
echo "Installing Python dependencies..."
pip3 install -r "$SCRIPT_DIR/requirements.txt"

# Make the provisioning script executable
chmod +x "$SCRIPT_DIR/provision_uptime_kuma.py"

echo ""
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Start Uptime Kuma: docker compose up -d uptime-kuma"
echo "2. Visit https://uptime.kcfam.us and complete initial setup (create admin user)"
echo "3. Store password in pass and run the provisioning script:"
echo "   pass insert uptime-kuma/admin"
echo "   python3 $SCRIPT_DIR/provision_uptime_kuma.py --url https://uptime.kcfam.us --username admin --pass-name uptime-kuma/admin"
echo ""
echo "   Or use direct password (not recommended):"
echo "   python3 $SCRIPT_DIR/provision_uptime_kuma.py --url https://uptime.kcfam.us --username admin --password YOUR_PASSWORD"
echo ""
echo "The script will create monitors for all services in your docker-compose stack."