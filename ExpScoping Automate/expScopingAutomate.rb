#require './connect.rb'
require 'openwfe/util/scheduler'
require 'rubygems'
require 'logger'
require 'rexml/document'
require './automaton.rb'
include OpenWFE
#require './rally_query.rb'
def setup_logger(doc) 
	puts "Setting up logger"
	logtext = doc.elements['/pfs-scoping-automate/service/log-level'].text.strip
	logfile = doc.elements['/pfs-scoping-automate/service/log-file'].text.strip
	
	log = Logger.new(logfile,'daily')
	
	log.level = case logtext
		when "INFO" then Logger::INFO
		when "DEBUG" then Logger::DEBUG
		when "WARN" then Logger::WARN
		when "ERROR" then Logger::ERROR
		when "FATAL" then Logger::FATAL
		else Logger::INFO
	end
	
	return log	
end

def process(doc,filename)

	
		@child_array = Array.new
		@parent_array = Array.new

		@count = true
		log = setup_logger(doc)
		log.info("logging to file #{doc.elements['/pfs-scoping-automate/service/log-file'].text.strip.strip}")
	
		#doc.elements.each('/pfs-scoping-automate/projects/project') do |project|
			log.info("rally-workspace= " + doc.elements['/pfs-scoping-automate/projects/project/rally-workspace'].text.strip)
			log.info("rally-project  = " + doc.elements["/pfs-scoping-automate/projects/project/rally-project"].text.strip)
			automator = Automaton.new(doc,filename,log)
			automator.process
		#end
	

end

if(ARGV.count != 1)
	puts "Please provide the config file as input"
	puts "Usage: #{__FILE__} config.xml"
	exit
end


scheduler = Scheduler.new
scheduler.start

ARGV.each do |arg|
	if  File::exists?( arg )
		# schedule the config file
		doc = REXML::Document.new(File.read(arg))
		#scheduler.schedule_every( 
		#	doc.elements['/pfs-scoping-automate/service/interval'].text.strip+'s')  
		process(doc,arg) 
	else
		puts "#{arg} not found!"
	end
end

scheduler.join