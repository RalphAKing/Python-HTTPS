# Python-HTTPS
Create HTTPS websites with python


# Initial server settup 

Firstly we are going to ssh into the server.

```bash
ssh root@your_server_ip
```

Now we are going to add a user to the server. For this example we will create a user called "pythonwebsite".

```bash
adduser pythonwebsite
```

Now we are going to add the user to the sudo group.

```bash
usermod -aG sudo sammy
```

Now we are going to configure the firewall to allow SSH access to the server.

```bash
ufw allow OpenSSH
```

Now we are going to enable the firewall.

```bash
ufw enable
```

- To check the status of the firewall, run the following command:
```bash
ufw status
```

Now we have created a user and configured the firewall. We can now ssh into this user.

```bash
ssh pythonwebsite@your_server_ip
```

Now we are going to update the local package index.

```bash
sudo apt update
```

Now we are going to install the python and pip dependicies.

```bash
sudo apt install python3-pip python3-dev build-essential libssl-dev libffi-dev python3-setuptools
```

Now we are going to install the virtual environment.

```bash
sudo apt install python3-venv
```

Now we are going to create the parent directory for our website and go into it.

```bash
mkdir ~/pythonwebsite
```

```bash
cd ~/pythonwebsite
```

Now we are going to create the virtual environment.

```bash
python -m venv pythonwebsiteenv
```

Now we are going to activate the virtual environment.

```bash
source pythonwebsiteenv/bin/activate
```

Now we are going to install the required packages.

```bash
pip install wheel
pip install uwsgi flask
```

Now we are going to create a basic website.

```bash
nano ~/pythonwebsite/pythonwebsite.py
```

Here is some example code for the website.

```python
from flask import Flask
app = Flask(__name__)

@app.route("/")
def hello():
    return "<h1>Hello World!</h1>"

if __name__ == "__main__":
    app.run(host='0.0.0.0')
```

# testing example (optionial)

Before we can test the website we need to allow port 5000 in the firewall.

```bash
sudo ufw allow 5000
```

Then we can run the website with the following command.

```bash
python pythonwebsite.py
```

### Output

```bash
* Serving Flask app "myproject" (lazy loading)
 * Environment: production
   WARNING: Do not use the development server in a production environment.
   Use a production WSGI server instead.
 * Debug mode: off
 * Running on http://0.0.0.0:5000/ (Press CTRL+C to quit)
 ```

 Now we can access the website by going to the server ip in a web browser.

 ## End of Example

 Now we need to create the wsgi entry pooint.

```bash
nano ~/pythonwebsite/wsgi.py
```

Here is some example code for the wsgi entry point.

```python
from pythonwebsite import app

if __name__ == "__main__":
    app.run()
```

To test if the entry point is working we can run the following command.

```bash
uwsgi --socket 0.0.0.0:5000 --protocol=http -w wsgi:app
```

Press CTRL+C to quit

Now we can leave the virtual environment.

```bash
deactivate
```

Now we need to create the ini file for the website.

```bash
nano ~/pythonwebsite/pythonwebsite.ini
```

Here is some example code for the ini file.

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

Now we need to create the systemd service.

```bash
sudo nano /etc/systemd/system/pythonwebsite.service
```

Here is some example code for the systemd service.

```service
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

Now we need to start and enable the service.

```bash
sudo systemctl start pythonwebsite
sudo systemctl enable pythonwebsite
```

We can check the status of the service with the following command.

```bash
sudo systemctl status pythonwebsite
```

Now we need to configure sites-available.

```bash
sudo nano /etc/nginx/sites-available/pythonwebsite
```

We can use the following code as a template. Replace the your_domain name with your own.

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

Now we need to create a symlink to sites-enabled.

```bash
sudo ln -s /etc/nginx/sites-available/pythonwebsite /etc/nginx/sites-enabled
```

Now we need to remove the default symlink.

```bash
sudo rm /etc/nginx/sites-enabled/default
```

now we need to restart nginx.

```bash
sudo systemctl restart nginx
```

Now we need to allow port 80 in the firewall and remove port 5000.

```bash
sudo ufw delete allow 5000
sudo ufw allow 'Nginx Full'
```

Now we can test the website by going to the server ip in a web browser.

Now we need to install certbot.

```bash
sudo apt install certbot python3-certbot-nginx
```

Now we need to generate the certificate. Replace the your_domain name with your own.

```bash
sudo certbot --nginx -d your_domain -d www.your_domain
```

Now certbot will ask you a few questions.

```bash
Please choose whether or not to redirect HTTP traffic to HTTPS, removing HTTP access.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
1: No redirect - Make no further changes to the webserver configuration.
2: Redirect - Make all requests redirect to secure HTTPS access. Choose this for
new sites, or if you're confident your site works on HTTPS. You can undo this
change by editing your web server's configuration.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Select the appropriate number [1-2] then [enter] (press 'c' to cancel):
``` 

Choose 2 and press enter.

```bash
IMPORTANT NOTES:
 - Congratulations! Your certificate and chain have been saved at:
   /etc/letsencrypt/live/your_domain/fullchain.pem
   Your key file has been saved at:
   /etc/letsencrypt/live/your_domain/privkey.pem
   Your cert will expire on 2020-08-18. To obtain a new or tweaked
   version of this certificate in the future, simply run certbot again
   with the "certonly" option. To non-interactively renew *all* of
   your certificates, run "certbot renew"
 - Your account credentials have been saved in your Certbot
   configuration directory at /etc/letsencrypt. You should make a
   secure backup of this folder now. This configuration directory will
   also contain certificates and private keys obtained by Certbot so
   making regular backups of this folder is ideal.
 - If you like Certbot, please consider supporting our work by:

   Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
   Donating to EFF:                    https://eff.org/donate-le
```

Now we can remoove the http Nginx accsess from the firewall.

```bash
sudo ufw delete allow 'Nginx HTTP'
```

Finaly we can visit your website in a web browser.

```bash
https://your_domain
```