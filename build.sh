#!/bin/bash

mkdir -p ./build
mkdir -p ./build/out
mkdir -p ./build/rdf-files

# Get dxml, the XML parsing library this application depends upon.
git clone --branch v0.4.5 --single-branch https://github.com/jmdavis/dxml

# Download the the Project Gutenberg XML offline catalog if we haven't already.
wget -nc -O "./build/rdf-files.tar.bz2" "https://www.gutenberg.org/cache/epub/feeds/rdf-files.tar.bz2"

# Only extract the Project Gutenberg XML offline catalog if we haven't already. It's big!
if [ ! -d ./build/rdf-files/cache ]; then
    tar -xjf build/rdf-files.tar.bz2 -C ./build/rdf-files/;
fi

# Build the application.
dmd -of=./build/gutentag.bin ./src/gutentag.d ./dxml/source/dxml/*.d
