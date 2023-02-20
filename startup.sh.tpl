# this runs on the VM at startup

mkdir -p "$(dirname "${config_path}")"

cat > "${config_path}" << EOF
version: '3.9'

services:
  houston:
    image: datasparq/houston:${houston_version}
    container_name: houston
    command:
      - api
    ports:
      - '8000:80'
    environment:
      HOUSTON_PASSWORD: '${houston_password}'
      HOUSTON_PORT: 80
    network_mode: host
    depends_on:
     - redis
  redis:
    image: redis:${redis_version}
    container_name: redis
    ports:
      - '6379:6379'
    network_mode: host
EOF
