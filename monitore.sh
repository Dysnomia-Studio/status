#!/usr/bin/env bash
set -euo pipefail

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. "$DIR/custom-setup.sh"

STATUS_WEBSITE="https://status.dysnomia.studio"

# ==========================
# Services list
# ==========================
declare -A ServicesWithOkCode;
declare -A ServicesWithNotFoundCode;

### Websites/Webservices

# Achieve.games
ServicesWithOkCode["https://achieve.games"]='."Websites / Webservices"."Achieve.games"'

# Achieve.games
ServicesWithOkCode["https://alchemistry-leaderboard.dysnomia.studio/leaderboard/game"]='."Websites / Webservices"."Alchemistry Leaderboard"'

# Dehash.me
ServicesWithOkCode["https://dehash.me"]='."Websites / Webservices"."Dehash.me"'

# Dysnomia
ServicesWithOkCode["https://dysnomia.studio"]='."Websites / Webservices"."Dysnomia"'

# Galactae
ServicesWithOkCode["https://galactae.eu"]='."Websites / Webservices"."Galactae - Website"'
ServicesWithOkCode["https://galactae.com"]='."Websites / Webservices"."Galactae - Website"'
ServicesWithOkCode["https://galactae.space"]='."Websites / Webservices"."Galactae - Website"'

ServicesWithOkCode["https://00-dev.galactae.eu"]='."Websites / Webservices"."Galactae - Dev Client"'
ServicesWithNotFoundCode["https://00-srv.galactae.eu"]='."Websites / Webservices"."Galactae - Dev Server"'

ServicesWithOkCode["https://01-milkyway.galactae.eu"]='."Websites / Webservices"."Galactae - Milkyway Client"'
ServicesWithNotFoundCode["https://01-srv.galactae.eu"]='."Websites / Webservices"."Galactae - Milkyway Server"'

### CDN
ServicesWithOkCode["https://01.cdn.elanis.eu/portfolio/img/Elanis.png"]='."CDN"."Elanis"'
ServicesWithOkCode["https://cdn.galactae.eu"]='."CDN"."Galactae"'

### Services
ServicesWithOkCode["https://bugs.dysnomia.studio"]='."Services"."Bug Tracker"'

### Nodes
declare -A Nodes
Nodes["https://helium.dysnomia.studio"]='."Nodes"."Helium"'
Nodes["https://lithium.dysnomia.studio"]='."Nodes"."Lithium"'
Nodes["https://beryllium.dysnomia.studio"]='."Nodes"."Beryllium"'
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

    curl --resolve "$domainName:443:$ip" --user-agent "Dysnomia-monitoring" -s -o /dev/null -w "%{http_code}" $1
}

check_website_insecure () {
    domainName=$(echo $1 | awk -F[/:] '{print $4}')
    ip=$(dig +short $domainName @1.1.1.1 | tail -n 1)
    curl --resolve "$domainName:443:$ip" --insecure --user-agent "Dysnomia-monitoring" -s -o /dev/null -w "%{http_code}" $1
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

for service in "${!ServicesWithNotFoundCode[@]}"
        do

        echo "Checking $service ..."

        if [ $(check_website "$service") != "404" ]; then
                echo "$service not ok !";
                setStatus "${ServicesWithNotFoundCode[$service]}" "down"
        else
                setStatus "${ServicesWithNotFoundCode[$service]}" "up"
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

git add status.json
git commit -m "Automatic monitoring update - $(date)";
git push -u origin master
