tmux new -s warehouse
# I will create a virtual environment
python3 -m venv .venv
source .venv/bin/activate
# I will change directory to my warehouse ui-application
cd /root/kafka-project/kafka/final_project/toy-shop
#install python requirements for app:
python -r requirements.txt
# change directory to warehouse-ui application:
cd ../warehouse-ui
vim app.py
#start application:
python3 app.py - port=5003
