
require 'rally_api' 
require 'bcrypt'
#change this to SSO if you do not wish to enter your username & password in this file.

#If you are using rally_api, ensure that you have added your username & password in the config below.

#If you use SSO, there are chances that this script will break because of 401 error from Rally.
#Better use rally_api if you have access directly.
class Query

	def initialize(workspace,project,doc)

		headers = RallyAPI::CustomHttpHeader.new()
		headers.name = "Portfolio Management Automation"
		headers.vendor = "EMC"
		headers.version = "1.0"


		@workspace_name = workspace
		@project_name = project
		file = File.new("../password.txt","r")
		password = file.gets
		my_password = BCrypt::Password.create(password.strip)
		

		config = {:base_url => "https://rally1.rallydev.com/slm"}
		config[:workspace]  = workspace
		config[:project]    = project
		config[:username] = "rohan.dalvi@emc.com"
		config[:password] = password.strip
    	config[:version] = doc.elements['//service/version']?doc.elements['//service/version'].text.strip: nil
		config[:headers]    = headers #from RallyAPI::CustomHttpHeader.new()
		config[:projectScopeUp] = false
		config[:projectScopeDown] = false
    

		@rally = RallyAPI::RallyRestJson.new(config) 
	end
	def build_query(type,fetch,string,order)
	   query = RallyAPI::RallyQuery.new()
	   query.type = type
	   query.fetch=fetch
	   query.query_string = string
	   query.project_scope_up = true
	   query.project_scope_down = true
	   query.order = order
	   result = @rally.find(query);
	   
	   if(result.length>0)
	   	puts "Result found for #{string}"
	  # 	puts "result found for #{query.query_string}"
	     return result
	   else
	   	puts "No result for #{string}"
	   	#puts "No result for #{@project_name}"
	   end  
	end

	def update(type,fields)
		@rally.update(type,fields)
	end

	def get_rally_object
		return @rally
	end
end