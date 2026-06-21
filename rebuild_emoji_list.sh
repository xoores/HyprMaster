#!/bin/bash

# You need following file - we are using emoji list used in Mattermost:
# https://raw.githubusercontent.com/mattermost/mattermost/refs/heads/master/webapp/channels/src/utils/emoji.json


if [[ ${#} -ne 1 || ! -f "${1}" ]]; then
    echo "USAGE: ${0} <EMOJI.JSON>"
    echo
    echo "First download latest emoji.json file from Mattermost repository [1] and then"
    echo "run this script and point it to that file. It will output new dictionary to"
    echo "config/Emoji.js"
    echo
    echo "[1]: https://raw.githubusercontent.com/mattermost/mattermost/refs/heads/master/webapp/channels/src/utils/emoji.json"
    echo
    exit 1
fi


echo "const EDICT = [" > config/Emoji.js
while read -r LINE; do
    UTF=$(cut -d'|' -f1 <<<"${LINE}")
    ALIAS=$(cut -d'|' -f2 <<<"${LINE}")
    EMOJI_UTF="$(printf "\U${UTF//\-/\\U}" )"
    echo -e "{ emoji:\"${EMOJI_UTF}\", \talias: [\"${ALIAS//,/\",\"}\"] }," >> config/Emoji.js
done < <(cat "${1}" |\
            jq -r '.[] | .unified + "|" + (.short_names | join(",") )' |\
            grep -v "skin.tone")

echo "]" >> config/Emoji.js