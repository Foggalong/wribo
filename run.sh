#!/bin/bash

# CONFIG

# Daily word goal
wordgoal=500

# Storage location
savefold="/home/josh/Nextcloud/Documents/Writing/Daily/"

# How many prompt skips to allow
skips=2


# SETUP

# Verifies if 'wget' is installed
if ! type "wget" >> /dev/null 2>&1; then
    echo -e \
        "$0: This tool requires 'wget' to be installed\n" \
        "\rto fetch the prompts from r/WritingPrompts.\n" \
        "\rPlease install it and rerun this script."
    exit
fi

# Verifies if 'vim' is installed
if ! type "vim" >> /dev/null 2>&1; then
    echo -e \
        "$0: This tool requires 'vim' to be installed\n" \
        "\rsince it is used as the document editor.\n" \
        "\rPlease install it and rerun this script."
    exit
fi

# Verifies if 'aspell' is installed
if ! type "aspell" >> /dev/null 2>&1; then
    echo -e \
        "$0: This tool requires 'aspell' to be installed\n" \
        "\rsince it uses it to run a spellcheck at the end..\n" \
        "\rPlease install it and rerun this script."
    exit
fi

# Checks for having internet access
if wget -q --spider https://reddit.com; then
    : # pass
else
    echo -e \
        "No internet connection available. This script\n" \
        "\rrequires internet access to connect to Reddit\n" \
        "\rto download the latest prompts."
    exit    
fi


# PROMPT SELECTION

# Download frontpage of r/WritingPrompts
wget -q "https://www.reddit.com/r/WritingPrompts/top/.rss" -O page

# Change up file data
sed -i "s/>/\n/g" page
sed -i "s/<\/title//g" page

# Iterate over lines in file to find prompts
while [ -s page ]; do

    # If first line is a writing prompt
    if [[ "$(head -n 1 page)" == "[WP] "* ]]; then
        
        # Print the prompt
        prompt=$(head -n 1 page | sed -e "s/\[WP\]\ //g")
        echo -e "\n\nPrompt $((3-skips))"
        echo -e "--------"
        echo -e "$prompt\n"

        if [[ $skips == 0 ]]; then
            read -r -p "Ran out of skips, you must use this prompt!"
            echo -e "Prompt: $prompt\n\n" >> doc
            rm page
        else
            while true; do
                read -r -p "Do you want to use this prompt? " answer
                case $answer in
                    [Yy]* ) echo -e "Prompt: $prompt\n\n" >> doc; rm page; break;;
                    [Nn]* ) skips=$((skips-1)); break;;
                    * ) echo "Please answer [Y]es or [N]o.";;
                esac
            done
        fi    
    fi
    
    # Remove line from file
    touch page
    sed -i '1d' page
done


# WRITING

while true; do
    # Open doc in vim
    vim doc +3 -c ":set syntax=markdown"
    
    # Calculate wordcount
    cp doc prose
    sed -i '1,2d' prose
    wordcount=$(wc -w prose | sed -e "s/\ prose//")
    
    if [ "$wordcount" -lt "$wordgoal" ]; then
        read -r -p "Not enough words! Need $((500-wordcount)) more."
    else
        echo "Writing complete!"
        break
    fi
    rm prose
done


# CLEAN UP

aspell check doc
mv -i doc "$savefold$(date +"%Y-%m-%d.md")"
rm page prose .doc.swp doc.bak 2> /dev/null 
