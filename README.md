# Pterodactyl Panel - Vollautomatisches Installationsskript

Ein vollautomatisches Bash-Skript zur Installation von Pterodactyl Panel auf Debian-Systemen mit Java, allen Dependencies und vollständiger Konfiguration.

## 🚀 Features

- ✅ **Vollautomatisch** - Keine manuelle Eingabe erforderlich
- ✅ **Java Installation** - OpenJDK 17 LTS
- ✅ **System-Updates** - Komplettes System-Upgrade
- ✅ **Pterodactyl Panel** - Neueste Version von GitHub
- ✅ **Wings Daemon** - Für Game-Server Management
- ✅ **NGINX Webserver** - Vollständig konfiguriert
- ✅ **MariaDB Datenbank** - Gesichert und optimiert
- ✅ **Redis Cache** - Für Performance
- ✅ **PHP 8.3** - Mit allen erforderlichen Extensions
- ✅ **Queue Worker** - Automatischer Systemd Service
- ✅ **Firewall** - UFW mit allen notwendigen Ports
- ✅ **Sichere Passwörter** - Automatisch generiert
- ✅ **Farbige Ausgabe** - Übersichtliche Installation
- ✅ **Detailliertes Logging** - Alle Aktionen protokolliert
- ✅ **IP als Domain** - Verwendet Server-IP als Panel-URL

## 📋 Voraussetzungen

- **Betriebssystem**: Debian 11 (Bullseye) oder Debian 12 (Bookworm)
- **Root-Zugriff**: Das Skript muss als Root ausgeführt werden
- **Internetverbindung**: Für Downloads erforderlich
- **Mindestens 2 GB RAM** empfohlen
- **Mindestens 10 GB freier Speicherplatz**

## 🔧 Installation

### Schnellstart

```bash
# Skript herunterladen
wget https://raw.githubusercontent.com/DEIN-REPO/install.sh

# Ausführbar machen
chmod +x install.sh

# Als Root ausführen
sudo ./install.sh
```

### Oder direkt ausführen

```bash
curl -sSL https://raw.githubusercontent.com/DEIN-REPO/install.sh | sudo bash
```

### Lokale Installation

Wenn du das Skript bereits heruntergeladen hast:

```bash
sudo bash install.sh
```

## 📦 Was wird installiert?

### System-Komponenten
- **Java**: OpenJDK 17 LTS (für Minecraft und andere Java-basierte Server)
- **PHP 8.3**: Mit Extensions (cli, gd, mysql, mbstring, bcmath, xml, fpm, curl, zip)
- **MariaDB**: Neueste stabile Version
- **Redis**: Für Caching und Sessions
- **NGINX**: Als Webserver
- **Docker**: Für Container-Management
- **Composer**: PHP Dependency Manager

### Pterodactyl Komponenten
- **Panel**: Neueste Version von GitHub
- **Wings**: Daemon für Server-Management
- **Queue Worker**: Systemd Service für Background-Jobs
- **Cron Jobs**: Für geplante Aufgaben

### Sicherheit
- **UFW Firewall**: Konfiguriert mit Ports 22, 80, 443, 8080, 2022
- **MariaDB Härtung**: Sichere Standardkonfiguration
- **Starke Passwörter**: Automatisch generiert (20 Zeichen)
- **APP_KEY Backup**: Verschlüsselungsschlüssel gesichert

## ⏱️ Installationsdauer

Die Installation dauert je nach Server-Geschwindigkeit und Internetverbindung:
- **Schneller Server**: ~5-8 Minuten
- **Durchschnittlicher Server**: ~10-15 Minuten
- **Langsamer Server**: ~15-20 Minuten

## 📊 Installationsschritte

Das Skript führt folgende Schritte aus:

