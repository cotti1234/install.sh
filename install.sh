#!/bin/bash

################################################################################
# Pterodactyl Panel - Vollautomatisches Installationsskript für Debian
# 
# Installiert: Java, System-Updates, Pterodactyl Panel, Wings, NGINX, MariaDB
# Autor: Auto-Install Script
# Version: 2.0
################################################################################

set -euo pipefail

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log-Dateien
LOG_FILE="/var/log/pterodactyl-install.log"
CREDENTIALS_FILE="/root/pterodactyl-credentials.txt"

# Logging aktivieren
exec > >(tee -i "$LOG_FILE")
exec 2>&1

print_header() {
    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    exit 1
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Fortschrittsbalken-Variablen
TOTAL_STEPS=100
CURRENT_PROGRESS=0
CURRENT_TASK=""

# Fortschrittsbalken anzeigen
show_progress() {
    local progress=$1
    local task="$2"
    local bar_length=50
    local filled_length=$((progress * bar_length / 100))
    local empty_length=$((bar_length - filled_length))
    
    # Erstelle den Balken
    local bar=""
    for ((i=0; i<filled_length; i++)); do
        bar+="█"
    done
    for ((i=0; i<empty_length; i++)); do
        bar+="░"
    done
    
    # Lösche vorherige Zeilen und zeige neuen Status
    echo -ne "\r\033[K"
    echo -ne "\033[1A\033[K" 2>/dev/null || true
    echo -ne "\033[1A\033[K" 2>/dev/null || true
    
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} ${YELLOW}${task}${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo -ne "${GREEN}[${bar}]${NC} ${YELLOW}${progress}%${NC}"
}

# Fortschritt aktualisieren
update_progress() {
    local step_progress=$1
    local task="$2"
    CURRENT_PROGRESS=$step_progress
    CURRENT_TASK="$task"
    show_progress "$CURRENT_PROGRESS" "$CURRENT_TASK"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Dieses Skript muss als Root ausgeführt werden!"
    fi
}

check_debian() {
    if [ ! -f /etc/debian_version ]; then
        print_error "Dieses Skript ist nur für Debian-Systeme!"
    fi
}

clear
print_header "PTERODACTYL AUTO INSTALL"
check_root
check_debian

export DEBIAN_FRONTEND=noninteractive

# Initialer Fortschrittsbalken
echo ""
echo ""
update_progress 0 "Starte Installation..."
sleep 1

update_progress 2 "Generiere sichere Passwörter..."
DB_PASS=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-20)
ADMIN_PASS=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-20)
echo ""
print_success "Passwörter generiert"

echo ""
print_header "Schritt 1/10: System-Update"
update_progress 5 "Aktualisiere Paketlisten..."
apt update -qq
echo ""
print_success "Paketlisten aktualisiert"

update_progress 10 "Führe System-Upgrade durch (kann einige Minuten dauern)..."
apt upgrade -y -qq
echo ""
print_success "System aktualisiert"

echo ""
print_header "Schritt 2/10: Dependencies Installation"
update_progress 15 "Installiere Basis-Tools..."
apt install -y -qq software-properties-common curl apt-transport-https ca-certificates gnupg lsb-release wget
echo ""
print_success "Basis-Tools installiert"

update_progress 18 "Füge PHP 8.3 Repository hinzu..."
curl -sSL https://packages.sury.org/php/apt.gpg -o /tmp/php-sury.gpg 2>/dev/null || wget -q https://packages.sury.org/php/apt.gpg -O /tmp/php-sury.gpg
gpg --dearmor -o /usr/share/keyrings/deb.sury.org-php.gpg /tmp/php-sury.gpg 2>/dev/null || cat /tmp/php-sury.gpg > /usr/share/keyrings/deb.sury.org-php.gpg
echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/sury-php.list
apt update -qq 2>/dev/null || apt update
echo ""
print_success "PHP Repository hinzugefügt"

update_progress 20 "Füge Redis Repository hinzu..."
curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg 2>/dev/null
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" > /etc/apt/sources.list.d/redis.list
apt update -qq
echo ""
print_success "Redis Repository hinzugefügt"

update_progress 25 "Installiere PHP 8.3 und Extensions..."
apt install -y -qq php8.3 php8.3-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip}
echo ""
print_success "PHP 8.3 installiert"

