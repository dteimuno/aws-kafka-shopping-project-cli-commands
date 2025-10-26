## Simulating A Real-Time Event-Driven Python Shopping App with Kafka on AWS For Real-Time Processing.


````markdown
 Kafka Toy Shop & Warehouse Project

Overview

This project simulates a simple event-driven e-commerce flow using Apache Kafka:

- toy-shop: A Python Flask app that acts like a "shop service." It produces events (for example, new cart or order events) into a Kafka topic.
- warehouse-ui: A Python Flask app that acts like a "warehouse dashboard / consumer service." It reads events from Kafka and exposes them via an HTTP endpoint / UI.
- Kafka broker: A self-managed Kafka 3.0.0 instance (no Docker) running directly on an Ubuntu server in **KRaft mode** (no ZooKeeper).
- tmux: Used to keep Kafka, the shop producer, and the warehouse consumer all running in separate terminal sessions on the same EC2 box.

This repo documents exactly how to bring all of that up on a fresh Ubuntu host.

---

Architecture

1. toy-shop service
   - Python 3 / Flask
   - Uses a Kafka producer to publish messages to a Kafka topic.
   - Talks to Kafka at `localhost:9092`.
   - Runs on port `5000`.

2. warehouse-ui service
   - Python 3 / Flask
   - Uses a Kafka consumer to read new messages from the same Kafka topic.
   - Exposes warehouse-facing data so you can inspect what the producer sent.
   - Runs on port `5003`.

3. **Kafka**
   - Apache Kafka `3.0.0` (binary tarball `kafka_2.13-3.0.0.tgz`)
   - Runs in KRaft mode using `server.properties` under `config/kraft/`
   - Java runtime is Amazon Corretto 8
   - Listens on `localhost:9092`

4. tmux
   - Each long-running process (Kafka broker, toy-shop app, warehouse-ui app) runs in its own tmux session
   - You can detach with `CTRL+b` then `d` and leave it running in the background

---

Prerequisites

- Ubuntu (tested on an EC2-style Ubuntu host)
- `sudo` access
- Python 3.12 with `venv` module
- `tmux`
- Internet access to download Kafka and dependencies

---

1. Install Java (Amazon Corretto 8)

Kafka 3.0.0 needs a JVM. We install Corretto 8 from Amazon's apt repo:

```bash
wget -O - https://apt.corretto.aws/corretto.key \
| sudo gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" \
| sudo tee /etc/apt/sources.list.d/corretto.list

sudo apt-get update
sudo apt-get install -y java-1.8.0-amazon-corretto-jdk

java -version
````

You should see something like:
`openjdk version "1.8.0_..." Corretto`

---

## 2. Install and Extract Kafka

Download and extract Kafka 3.0.0 (Scala 2.13 build):

```bash
sudo su
wget https://archive.apache.org/dist/kafka/3.0.0/kafka_2.13-3.0.0.tgz
tar -xvf kafka_2.13-3.0.0.tgz
cd kafka_2.13-3.0.0
```

We'll run Kafka in **KRaft mode** (no ZooKeeper).

---

## 3. Configure Kafka (KRaft mode)

Edit the Kafka broker config:

```bash
cd kafka_2.13-3.0.0
vim config/kraft/server.properties
```

Things that typically need to be correct in this file:

* `process.roles=broker,controller`
* `listeners=PLAINTEXT://:9092`
* `log.dirs=/tmp/kraft-combined-logs` (or another directory you want for broker data)
* unique `node.id`
* correct `controller.quorum.voters`

> Note: These values depend on how you’re running Kafka; this project uses a single-broker setup.

---

## 4. Initialize Kafka Storage (KRaft)

Before Kafka can start in KRaft mode, you must generate a cluster ID and format the log directory. This writes a `meta.properties` file that Kafka needs.

Generate a UUID:

```bash
cd kafka_2.13-3.0.0
bin/kafka-storage.sh random-uuid
```

Copy that UUID. Then format the storage directory with it:

```bash
bin/kafka-storage.sh format \
  --cluster-id <the-uuid-you-got-above> \
  --config config/kraft/server.properties
```

This step creates the metadata under `log.dirs` (for example `/tmp/kraft-combined-logs`) so the broker knows its identity.

---

## 5. Start Kafka (in tmux)

We keep Kafka running in the background using `tmux`.

Create a new tmux session and start the broker:

```bash
tmux new -s kafka
cd kafka_2.13-3.0.0
bin/kafka-server-start.sh ~/kafka_2.13-3.0.0/config/kraft/server.properties
```

Kafka will now run in the foreground inside that tmux session.

Detach from tmux without killing Kafka:

* Press `CTRL+b`, then `d`

To reattach later:

```bash
tmux attach -t kafka
```

---

## 6. Clone the App Sources

We use the sample Kafka app code from KodeKloud (which includes the toy shop and warehouse code):

```bash
git clone https://github.com/kodekloudhub/kafka.git
cd kafka
ls final_project/
cd final_project/toy-shop
```

Directory layout we care about:

* `final_project/toy-shop` → producer service (toy shop)
* `final_project/warehouse-ui` → consumer/warehouse dashboard

---

