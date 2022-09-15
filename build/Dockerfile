FROM python:3.8-slim

RUN apt-get update && apt-get -y install cron vim
WORKDIR /app

COPY requirements.txt requirements.txt
RUN python3 -m venv venv
RUN venv/bin/pip3 install -r requirements.txt

COPY --chmod=644 ./build/crontab /etc/cron.d/crontab
COPY subscribe.py boot.sh ./

RUN /usr/bin/crontab /etc/cron.d/crontab
