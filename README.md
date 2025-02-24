# Python-HTTPS

Easily create HTTPS websites with Python using Flask, uWSGI, and Nginx.

---

## Table of Contents

1. [Initial Server Setup](#initial-server-setup)
2. [Installing Python and Dependencies](#installing-python-and-dependencies)
3. [Setting Up the Flask Application](#setting-up-the-flask-application)
4. [Testing the Flask Application (Optional)](#testing-the-flask-application-optional)
5. [Configuring uWSGI](#configuring-uwsgi)
6. [Setting Up Systemd Service](#setting-up-systemd-service)
7. [Configuring Nginx](#configuring-nginx)
8. [Enabling HTTPS with Certbot](#enabling-https-with-certbot)
9. [Final Steps](#final-steps)

---

## Initial Server Setup

1. **SSH into the server**:
   ```bash
   ssh root@your_server_ip
   ```

2. **Create a new user**:
   ```bash
   adduser pythonwebsite
   ```

3. **Add the user to the `sudo` group**:
   ```bash
   usermod -aG sudo pythonwebsite
   ```

4. **Configure the firewall to allow SSH access**:
   ```bash
   ufw allow OpenSSH
   ```

5. **Enable the firewall**:
   ```bash
   ufw enable
   ```

6. **Check the firewall status**:
   ```bash
   ufw status
   ```

7. **Switch to the new user**:
   ```bash
   ssh pythonwebsite@your_server_ip
   ```

---

## Installing Python and Dependencies

1. **Update the local package index**:
   ```bash
   sudo apt update
   ```

2. **Install Python and required dependencies**:
   ```bash
   sudo apt install python3-pip python3-dev build-essential libssl-dev libffi-dev python3-setuptools
   ```

3. **Install the virtual environment package**:
   ```bash
   sudo apt install python3-venv
   ```

---

## Setting Up the Flask Application

1. **Create a directory for the project**:
   ```bash
   mkdir ~/pythonwebsite
   cd ~/pythonwebsite
   ```

2. **Set up a virtual environment**:
   ```bash
   python3 -m venv pythonwebsiteenv
   source pythonwebsiteenv/bin/activate
   ```

3. **Install required Python packages**:
   ```bash
   pip install wheel uwsgi flask
   ```

4. **Create a basic Flask application**:
   ```bash
   nano ~/pythonwebsite/pythonwebsite.py
   ```

   Example code:
   ```python
   from flask import Flask
   app = Flask(__name__)

   @app.route("/")
   def hello():
       return "<h1>Hello World!</h1>"

   if __name__ == "__main__":
       app.run(host='0.0.0.0')
   ```

---

## Testing the Flask Application (Optional)

1. **Allow port 5000 in the firewall**:
   ```bash
   sudo ufw allow 5000
   ```

2. **Run the Flask application**:
   ```bash
   python pythonwebsite.py
   ```

3. **Access the application**: Open your browser and navigate to `http://your_server_ip:5000`.

---

## Configuring uWSGI

1. **Create a WSGI entry point**:
   ```bash
   nano ~/pythonwebsite/wsgi.py
   ```

   Example code:
   ```python
   from pythonwebsite import app

   if __name__ == "__main__":
       app.run()
   ```

2. **Test the WSGI entry point**:
   ```bash
   uwsgi --socket 0.0.0.0:5000 --protocol=http -w wsgi:app
   ```

3. **Deactivate the virtual environment**:
   ```bash
   deactivate
   ```

4. **Create a uWSGI configuration file**:
   ```bash
   nano ~/pythonwebsite/pythonwebsite.ini
   ```

   Example configuration:
   ```ini
   [uwsgi]
   module = wsgi:app

   master = true
   processes = 5

   socket = pythonwebsite.sock
   chmod-socket = 660
   vacuum = true

   die-on-term = true
   ```

---

## Setting Up Systemd Service

1. **Create a systemd service file**:
   ```bash
   sudo nano /etc/systemd/system/pythonwebsite.service
   ```

   Example configuration:
   ```ini
   [Unit]
   Description=uWSGI instance to serve pythonwebsite
   After=network.target

   [Service]
   User=pythonwebsite
   Group=www-data
   WorkingDirectory=/home/pythonwebsite/pythonwebsite
   Environment="PATH=/home/pythonwebsite/pythonwebsite/pythonwebsiteenv/bin"
   ExecStart=/home/pythonwebsite/pythonwebsite/pythonwebsiteenv/bin/uwsgi --ini pythonwebsite.ini

   [Install]
   WantedBy=multi-user.target
   ```

2. **Start and enable the service**:
   ```bash
   sudo systemctl start pythonwebsite
   sudo systemctl enable pythonwebsite
   ```

3. **Check the service status**:
   ```bash
   sudo systemctl status pythonwebsite
   ```

---

## Configuring Nginx

1. **Create an Nginx configuration file**:
   ```bash
   sudo nano /etc/nginx/sites-available/pythonwebsite
   ```

   Example configuration:
   ```nginx
   server {
       listen 80;
       server_name your_domain www.your_domain;

       location / {
           include uwsgi_params;
           uwsgi_pass unix:/home/pythonwebsite/pythonwebsite/pythonwebsite.sock;
       }
   }
   ```

2. **Enable the site**:
   ```bash
   sudo ln -s /etc/nginx/sites-available/pythonwebsite /etc/nginx/sites-enabled
   ```

3. **Remove the default site**:
   ```bash
   sudo rm /etc/nginx/sites-enabled/default
   ```

4. **Restart Nginx**:
   ```bash
   sudo systemctl restart nginx
   ```

5. **Update the firewall**:
   ```bash
   sudo ufw delete allow 5000
   sudo ufw allow 'Nginx Full'
   ```

---

## Enabling HTTPS with Certbot

1. **Install Certbot**:
   ```bash
   sudo apt install certbot python3-certbot-nginx
   ```

2. **Generate an SSL certificate**:
   ```bash
   sudo certbot --nginx -d your_domain -d www.your_domain
   ```

3. **Choose the redirect option**: Select `2` to redirect HTTP traffic to HTTPS.

4. **Remove HTTP access from the firewall**:
   ```bash
   sudo ufw delete allow 'Nginx HTTP'
   ```

---

## Final Steps

Visit your website in a browser using `https://your_domain`. Congratulations! Your HTTPS-enabled Python website is now live.

