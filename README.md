
<img src="https://github.com/gerardogrisolini/ZenRetail/blob/master/Assets/logo.png?raw=true" width="80" alt="ZenRetail - RMS" />

# ZenRetail - RMS

Retail Management System and e-Commerce
developed with Swift, Angular and PostgreSQL .

#### Under active development. Please do not use.


## Build Notes

Ensure you have installed Xcode 12.0 or later.


### macOS

To install nodejs. libgd and phantomjs:

```
brew install node
brew cask install phantomjs
```

### Linux


To install nodejs and phantomjs:

```
sudo apt-get install -y nodejs
sudo apt-get install build-essential chrpath libssl-dev libxft-dev libfreetype6-dev libfreetype6 libfontconfig1-dev libfontconfig1 -y
sudo wget https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2
sudo tar xvjf phantomjs-2.1.1-linux-x86_64.tar.bz2 -C /usr/local/share/
sudo ln -s /usr/local/share/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/local/bin/
```

## Angular - Terminal

Steps for the development UI:

in the subfolders:
* AdminUI
* WebUI

```
npm install
npm start
```

Steps for build UI:
```
npm run build
npm run deploy
```

## Docker - Terminal

* Postgresql

```
docker pull postgres
docker run -p 5432:5432 --name db -e POSTGRES_DB=zenretail -e POSTGRES_PASSWORD=zBnwEe8QDR -d postgres
```

* Zenretail

```
docker build -t zenretail .
docker run -d -p 80:8080 --link db -t zenretail
```

## Heroku

Config Vars:

```
LANG = C.UTF-8
LC_ALL = C.UTF-8
HOST = zenretail.herokuapp.com
```

Buildpack:

```
https://github.com/heroku/heroku-buildpack-apt.git
https://github.com/stomita/heroku-buildpack-phantomjs.git
https://github.com/vapor-community/heroku-buildpack.git
```

## Install on linux as service

nano /etc/systemd/system/zenretail.service

```
[Unit]
Description=Swift Application running on Ubuntu 16.04
[Service]
WorkingDirectory=/root/ZenRetail
ExecStart=/root/ZenRetail/.build/x86_64-unknown-linux/release/ZenRetail
Restart=always
RestartSec=10
SyslogIdentifier=ZenRetail
User=root
Environment=SWIFT_ENVIRONMENT=Production
[Install]
WantedBy=multi-user.target
```

* Commands

```
systemctl enable zenretail.service
systemctl start zenretail.service
systemctl status zenretail.service
systemctl stop zenretail.service
```