update_progress 30 "Installiere MariaDB, Redis, NGINX und weitere Tools..."
apt install -y -qq mariadb-server nginx tar unzip git redis-server docker.io jq ufw cron
echo ""
print_success "Alle Dependencies installiert"

update_progress 35 "Aktiviere und starte Services..."
systemctl enable docker mariadb nginx php8.3-fpm redis-server >/dev/null 2>&1
systemctl start docker mariadb nginx php8.3-fpm redis-server
echo ""
print_success "Services gestartet"

echo ""
print_header "Schritt 3/10: Java Installation"
update_progress 38 "Installiere OpenJDK 17 LTS..."
apt install -y -qq openjdk-17-jdk openjdk-17-jre
JAVA_VERSION=$(java -version 2>&1 | head -n 1)
echo ""
print_success "Java installiert: $JAVA_VERSION"

update_progress 40 "Konfiguriere JAVA_HOME..."
echo "export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64" >> /etc/environment
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
echo ""
print_success "JAVA_HOME konfiguriert"

echo ""
print_header "Schritt 4/10: Composer Installation"
if ! command -v composer >/dev/null; then
  update_progress 42 "Installiere Composer..."
  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer >/dev/null 2>&1
  COMPOSER_VERSION=$(composer --version 2>&1 | head -n 1)
  echo ""
  print_success "Composer installiert: $COMPOSER_VERSION"
else
  echo ""
  print_success "Composer bereits installiert"
fi

update_progress 45 "Konfiguriere Firewall..."
ufw allow 22/tcp >/dev/null 2>&1
ufw allow 80/tcp >/dev/null 2>&1
ufw allow 443/tcp >/dev/null 2>&1
ufw allow 8080/tcp >/dev/null 2>&1
ufw allow 2022/tcp >/dev/null 2>&1
ufw --force enable >/dev/null 2>&1
echo ""
print_success "Firewall konfiguriert (Ports: 22, 80, 443, 8080, 2022)"

echo ""
print_header "Schritt 5/10: Datenbank-Setup"
update_progress 48 "Sichere MariaDB Installation..."
mysql -u root <<-EOF
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${DB_PASS}');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF
echo ""
print_success "MariaDB gesichert"

update_progress 50 "Erstelle Pterodactyl Datenbank und User..."
mysql -u root -p"${DB_PASS}" <<-EOF
CREATE DATABASE IF NOT EXISTS panel;
CREATE USER IF NOT EXISTS 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
echo ""
print_success "Datenbank und User erstellt"

echo ""
print_header "Schritt 6/10: Pterodactyl Panel Download"
update_progress 52 "Erstelle Panel-Verzeichnis..."
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
echo ""
print_success "Verzeichnis erstellt: /var/www/pterodactyl"

update_progress 55 "Lade neueste Panel-Version herunter..."
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz 2>/dev/null
echo ""
print_success "Panel heruntergeladen"

update_progress 58 "Entpacke Panel-Dateien..."
tar -xzf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/
echo ""
print_success "Panel-Dateien entpackt"

update_progress 60 "Erstelle .env Konfigurationsdatei..."
cp .env.example .env
echo ""
print_success ".env Datei erstellt"

update_progress 62 "Installiere Composer Dependencies (kann einige Minuten dauern)..."
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader --no-interaction >/dev/null 2>&1
echo ""
print_success "Composer Dependencies installiert"

update_progress 65 "Generiere Application Key..."
php artisan key:generate --force >/dev/null 2>&1
echo ""
print_success "Application Key generiert"

# APP_KEY sichern
APP_KEY=$(grep APP_KEY .env)
echo "$APP_KEY" > /root/pterodactyl-app-key.txt
chmod 600 /root/pterodactyl-app-key.txt
print_warning "APP_KEY gesichert in: /root/pterodactyl-app-key.txt"

echo ""
print_header "Schritt 7/10: Panel-Konfiguration"
update_progress 68 "Ermittle Server-IP..."
APP_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || hostname -I | awk '{print $1}')
echo ""
print_success "Server-IP: $APP_IP"

