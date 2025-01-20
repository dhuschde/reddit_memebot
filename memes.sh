#!/bin/bash

# Please fill out!
INSTANCE_URL="https://mastodon.social" # Mastodon Instance
ACCESS_TOKEN="my_bot_token" # Mastodon Access Token
SUBREDDIT="memes" # Subreddit (must be Image Only, like r/memes)

# Fetch the JSON feed
json=$(curl -H 'User-Agent: Mozilla/5.0' "https://bridge.easter.fr/?action=display&bridge=RedditBridge&context=single&r=$SUBREDDIT&f=&score=&d=hot&search=&format=Json" 2>/dev/null)

# extract the first item
item=$(echo "$json" | jq '.items[0]')

# extract the title and URL
title=$(echo "$item" | jq -r '.title')
url=$(echo "$item" | jq -r '.url')

if [ "$url" == "null" ] || [ -z "$url" ]; then # Make sure there is no null posting. Happens when RSS-Bridge gets no Content from Reddit
exit 1
INSTANCE_URL="https://failed.dhusch.de" # am not sure if the exit actually works. But don't want the Bot to do anything.
fi

tags=$(echo "$item" | jq -r '.tags') # Needed for NSFW check

# extract the image URL from the content_html
content_html=$(echo "$item" | jq -r '.content_html')
image_url=$(echo "$content_html" | grep -oP '(?<=src=")[^"]+(?=")')

filename=$(basename "$image_url")     # Extract the filename from the URL
wget "$image_url" -N -P /tmp/    # Download the image and save to the output file

# Resize Files larger that 8 MB
if [ $(du -m /tmp/$filename | awk '{print $1}') -gt 8 ]; then # Check if the file size is greater than 8 MB
    ffmpeg -i /tmp/$filename -fs 8M /tmp/ff.$filename # Resize the file to 8 MB using FFMPEG (needs to be installed)
    mv /tmp/ff.$filename /tmp/$filename
fi

# Upload the image and get the media ID
MEDIA_ID=$(curl -X POST -H "Authorization: Bearer $ACCESS_TOKEN" \
             -F "file=@/tmp/$filename" \
             "$INSTANCE_URL/api/v1/media" \
             | jq -r '.id')

if [ "$tags" = "null" ]; then # Check if the Post is NSFW

# Post the status with the image
status=$(curl -X POST -H "Authorization: Bearer $ACCESS_TOKEN" \
     -F "status=$title

($url) #SFW" \
     -F "media_ids[]=$MEDIA_ID" \
     "$INSTANCE_URL/api/v1/statuses")
else

# Post the status with the image and make it NSFW
status=$(curl -X POST -H "Authorization: Bearer $ACCESS_TOKEN" \
     -F "status=$title

($url) #NSFW" \
     -F "sensitive=true" \
     -F "media_ids[]=$MEDIA_ID" \
     "$INSTANCE_URL/api/v1/statuses")
fi

rm /tmp/$filename # Delete the Image

# Now getting alt text from altbot. | this is temporary until i finally figure stuff out.
echo "Waiting two minutes to let altbot have time to respond"
sleep 120
status=$(echo $status | jq -r '.id')

alt=$(curl -X GET "https://mastodon.social/api/v1/statuses/$status/context")
alt=$(echo $alt | jq '.descendants[] | select(.account.acct == "altbot@fuzzies.wtf" and (.content | contains("generated using Gemini"))) | .content' | head -n 1)
alt=$(echo "$alt" | sed -e 's/<p>/\n/g' -e 's/<\/p>/\n/g' -e 's/<[^>]*>//g' -e 's/@reddit_memebot//')
alt=$(echo "$alt" | sed 's/  */ /g' | sed 's/^ //;s/ $//')
alt=$(echo "$alt" | sed 's/^"//;s/"$//')
alt=$(echo "$alt" | sed 's/\\"/"/g')
alt=$(printf '%q' "$alt")

# Step 1: Replace newlines with a placeholder
alt=$(echo "$alt" | sed ':a;N;$!ba;s/\n/PLACEHOLDER_NEWLINE/g')

# Step 2: Escape the string using jq
alt=$(jq -Rn --arg alt "$alt" '$alt')

# Step 3: Restore newlines
alt=$(echo "$alt" | sed 's/PLACEHOLDER_NEWLINE/\n/g')

echo "Adding alt Text"
echo $alt

if [ -n "$alt" ]; then
# bad: using the same code twice
			if [ "$tags" = "null" ]; then # Check if the Post is NSFW

			# Post the status with the image
			status_edit=$(curl -X PUT -H "Authorization: Bearer $ACCESS_TOKEN" \
			     -F "status=$title

($url) #SFW" \
			     -F "media_ids[]=$MEDIA_ID" \
			     -F "media_attributes[][id]=$MEDIA_ID" \
			     -F "media_attributes[][description]=$alt" \
			     "$INSTANCE_URL/api/v1/statuses/$status")
			else

			# Post the status with the image and make it NSFW
			status_edit=$(curl -X PUT -H "Authorization: Bearer $ACCESS_TOKEN" \
			     -F "status=$title

($url) #NSFW" \
			     -F "sensitive=true" \
			     -F "media_ids[]=$MEDIA_ID" \
			     -F "media_attributes[][id]=$MEDIA_ID" \
			     -F "media_attributes[][description]=$alt" \
			     "$INSTANCE_URL/api/v1/statuses/$status")
			fi




     


else

echo "There is no alt text, not editing the post"

fi

echo $status_edit
