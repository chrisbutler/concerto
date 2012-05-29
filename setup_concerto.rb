#!/usr/bin/env ruby
#A script for bootstrapping Concerto so the installation scripts can do their work
#Parameters: 
  #concerto_location
  #concerto_hostname
  #rails_mode
  #webserver_type
  #database_type

def main
  parse_options()
  
  #Retrieve Concerto source/zip from Github 
  if command?("git")
    puts "Cloning Git repository..."
    system("git clone git://github.com/concerto/concerto.git #{$concerto_location}")
  else
    puts "Git executable not found!"
    exit
  end
  
  Dir.chdir($concerto_location) do
    #Install gems
    puts "Installing Gems..."
    system("bundle install --path vendor/bundle;")
    
    if $database_type.nil?
      #Copy over default database.yml for dong default sqlite
      system("cp config/database.yml.sample config/database.yml")
    end
    
    #Migrate database and install seed data
    puts "Migrating Database and Installing Seed Data..."
    system("rake db:migrate; rake db:seed")
  end
  
  #Create Apache VHost entry with interpolated values
  vhost_entry = %{<VirtualHost *:80>
    ServerName #{$concerto_hostname}
    DocumentRoot "#{$concerto_location}"
    RailsEnv #{$rails_mode}
    <Directory "#{$concerto_location}">
      Order allow,deny
      Allow from all
    </Directory>
  </VirtualHost>}
  puts "Please add the following to your Apache configuration file and restart Apache...\n\n"
  puts vhost_entry

end

#Parse command line options with some Ruby magicks
def parse_options
  require 'optparse'
  OptionParser.new do |o|
    o.on("-m rails_mode") { |m| $rails_mode = m }
    o.on("-m database_type") { |d| $database_type = d }
    o.on("-n concerto_hostname") { |n| $concerto_hostname = n }
    o.on("-w webserver_type") { |w| $webserver_type = w }
    o.on('-l concerto_location') { |location| $concerto_location = location }
    o.on("-h", "--help", "Show this message") { puts o; exit }
    o.parse!
  end
  
  if $concerto_location.nil?
    puts "Please specify the location to deploy Concerto to (-l option)"
    exit  
  end
end

#Check for existence of a command for use (and send the output to the bitbucket)
def command?(command)
  system("which #{ command} > /dev/null 2>&1")
end

main()