#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."

. lib/util.sh

echo "OS version: $(uname -a)"
check_command_exists docker
check_command_exists docker-compose

# Initialize and check all config files
check_config_present .env etc/env.template
copy_template_if_absent etc/webserver/nginx.conf

# Set permissions
sudo-linux chmod og-rw ./.env
sudo-linux chmod og-rwx ./etc

. ./.env

# Check provided directories and configurations
check_parent_exists WP_MYSQL_DIR ${WP_MYSQL_DIR}
check_parent_exists WORDPRESS_FILE_PATH ${WORDPRESS_FILE_PATH}

# set wordpress location permission
chmod 755 ${WORDPRESS_FILE_PATH}

# Checking provided passwords and environment variables
ensure_env_default SERVER_NAME localhost

ensure_env_password MYSQL_ROOT_PASSWORD "MYSQL root password is not set"
ensure_env_default MYSQL_DATABASE_NAME radarbase
ensure_env_default MYSQL_DATABASE_USERNAME radarbase
ensure_env_password MYSQL_DATABASE_PASSWORD 'MySQL database user ${MYSQL_DATABASE_USERNAME} password not set in .env.'



echo "==> Checking docker external volumes"
if ! sudo-linux docker volume ls -q | grep -q "^certs$"; then
  sudo-linux docker volume create --name=certs --label certs
fi
if ! sudo-linux docker volume ls -q | grep -q "^certs-data$"; then
  sudo-linux docker volume create --name=certs-data --label certs
fi

echo "==> Configuring nginx"
inline_variable 'server_name[[:space:]]*' "${SERVER_NAME};" etc/webserver/nginx.conf
sed_i 's|\(/etc/letsencrypt/live/\)[^/]*\(/.*\.pem\)|\1'"${SERVER_NAME}"'\2|' etc/webserver/nginx.conf
init_certificate "${SERVER_NAME}"



echo "==> Starting RADAR-base Platform"
sudo-linux bin/radar-docker up -d --remove-orphans "$@"

request_certificate "${SERVER_NAME}" "${SELF_SIGNED_CERT:-yes}"
echo "### SUCCESS ###"
