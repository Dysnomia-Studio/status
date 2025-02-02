#!/usr/bin/env bash
set -euo pipefail

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

STATUS_WEBSITE="https://status.dysnomia.studio"

# ==========================
# Services list
# ==========================
declare -A ServicesWithOkCode;
declare -A ServicesWebsocket;

### Websites/Webservices

# Achieve.games
ServicesWithOkCode["https://achieve.games"]='."Websites / Webservices"."Achieve.games"'

# Achieve.games
ServicesWithOkCode["https://alchemistry-leaderboard.dysnomia.studio/leaderboard/game"]='."Websites / Webservices"."Alchemistry Leaderboard"'

# Dehash.me
ServicesWithOkCode["https://dehash.me"]='."Websites / Webservices"."Dehash.me"'

# Dysnomia
ServicesWithOkCode["https://dysnomia.studio"]='."Websites / Webservices"."Dysnomia"'
ServicesWithOkCode["https://wiki.dysnomia.studio"]='."Websites / Webservices"."Dysnomia''s Wiki"'

# Galactae
ServicesWithOkCode["https://galactae.eu"]='."Websites / Webservices"."Galactae - Website"'
ServicesWithOkCode["https://galactae.com"]='."Websites / Webservices"."Galactae - Website"'
ServicesWithOkCode["https://galactae.space"]='."Websites / Webservices"."Galactae - Website"'

ServicesWithOkCode["https://00-dev.galactae.eu"]='."Websites / Webservices"."Galactae - Dev Client"'
ServicesWebsocket["https://00-srv.galactae.eu"]='."Websites / Webservices"."Galactae - Dev Server"'

ServicesWithOkCode["https://01-milkyway.galactae.eu"]='."Websites / Webservices"."Galactae - Milkyway Client"'
ServicesWebsocket["https://01-srv.galactae.eu"]='."Websites / Webservices"."Galactae - Milkyway Server"'

### CDN
ServicesWithOkCode["https://01.cdn.elanis.eu/portfolio/img/Elanis.png"]='."CDN"."Elanis"'
ServicesWithOkCode["https://cdn.galactae.eu"]='."CDN"."Galactae"'

### Manufactur'inc
ServicesWebsocket["https://ptb.manufacturinc.dysnomia.studio"]='."Websites / Webservices"."Manufactur''inc PTB Game servers"'
ServicesWebsocket["https://prd.manufacturinc.dysnomia.studio"]='."Websites / Webservices"."Manufactur''inc Game servers"'

### Services
ServicesWithOkCode["https://bugs.dysnomia.studio"]='."Services"."Bug Tracker"'

### Nodes
declare -A Nodes
Nodes["https://carbon.dysnomia.studio"]='."Nodes"."Carbon"'
Nodes["https://nitrogen.dysnomia.studio"]='."Nodes"."Nitrogen"'
Nodes["https://oxygen.dysnomia.studio"]='."Nodes"."Oxygen"'

# ==========================
# Script
# DO NOT EDIT BELOW THIS LINE
# ==========================
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

check_website () {
    domainName=$(echo $1 | awk -F[/:] '{print $4}')
    ip=$(dig +short $domainName @1.1.1.1 | tail -n 1)

    curl --max-time 5 --resolve "$domainName:443:$ip" --user-agent "Dysnomia-monitoring" -s -o /dev/null -w "%{http_code}" $1
}

check_website_insecure () {
    domainName=$(echo $1 | awk -F[/:] '{print $4}')
    ip=$(dig +short $domainName @1.1.1.1 | tail -n 1)
    curl --max-time 5 --resolve "$domainName:443:$ip" --insecure --user-agent "Dysnomia-monitoring" -s -o /dev/null -w "%{http_code}" $1
}

setStatus () {
    jq -c "$1 = \"$2\"" "$SCRIPT_DIR/status.json" > tmp.status.json && mv tmp.status.json "$SCRIPT_DIR/status.json"
}

if [ $(check_website "$STATUS_WEBSITE") != "200" ]; then
	echo "Error: Cannot reach internet !";
	exit -1;
fi

for service in "${!ServicesWithOkCode[@]}"
	do

	echo "Checking $service ..."

	if [ $(check_website "$service") != "200" ]; then
		echo "$service not ok !";
		setStatus "${ServicesWithOkCode[$service]}" "down"
	else
		setStatus "${ServicesWithOkCode[$service]}" "up"
	fi
done

for service in "${!ServicesWebsocket[@]}"
        do

        echo "Checking $service ..."

        if [ $(check_website "$service/socket.io/") != "400" ]; then
                echo "$service not ok !";
                setStatus "${ServicesWebsocket[$service]}" "down"
        else
                setStatus "${ServicesWebsocket[$service]}" "up"
        fi
done

for node in "${!Nodes[@]}"
        do

        echo "Checking $node ..."
	let httpCode=$(check_website_insecure "$node")
	echo "Http code: $httpCode"

        if [ "$httpCode" != "302" ] && [ "$httpCode" != "404" ]; then
                echo "$node not ok !";
                setStatus "${Nodes[$node]}" "down"
        else
                setStatus "${Nodes[$node]}" "up"
        fi
done

cd "$SCRIPT_DIR"


if [[ `git status --porcelain` ]]; then
	. "$DIR/custom-setup.sh"
	git add status.json
	git commit -m "Automatic monitoring update - $(date)";
	git push -u origin master
fi
