# Memebot made with n8n
you can import this bot to your own n8n by using the json file.
Please change the rss-bridge to your own one.


# old:
## reddit_memebot

The SourceCode behind [@reddit_memebot@mastodon.social](https://mastodon.social/@reddit_memebot)

You can also use it for other SubReddits, as long as they also only use images.
The NSFW check only checks if any tags are given, so you might wanna remove that.

It resizes files, if they are above 8 MB. You need to have FFMPEG installed. If not, some GIFs and Videos might be too big for Mastodon.

it always tries to get alttext from altbot. follow @altbot@fuzzies.wtf for alt text support.
it wont add alt text if altbot takes longer than 2 minutes.
