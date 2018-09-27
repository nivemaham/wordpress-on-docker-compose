cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo $(pwd)
. lib/util.sh
. .env

if id -Gn | grep -qe '\<sudo\>'; then
  BASE=/etc/systemd/system
  SYSTEMCTL_OPTS=()
else
  BASE=$HOME/.config/systemd/user
  mkdir -p $BASE
  SYSTEMCTL_OPTS=(--user)
  export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$UID}
fi

echo "==> Copying templates"
copy_template_if_absent $BASE/radar-docker.service lib/systemd/radar-docker.service.template
copy_template_if_absent $BASE/radar-renew-certificate.service lib/systemd/radar-renew-certificate.service.template
copy_template_if_absent $BASE/radar-renew-certificate.timer lib/systemd/radar-renew-certificate.timer.template

echo "==> Inlining variables"
inline_variable 'WorkingDirectory=' "$PWD" $BASE/radar-docker.service
inline_variable 'ExecStart=' "$PWD/bin/radar-docker foreground" $BASE/radar-docker.service

inline_variable 'WorkingDirectory=' "$DIR" $BASE/radar-renew-certificate.service
inline_variable 'ExecStart=' "$PWD/bin/radar-docker cert-renew" $BASE/radar-renew-certificate.service

echo "==> Reloading systemd"
systemctl "${SYSTEMCTL_OPTS[@]}" daemon-reload
systemctl "${SYSTEMCTL_OPTS[@]}" enable radar-docker
systemctl "${SYSTEMCTL_OPTS[@]}" enable radar-renew-certificate.timer
systemctl "${SYSTEMCTL_OPTS[@]}" start radar-docker
systemctl "${SYSTEMCTL_OPTS[@]}" start radar-renew-certificate.timer