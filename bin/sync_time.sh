#! /bin/bash
#NTP_SERVER_IP=IAA0631.bt.bombardier.net
NTP_SERVER_IP=ptbtime1.ptb.de
echo "Try to sync time with ${NTP_SERVER_IP}"
#ntpdate $NTP_SERVER_IP >> /dev/null
sudo ntpdate $NTP_SERVER_IP
