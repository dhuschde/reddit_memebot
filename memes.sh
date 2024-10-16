#!/bin/bash

# Please fill out!
INSTANCE_URL="https://botsin.space" # Mastodon Instance
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

ffmpeg -i /tmp/$filename /tmp/meme.gen.png

alt=$(ollama run llava "Describe the meme. do not use more than 1000 characters /tmp/meme.gen.png")
ollama stop llava
alt=$(echo $alt | sed 's/"//g' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
echo $alt
rm /tmp/meme.gen.png

# Upload the image and get the media ID
MEDIA_ID=$(curl -X POST -H "Authorization: Bearer $ACCESS_TOKEN" \
             -F "file=@/tmp/$filename" \
             -F "description=AI generated Alt Text: $alt" \
             "$INSTANCE_URL/api/v1/media" \
             | jq -r '.id')

if [ "$tags" = "null" ]; then # Check if the Post is NSFW

# Post the status with the image
curl -X POST -H "Authorization: Bearer $ACCESS_TOKEN" \
     -F "status=$title

($url) #SFW" \
     -F "media_ids[]=$MEDIA_ID" \
     "$INSTANCE_URL/api/v1/statuses"
else

# Post the status with the image and make it NSFW
curl -X POST -H "Authorization: Bearer $ACCESS_TOKEN" \
     -F "status=$title

($url) #NSFW" \
     -F "sensitive=true" \
     -F "media_ids[]=$MEDIA_ID" \
     "$INSTANCE_URL/api/v1/statuses"
fi

rm /tmp/$filename # Delete the Image
