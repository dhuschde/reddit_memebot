#!/bin/bash
mkdir /tmp/memes

# Fetch the RSS feed and save it to a file
curl -H 'User-Agent: Mozilla/5.0' "https://dhusch.de/rss-bridge/?action=display&bridge=RedditBridge&context=single&r=memes&f=&score=&d=hot&search=&format=Json" > /tmp/memes/memes.json


# read the JSON file into a variable
json=$(cat /tmp/memes/memes.json)

# extract the first item
item=$(echo "$json" | jq '.items[0]')

# extract the title and URL
title=$(echo "$item" | jq -r '.title')
url=$(echo "$item" | jq -r '.url')
tags=$(echo "$item" | jq -r '.tags')

# extract the image URL from the content_html
content_html=$(echo "$item" | jq -r '.content_html')
image_url=$(echo "$content_html" | grep -oP '(?<=src=")[^"]+(?=")')

filename=$(basename "$image_url")     # Extract the filename from the URL
wget "$image_url" -N -P /tmp/memes/    # Download the image and save to the output file

# Mastodon instance URL and access token
INSTANCE_URL="https://botsin.space"
ACCESS_TOKEN="my_bot_token"

# Image to upload
IMAGE_PATH="/tmp/memes/$filename"

# Upload the image and get the media ID
MEDIA_ID=$(curl -X POST -H "Authorization: Bearer $ACCESS_TOKEN" \
             -F "file=@$IMAGE_PATH" \
             "$INSTANCE_URL/api/v1/media" \
             | jq -r '.id')



if [ "$tags" = "null" ]; then
# Post the status with the image
curl -X POST -H "Authorization: Bearer $ACCESS_TOKEN" \
     -F "status=$title

($url)" \
     -F "media_ids[]=$MEDIA_ID" \
     "$INSTANCE_URL/api/v1/statuses"
else
# Post the status with the image and make it NSFW
curl -X POST -H "Authorization: Bearer $ACCESS_TOKEN" \
     -F "status=$title 

($url)" \
     -F "spoiler_text=NSFW Meme" \
     -F "media_ids[]=$MEDIA_ID" \
     "$INSTANCE_URL/api/v1/statuses"
fi
