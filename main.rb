require 'rubygems'
require 'logger'
class Main
  
  def initialize
    puts "Initialized object"
  end

  def setup_logger(file)
    log = Logger.new(file) 
    return log
  end

  def check_validity
    cmd = ""
    cmd2 = ""
    case ARGV[0]
    when "PIstates.xml"
      cmd = 'PIstateAutomate'
      cmd2 = "ruby rally_PIstates_automate.rb #{ARGV[0].strip}"
      Dir.chdir(cmd)
      system(cmd2)
    when "PFSAutomate.xml"
      cmd = "AutomatePFS"
      cmd2 = "ruby rally_PFS_automate.rb #{ARGV[0].strip}"
      Dir.chdir(cmd)
      system(cmd2)
    when "ExpScoping.xml"
      cmd = "ExpScoping Automate"
      cmd2 = "ruby expScopingAutomate.rb #{ARGV[0].strip}"
      Dir.chdir(cmd)
      system(cmd2)
    when "HLSAutomate.xml"
      cmd = "HLSAutomate"
      cmd2 = "ruby rally_HLS_automate.rb #{ARGV[0].strip}"
      Dir.chdir(cmd)
      system(cmd2)
    else
      puts "Please enter a valid argument"
      usage
      exit
    end
    
  end

  def usage
    puts "Usage: ruby #{__FILE__} <optional_xml>"
    puts "<optional_xml> = PIstates.xml -> If you want to automate PIstate script"
    puts "<optional_xml> = PFSAutomate.xml -> If you want to automate PFS script"
    puts "<optional_xml> = PFSFeature.xml -> If you want to automate exploratory story script"
    
  end

  main = Main.new
  if(ARGV.length!=1)
    main.usage    
    exit
  else
    main.check_validity
  end
end
