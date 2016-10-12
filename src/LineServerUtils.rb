#
# Utility functions for LineServer.rb
#

def get_http_200(size)
    return "HTTP/1.1 200 OK \r\n"+
            "Content-Type: text/plain\r\n"+
            "Content-Length: #{size}\r\n"+
            "Connection: close\r\n"
end

def get_http_413(message)
    return "HTTP/1.1 413 Request Entity Too Large \r\n"+
            "Content-Type: text/plain\r\n"+
            "Content-Length: #{message.size}\r\n"+
            "Connection: close\r\n"
end

def isNumber(item)
    return (item.class == Fixnum ||
    item.class == Integer ||
    item.class == Float ||
    item.to_f.to_s == item ||
    item.to_i.to_s == item)
end

def file_size(size)
    size = size.to_f
    units = 'Bytes'
    if size > 1024
        size /= 1024
        units = 'KB'
    end
    if size > 1024
        size /= 1024
        units = 'MB'
    end
    if size > 1024
        size /= 1024
        units = 'GB'
    end
    return "#{'%.1f' % size} #{units}"
end
