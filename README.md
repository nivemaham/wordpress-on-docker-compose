# WordPress protected by Ngnix

This docker-compose stack contains a wordpress installation with mysql as database and protected by nginx. 

## Configuration

### Required
This is the set of minimal configuration required to run the stack.

1. First copy `etc/env.template` file to `./.env` and check and modify all its variables.

   1.1. To have a valid HTTPS connection for a public host, set `SELF_SIGNED_CERT=no`. You need to provide a public valid DNS name as `SERVER_NAME` for SSL certificate to work. IP addresses will not work.
   
## Usage

Run
```shell
bin/radar-docker install
```
to start all the WordPress services. Use the `bin/radar-docker start|down|restart` to start, stop or reboot it. In general, `bin/radar-docker` is a convenience script to `docker-compose`, so all commands that work on docker-compose also work on `bin/radar-docker`. Note: whenever `.env` or `docker-compose.yml` are modified, the `install` command needs to be called again. To start a reduced set of containers, call `bin/radar-docker install` with the intended containers as arguments.

To enable a `systemd` service to control the platform, run
```shell
bin/radar-docker install-systemd
```
After that command, the RADAR platform should be controlled via `systemctl`. When running as a user without `sudo` rights, in the following commands replace `sudo systemctl` with `systemctl --user`.
```shell
# query the latest status and logs
sudo systemctl status radar-docker

# Stop radar-docker
sudo systemctl stop radar-docker

# Restart all containers
sudo systemctl reload radar-docker

# Start radar-docker
sudo systemctl start radar-docker

# Full radar-docker system logs
sudo journalctl -u radar-docker
```
The control scripts in this directory should preferably not be used if `systemctl` is used. To remove `systemctl` integration, run
```
sudo systemctl disable radar-docker
sudo systemctl disable radar-renew-certificate
```

To rebuild an image and restart them, run `bin/radar-docker rebuild IMAGE`. To stop and remove an container, run `bin/radar-docker quit CONTAINER`. 

### Certificate

If systemd integration is enabled, the ssl certificate will be renewed daily. It can then be run directly by running
```
sudo systemctl start radar-renew-certificate.service
```
Otherwise, the following manual commands can be invoked.
If `SELF_SIGNED_CERT=no` in `./.env`, be sure to run `bin/radar-cert-renew` daily to ensure that your certificate does not expire.
