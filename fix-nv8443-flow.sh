#!/bin/sh
# HomeProxy: NV-8443 empty Vision. Importer often writes xtls-rprx-vision back.
# After this patch JSON never emits flow on port 8443. Safe to re-run.
# No secrets. Does not print subscription URL.
set -e
G=/etc/homeproxy/scripts/generate_client.uc
U=/etc/homeproxy/scripts/update_subscriptions.uc
[ -f "$G" ] && [ -f "$U" ] || { echo "no HomeProxy scripts"; exit 1; }
cp -a "$G" "$G.bak-nv8443"
cp -a "$U" "$U.bak-nv8443"

grep -q 'node.port === .8443' "$G" || \
  sed -i 's/flow: node.vless_flow,/flow: ("" + node.port === "8443") ? null : node.vless_flow,/' "$G"
grep -q 'node.port === .8443' "$G" || { echo "generate_client.uc: flow line not patched"; exit 1; }

grep -q "config.port === '8443'" "$U" || \
  sed -i "s/config.vless_flow = ob.flow || null;/config.vless_flow = (config.port === '8443') ? null : (ob.flow || null);/" "$U"
grep -q "url.port == '8443'" "$U" || \
  sed -i "s/vless_flow: (params.security in \['tls', 'reality'\]) ? params.flow : null/vless_flow: (url.port == '8443' || url.port == 8443) ? null : ((params.security in ['tls', 'reality']) ? params.flow : null)/" "$U"
grep -q "config.port === '8443'" "$U" || { echo "update_subscriptions.uc: parse outbound not patched"; exit 1; }

for s in $(uci -q show homeproxy | sed -n 's/^homeproxy\.\([^=]*\)=node$/\1/p'); do
  [ "$(uci -q get homeproxy.$s.port)" = 8443 ] || continue
  uci -q delete homeproxy.$s.vless_flow
done
uci commit homeproxy
echo "nv8443-flow: patched. restart HomeProxy once: /etc/init.d/homeproxy restart"
echo "check: jsonfilter -i /var/run/homeproxy/hiddify-c.json -e '@.outbounds[@.tag=\"main-out\"].flow'  must be empty"
echo "check: jsonfilter ... main-out.server  must match selected node address"
