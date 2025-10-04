# Gutentag

Utility to generate browsable list of literature on Project Gutenberg.

## About

Project Gutenberg is an internet-based archive of books that have entered the public domain. It contains over 70,000 books on various topics, both fiction and non-fiction. Consider the overwhelming number of entries, the ability to browse by category is quite useful. When searching through literature, however, the results ended abruptly after a hundred or so pages. This project attempts to address that issue.

Using [Project Gutenberg's offline catalog](https://www.gutenberg.org/ebooks/offline_catalogs.html), this utility scans the metadata for all the books listed and generates a series of web pages that list books that appear to be literature.

This project depends on [dxml](https://github.com/jmdavis/dxml) for parsing XML files. This is fetched automatically by running the build script that comes with the utility.

## Usage

On Linux, run the following commands in the terminal to download, build, and run the utility:

``
    git clone https://github.com/tspike2k/gutentag
    cd gutentag
    ./build.sh
    ./run.sh
``

The resulting webpages will then be in the build/out sub-directory of the project.

## License

Source code is licensed under the [Boost Software License 1.0](https://www.boost.org/LICENSE_1_0.txt).
