# Add crontab entry

# TODO: Add this file and then reference it all from crontab...

CLOUDFLARE_API_KEY=SOMEKEY
TARGET_DOMAIN=vpn.liamtbrand.com

# Get IP from Google
MYIP="$(dig TXT +short o-o.myaddr.l.google.com @ns1.google.com)"

# Send request to change target domain to point to IP fetched from Google
curl --request PUT \
  --url https://api.cloudflare.com/client/v4/zones/zone_identifier/dns_records/identifier \
  --header 'Content-Type: application/json' \
  --header 'X-Auth-Email: ' \
  --data '{ "comment": "Domain verification record", "content": "${MYIP}", "name": "${TARGET_DOMAIN}", "proxied": false, "tags": [ "owner:dns-team" ], "ttl": 3600 }'