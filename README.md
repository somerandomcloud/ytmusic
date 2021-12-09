# ytmusic
Script I found on r/unixporn. Do not use yet!

Original creator: https://www.reddit.com/user/appypolligies/

Quotes from creator:
i am not very good at this stuff but i wanted something like this for a long while so i made it! and i am putting it out here because i know you guys will be able to do with it more than i ever could.

requires:
yt-dlp (or youtube-dl - you'd have to switch the names)
jq
mpv
ueberzug
fzf

released to public domain. please improve this! some of the problems:

i don't know how to simultaneous play the file with mpv and display the thumbnail with uberzug. i have to ctrl-c the thumbnail/uberzug to get to the music.

if you use multi select but you filter with some characters before, the search is done with what you typed and the fzf selections.

grep complains about backslashes time to time as well as other deficiencies in getting the name of the artists (you will notice in the video the disorder).
some features that would make this great:

some way to display ansii art? or just format all the text and thumbnail very nicely and put them in some sort of decorative box

ability to queue and search for other songs while the program is active as well as some way to remove/rearrange the queue
this is really slow by the way because it gets a big json file, if you just need something quick and functional try these:
pipe-viewer --no-interactive -n -A "$*"
or
mpv --ytdl-format=bestaudio ytdl://ytsearch10:"$*"
(put them in a function in your shell rc)
