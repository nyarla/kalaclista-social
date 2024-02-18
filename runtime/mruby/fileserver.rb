#!/usr/bin/env ruby

BASEDIR = "/data/media"
BASEDIR_RE = Regexp.compile("^/data/media")

def try_file(path)
  realpath = File.expand_path(path, BASEDIR)
  if realpath =~ BASEDIR_RE
    return realpath
  end

  return ""
end

def mime_type(ext)
  case ext
  when ".gif"
    return "image/gif"
  when ".jpeg"
    return "image/jpeg"
  when ".jpg"
    return "image/jpg"
  when ".mp3"
    return "audio/mp3"
  when ".mp4"
    return "video/mp4"
  when ".png"
    return "image/png"
  when ".webp"
    return "image/webp"
  end

  return "application/octet-stream"
end

lambda do |env|
  path = try_file(BASEDIR + "/" + env['PATH_INFO']);
  if path == ""
    return [ 399, {}, [] ]
  end

  if File.exist?(path)
    fh = File.new(path)
    type = mime_type(File.extname(path))

    return [ 200, { "Content-Type" => type, 'Content-Length' => fh.size }, fh ]
  end

  return [ 399, {}, [] ]
end
