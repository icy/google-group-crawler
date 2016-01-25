#GoogleGroupCrawler
for documentation please refer https://github.com/icy/google-group-crawler.git

I have added a piece of code that lets you download only limted messages from a group
before the mdoule that downloads raw messages from the msgs folder.
#Usage
I have used Group name CodeWar

export _GROUP="CodeWar"


and downloaded only two topic that were dicussed more
by using the command 


wc -l *.* | sort -r | head -2


Now top most discussed posts get downloaded.
