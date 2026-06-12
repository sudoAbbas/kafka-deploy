# Kafka 4.x Manual Deployment Guide (2 Broker KRaft Cluster)

## Purpose

This guide intentionally avoids:

* Packer
* AMI baking
* Systemd services
* Auto Scaling Groups
* Startup automation

The goal is to manually deploy Kafka so that every future automation step makes sense.

---

## Architecture

```text
+-------------------+         +-------------------+
| Broker 1          |         | Broker 2          |
| EC2 Instance      | <-----> | EC2 Instance      |
| Kafka Broker      |         | Kafka Broker      |
| KRaft Controller  |         | KRaft Controller  |
+-------------------+         +-------------------+

        EBS Volume                   EBS Volume
           |                             |
           v                             v
       /data/kafka                  /data/kafka
```

> This is a learning setup only.
>
> A two-node KRaft cluster is not considered production-ready because it lacks an odd-numbered controller quorum.

---

## EC2 Prerequisites

Create two EC2 instances.

### Broker 1

```text
Hostname: kafka-1
OS: Amazon Linux 2023
Instance Type: t3.small
Root Volume: 50GB
Additional EBS Volume: 5GB gp3
```

### Broker 2

```text
Hostname: broker2
OS: Amazon Linux 2023
Instance Type: t3.small
Root Volume: 50GB
Additional EBS Volume: 5GB gp3
```

Record the private IPs.

Example:

```text
Broker1: 10.0.1.10
Broker2: 10.0.1.11
```

---

## Step 1 - Verify EBS Volumes

SSH into Broker1:

```bash
ssh ec2-user@broker1
```

Check disks:

```bash
lsblk
```

Example:

```text
nvme0n1   50G
nvme1n1   5G
```

The second disk is the Kafka EBS volume.

Repeat on Broker2.

---

## Step 2 - Format the EBS Volume

Create an XFS filesystem.

Broker1:

```bash
sudo mkfs.xfs /dev/nvme1n1
```

Broker2:

```bash
sudo mkfs.xfs /dev/nvme1n1
```

Verify:

```bash
sudo blkid
```

Example:

```text
/dev/nvme1n1:
UUID="1234-abcd"
TYPE="xfs"
```

---

## Step 3 - Create Mount Point

Broker1:

```bash
sudo mkdir -p /data
```

Broker2:

```bash
sudo mkdir -p /data
```

---

## Step 4 - Mount EBS

Broker1:

```bash
sudo mount /dev/nvme1n1 /data
```

Broker2:

```bash
sudo mount /dev/nvme1n1 /data
```

Verify:

```bash
df -h
```

Expected:

```text
/dev/nvme1n1 ... /data
```

---

## Step 5 - Configure Automatic Mounting

Find UUID:

```bash
sudo blkid
```

Edit:

```bash
sudo vi /etc/fstab
```

Add:

```text
UUID=<your-uuid> /data xfs defaults,nofail 0 2
```

Test:

```bash
sudo mount -a
```

No output means success.

Repeat on Broker2.

---

## Step 6 - Install Java

Install Java 21.

```bash
sudo dnf install java-21-amazon-corretto -y
```

Verify:

```bash
java -version
```

Expected:

```text
openjdk version "21"
```

Repeat on Broker2.

---

## Step 7 - Create Kafka User

Broker1:

```bash
sudo useradd -r -m -s /bin/bash kafka
```

Broker2:

```bash
sudo useradd -r -m -s /bin/bash kafka
```

Verify:

```bash
id kafka
```

---

## Step 8 - Download Kafka

Download Kafka:

```bash
cd /tmp

curl -O https://archive.apache.org/dist/kafka/4.3.0/kafka_2.13-4.3.0.tgz
```

Create installation directory:

```bash
sudo mkdir -p /opt/kafka
```

Extract:

```bash
sudo tar -xzf kafka_2.13-4.3.0.tgz \
  -C /opt/kafka \
  --strip-components=1
```

Repeat on Broker2.

---

## Step 9 - Create Kafka Data Directories

Broker1:

```bash
sudo mkdir -p /data/kafka
```

Broker2:

```bash
sudo mkdir -p /data/kafka
```

Set ownership:

```bash
sudo chown -R kafka:kafka /opt/kafka
sudo chown -R kafka:kafka /data/kafka
```

Repeat on Broker2.

---

## Step 10 - Generate Cluster ID

Run only once.

```bash
/opt/kafka/bin/kafka-storage.sh random-uuid
```

Example:

```text
N7v6s0RZQ1iJ0CwGz0WwJQ
```

Save this value.

Both brokers will use the same cluster ID.

---

## Step 11 - Configure Broker 1

Create configuration:

```bash
sudo vi /opt/kafka/config/server.properties
```

Contents:

```properties
process.roles=broker,controller

node.id=1

controller.quorum.voters=1@kafka-1.kafka.internal:9093,2@kafka-2.kafka.internal:9093

listeners=PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:9093

advertised.listeners=PLAINTEXT://kafka-1.kafka.internal:9092

listener.security.protocol.map=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT

inter.broker.listener.name=PLAINTEXT

controller.listener.names=CONTROLLER

log.dirs=/data/kafka

num.partitions=3

default.replication.factor=2

offsets.topic.replication.factor=2

transaction.state.log.replication.factor=2

transaction.state.log.min.isr=1
```



