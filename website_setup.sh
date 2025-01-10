#!/bin/bash

# Variables - MODIFY THESE
SERVER_IP="your_server_ip"
DOMAIN="your_domain"
USERNAME="username"
PROJECT_NAME="projectname"

# Update and install dependencies
apt update
apt install -y python3-pip python3-dev build-essential libssl-dev libffi-dev python3-setuptools python3-venv nginx

# Create user and add to sudo group
adduser --gecos "" --disabled-password $USERNAME
usermod -aG sudo $USERNAME

# Configure firewall
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

# Switch to the new user
su - $USERNAME << EOF

# Create project directory
mkdir ~/$PROJECT_NAME
cd ~/$PROJECT_NAME

# Set up Python virtual environment
python3 -m venv ${PROJECT_NAME}env
source ${PROJECT_NAME}env/bin/activate

# Install Python packages
pip install wheel uwsgi flask

# Create Flask application
cat > ~/$PROJECT_NAME/$PROJECT_NAME.py << EOL
from flask import Flask
app = Flask(__name__)

@app.route("/")
def hello():
    return "<h1>Hello World!</h1>"

if __name__ == "__main__":
    app.run(host='0.0.0.0')
EOL

# Create WSGI entry point
cat > ~/$PROJECT_NAME/wsgi.py << EOL
from $PROJECT_NAME import app

if __name__ == "__main__":
    app.run()
EOL

# Create uWSGI configuration file
cat > ~/$PROJECT_NAME/$PROJECT_NAME.ini << EOL
[uwsgi]
module = wsgi:app

master = true
processes = 5

socket = $PROJECT_NAME.sock
chmod-socket = 660
vacuum = true

die-on-term = true
EOL

# Exit user shell
EOF

# Create systemd service file
cat > /etc/systemd/system/$PROJECT_NAME.service << EOL
[Unit]
Description=uWSGI instance to serve $PROJECT_NAME
After=network.target

[Service]
User=$USERNAME
Group=www-data
WorkingDirectory=/home/$USERNAME/$PROJECT_NAME
Environment="PATH=/home/$USERNAME/$PROJECT_NAME/${PROJECT_NAME}env/bin"
ExecStart=/home/$USERNAME/$PROJECT_NAME/${PROJECT_NAME}env/bin/uwsgi --ini $PROJECT_NAME.ini

[Install]
WantedBy=multi-user.target
EOL

# Start and enable the service
systemctl start $PROJECT_NAME
systemctl enable $PROJECT_NAME

# Configure Nginx
cat > /etc/nginx/sites-available/$PROJECT_NAME << EOL
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    location / {
        include uwsgi_params;
        uwsgi_pass unix:/home/$USERNAME/$PROJECT_NAME/$PROJECT_NAME.sock;
    }
}
EOL

# Create symlink and remove default
ln -s /etc/nginx/sites-available/$PROJECT_NAME /etc/nginx/sites-enabled
rm /etc/nginx/sites-enabled/default

# Restart Nginx
systemctl restart nginx

# Install and configure Let's Encrypt
apt install -y certbot python3-certbot-nginx
certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email webmaster@$DOMAIN --redirect

echo "Setup complete! You can now access your website at https://$DOMAIN"