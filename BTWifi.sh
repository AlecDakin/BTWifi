#!/bin/sh

# CONF

DBG=true
RELOG_UNAME=xxxxxxx
RELOG_PASSW=xxxxxxx

# END CONF
if ! ifconfig tun0 | grep -q "00-00-00-00-00-00-00-00-00-00-00-00-00-00-00-00" 
then
  #VPN is down so stop service?
  $DBG && echo "Stopping VPN"
  $DBG && logger -t "logon_bt" "Stopping VPN"
  /etc/init.d/openvpn stop
  sleep 30s
  #change DNS to BT
  IS_DNS=$(uci show network.lan.dns | grep "9.9.9.9" | wc -l)
  if [ $IS_DNS -eq 1 ]
  then
    #Remove Lan DNS servers
    $DBG && echo "Currently on Quad9 reverting to BT"
    $DBG && logger -t "logon_bt" "Currently on Quad9 reverting to BT"
    uci -q delete network.lan.dns
    uci commit network
    /etc/init.d/network reload
    sleep 30s
  fi
  $DBG && echo "Check BTWi-fi"
  $DBG && logger -t "logon_bt" "Check BTWi-fi"

  IS_LOGGED_IN=$(wget "https://www.btopenzone.com:8443/home" --no-check-certificate --no-cache --timeout 30 -O - 2>/dev/null | grep "now logged on")

  if [ "$IS_LOGGED_IN" ]
  then
    $DBG && echo "Currently logged in. Nothing to do... :)"
    $DBG && logger -t "logon_bt" "Currently logged in. Nothing to do... :)"
    # Start VPN connection
    $DBG && echo "Starting VPN"
    $DBG && logger -t "logon_bt" "Starting VPN"
    /etc/init.d/openvpn start
    sleep 30s
  else
    $DBG && echo "You're not logged in... will log in now!"
    $DBG && logger -t "logon_bt" "You're not logged in... will log in now!"
    OUT=$(wget -qO - --no-check-certificate --no-cache --post-data "partnerNetwork=btb&username=$RELOG_UNAME&password=$RELOG_PASSW" "https://www.btwifi.com:8443/ante")
    ONLINE=$(echo $OUT | grep "now logged on" )
    if [ "$ONLINE" ]
    then
      $DBG && echo "You're online!"
      $DBG && logger -t "logon_bt" "You're online!" 
      # Start VPN connection
      $DBG && echo "Starting VPN"
      $DBG && logger -t "logon_bt" "Starting VPN"
      /etc/init.d/openvpn start
      sleep 30s
    else
      $DBG && echo "Could not login :("
      $DBG && logger -t "logon_bt" "Could not login :("
    fi
  fi

else
  IS_DNS=$(uci show network.lan.dns | grep "9.9.9.9" | wc -l)
  if [ $IS_DNS -eq 0 ]
  then
    #Still on BT DNS, switching to Quad9
    $DBG && echo "Currently on BT reverting to Quad9"
    $DBG && logger -t "logon_bt" "Currently on BT reverting to Quad9"
    uci -q delete network.lan.dns
    uci add_list network.lan.dns="9.9.9.9"
    uci add_list network.lan.dns="149.112.112.112"
    uci commit network
    /etc/init.d/network reload
  fi
  $DBG && echo "VPN is up. Nothing to do... :)"
  $DBG && logger -t "logon_bt" "VPN is up. Nothing to do... :)"
fi

