# RADAR platform

This docker-compose stack contains the full operational RADAR platform. Once configured, it is meant to run on a single server with at least 16 GB memory and 4 CPU cores. It is tested on Ubuntu 16.04 and on macOS 11.1 with Docker 17.06.

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
to start all the RADAR services. Use the `bin/radar-docker start|down|restart` to start, stop or reboot it. In general, `bin/radar-docker` is a convenience script to `docker-compose`, so all commands that work on docker-compose also work on `bin/radar-docker`. Note: whenever `.env` or `docker-compose.yml` are modified, the `install` command needs to be called again. To start a reduced set of containers, call `bin/radar-docker install` with the intended containers as arguments.

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
sudo systemctl disable radar-output
sudo systemctl disable radar-check-health
sudo systemctl disable radar-renew-certificate
```

To clear all data from the platform, run
```
sudo systemctl stop radar-docker
bin/docker-prune
sudo systemctl start radar-docker
```

To rebuild an image and restart them, run `bin/radar-docker rebuild IMAGE`. To stop and remove an container, run `bin/radar-docker quit CONTAINER`. To start the HDFS cluster, run `bin/radar-docker hdfs`. For a health check, run `bin/radar-docker health`.

### Monitoring a topic

To see current data coming out of a Kafka topic, run
```script
bin/radar-kafka-consumer TOPIC
```

### Postgres Data Migration
If a major Postgres version upgrade is planned, existing data need to be migrated to the new version. To do so run `bin/postgres-upgrade NEW_VERSION`

### Data extraction

If systemd integration is enabled, HDFS data will be extracted to the `./output` directory every hour. It can then be run directly by running
```
sudo systemctl start radar-output.service
```
Otherwise, the following manual commands can be invoked.

Raw data can be extracted from this setup by running:

```shell
bin/hdfs-extract <hdfs file> <destination directory>
```
This command will not overwrite data in the destination directory.

CSV-structured data can be gotten from HDFS by running

```shell
bin/hdfs-restructure /topicAndroidNew <destination directory>
```
This will put all CSV files in the destination directory, with subdirectory structure `ProjectId/SubjectId/SensorType/Date_Hour.csv`.

### Certificate

If systemd integration is enabled, the ssl certificate will be renewed daily. It can then be run directly by running
```
sudo systemctl start radar-renew-certificate.service
```
Otherwise, the following manual commands can be invoked.
If `SELF_SIGNED_CERT=no` in `./.env`, be sure to run `bin/radar-cert-renew` daily to ensure that your certificate does not expire.


### cAdvisor

cAdvisor (Container Advisor) provides container users an understanding of the resource usage and performance characteristics of their running containers.

To view current resource performance,if running locally, try <http://localhost:8080>. This will bring up the built-in Web UI. Clicking on `/docker` in `Subcontainers` takes you to a new window with all of the Docker containers listed individually.

### Portainer

Portainer provides simple interactive UI-based docker management. If running locally, try <http://localhost/portainer/> for portainer's UI. To set-up portainer follow this [link](https://www.ostechnix.com/portainer-an-easiest-way-to-manage-docker/).

### Kafka Manager

The [kafka-manager](https://github.com/yahoo/kafka-manager) is an interactive web based tool for managing Apache Kafka. Kafka manager has beed integrated in the stack. It is accessible at `http://<your-host>/kafkamanager/`

### Check Health
Each of the containers in the stack monitor their own health and show the output as healthy or unhealthy. A script called `bin/radar-docker health` is used to check this output and send an email to the maintainer if a container is unhealthy.

First check that the `MAINTAINER_EMAIL` in the .env file is correct.

Then make sure that the SMTP server is configured properly and running.

If systemd integration is enabled, the `bin/radar-docker health` script will check health of containers every five minutes. It can then be run directly by running if systemd wrappers have been installed
```
sudo systemctl start radar-check-health.service
```
Otherwise, the following manual commands can be invoked.

Add a cron job to run the `bin/radar-docker health` script periodically like -
1. Edit the crontab file for the current user by typing `$ crontab -e`
2. Add your job and time interval. For example, add the following for checking health every 5 mins -

```
*/5 * * * * /home/ubuntu/RADAR-Docker/dcompose-stack/radar-cp-hadoop-stack/bin/radar-docker health
```

You can check the logs of CRON by typing `grep CRON /var/log/syslog`.

### HDFS

This folder contains useful scripts to manage the extraction of data from HDFS in the RADAR-base Platform.

- `bin/hdfs-upgrade VERSION`
  - Perform an upgrade from an older version of the [Smizy HDFS base image](https://hub.docker.com/r/smizy/hadoop-base/) to a newer one. E.g. from `2.7.6-alpine`, which is compatible with the `uhopper` image, to `3.0.3-alpine`.
- `bin/hdfs-restructure`
  - This script uses the Restructure-HDFS-topic to extracts records from HDFS and converts them from AVRO to specified format
  - By default, the format is CSV, compression is set to gzip and deduplication is enabled.
  - To change configurations and for more info look at the [README here](https://github.com/RADAR-base/Restructure-HDFS-topic)

- `bin/hdfs-restructure-process` for running the above script in a controlled manner with rotating logs
  - `logfile` is the log file where the script logs each operation
  - `storage_directory` is the directory where the extracted data will be stored
  - `lockfile` lock useful to check whether there is a previous instance still running

- A systemd timer for this script can be installed by running the `bin/radar-docker install-systemd`. Or you can add a cron job like below.

To add a script to `CRON` as `root`, run on the command-line `sudo crontab -e -u root` and add your task at the end of the file. The syntax is
```shell
*     *     *     *     *  command to be executed
-     -     -     -     -
|     |     |     |     |
|     |     |     |     +----- day of week (0 - 6) (Sunday=0)
|     |     |     +------- month (1 - 12)
|     |     +--------- day of month (1 - 31)
|     +----------- hour (0 - 23)
+------------- min (0 - 59)
```

For example, `*/2 * * * * /absolute/path/to/script-name.sh` will execute `script-name.sh` every `2` minutes.
