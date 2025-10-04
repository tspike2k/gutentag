import std.stdio;
import std.algorithm;
import std.conv;
import std.string;

import dxml.parser;
import core.sys.linux.unistd;
import core.sys.linux.fcntl;
import core.sys.posix.sys.stat;
import core.stdc.stdlib;

enum Max_Book_ID = 75165;

// TODO: 11480 has a meta file but it isn't found. Why not?

// TODO: Rather than free/malloc, we could pass a fixed buffer and allocate only once.
char[] read_file_into_memory(const(char)[] file_name){
    char[] result;

    auto file = open(file_name.ptr, O_RDONLY);
    if(file != -1){
        stat_t s;
        fstat(file, &s);
        auto memory = calloc(1, s.st_size);
        result = cast(char[])memory[0 .. s.st_size];
        read(file, result.ptr, result.length); // TODO: Read in a loop, just in case!
        close(file);
    }
    else{
        write("Unable to open file " ~ file_name);
    }

    return result;
}

alias String = const(char)[];

String strip_preps(String s){
    auto result = s;
    if(startsWith(s, "A ")){
        result = s[2..$];
    }
    else if(startsWith(s, "An ")){
        result = s[3..$];
    }
    else if(startsWith(s, "The ")){
        result = s[4..$];
    }
    return result;
}

struct Book_Meta{
    ulong id;
    String title;
    String author;
    String summary;
    String url;
    bool is_english;
    bool is_text;
    bool is_literature;

    int opCmp(ref Book_Meta other){
        int result = 0;
        auto a = toLower(strip_preps(title));
        auto b = toLower(strip_preps(other.title));
        if (a < b){
            result = -1;
        }
        else if(a > b){
            result = 1;
        }
        return result;
    }
}

String get_element_text(alias range)(){
    auto sub = range.front();
    range.popFront();
    auto result = sub.text;
    return result;
}

String extract_value_from_descriptor_block(alias range)(){
    assert(range.front.type == EntityType.elementStart);
    assert(startsWith(range.front.name, "rdf:Description"));
    String result;
    while(!(range.front.type == EntityType.elementEnd && startsWith(range.front.name, "rdf:Description"))){
        if(startsWith(range.front.name, "rdf:value")){
            range.popFront();
            result = range.front.text;
            break;
        }
        range.popFront();
    }

    assert(result);
    return result;
}

char[] read_book_into_memory(String book_id_str){
    auto source_file_name = "./build/rdf-files/cache/epub/" ~ book_id_str ~ "/pg" ~ book_id_str ~ ".rdf\0";
    auto result = read_file_into_memory(source_file_name);
    return result;
}

Book_Meta get_book_meta(ulong file_index, String index_str, const(char)[] source){
    auto range = parseXML!simpleXML(source);

    Book_Meta result;
    result.id = file_index;
    while(!range.empty){
        auto element = range.front();
        range.popFront();

        if(element.type == EntityType.elementStart){
             if(endsWith(element.name, "name")){
                result.author = get_element_text!(range).dup;
             }
             else if(endsWith(element.name, "title")){
                result.title = get_element_text!(range).dup;
             }
             else if(endsWith(element.name, "marc520")){
                result.summary = get_element_text!(range).dup;
             }
             else if(endsWith(element.name, "bookshelf")){
                auto value = extract_value_from_descriptor_block!(range);
                if(indexOf(value, "Literature") != -1
                || indexOf(value, "Fiction") != -1
                || indexOf(value, "Novel") != -1){
                    result.is_literature = true;
                }
             }
             else if(endsWith(element.name, "language")){
                auto value = extract_value_from_descriptor_block!(range);
                if(value == "en"){
                    result.is_english = true;
                }
             }
             else if(endsWith(element.name, "type")){
                auto value = extract_value_from_descriptor_block!(range);
                if(value == "Text"){
                    result.is_text = true;
                }
             }
        }
    }

    result.url = "https://www.gutenberg.org/ebooks/" ~ index_str;
    return result;
}

enum Page_Start =
`<!DOCTYPE html>
<html lang="en_US">
<head>
</head>
<body>
<body>`;

enum Page_End = `
</html>
`;

void main(){
    Book_Meta[] entries;

    auto t = read_book_into_memory(to!string(11480));
    assert(t.length > 0);

    foreach(book_id; 1 .. Max_Book_ID){
        auto book_id_str = to!string(book_id);

        auto source = read_book_into_memory(book_id_str);
        scope(exit) free(source.ptr);
        if(source.length > 0){
            auto book = get_book_meta(book_id, book_id_str, source);
            if(book.is_english && book.is_text){
                if(book.is_literature){
                    entries ~= book;
                }
                else{
                   writeln(format("%*d", 4, book_id) ~ ` Not literature: "` ~ book.title ~ `"`);
                }
            }
        }
        else{
            writeln("Missing meta file.");
        }
    }
    sort(entries);

    auto books_per_file = 12;
    auto reader = entries;
    auto file_number = 0;
    while(reader.length > 0){
        auto reader_advance = min(books_per_file, reader.length);
        auto to_write = reader[0 .. reader_advance];
        reader = reader[reader_advance .. $];

        auto dest_name = "./build/out/page" ~ to!string(file_number) ~ ".html";
        auto dest = File(dest_name, "w");
        dest.write(Page_Start);
        foreach(book; to_write){
            auto id_string = to!string(book.id);
            dest.write("<h1>" ~ book.title ~ "</h1>" ~ "\n");
            dest.write(`<img src="https://www.gutenberg.org/cache/epub/` ~ id_string ~ `/pg` ~ id_string ~ `.cover.medium.jpg"/>` ~ "\n");
            dest.write("<p>Author: " ~ book.author ~ "</p>" ~ "\n");
            dest.write("<p>Summary: " ~ book.summary ~ "</p>" ~ "\n");
            dest.write(`<a href="` ~ book.url ~ `">Web page</a>` ~ "\n");
        }

        dest.write("<hr/>\n");
        if(file_number > 0){
            dest.write(`<a href="page` ~ to!string(file_number-1) ~ `.html">Prev</a>` ~ "\n");
        }
        dest.write("<span></span>\n");
        if(file_number < entries.length/books_per_file){
           dest.write(`<a href="page` ~ to!string(file_number+1) ~ `.html">Next</a>` ~ "\n");
        }

        dest.write(Page_End);
        file_number++;
    }

    version(none) foreach(ref entry; entries){
        writeln(entry.title);
    }
}
