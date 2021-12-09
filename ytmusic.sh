#!/bin/sh
# file to dump yt-dlp's json
search_dump_file=/home/mellow/src/ytm/dump
# file to store all the entered searches
all_searches_files=/home/mellow/src/ytm/searches
# file to store names of played files
all_played_titles=/home/mellow/src/ytm/played
# file to store video id, how many times its been played, and whether it's downloaded
all_played_urls=/home/mellow/src/ytm/urls
# file to store the name of all those who contributed
all_played_artists=/home/mellow/src/ytm/artists
# directory to download files to
download_dir=/home/mellow/src/ytm/
# name format of the downloaded files
dl_name_format="$download_dir/%(channel)s.%(title)s.%(id)s.%(ext)s"
# number of times a unique url can be played before it's downloaded
max_play_num=2
# fzf will print the characters you enter to filter the output
# because of --print-query flag even if you tab select after filtering
query="$( cat $all_played_artists $all_played_titles all_searches_files | fzf -m --print-query | tr '\n' ' ' )"
echo "searching for $query"
# if you don't want to search using fzf and would rather pass arguements manually,
# uncomment below and comment the above line
# query="$*"
# add search query to file if non existant
if ! grep -q "$query" $all_searches_files; then
echo "$query" >> $all_searches_files
fi
# the -j flag is used instead of -g for the url because -g returns a direct video url which can't be used to retrieve description, title, etc.
# change ytsearch[n] to however many urls you want to queue
yt-dlp -j ytsearch6:"auto-generated provided to youtube $query" > dump
# search result index (the queue)
q=1
# decorates - draws thumbnail, title, etc
decorator () {
# external bash script that runs ueberzug to display the file - tweak args to fit your screen
# or fiddle with output of tput cols and lines for more universal use
bash /home/mellow/.local/bin/termfilprev "$1" 35 8 100 100
}
# function called to download the files
viddl () {
yt-dlp -f bestaudio -o $dl_name_format --restrict-filenames "https://www.youtube.com/watch?v=$1"
yt-dlp --get-thumbnail "https://www.youtube.com/watch?v=$1" | xargs curl --output "$download_dir/thumbnails/$1.webp"
}
# this is run if a file is marked as downloaded
localsrchandplay () {
file_path=$( ls -d $download_dir/* | grep "$1" )
thumb_path=$( ls -d $download_dir/thumbnails/* | grep "$1" )
decorator "$thumb_path"
mpv "$file_path"
}
# this is run otherwise
streamandplay () {
yt-dlp --get-thumbnail "https://www.youtube.com/watch?v=$id" | xargs curl --output "$download_dir/thumbnails/temp.webp"
# this is a bash script which calls ueberzug
decorator "$download_dir/thumbnails/temp.webp"
mpv --ytdl-format=bestaudio "https://www.youtube.com/watch?v=$1"
}
while true; do
# data gathering
title=$( jq '.title' $search_dump_file | sed "$q"!d )
echo "$q) $title"
desc="$( jq '.description' $search_dump_file | sed $q!d | xargs -0 echo -e | sed -e '/℗/d' -e '1d' -e '$d' )"
dt="$( date +'%d-%m-%y %T' )"
# searching for names of artist which is often separated by a ·
if ( echo "$desc" | grep -q '·' ); then
artist="$( echo "$desc" | grep '·' | sed -e 's/^[^·]*·//g' -e 's/·/\\\n/g' | xargs -0 echo -e )"
echo "$artist" | while read -r f; do
if ! grep -q "$f" $all_played_artists; then
echo "$f" >> $all_played_artists
fi
done
fi
# searching for names of other credits which are often separated by a :
if ( echo "$desc" | grep -q ':' ); then
echo "adding artist names to file"
contrb="$( echo "$desc" | sed -e '/.*:/!d' -e 's/.*://p' | sed -e '/\.com/d' | sort -u )"
echo "$contrb" | while read -r f; do
if ! grep -q "$f" $all_played_artists; then
echo "$f" >> $all_played_artists
fi
done
fi
# add the title to title file if it's new
if ! grep -q "$title" "$all_played_titles"; then
echo "adding song name to file"
echo "$title" >> $all_played_titles
fi
# get id - check if previously added - if not, add to file - if it is, add to counter and check if counter is above the max defined in the max_play_num var - if it is, download
id="$( jq '.id' $search_dump_file | sed -e $q!d -e 's/\"//g' )"
if grep -q "$id" $all_played_urls; then
amnt_played="$( grep $id $all_played_urls | awk '{print $2}' )"
# if the amount played is equal to the max number, download it and add 'dl'
if [ "$amnt_played" -eq "$max_play_num" ]; then
sed -i "/$id/d" $all_played_urls
amnt_played=$((amnt_played + 1))
echo "$id $amnt_played dl $dt" >> $all_played_urls
viddl "$id"
# then call function to search and play it
localsrchandplay "$id"
fi
# else if there is a third field (i.e. it was previously downloaded and now has dl field, play that)
thrd_field=$( grep "$id" $all_played_urls | awk '{print $3}' )
if [ "$thrd_field" = 'dl' ]; then
sed -i "/$id/d" $all_played_urls
amnt_played=$((amnt_played + 1))
echo "$id $amnt_played dl $dt" >> $all_played_urls
localsrchandplay $id
# else the file has been previously played but doesn't equal max play so increase its counter and stream it
else
sed -i "/$id/d" $all_played_urls
amnt_played=$((amnt_played + 1))
echo "$id $amnt_played $dt" >> $all_played_urls
mpv --ytdl-format=bestaudio "https://www.youtube.com/watch?v=$id"
streamandplay $id
fi
# else it's a never registered id, register it
else
echo "new url, adding to file"
echo "$id 1 $dt" >> $all_played_urls
streamandplay $id
fi
q=$((q + 1))
wait
done
