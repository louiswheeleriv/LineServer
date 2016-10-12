# LineServer
A simple ruby server which accepts requests for lines from a text file

### Setup
Clone the git repo using  
`git clone https://github.com/louiswheeleriv/LineServer.git`  
`cd LineServer`  

Run build script to install dependencies:  
`./bin/build.sh` (NOTE: This assumes you have ruby and gem installed)

If you don't have test data, create some with this script:  
`./bin/createTextFile <num lines> <num words per line> <file path to create>`  

Run the server with default settings like so:  
`./bin/run.sh <file to serve>`  

Or run it with extra settings:  
`ruby LineServer.rb <file to serve> <port number> <cache size>`  

Send requests to the server via a web browser, the curl command, or using  
one or more instances of the provided script which repeatedly makes requests:  
`./bin/callServer.sh <max index to request> <port number>`  

### How it works
This program creates a simple multi-threaded TCP server in ruby which reads  
lines from a text file and serves them to clients via a simple REST API.  

Because the text file could be arbitrarily large (and thus bigger than RAM),  
the entire text file can't necessarily be read into memory and stored in an  
array.  This means, in order to prevent spooling to disk and intractably long  
load times, we can only load a certain number of lines into memory at a time.  

The data structure I've decided to use for this is an LRU (least recently used)  
cache.  When the program starts, it reads in $CACHE_SIZE lines from the text file  
into the cache.  When a request comes in, if the line is present in the cache, we  
simply return the line.  If a line is requested which isn't in the cache, we read  
the line from the text file (from disk, expensive), place it in the cache, remove the  
least recently used item in the cache, and return the requested line.

### Size considerations
This server performs well for text files under about 5 GB.  I've tested it with  
text files up to about 12 GB with 40 million lines.  The biggest issue this server  
runs into at large file sizes is due to the method it uses to read a particular line  
from the file.  Because the whole file can't be read into memory at once, it needs  
to be iterated over as an Enumerable object, meaning we can't just grab a particular  
index (i.e. line number) like we could from an array.  This means we have to step  
through the Enum until we get to the desired line number.

One solution I thought of to tackle this issue would be, when searching for a particular  
line, to read the file starting at a particular byte offset, then seek to the desired  
line.  The problem with this approach however is there is not guarantee that all lines  
are the same size.  Therefore starting at a 50% byte offset to look for a line 60% of  
the way through the file could actually start looking after the occurrance of the line  
if the second half of the file has longer lines than the first.

### Multiple users
The server can handle multiple concurrent users, as it creates a new thread to handle  
an incoming request when it's already dealing with one.  I tested the server's  
handling of multiple connections by running multiple instances of the included  
callServer script like so:  

`./bin/callServer <max index to request> <port number>`  

This script repeatedly sends requests to the server for a random index from 0 to the  
maximum defined index.  The server was able to handle multiple requests concurrently.  
This is visible when the server prints to the terminal that it's retrieving a particular  
index, then prints that it's handling a new request before it prints the result of the  
first retrieval.

One possible problem with this server is that it creates a new thread any time a request  
comes in, and does not decide at any point to prioritize a request that it may already  
be servicing.  A solution to this could be to create a maximum number of requests to  
process at a time, and if another request comes in, place it in a queue.  This would  
ensure that requests which came first get preferential treatment, and prevent them from  
experiencing unnecessarily long load times.

### References
In my research for this project, I used the following sources:  

- https://practicingruby.com/articles/implementing-an-http-file-server  
- http://stackoverflow.com/questions/25189262/why-is-slurping-a-file-bad  
- http://blog.honeybadger.io/using-lazy-enumerators-to-work-with-large-files-in-ruby/  

### Third party resources
I used the following github project by SamSaffron as an implementation of an LRU cache  

- https://github.com/SamSaffron/lru_redux  

I also used the following blog post for my test data generation script

- http://www.skorks.com/2010/03/how-to-quickly-generate-a-large-file-on-the-command-line-with-linux/  

### Improvements
I spent about 12 hours on this project between research, coding, and writing this document.  
Given an unlimited amount of extra time to improve this project, I would do the following  
(in priority order):

1. Use a database to store the contents of the text file  

  * I found this to be an interesting challenge, as I was told from the beginning that  
    the obvious simplest solution was to just insert the text file into a database and serve lines  
    from that, and that I should go for a different solution.  

  * I feel that if I had made the decision to use a database to store the contents of the  
    text file, it would be much more efficient.  The initial time taken to load the lines  
    into the database would be a one time cost, and it would make reading a single line  
    much, much faster than having to read the file in and step through a ruby Enumerable.  

2. Implement a prioritization algorithm for incoming requests  

  * Even with the retrieval time improvement achieved by using a database, it's possible  
    that with a large enough number of users, this server wouldn't have enough resources  
    to efficiently respond to all requests as soon as they come in.  

  * Aside from running multiple instances of this server on different machines, one improvement  
    could be to prioritize requests by creating a fixed upper limit for the number of requests  
    to be served simultaneously.  This limit could be determined by measuring the performance  
    of the server as the number of simultaneous clients is increased.  When a client connects  
    and the server is already handling the max number of requests, the client would be  
    placed in a queue to ensure the clients who have been waiting are served first, rather  
    than treating a new client with the same priority as one who has been waiting.  
