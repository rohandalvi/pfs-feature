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
    @rally_url       = @doc.elements['/pfs-rally-automate/rally/server'].text.strip
    @trigger_tag     = @doc.elements['/pfs-rally-automate/rally/rally-trigger'].text.strip
  end
  def process
    print( "Automaton::Process Start" )
    @doc.elements.each('/pfs-rally-automate/projects/project') do |project|
      rp = RallyProject.new(project.elements["rally-workspace"].text.strip,project.elements["rally-project"].text.strip,@logger)
      
                
      rp.log_info( "Processing project: " + rp.get_project(project.elements["rally-project"].text.strip) + ", workspace: " +  rp.get_workspace(project.elements["rally-workspace"].text.strip) )
      #Find any story with the needed trigger
      #Find the right US based on some query
      #Do we need project here?  Need it for creation, but for search?

      parent = rp.find_portfolio_item_by_tag_sub( @trigger_tag )

      if parent.results.count == 0
        rp.log_info( "No PI results matching '" + @trigger_tag + "' found" )
      else
        rp.log_debug( "Parent cnt: " + parent.results.count.to_s  )
        parent.results.each do |this_parent|
          rp.log_debug( "Found Parent: " + this_parent.FormattedID)

          #Add the new story
          project.elements.each('artifacts/artifact') do |artifact|
            #Copying the name from the parent instead
            story_name = this_parent.name
            rp.log_info "Processing artifact name: " + story_name + "\n"
            #Find the tag that triggered this (in the form of NeedsPFS-KittyHawk
            project_name =  artifact.elements['target-project'].text.strip
            rp.log_debug ("got project_name: " + project_name )
            a_project = rp.find_project( project_name )
            result_story = rp.create_story_with_portfolio_item_parent( story_name, this_parent, a_project )
            if( nil != result_story )
              rp.log_info "Result story: " + result_story.FormattedID + "\n"
              
              artifact.elements.each('tags/tag') do |tag|
                rp.add_tag( result_story, tag.text.strip )
              end
              #Now add the necessary tasks to the new story
              artifact.elements.each('tasks/task') do |task|
                rp.create_task_on_story( task.text.strip, result_story )
              end
            else
              p.log_info "No new result_story_id"
            end
          end

          rp.remove_tag(this_parent, @trigger_tag)
        end
      end
    end
    print "Automaton::Process End\n";
  end
end