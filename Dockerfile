FROM perfectlysoft/perfectassistant:5.0
LABEL Description="Docker image for ZenRetail."

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

EXPOSE 8080

RUN apt-get -y update && apt-get install -y openssl libssl-dev libcurl4-openssl-dev uuid-dev libpq-dev libgd-dev build-essential chrpath libxft-dev libfreetype6-dev libfreetype6 libfontconfig1-dev libfontconfig1 wget

RUN wget https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2
RUN tar xvjf phantomjs-2.1.1-linux-x86_64.tar.bz2 -C /usr/local/share/
RUN ln -s /usr/local/share/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/local/bin/
RUN rm -f phantomjs-2.1.1-linux-x86_64.tar.bz2

RUN rm -rf /var/lib/apt/lists/*

WORKDIR /app
ADD Package.swift .
ADD webretail.json .
ADD rasterize.js .
# ADD certificate.crt .
# ADD private.pem .
COPY Sources ./Sources/
COPY webroot ./webroot/

RUN swift build -c release

ENTRYPOINT [".build/x86_64-unknown-linux/release/ZenRetail"]