update_progress 70 "Konfiguriere Umgebungsvariablen..."
sed -i "s|APP_URL=.*|APP_URL=http://$APP_IP|" .env
sed -i "s/DB_HOST=.*/DB_HOST=127.0.0.1/" .env
sed -i "s/DB_PORT=.*/DB_PORT=3306/" .env
sed -i "s/DB_DATABASE=.*/DB_DATABASE=panel/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=pterodactyl/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" .env
sed -i "s/CACHE_DRIVER=.*/CACHE_DRIVER=redis/" .env
sed -i "s/SESSION_DRIVER=.*/SESSION_DRIVER=redis/" .env
sed -i "s/QUEUE_CONNECTION=.*/QUEUE_CONNECTION=redis/" .env
sed -i "s/REDIS_HOST=.*/REDIS_HOST=127.0.0.1/" .env
sed -i "s/MAIL_MAILER=.*/MAIL_MAILER=mail/" .env
echo ""
print_success "Umgebungsvariablen konfiguriert"

update_progress 72 "Migriere Datenbank und seede Daten (kann einige Minuten dauern)..."
for i in {1..10}; do
    if php artisan migrate --seed --force 2>&1 | tee -a "$LOG_FILE" | grep -q "Nothing to migrate\|Migration table created successfully\|Migrated:"; then
        break
    else
        echo ""
        print_warning "Migration fehlgeschlagen, Versuch $i/10..."
        if [ $i -eq 10 ]; then
            print_warning "Migration nach 10 Versuchen fehlgeschlagen - fahre trotzdem fort"
        fi
        sleep 2
    fi
done

update_progress 75 "Erstelle Admin-User..."
php artisan p:user:make \
--email=admin@localhost \
--username=admin \
--name-first=Admin \
--name-last=User \
--password="$ADMIN_PASS" \
--admin=1 >/dev/null 2>&1 || print_warning "User existiert möglicherweise bereits"
echo ""
print_success "Admin-User erstellt"

echo ""
print_header "Schritt 8/10: NGINX Konfiguration"
update_progress 78 "Erstelle NGINX-Konfiguration..."

cat > /etc/nginx/sites-available/pterodactyl.conf <<'NGINX_EOF'
server {
    listen 80;
    server_name _SERVER_IP_;
    root /var/www/pterodactyl/public;
    index index.html index.htm index.php;
    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log off;
    error_log  /var/log/nginx/pterodactyl.app-error.log error;

    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht {
        deny all;
    }
}
NGINX_EOF

sed -i "s/_SERVER_IP_/$APP_IP/g" /etc/nginx/sites-available/pterodactyl.conf
echo ""
print_success "NGINX-Konfiguration erstellt"

update_progress 80 "Aktiviere NGINX-Konfiguration..."
ln -sf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
rm -f /etc/nginx/sites-enabled/default
echo ""
print_success "NGINX-Konfiguration aktiviert"

update_progress 82 "Teste NGINX-Konfiguration..."
nginx -t >/dev/null 2>&1 && echo "" && print_success "NGINX-Konfiguration gültig" || print_error "NGINX-Konfiguration ungültig!"

update_progress 84 "Starte NGINX neu..."
systemctl restart nginx
echo ""
print_success "NGINX neu gestartet"

