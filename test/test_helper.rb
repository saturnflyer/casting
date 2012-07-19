require 'cover_me'

CoverMe.config do |c|
  c.project.root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
  c.file_pattern = [/#{CoverMe.config.project.root}\/lib\/.+\.rb/]
end

require 'minitest/spec'
require 'minitest/autorun'