---

## Step 12 - Configure Broker 2

Create configuration:

```bash
sudo vi /opt/kafka/config/kraft/server.properties
```

Contents:

```properties
process.roles=broker,controller

node.id=2

controller.quorum.voters=1@kafka-1.kafka.internal:9093,2@kafka-2.kafka.internal:9093

listeners=PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:9093

advertised.listeners=PLAINTEXT://kafka-2.kafka.internal:9092

listener.security.protocol.map=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT

inter.broker.listener.name=PLAINTEXT

controller.listener.names=CONTROLLER

log.dirs=/data/kafka

num.partitions=3

default.replication.factor=2

offsets.topic.replication.factor=2

transaction.state.log.replication.factor=2

transaction.state.log.min.isr=1
```

---

## Step 13 - Format Kafka Storage

Broker1:

```bash
sudo -u kafka \
/opt/kafka/bin/kafka-storage.sh format \
-t <cluster-id> \
-c /opt/kafka/config/server.properties
```

Broker2:

```bash
sudo -u kafka \
/opt/kafka/bin/kafka-storage.sh format \
-t <cluster-id> \
-c /opt/kafka/config/kraft/server.properties
```

Replace `<cluster-id>` with the UUID generated earlier.

---

## Step 14 - Start Broker 1
Will create a service file so that kafka is running in the background
```bash
sudo vi /etc/systemd/system/kafka.service
```
And then paste in the following

```service
[Unit]
Description=Apache Kafka (KRaft)
Documentation=https://kafka.apache.org/
After=network-online.target
Wants=network-online.target

[Service]
Type=simple

User=kafka
Group=kafka

Environment="KAFKA_HEAP_OPTS=-Xms1G -Xmx1G"

ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
ExecStop=/opt/kafka/bin/kafka-server-stop.sh

Restart=on-failure
RestartSec=10

LimitNOFILE=100000

SuccessExitStatus=143

[Install]
WantedBy=multi-user.target
```
Make sure kafka owns the installation

```bash
sudo chown -R kafka:kafka /opt/kafka
```
Then enable it to restart and run by running following command
```bash
sudo systemctl daemon-reload
sudo systemctl enable kafka
sudo systemctl start kafka
```
Can check status by
```bash
sudo systemctl status kafka
```
To watch logs can run the following commands
```bash
sudo journalctl -u kafka -f
sudo journalctl -u kafka -n 100 # view recent logs
```
---

## Step 15 - Start Broker 2

Do the same for other broker
---

## Step 16 - Verify Cluster

Run:

```bash
/opt/kafka/bin/kafka-metadata-quorum.sh \
--bootstrap-server localhost:9092 \
describe --status
```

Expected:

```text
ClusterId: ...
LeaderId: ...
CurrentVoters:
1
2
```

---

## Step 17 - Create Topic

```bash
/opt/kafka/bin/kafka-topics.sh \
--bootstrap-server localhost:9092 \
--create \
--topic orders \
--partitions 3 \
--replication-factor 2
```

Verify:

```bash
/opt/kafka/bin/kafka-topics.sh \
--bootstrap-server localhost:9092 \
--describe \
--topic orders
```

Expected:

```text
PartitionCount:3
ReplicationFactor:2
```

---

## Step 18 - Produce Messages

Start producer:

```bash
/opt/kafka/bin/kafka-console-producer.sh \
--bootstrap-server localhost:9092 \
--topic orders
```

Send:

```text
order1
order2
order3
```

---

## Step 19 - Consume Messages

On Broker2:

```bash
/opt/kafka/bin/kafka-console-consumer.sh \
--bootstrap-server localhost:9092 \
--topic orders \
--from-beginning
```

Expected:

```text
order1
order2
order3
```

---

## Step 20 - Verify Data Is Stored On EBS

Check:

```bash
ls /data/kafka
```

Expected:

```text
orders-0
orders-1
orders-2
```

Kafka topic data is now stored on EBS.

---

## Step 21 - Reboot Test

Reboot:

```bash
sudo reboot
```

Reconnect and verify:

```bash
df -h
```

Expected:

```text
/data mounted
```

If not:

```text
Check /etc/fstab
```

---

## Step 22 - Broker Failure Test

Stop Broker2.

Produce messages on Broker1.

Observe how the cluster behaves when one broker is unavailable.

This helps demonstrate replication and fault tolerance behaviour.

---

## What This Teaches

By completing this guide you will understand:

1. Why Kafka requires durable storage.
2. Why EBS is used.
3. Why filesystems must be created.
4. Why volumes must be mounted.
5. Why `/etc/fstab` exists.
6. Why Kafka needs `log.dirs`.
7. Why KRaft storage must be formatted.
8. Why advertised listeners are required.
9. Why controller quorum exists.
10. Why startup automation exists.

After completing this guide, the purpose of:

* attach-ebs.sh
* init-kafka.sh
* kafka.service
* attach-ebs.service
* Packer
* AMIs

will become much easier to understand because each one simply automates a manual step from this document.
