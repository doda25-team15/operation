#!/usr/bin/env bash

while true; do
  RESPONSE=$(curl -s -c cookies.txt -H "Host: sms-checker-app" http://${EXTERNAL_IP}:80)
  echo "$RESPONSE"

  if echo "$RESPONSE" | grep -q "testing canary"; then
    echo "Canary detected! Reusing cookie and sending 10 more requests..."
    cat cookies.txt
    break
  fi

  sleep 1
done

for i in $(seq 1 10); do
  curl -s -b cookies.txt -H "Host: sms-checker-app" http://${EXTERNAL_IP}:80
  echo
  sleep 1
done
