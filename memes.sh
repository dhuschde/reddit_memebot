#!/bin/bash

# Please fill out!
INSTANCE_URL="https://botsin.space" # Mastodon Instance
ACCESS_TOKEN="my_bot_token" # Mastodon Access Token
SUBREDDIT="memes" # Subreddit (must be Image Only, like r/memes)


mkdir /tmp/reddit_bot # Make a Temp Directory

# Fetch the JSON feed and save it to a file
curl -H 'User-Agent: Mozilla/5.0' "https://dhusch.de/rss-bridge/?action=display&bridge=RedditBridge&context=single&r=$SUBREDDIT&f=&score=&d=hot&search=&format=Json" > /tmp/reddit_bot/$SUBREDDIT.json

# read the JSON file into a variable
json=$(cat /tmp/reddit_bot/$SUBREDDIT.json)

# extract the first item
item=$(echo "$json" | jq '.items[0]')

# extract the title and URL
title=$(echo "$item" | jq -r '.title')
url=$(echo "$item" | jq -r '.url')

tags=$(echo "$item" | jq -r '.tags') # Needed for NSFW check

# extract the image URL from the content_html
content_html=$(echo "$item" | jq -r '.content_html')
image_url=$(echo "$content_html" | grep -oP '(?<=src=")[^"]+(?=")')

filename=$(basename "$image_url")     # Extract the filename from the URL
wget "$image_url" -N -P /tmp/reddit_bot/    # Download the image and save to the output file

# Upload the image and get the media ID
MEDIA_ID=$(curl -X POST -H "Authorization: Bearer $ACCESS_TOKEN" \
             -F "file=@/tmp/reddit_bot/$filename" \
             "$INSTANCE_URL/api/v1/media" \
             | jq -r '.id')

if [ "$tags" = "null" ]; then # Check if the Post is NSFW

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

rm -r /tmp/reddit_bot # Remove the Temp Directory
