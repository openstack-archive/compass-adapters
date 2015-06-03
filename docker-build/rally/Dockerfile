FROM ubuntu:trusty
RUN apt-get update && \
    apt-get -y install vim git python2.7 bash-completion python-dev libffi-dev \
                       libxml2-dev libxslt1-dev libssl-dev libmysqlclient-dev libpq-dev wget build-essential && \
    wget https://raw.github.com/pypa/pip/master/contrib/get-pip.py -O /tmp/pip.py &&\
    python /tmp/pip.py && rm /tmp/pip.py &&\
    pip install mysql-python
RUN mkdir -p /tmp/rally-src && \
    cd /tmp/rally-src && \
    git clone https://github.com/stackforge/rally.git
RUN mkdir -p /opt/rally/database && \
    mkdir -p /etc/rally && \
    mkdir -p /opt/compass/rally/deployment && \
    mkdir -p /opt/compass/rally/scenarios && \
    chmod 0755 /opt/compass && \
    chmod 0755 /opt/compass/rally && \
    chmod 0755 /opt/compass/rally/deployment && \
    chmod 0755 /opt/compass/rally/scenarios

ADD check_health.py /opt/compass/check_health.py

#RUN git clone https://github.com/stackforge/rally.git
RUN cd /tmp/rally-src/rally && \
    ./install_rally.sh
