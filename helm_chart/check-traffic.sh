EXTERNAL_IP="${EXTERNAL_IP:?EXTERNAL_IP is required}"
HOST="${HOST:-sms-checker-app}"
REQUESTS="${REQUESTS:-100}"

main=0
canary=0

for i in $(seq 1 $REQUESTS); do
  response=$(curl -s -H "Host: $HOST" http://$EXTERNAL_IP:80)

  if [[ "$response" == "Hello World! testing canary" ]]; then
    ((canary++))
  elif [[ "$response" == "Hello World!" ]]; then
    ((main++))
  fi
done

echo "Total requests: $REQUESTS"
echo "Main hits:   $main"
echo "Canary hits: $canary"

canary_pct=$(awk "BEGIN { printf \"%.2f\", ($canary / $REQUESTS) * 100 }")
echo "Canary %:    ${canary_pct}%"

