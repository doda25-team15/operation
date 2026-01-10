#!/bin/bash
echo "Starting Load Test (100 iterations)..."
echo "Sending a mix of: "
echo " - 80% Standard Traffic (Routes 90% to v1, 10% to v2)"
echo " - 20% Forced Canary Traffic (Routes 100% to v2)"

for i in {1..100}; do
  # 1. Standard Request (Mostly v1)
  curl -s -o /dev/null -X POST \
     -H "Content-Type: application/json" \
     -H "Host: sms-checker-app" \
     -d '{"sms":"standard request","guess":"ham"}' \
     http://localhost:8080/sms/

  # 2. Another Standard Request (Mostly v1)
  curl -s -o /dev/null -X POST \
     -H "Content-Type: application/json" \
     -H "Host: sms-checker-app" \
     -d '{"sms":"standard request","guess":"ham"}' \
     http://localhost:8080/sms/

  # 3. Forced Canary Request (Always v2 - to ensure we see the spikes)
  curl -s -o /dev/null -X POST \
     -H "Content-Type: application/json" \
     -H "Host: sms-checker-app" \
     -H "testing: true" \
     -d '{"sms":"canary test","guess":"ham"}' \
     http://localhost:8080/sms/

  sleep 0.5
done

echo "Load test complete!"