## 7. Set Up the `toy-shop` Producer App

This app publishes messages to Kafka (producer role).

### Create and activate a Python virtual environment

```bash
tmux new -s shop   # (optional: run the app in its own tmux session)
sudo apt install python3.12-venv -y

cd final_project/toy-shop
python3 -m venv .venv
source .venv/bin/activate
```

### Install dependencies

```bash
pip3 install -r requirements.txt
```

### Configure the Kafka producer to point at your local Kafka

Open `app.py`:

```bash
vim app.py
```

Find the Kafka producer config and make sure it uses localhost:

```python
# Kafka producer configuration
conf = {
    'bootstrap.servers': 'localhost:9092',    # Modified to localhost
    'client.id': socket.gethostname()
}
```

Save and exit.

### Run the toy-shop app

```bash
python3 app.py --host=0.0.0.0 --port=5000
```

This:

* Starts Flask on port `5000`
* Keeps producing events to Kafka when you hit its endpoints (for example, creating cart/order events, etc.)

Detach this tmux session to leave it running:

* `CTRL+b`, then `d`

To get back in later:

```bash
tmux attach -t shop
```

---

## 8. Set Up the `warehouse-ui` Consumer App

This app consumes messages from Kafka (consumer role) and exposes them (e.g. JSON API / dashboard).

### New tmux session for warehouse

```bash
tmux new -s warehouse
```

### Create and activate virtual environment

```bash
cd /root/kafka-project/kafka/final_project/toy-shop    # starting point from notes
python3 -m venv .venv
source .venv/bin/activate
```

> Note: In practice you'll want to `cd` into the right project before installing requirements. The warehouse-ui app lives in `final_project/warehouse-ui`.

Install Python requirements:

```bash
# if you haven't yet:
pip3 install -r requirements.txt
```

Then move into the warehouse UI app:

```bash
cd ../warehouse-ui
vim app.py
```

Your `warehouse-ui/app.py` typically:

* creates a Kafka **consumer**
* reads messages from the topic (like `cartevent`)
* serves them over Flask

Start the warehouse UI app:

```bash
python3 app.py --port=5003
```

(Your original note said `python3 app.py - port=5003` — the common Flask pattern is `--port=5003`. If your script expects something else, keep that exact syntax.)

This runs the consumer/dashboard on port `5003`.

Detach the tmux session:

* `CTRL+b`, then `d`

To reattach later:

```bash
tmux attach -t warehouse
```

---

## 9. tmux Cheat Sheet

* Create and enter a named session:

  ```bash
  tmux new -s <name>
  ```
* Detach (leave it running in background):

  * `CTRL+b`, then `d`
* List tmux sessions:

  ```bash
  tmux ls
  ```
* Reattach:

  ```bash
  tmux attach -t <name>
  ```

In this project we used:

* `tmux new -s kafka` → runs the Kafka broker
* `tmux new -s shop` → runs the toy-shop Flask producer
* `tmux new -s warehouse` → runs the warehouse-ui Flask consumer

Each service stays up even if you close your SSH session.

---

## 10. How Everything Works Together

1. **Kafka Broker**

   * Runs locally on the EC2 host (KRaft mode, port `9092`).
   * Acts as the event bus.

2. **toy-shop App (Producer)**

   * Endpoint(s) in Flask trigger business events (like a shopping cart event).
   * Publishes those events to Kafka using the `confluent_kafka` producer with `bootstrap.servers='localhost:9092'`.
   * Serves HTTP on `0.0.0.0:5000`.

3. **warehouse-ui App (Consumer/UI)**

   * Uses `confluent_kafka` consumer to read those Kafka events (example topic: `cartevent`).
   * Exposes data for warehouse visibility on port `5003`.

Result: you can generate events in the toy shop service and immediately see them reflected in the warehouse dashboard, all powered by Kafka.

---

## 11. Notes / Gotchas

* **KRaft init is one-time per data dir**
  If you delete `/tmp/kraft-combined-logs` (or whatever your `log.dirs` is), you’ll need to re-run the `kafka-storage.sh format` step with a *new* UUID.

* **Ports**

  * Kafka broker: `9092`
  * toy-shop Flask app: `5000`
  * warehouse-ui Flask app: `5003`

* **Virtual Envs**
  Each Python service should have its own `.venv` so dependencies don’t collide.

* **Long-running services**
  We do *not* use systemd or Docker here. We intentionally used `tmux` to keep each service alive in its own session for easy debugging and log watching.

---

## Summary

You built a complete, working Kafka pipeline on a real Linux box:

1. Provisioned Java (Amazon Corretto 8) and downloaded Kafka 3.0.0.
2. Configured and formatted Kafka in KRaft mode (no ZooKeeper).
3. Launched Kafka in its own `tmux` session.
4. Cloned the app code.
5. Set up two Python Flask services:

   * `toy-shop` as a Kafka **producer** (port 5000)
   * `warehouse-ui` as a Kafka **consumer** / dashboard (port 5003)
6. Kept each service running in the background using `tmux`.

This is basically the same pattern you'll see in real platform / SRE work: message bus in one session, producers/consumers in others, all talking over localhost.

---


