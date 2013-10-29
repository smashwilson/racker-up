# accept a directory and a container name as arguments.
# upload the contents of the specified container (creating it if it doesn't exist).
# handle errors appropriately.

require 'optparse'
require_relative 'boilerplate'

directory, container_name = nil, nil
opts = OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} -d directory/ -c container"

  opts.on('-d', '--directory DIRNAME', 'Upload the contents of a directory.') do |d|
    directory = d
  end

  opts.on('-c', '--container CONTNAME', 'Cloud Files container to upload.') do |c|
    container_name = c
  end

  opts.on('-h', '--help', "You're looking at it.") do
    puts opts
    exit 0
  end
end

opts.parse! ARGV

unless directory && container_name
  puts opts
  exit 1
end

service = log_me_in Fog::Storage

step "validating your arguments."

raise "Directory #{directory} doesn't exist!" unless File.exist? directory
raise "Path #{directory} isn't a directory!" unless File.directory? directory

step "verifying that the container exists."

container = service.directories.get container_name
if container.nil?
  step ".. creating container."
  container = service.directories.create key: container_name
else
  step ".. container already exists."
end

step "uploading files from the specified directory."
Dir["#{directory}/*"].each do |path|
  next if File.directory? path
  step ".. uploading #{path}"
  container.files.create key: File.basename(path), body: File.open(path, 'r')
end

step "complete."