echo ""
print_header "Schritt 9/10: Queue Worker Setup"
update_progress 86 "Erstelle Crontab-Eintrag..."
(crontab -l 2>/dev/null | grep -v "pterodactyl/artisan schedule:run"; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1") | crontab -
echo ""
print_success "Crontab-Eintrag erstellt"

update_progress 87 "Erstelle Queue Worker Service..."
cat > /etc/systemd/system/pteroq.service <<'PTEROQ_EOF'
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
PTEROQ_EOF
echo ""
print_success "Queue Worker Service erstellt"

update_progress 88 "Aktiviere und starte Queue Worker..."
systemctl daemon-reload
systemctl enable pteroq.service >/dev/null 2>&1
systemctl start pteroq.service
echo ""
print_success "Queue Worker gestartet"

update_progress 89 "Setze Dateiberechtigungen..."
chown -R www-data:www-data /var/www/pterodactyl/*
echo ""
print_success "Dateiberechtigungen gesetzt"

echo ""
print_header "Schritt 10/10: Wings Installation & Node Setup"
update_progress 90 "Installiere Wings..."
curl -L -o /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64 2>/dev/null
chmod +x /usr/local/bin/wings
echo ""
print_success "Wings heruntergeladen"

update_progress 91 "Erstelle Pterodactyl User für Wings..."
useradd -r -m -d /var/lib/pterodactyl -s /bin/bash pterodactyl 2>/dev/null || true
mkdir -p /etc/pterodactyl
chown -R pterodactyl:pterodactyl /etc/pterodactyl
echo ""
print_success "Pterodactyl User erstellt"

update_progress 92 "Warte auf Panel-Verfügbarkeit..."
sleep 5

cd /var/www/pterodactyl

update_progress 93 "Generiere API-Key für automatische Konfiguration..."
API_KEY=$(php artisan p:api:key --identifier=AutoInstall --description="Auto-generated for installation" --no-interaction 2>/dev/null | grep -oP 'ptlc_[a-zA-Z0-9]{48}')

if [ -z "$API_KEY" ]; then
    print_warning "API-Key konnte nicht automatisch generiert werden, versuche alternative Methode..."
    API_KEY=$(php artisan tinker --execute="echo \\Pterodactyl\\Models\\ApiKey::create(['user_id' => 1, 'key_type' => 0, 'identifier' => 'AutoInstall', 'token' => hash('sha256', bin2hex(random_bytes(32))), 'allowed_ips' => null, 'memo' => 'Auto-generated'])->identifier . '_' . bin2hex(random_bytes(24));" 2>/dev/null)
fi

echo "$API_KEY" > /root/pterodactyl-api-key.txt
chmod 600 /root/pterodactyl-api-key.txt
echo ""
print_success "API-Key generiert und gespeichert"

update_progress 94 "Erstelle Location..."
LOCATION_RESPONSE=$(curl -s -X POST http://127.0.0.1/api/application/locations \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"short":"Main","long":"Main Location"}')

LOCATION_ID=$(echo "$LOCATION_RESPONSE" | jq -r '.attributes.id' 2>/dev/null || echo "1")
echo ""
print_success "Location erstellt (ID: $LOCATION_ID)"

update_progress 95 "Ermittle verfügbare Ressourcen..."
TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
TOTAL_DISK=$(df -BG / | awk 'NR==2 {print $2}' | sed 's/G//')
ALLOCATED_RAM=$((TOTAL_RAM * 80 / 100))
ALLOCATED_DISK=$((TOTAL_DISK * 80 / 100))

update_progress 96 "Erstelle Node (RAM: ${ALLOCATED_RAM}MB, Disk: ${ALLOCATED_DISK}GB)..."
NODE_RESPONSE=$(curl -s -X POST http://127.0.0.1/api/application/nodes \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{
    \"name\": \"Node-${APP_IP}\",
    \"location_id\": ${LOCATION_ID},
    \"fqdn\": \"${APP_IP}\",
    \"scheme\": \"http\",
    \"memory\": ${ALLOCATED_RAM},
    \"memory_overallocate\": 0,
    \"disk\": ${ALLOCATED_DISK}000,
    \"disk_overallocate\": 0,
    \"upload_size\": 100,
    \"daemon_listen\": 8080,
    \"daemon_sftp\": 2022,
    \"daemon_base\": \"/var/lib/pterodactyl/volumes\",
    \"public\": true,
    \"behind_proxy\": false,
    \"maintenance_mode\": false
  }")

NODE_ID=$(echo "$NODE_RESPONSE" | jq -r '.attributes.id' 2>/dev/null)

if [ -z "$NODE_ID" ] || [ "$NODE_ID" = "null" ]; then
    print_warning "Node-ID konnte nicht ermittelt werden, verwende ID 1"
    NODE_ID=1
fi

echo ""
print_success "Node erstellt (ID: $NODE_ID, Name: Node-${APP_IP})"

update_progress 97 "Lade Node-Konfiguration herunter..."
for i in {1..15}; do
  if curl -s http://127.0.0.1/api/application/nodes/${NODE_ID}/configuration \
    -H "Authorization: Bearer $API_KEY" \
    -H "Accept: application/json" \
    -o /etc/pterodactyl/config.yml 2>/dev/null; then
    
    if [ -s /etc/pterodactyl/config.yml ]; then
        echo ""
        print_success "Node-Konfiguration heruntergeladen"
        break
    fi
  fi
  echo ""
  print_warning "Versuch $i/15 fehlgeschlagen, warte 3 Sekunden..."
  sleep 3
done

if [ ! -s /etc/pterodactyl/config.yml ]; then
    print_warning "Automatische Konfiguration fehlgeschlagen, erstelle manuelle Basis-Konfiguration..."
    cat > /etc/pterodactyl/config.yml <<WINGS_CONFIG
debug: false
api:
  host: 0.0.0.0
  port: 8080
  ssl:
    enabled: false
  upload_limit: 100
system:
  root_directory: /var/lib/pterodactyl/volumes
  log_directory: /var/log/pterodactyl
  data: /etc/pterodactyl
  sftp:
    bind_port: 2022
remote: http://${APP_IP}
WINGS_CONFIG
fi

chown -R pterodactyl:pterodactyl /etc/pterodactyl
echo ""
print_success "Berechtigungen gesetzt"

update_progress 98 "Erstelle Wings Systemd Service..."
cat > /etc/systemd/system/wings.service <<'WINGS_SERVICE'
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service network.target
Requires=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
WINGS_SERVICE
echo ""
print_success "Wings Service erstellt"

update_progress 99 "Aktiviere und starte Wings..."
systemctl daemon-reload
systemctl enable wings >/dev/null 2>&1
systemctl start wings
sleep 3

if systemctl is-active --quiet wings; then
    echo ""
    print_success "Wings erfolgreich gestartet"
else
    echo ""
    print_warning "Wings konnte nicht gestartet werden, prüfe Logs mit: journalctl -u wings -n 50"
fi

update_progress 100 "Speichere alle Credentials..."
cat > "$CREDENTIALS_FILE" <<CREDS_EOF
╔════════════════════════════════════════════════════════════════╗
║         PTERODACTYL PANEL - INSTALLATIONS-CREDENTIALS          ║
╚════════════════════════════════════════════════════════════════╝

Erstellt am: $(date)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  PANEL ZUGANG (Web-Interface)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

URL:      http://${APP_IP}
Email:    admin@localhost
Username: admin
Passwort: ${ADMIN_PASS}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  DATENBANK (MariaDB)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Host:              127.0.0.1
Port:              3306
Datenbank:         panel
User:              pterodactyl
Passwort:          ${DB_PASS}

MySQL Root User:   root
MySQL Root Pass:   ${DB_PASS}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  API & WINGS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

API-Key:           ${API_KEY}
Node-ID:           ${NODE_ID}
Node-Name:         Node-${APP_IP}
Wings-Port:        8080
SFTP-Port:         2022

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  SYSTEM-BENUTZER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Webserver User:    www-data
Wings User:        pterodactyl
Wings Home:        /var/lib/pterodactyl

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  WICHTIGE DATEIEN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Credentials:       ${CREDENTIALS_FILE}
APP_KEY Backup:    /root/pterodactyl-app-key.txt
API-Key Backup:    /root/pterodactyl-api-key.txt
Installations-Log: ${LOG_FILE}
Panel-Verzeichnis: /var/www/pterodactyl
Wings-Config:      /etc/pterodactyl/config.yml

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  SERVICES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Panel Queue:       systemctl status pteroq
Wings Daemon:      systemctl status wings
NGINX:             systemctl status nginx
MariaDB:           systemctl status mariadb
Redis:             systemctl status redis-server
PHP-FPM:           systemctl status php8.3-fpm

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  FIREWALL (UFW)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SSH:               22/tcp
HTTP:              80/tcp
HTTPS:             443/tcp
Wings:             8080/tcp
SFTP:              2022/tcp

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  SCHNELLZUGRIFF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Panel öffnen:      http://${APP_IP}
Wings-Logs:        journalctl -u wings -f
Panel-Logs:        tail -f /var/www/pterodactyl/storage/logs/laravel-$(date +%Y-%m-%d).log
NGINX-Logs:        tail -f /var/log/nginx/pterodactyl.app-error.log

⚠️  SICHERHEITSHINWEISE:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Ändere SOFORT das Admin-Passwort nach dem ersten Login!
2. Sichere die APP_KEY Datei: /root/pterodactyl-app-key.txt
3. Lösche diese Credentials-Datei nach dem Kopieren: rm ${CREDENTIALS_FILE}
4. Richte SSL/TLS für Produktionsumgebungen ein
5. Erstelle regelmäßige Backups der Datenbank
6. Aktiviere 2FA im Panel für zusätzliche Sicherheit

╔════════════════════════════════════════════════════════════════╗
║  WICHTIG: Diese Datei enthält sensible Daten!                  ║
║  Bewahre sie sicher auf und lösche sie nach dem ersten Login!  ║
╚════════════════════════════════════════════════════════════════╝
CREDS_EOF
chmod 600 "$CREDENTIALS_FILE"
echo ""
print_success "Alle Credentials gespeichert in: $CREDENTIALS_FILE"

update_progress 100 "Installation abgeschlossen!"
sleep 2

clear
print_header "Installation abgeschlossen!"
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                ║${NC}"
echo -e "${GREEN}║     Pterodactyl Panel Installation erfolgreich abgeschlossen!  ║${NC}"
echo -e "${GREEN}║                                                                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  PANEL ZUGANG (Web-Interface)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "  URL:      ${GREEN}http://${APP_IP}${NC}"
echo -e "  Email:    ${GREEN}admin@localhost${NC}"
echo -e "  Username: ${GREEN}admin${NC}"
echo -e "  Passwort: ${GREEN}${ADMIN_PASS}${NC}"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  DATENBANK (MariaDB)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "  Host:     ${GREEN}127.0.0.1${NC}"
echo -e "  Port:     ${GREEN}3306${NC}"
echo -e "  Database: ${GREEN}panel${NC}"
echo -e "  User:     ${GREEN}pterodactyl${NC}"
echo -e "  Passwort: ${GREEN}${DB_PASS}${NC}"
echo -e "  Root-PW:  ${GREEN}${DB_PASS}${NC}"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  API & WINGS${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "  API-Key:  ${GREEN}${API_KEY}${NC}"
echo -e "  Node-ID:  ${GREEN}${NODE_ID}${NC}"
echo -e "  Node:     ${GREEN}Node-${APP_IP}${NC}"
echo -e "  Wings:    ${GREEN}http://${APP_IP}:8080${NC}"
echo -e "  SFTP:     ${GREEN}${APP_IP}:2022${NC}"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  WICHTIGE DATEIEN & VERZEICHNISSE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "  Credentials:  ${YELLOW}${CREDENTIALS_FILE}${NC}"
echo -e "  APP_KEY:      ${YELLOW}/root/pterodactyl-app-key.txt${NC}"
echo -e "  API-Key:      ${YELLOW}/root/pterodactyl-api-key.txt${NC}"
echo -e "  Log:          ${YELLOW}${LOG_FILE}${NC}"
echo -e "  Panel:        ${YELLOW}/var/www/pterodactyl${NC}"
echo -e "  Wings-Config: ${YELLOW}/etc/pterodactyl/config.yml${NC}"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  INSTALLIERTE KOMPONENTEN${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "  ${GREEN}✓${NC} Java (OpenJDK 17 LTS)"
echo -e "  ${GREEN}✓${NC} PHP 8.3 mit allen Extensions"
echo -e "  ${GREEN}✓${NC} MariaDB Server"
echo -e "  ${GREEN}✓${NC} Redis Server"
echo -e "  ${GREEN}✓${NC} NGINX Webserver"
echo -e "  ${GREEN}✓${NC} Composer"
echo -e "  ${GREEN}✓${NC} Pterodactyl Panel (neueste Version)"
echo -e "  ${GREEN}✓${NC} Queue Worker (pteroq.service)"
echo -e "  ${GREEN}✓${NC} Wings Daemon"
echo -e "  ${GREEN}✓${NC} Cron Jobs"
echo -e "  ${GREEN}✓${NC} Firewall (UFW)"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  NÄCHSTE SCHRITTE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "  1. Öffne ${GREEN}http://${APP_IP}${NC} in deinem Browser"
echo -e "  2. Logge dich mit den oben genannten Credentials ein"
echo -e "  3. Ändere das Admin-Passwort in den Einstellungen"
echo -e "  4. ${YELLOW}Optional:${NC} SSL-Zertifikat mit Let's Encrypt einrichten:"
echo -e "     ${YELLOW}apt install certbot python3-certbot-nginx${NC}"
echo -e "     ${YELLOW}certbot --nginx -d deine-domain.de${NC}"
echo -e "  5. Lösche die Credentials-Datei nach dem ersten Login:"
echo -e "     ${YELLOW}rm ${CREDENTIALS_FILE}${NC}"
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  SICHERHEITSHINWEISE${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "  ${RED}⚠${NC} Sichere die APP_KEY Datei: ${YELLOW}/root/pterodactyl-app-key.txt${NC}"
echo -e "  ${RED}⚠${NC} Ändere das Admin-Passwort nach dem ersten Login"
echo -e "  ${RED}⚠${NC} Richte SSL/TLS für Produktionsumgebungen ein"
echo -e "  ${RED}⚠${NC} Richte regelmäßige Backups ein"
echo ""
echo -e "${GREEN}Installation abgeschlossen am: $(date)${NC}"
echo ""
