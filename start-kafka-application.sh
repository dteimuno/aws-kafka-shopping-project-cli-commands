tmux new -s kafka
cd kafka_2.13-3.0.0
bin/kafka-storage.sh random-uuid #this generates a random UUID that will be used in the next step to start the Kafka service
vim config/kraft/server.properties
bin/kafka-server-start.sh ~/kafka_2.13-3.0.0/config/kraft/server.properties
# Use CTRL+b, then d to detach session. keeps kafka running in background
