sudo su
wget https://archive.apache.org/dist/kafka/3.0.0/kafka_2.13-3.0.0.tgz
tar -xvf kafka_2.13-3.0.0.tgz
# Navigate to https://docs.aws.amazon.com/corretto/latest/corretto-8-ug/downloads-list.html
wget -O - https://apt.corretto.aws/corretto.key | sudo gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg && \
echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" | sudo tee /etc/apt/sources.list.d/corretto.list
sudo apt-get update; sudo apt-get install -y java-1.8.0-amazon-corretto-jdk
java -version