1. **System-Update** - Paketlisten und System aktualisieren
2. **Dependencies Installation** - PHP, MariaDB, Redis, NGINX, etc.
3. **Java Installation** - OpenJDK 17 LTS
4. **Composer Installation** - PHP Dependency Manager
5. **Datenbank-Setup** - MariaDB sichern und Pterodactyl DB erstellen
6. **Panel Download** - Neueste Version von GitHub
7. **Panel-Konfiguration** - .env Setup, Migrations, Admin-User
8. **NGINX Konfiguration** - Webserver Setup mit PHP-FPM
9. **Queue Worker Setup** - Systemd Service und Cron Jobs
10. **Wings Installation** - Daemon für Server-Management

## 🔐 Nach der Installation

### Zugangsdaten

Nach erfolgreicher Installation findest du alle Zugangsdaten in:

```bash
/root/pterodactyl-credentials.txt
```

**Wichtig**: Diese Datei enthält:
- Panel-URL (http://DEINE-SERVER-IP)
- Admin-Login (admin@localhost / admin)
- Admin-Passwort
- Datenbank-Credentials
- MySQL Root-Passwort

### Erste Schritte

1. **Panel öffnen**: Öffne `http://DEINE-SERVER-IP` im Browser
2. **Einloggen**: Verwende die Credentials aus der Datei
3. **Passwort ändern**: Ändere das Admin-Passwort in den Einstellungen
4. **Wings konfigurieren**: Konfiguriere Wings im Panel unter "Nodes"
5. **Credentials löschen**: Lösche die Credentials-Datei nach dem ersten Login:
   ```bash
   rm /root/pterodactyl-credentials.txt
   ```

### SSL-Zertifikat einrichten (Optional, aber empfohlen)

Für Produktionsumgebungen solltest du ein SSL-Zertifikat einrichten:

```bash
# Certbot installieren
apt install certbot python3-certbot-nginx

# SSL-Zertifikat mit Let's Encrypt erstellen
certbot --nginx -d deine-domain.de
```

**Hinweis**: Du benötigst eine Domain, die auf deinen Server zeigt.

## 📁 Wichtige Dateien und Verzeichnisse

| Pfad | Beschreibung |
|------|--------------|
| `/var/www/pterodactyl` | Panel-Installation |
| `/etc/pterodactyl` | Wings-Konfiguration |
| `/var/log/pterodactyl-install.log` | Installations-Log |
| `/root/pterodactyl-credentials.txt` | Zugangsdaten |
| `/root/pterodactyl-app-key.txt` | APP_KEY Backup |
| `/etc/nginx/sites-available/pterodactyl.conf` | NGINX-Konfiguration |
| `/etc/systemd/system/pteroq.service` | Queue Worker Service |
| `/etc/systemd/system/wings.service` | Wings Service |

## 🔍 Services überprüfen

Nach der Installation sollten folgende Services laufen:

```bash
# Panel Queue Worker
systemctl status pteroq

# Wings Daemon
systemctl status wings

# NGINX Webserver
systemctl status nginx

# MariaDB Datenbank
systemctl status mariadb

# Redis Cache
systemctl status redis-server

# PHP-FPM
systemctl status php8.3-fpm
```

## 🐛 Troubleshooting

### Panel lädt nicht

```bash
# NGINX-Logs prüfen
tail -f /var/log/nginx/pterodactyl.app-error.log

# PHP-FPM-Logs prüfen
tail -f /var/log/php8.3-fpm.log

# NGINX neu starten
systemctl restart nginx php8.3-fpm
```

### Queue Worker läuft nicht

```bash
# Status prüfen
systemctl status pteroq

# Logs anzeigen
journalctl -u pteroq -f

# Neu starten
systemctl restart pteroq
```

### Wings verbindet nicht

```bash
# Wings-Status prüfen
systemctl status wings

# Wings-Logs anzeigen
journalctl -u wings -f

# Wings-Konfiguration prüfen
cat /etc/pterodactyl/config.yml
```

### Datenbank-Probleme

```bash
# MariaDB-Status prüfen
systemctl status mariadb

# In MariaDB einloggen
mysql -u root -p

# Datenbank prüfen
USE panel;
SHOW TABLES;
```

## 📝 Logs

Alle Installationsschritte werden protokolliert:

```bash
# Installations-Log anzeigen
cat /var/log/pterodactyl-install.log

# Log in Echtzeit verfolgen (während Installation)
tail -f /var/log/pterodactyl-install.log
```

## 🔄 Updates

### Panel aktualisieren

```bash
cd /var/www/pterodactyl

# Wartungsmodus aktivieren
php artisan down

# Backup erstellen
cp .env .env.backup

# Neueste Version herunterladen
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz

# Dependencies aktualisieren
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader

# Datenbank migrieren
php artisan migrate --seed --force

# Cache leeren
php artisan view:clear
php artisan config:clear

# Berechtigungen setzen
chown -R www-data:www-data /var/www/pterodactyl/*

# Wartungsmodus deaktivieren
php artisan up

# Queue Worker neu starten
systemctl restart pteroq
```

### Wings aktualisieren

```bash
# Wings stoppen
systemctl stop wings

# Neueste Version herunterladen
curl -L -o /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64
chmod +x /usr/local/bin/wings

# Wings starten
systemctl start wings
```

## 🔒 Sicherheitsempfehlungen

1. **Passwörter ändern**: Ändere alle Standardpasswörter nach dem ersten Login
2. **SSL einrichten**: Verwende HTTPS für Produktionsumgebungen
3. **Firewall prüfen**: Stelle sicher, dass nur notwendige Ports offen sind
4. **Backups**: Richte regelmäßige Backups ein
5. **Updates**: Halte Panel und Wings aktuell
6. **2FA aktivieren**: Aktiviere Zwei-Faktor-Authentifizierung im Panel
7. **Credentials löschen**: Lösche `/root/pterodactyl-credentials.txt` nach dem ersten Login

## 🆘 Support

### Offizielle Ressourcen

- **Pterodactyl Dokumentation**: https://pterodactyl.io/
- **Discord Community**: https://discord.gg/pterodactyl
- **GitHub**: https://github.com/pterodactyl/panel

### Häufige Probleme

**Problem**: "Permission denied" beim Ausführen des Skripts
```bash
# Lösung: Als Root ausführen
sudo bash install.sh
```

**Problem**: Panel zeigt "500 Internal Server Error"
```bash
# Lösung: Berechtigungen prüfen und neu setzen
cd /var/www/pterodactyl
chown -R www-data:www-data *
chmod -R 755 storage bootstrap/cache
```

**Problem**: Wings kann nicht mit Panel kommunizieren
```bash
# Lösung: Firewall-Regeln prüfen
ufw status
ufw allow 8080/tcp
```

## 📜 Lizenz

Dieses Skript ist Open Source. Pterodactyl Panel selbst ist unter der MIT-Lizenz lizenziert.

## ⚠️ Haftungsausschluss

Dieses Skript wird "wie besehen" bereitgestellt. Teste es zuerst auf einem Test-Server, bevor du es in Produktionsumgebungen verwendest. Erstelle immer Backups vor der Installation.

## 🎯 Verbesserungen gegenüber manueller Installation

| Feature | Manuell | Mit Skript |
|---------|---------|------------|
| Installationszeit | ~30-45 Min | ~5-15 Min |
| Fehleranfälligkeit | Hoch | Niedrig |
| Reproduzierbarkeit | Schwierig | Einfach |
| Dokumentation | Manuell | Automatisch |
| Passwort-Sicherheit | Variabel | Stark |
| Logging | Keine | Vollständig |
| Farbige Ausgabe | Nein | Ja |
| Fehlerbehandlung | Manuell | Automatisch |

## 🌟 Danksagungen

- Pterodactyl Team für das großartige Panel
- Debian Team für das stabile Betriebssystem
- Alle Contributors und Community-Mitglieder

---

**Version**: 2.0  
**Letzte Aktualisierung**: 2026  
**Kompatibilität**: Debian 11/12
