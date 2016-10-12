require 'socket'
require 'lru_redux'
require_relative 'src/LineServerUtils'

$fileName = (!ARGV[0].nil?) ? ARGV[0] : 'public/file.txt'
$portNumber = (!ARGV[1].nil?) ? ARGV[1].to_i : 3000
$CACHE_SIZE = (!ARGV[2].nil?) ? ARGV[2].to_i : 5000

puts "Using file: #{$fileName}"
puts "Using port: #{$portNumber}"
puts "Using cache size: #{$CACHE_SIZE}\n"

puts "Loading file..."
$cache = LruRedux::ThreadSafeCache.new($CACHE_SIZE)

t1 = Time.now
$numLinesInFile = `wc -l "#{$fileName}"`.strip.split(' ')[0].to_i
puts "File is #{$numLinesInFile} lines (#{'%.2f' % (Time.now-t1)} sec)"

t2 = Time.now
index = 0
$fileEnum = File.foreach($fileName)

$fileEnum.each do |line|
    $cache[index] = line
    index += 1
    if $cache.to_a.size >= $CACHE_SIZE
        break
    end
end

puts "SUCCESS: Read first #{$cache.to_a.size} lines into cache (#{'%.2f' % (Time.now-t2)} sec)"

# Retrieve a particular line from the file
def read_line_from_file(index)
    line = $fileEnum.each.tap{|enum| index.times{enum.next}}.next
    $fileEnum.rewind
    return line
end

# Get the requested line index
def get_requested_index(req)
    # Format is:
    # GET /lines/<index>
    reqPath = req.split(" ")[1]
    reqIndex = reqPath.split('/')[-1]
    return (isNumber(reqIndex) ? reqIndex.to_i : -1)
end

# Get the requested line if index is valid
def get_line_at_index(index)
    if index < 0
        puts "NEGATIVE INDEX"
        return nil
    elsif index >= $numLinesInFile
        puts "INDEX OUT OF BOUNDS"
        return nil
    else
        # index is valid, check if in cache
        result = $cache[index]
        if !result.nil?
            puts "CACHE HIT, RETURNING"
            return result
        else
            puts "CACHE MISS, RETRIEVING"
            t1 = Time.now
            $cache[index] = read_line_from_file(index)
            puts "READ LINE #{index} IN #{'%.2f' % (Time.now-t1)} seconds"
            return $cache[index]
        end
    end
end

server = TCPServer.new('localhost', $portNumber)
puts "\nServer listening at port #{$portNumber}..."

loop do
    # Accept requests
    Thread.fork(server.accept) do |client|
        req = client.gets
        if (req =~ /favicon/).nil?
            puts "\n#{client.addr}"
            puts "#{req}"

            # Get requested line
            line = get_line_at_index(get_requested_index(req))

            # Return the response
            if !line.nil?
                # Return line
                client.print get_http_200 line.size
                client.print "\r\n"
                client.print line
            else
                # Bad index, return HTTP 413
                message = "Invalid index requested"
                client.print get_http_413 message
                client.print "\r\n"
                client.print message
            end
            client.close
        end
    end
end
