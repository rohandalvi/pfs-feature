require 'logger'
require '../rally_query.rb'
require '../rally_project.rb'
class Automaton

	@doc = nil

	@use_tag = true
	
	def initialize(doc,filename,logger)
		@filename = filename
		@doc = doc
		@logger = logger
		                          
		@rally_url      = @doc.elements['/PIstates-rally-automate/rally/server'].text.strip
		@PIstate 	    = @doc.elements['/PIstates-rally-automate/rally/rally-trigger'].text.strip
		@needed_tag     = @doc.elements['/PIstates-rally-automate/rally/rally-tag-action'].text.strip
		# check passwords for obfuscation
		
		#get_creds
		
	end

	def process
		print( "Automaton::Process Start" )
 		@doc.elements.each('/PIstates-rally-automate/projects/project') do |project|
			rp = RallyProject.new(project.elements["rally-workspace"].text.strip,project.elements["rally-project"].text.strip,@logger)
							  
			rp.log_info( "Processing project: " + rp.get_project(project.elements["rally-project"].text.strip) + ", worksapce: " +  rp.get_workspace(project.elements["rally-workspace"].text.strip))
			results = rp.find_PI_feature_by_state( @PIstate )
			
			if results.count == 0
				rp.log_info( "No results matching '" + @PIstate + "' and zero stories found" )
			else
				rp.log_debug( "Results cnt: " + results.count.to_s  )
				results.each do |res|
					rp.log_debug "ID: #{res.FormattedID}"
					rp.log_debug "DirectChildrenCount: #{res.DirectChildrenCount} "    
					rp.log_debug "State: #{res.State}" 
		
					if( res.direct_children_count.to_i == 0 ) 
						tags_set = res.tags
						if( nil == tags_set )
							rp.log_debug( "About add a tag to: #{res.FormattedID}")
							puts "Needed tag: #{@needed_tag}"
							rp.add_tag( res, @needed_tag )
						else
							i = tags_set.index{|x|x.to_s==@needed_tag}
							if( nil == i )
								rp.log_debug( "About add a tag to: #{res.FormattedID}")
								rp.add_tag( res, @needed_tag )
							end
						end
					else
						rp.log_debug "did not add a tag"
					end
				end
			end
		end
	end
	
end