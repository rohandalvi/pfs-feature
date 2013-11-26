
require 'rally_api_emc_sso'

class Query

	def initialize(workspace,project)

		headers = RallyAPI::CustomHttpHeader.new()
		headers.name = "My Utility"
		headers.vendor = "MyCompany"
		headers.version = "1.0"


		workspace_name = workspace
		project_name = project


		config = {:base_url => "https://rally1.rallydev.com/slm"}
		config[:workspace]  = workspace_name
		config[:project]    = project_name

		config[:headers]    = headers #from RallyAPI::CustomHttpHeader.new()
		config[:projectScopeUp] = false
		config[:projectScopeDown] = false

		config[:version] = "v2.0"

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
	     return result
	   else
	     #puts "No result"
	   end  
	end

end