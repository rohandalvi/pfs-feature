require 'logger'
#require 'rally_api'
require 'logger'
require './rally_query.rb'

class Project
	
	def initialize(doc,workspace,project)
		@allowedState = []

		doc.elements.each('/pfs-scoping-automate/allowed-state') do |allowed_state|
			@allowedState.push(allowed_state.text.strip)
		end

		@parent_array = Array.new
		@child_array = Array.new
		@flag = true
		@query = Query.new(workspace,project,doc)

		
	end

	def get_all_projects(parentProject)
			@parent_array.push(parentProject)

	        while @child_array.length!=0 || @flag==true
		          @flag=false
		          @child_array.pop
		          
		          result = @query.build_query(:project,"Name,Children","(Name = \"#{parentProject}\")","")
		          if(result!=nil)
		          result.each{ |res|
		            res.read
		            #temp_array = process_array(res.Children.results)
		            res.Children.results.each{|element|
		           
		            @child_array.push(element.to_s.strip)
		           
		           }    
		         } 
		          end
		        
		         @child_array.length!=0?get_all_projects(@child_array.fetch(-1)):return 
	        end #end of while
		return @parent_array
	end
end