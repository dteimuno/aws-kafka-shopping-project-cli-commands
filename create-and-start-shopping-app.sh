git clone https://github.com/kodekloudhub/kafka.git
cd kafka
ls final_project/
cd final_project/toy-shop
tmux new -s shop
sudo apt install python3.12-venv -y
python3 -m venv .venv #reinstall virtual environment again
source .venv/bin/activate #activate virtual environment
pip3 install -r requirements.txt
vim app.py
#modify the following in app.py and then save:
# Kafka producer configuration
conf = {
    'bootstrap.servers': 'localhost:9092',    # Modify to localhost
    'client.id': socket.gethostname()
}
##start application:
python3 app.py --host=0.0.0.0 --port=5000
I will detach this shell so that I can keep it running:
# CTRL +b, then d
