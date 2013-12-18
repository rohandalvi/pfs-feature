require 'logger'
require 'rally_api'
require '../rally_project.rb'
require '../rally_query.rb'

class Automaton
@doc = nil
@use_tag = true

def initialize(doc,filename,logger)

		@filename = filename
		@doc = doc
		@logger = logger
		@rally_url       = @doc.elements['/hls-rally-automate/rally/server'].text.strip
		@trigger_tag     = @doc.elements['/hls-rally-automate/rally/rally-trigger'].text.strip
end

def process
print("Automaton:: Process start")
	 @doc.elements.each('/hls-rally-automate/projects/project') do |project|
	 	rp = RallyProject.new(project.elements["rally-workspace"].text.strip,project.elements["rally-project"].text.strip,@logger,@doc)
	 	rp.log_info( "Processing project: " + rp.get_project(project.elements["rally-project"].text.strip) + ", workspace: " +  rp.get_workspace(project.elements["rally-workspace"].text.strip) )

	 	parent = rp.find_story_by_tag( @trigger_tag )

	 	if parent== nil #parent.results.count == 0
				rp.log_info( "No results matching '" + @trigger_tag + "' found" )
		else
				rp.log_debug( "Parent cnt: " + parent.results.count.to_s  )
				parent.results.each do |this_parent|

         			rp.log_debug( "Found Parent: " + this_parent.FormattedID)
         			project.elements.each('artifacts/artifact') do |artifact|
         				story_name = this_parent.name
         				len = this_parent.name.length
         				if len>18
         					len=18
         				end
         				a_slice = this_parent.name.slice(0,len)

         				#Add some info to the name
         				story_name = this_parent.FormattedID+"-"+a_slice+"-"+story_name
         				rp.log_info "Processing artifact name: " + story_name + "\n"
         				result_story = rp.create_story(story_name,this_parent)
         				if(nil!=result_story)
         					rp.log_info "Result story: #{result_story.FormattedID}"+"\n"
         					artifact.elements.each('tags/tag') do |tag|
								rp.add_tag( result_story, tag.text.strip )
							end

							artifact.elements.each('tasks/task') do |task|
			                	rp.create_task( task.text.strip, result_story.FormattedID )
			              	end
			            else
			            	rp.log_info "No new result_story_id"
         				end

         			end
         			rp.remove_tag(this_parent, @trigger_tag)
         		end
        end
 	end
 	print "Automaton::Process End\n";
end

end