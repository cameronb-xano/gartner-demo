#!/usr/bin/env bash
# Recorded demo helper: hit the /escalate endpoint and show the downstream
# effects for the insurance claims story.
#
# Usage:  ./demo/demo_call.sh [CLAIM_ID]
#         ./demo/demo_call.sh 1            # default

set -e

CLAIM_ID="${1:-1}"
TICK="https://xjik-uiot-gpzk.n7d.xano.io/api:gartner-claims"
TICK_AUTH="https://xjik-uiot-gpzk.n7d.xano.io/api:gartner-claims-auth"
PROF="https://xjik-uiot-gpzk.n7d.xano.io/api:gartner-profiling"
NOTIFY="https://xjik-uiot-gpzk.n7d.xano.io/api:gartner-notify"

# Reuse demo agent if exists, otherwise create
TOKEN=$(curl -s -X POST "${TICK_AUTH}/login" -H "Content-Type: application/json" \
  -d '{"email":"lead@gartner.demo","password":"demo1234"}' \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('token',''))")

if [ -z "$TOKEN" ]; then
  echo "→ Creating fresh demo agent..."
  TOKEN=$(curl -s -X POST "${TICK_AUTH}/signup" -H "Content-Type: application/json" \
    -d "{\"name\":\"Demo Agent\",\"email\":\"demo-$(date +%s)@gartner.demo\",\"password\":\"demo1234\"}" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")
fi

echo "→ POST /claims/${CLAIM_ID}/escalate ..."
curl -s -X POST "${TICK}/claims/${CLAIM_ID}/escalate" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"reason":"customer hospitalized — needs immediate review"}' \
  | python3 -m json.tool

CUSTOMER_ID=$(curl -s "${TICK}/claims/${CLAIM_ID}" -H "Authorization: Bearer ${TOKEN}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('customer_id',1))")

sleep 0.5

echo
echo "════════════════ DOWNSTREAM EFFECTS ════════════════"
echo
echo "→ Policy Data / customer context"
curl -s "${PROF}/customers/${CUSTOMER_ID}" | python3 -c "
import sys, json
d = json.load(sys.stdin)
c = d.get('customer', {})
print(f\"  segment={c.get('segment')} risk={c.get('risk_score')} ltv={c.get('lifetime_value')}\")
recent = d.get('recent_events', [])[:3]
for e in recent:
    print(f\"  recent: {e['event_type']} from {e['source']}\")
"

echo
echo "→ Customer communications"
curl -s "${NOTIFY}/notifications?customer_id=${CUSTOMER_ID}&template_name=claim_escalated&per_page=3" \
  | python3 -c "
import sys, json
d = json.load(sys.stdin)
for n in d.get('items', []):
    print(f\"  → {n['recipient']:35} | {n['subject']}\")
    print(f\"    {n['body'].split(chr(10))[0]}...\")
"

echo
echo "✓ One endpoint, one HTTP call, four backends updated."
