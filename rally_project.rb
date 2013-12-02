require 'logger'
require 'rally_api'
require 'date'
require './rally_query.rb'

class RallyProject
  def initialize(workspace,project,logger)
    @query = Query.new(workspace,project)
    @logger=logger
    @workspace = workspace
    @project = project
    log_debug( "RallyProject::initialize Start: " + workspace + ", project: " + project)
  end
  def get_workspace(workspace_name)
    #return workspace_ref
    result = @query.build_query(:workspace, "Name","(Name = \"#{workspace_name}\")","")
    if(result!=nil)
      log_debug( "RallyProject::initialize found ws: " + workspace_name)
    else
      log_debug( "RallyProject::initialize not found ws: " + workspace_name)
    end
    workspace_ref = result.first._ref
    return workspace_ref
  end
  
  def get_project(project_name)
    result = @query.build_query(:project, "Name","(Name = \"#{project_name}\")","")
    if(result!=nil)
      log_debug( "RallyProject::initialize found project: " + project_name )
    else
      log_debug( "RallyProject::initialize - project " + project_name + " not found!" )
    end
    project_ref = result.first._ref
    return project_ref
  end
  
  def find_story_by_tag(trigger_tag)
    log_debug( "find_story_by_tag Start" )
    
    result = @query.build_query(:hierarchicalrequirement,"FormattedID,Tags","(Tags.Name = \"#{trigger_tag}\")","")
    if(result!=nil && result.results.count!=0)
      log_debug( "found parent count: " + result.results.count.to_s + " - first story: " + result.results.first.FormattedID )
    else
      log_debug("no parent found")
    end
      log_debug( "find_story_by_tag End" )
    return result
  end
  
  def find_PI_feature_by_state( state )
    log_debug( "find_PI_feature_by_state Start" ) 
    query_result = @query.build_query("portfolioitem/feature","State,Name,DirectChildrenCount","((State.Name = \"#{state}\") AND (DirectChildrenCount = 0))")
    
    if query_result != nil && query_result.count != 0
      log_debug( "found PI results: " + query_result.count.to_s )
    else
      log_debug( "no PI feature found" )
    end

    log_debug( "find_PI_feature_by_state End" )
    return query_result
    
  end 
  
  def find_portfolio_item_by_tag( trigger_tag )
    log_debug( "find_portfolio_item_by_tag Start" )
    query_result = @query.build_query("portfolioitem","FormattedID,Tags,Name","(Tags.Name = \"#{trigger_tag}\")","")
    if query_result != nil && query_result.results.count != 0
      log_debug( "found PI parent count: " + query_result.results.count.to_s + " - first story: " + query_result.results.first.FormattedID )
    else
      log_debug( "no PI parent found" )
    end
    
    log_debug( "find_portfolio_item_by_tag End" )
    return query_result    
  end
  
  def find_workspace(name)
     result = @query.build_query(:workspace,"Name","(Name = \"#{name}\")","")
     return result.first  
  end
  def find_project(name)
    result = @query.build_query(:project,"Name,Owner","(Name = \"#{name}\")","")
    return result.first
  end
  
  def find_project_owner(name)
    result = @query.build_query(:project,"Name,Owner,ObjectID","(Name = \"#{name}\")","")
    if result && result.length>0
      if nil!=result.first.Owner and nil!=result.first.Owner.Name
        log_info("Found project owner username: " +  result.first.Owner.Name)
        return result.first
      end
    else
        log_info("did not find that project")
    end
    return nil
  end
  
  def find_changeset(rev)
    result = @query.build_query(:changeset, "Revision","(Revision = \"#{rev}\")","")
    if result && result.length>0
      return result.first
    end
    return nil
  end
  def find_objects_by_name(type,name)
     if name!="" && name!=nil
       result = @query.build_query(type,"Name","(Name = \"#{name}\")","")
       if(result==nil)
         puts "No object found of type #{type} and name #{name}"
       end
       return result
     end
  end
  def find_story_by_id(story_id)
    if story_id!="" && story_id!=nil
    result = @query.build_query(:hierarchicalrequirement,"Name,FormattedID","(FormattedID = \"#{story_id}\")","")
    return result.first
    end
  end
  def find_or_create_build_definition(def_name)
    log_debug("Looking for build definition #{def_name}")
    results = find_objects_by_name(:BuildDefinition,def_name)
    log_debug("Found #{results.length} results")
    
    if !results || results.length == 0
      #create
      fields = {
        "Name" => def_name,
        "Project" => @project
      }
      build_def = @query.get_rally_object.create(:BuildDefinition,fields)
      log_debug("Created #{def_name}")
    else
      #if already present
      log_debug("Found build definition #{def_name}")
      build_def = results.first
    end
  end
  def create_story(story_name,story_parent)
   log_debug("Create story start")
   result_story = nil
   #If children exist with the name, don't create them
   if child_exists(story_name,story_parent)
     log_info("Child #{story_name} exists -- skipping")
     return nil
   else
     log_info("Processing child #{story_name}")
   end 
    log_info("Creating story #{story_name}, for parent: #{story_parent}")
    fields = {
      "Name" => "story_name",
      "Owner" => "#{find_project_owner(@project)._ref}",
      "Parent" => "story_parent"
    }
    @query.get_rally_object.create(:hierarchicalrequirement,fields) do |user_story|
    result_story = user_story
    log_info("New story created #{story_name}")
    log_info("Parent: #{story_parent}")
    log_info("Project Name: #{@project}")
    log_info("Project Owner Name: #{find_project_owner(@project).Owner.Name}")
    end
    log_debug("create_story end")
    return result_story
  end
  
  #this function may fail if there are duplicate stories with the same name or if the name has any "/ or \"
  # a quick fix would be to query based on the objectid and not on the name
  def child_exists(story,parent)
    result = @query.build_query(:hierarchicalrequirement,"Name,FormattedID,ObjectID,Children","(Name = #{parent})")
    if(result==nil)
      return false
    else
      result.each do |res|
        res.read
          res.Children.results.each do |child|
            if child.to_s == story.to_s
              return true
            end
          end
        end
      end
      return false
    end
  
  def create_task_on_story( a_task_name, a_story )
    log_info( "Creating task: "+a_task_name+", for user story: "+a_story+"\n")
    owner_name = find_project_owner(@project).Owner.Name
    log_info("Owner name: "+owner_name+"\n")
    
    rally = @query.get_rally_object
    fields = {
      "Name" => "#{a_task_name}",
      "WorkProduct" => "#{a_story}",
      "Workspace" => find_workspace(@workspace),
      "Project" => find_project(@project)
    }
    rally.create(:task,fields) do |this_task|
      log_info("Created task "+this_task)
      owner = find_project_owner(@project)._ref
      
      if nil == owner
        log_info "No owner object found\n"
      end
      log_info("Owner.user_name: #{find_project_owner(@project).Owner.Name}")
      fields ={}
      fields["Owner"] = owner
      rally.update(this_task,fields)
    end
  end
  
  def create_task(a_task_name,a_story_id)
    log_info("Creating a task: #{a_task_name}, for user story: #{a_story_id} \n")
    user_story = find_story_by_id(a_story_id)
    
    log_info("Found Story: #{user_story.FormattedID}")
    create_task_on_story(a_task_name,user_story)
    
  end
  
  def create_build(build_defs,changesets,duration,message,number,start,status,uri)
    log_debug("Creating build")
    
    fields = {
      "BuildDefinition" => build_def,
      "Changesets" => changesets,
      "Duration" => duration,
      "Message" => message,
      "Number" => number,
      "Status" => status,
      "Start" => start,
      "Uri" => uri
    }
    
    log_debug("Creating build for #{fields}")
    build = @query.get_rally_object.create(:build, fields)
    log_debug("Created build #{fields}")
  end
  #given a story and a tag, remove tag
  
  def remove_tag(artifact, a_tag)
    log_debug( "RallyProject::remove_tag( " + a_tag + ") Start" )
    if nil == artifact
      log_debug( "remove_tag error: No story provided" )
    else
      tags_set = artifact.tags
      tags_set.each do |tag| 
        if tag.to_s == a_tag.to_s
          tags_set.delete(tag)
          @query.get_rally_object.update(artifact,:tags=>tags_set)  
        end #end of if
        
      end #end of do
      
    end #end of else
    
  end #end of remove_tag
  
  def find_tag(tag_name)
    if(tag_name != "" and tag_name !=nil)
      query_result = @query.build_query(:tag,"Workspace","(Name = \"#{tag_name}\")","")
      if query_result.count == 0
        puts "Creating #{tag_name}\n"
        return @query.get_rally_object.create(:tag,{"Name" => tag_name,"Workspace" => find_workspace(@workspace)}) 
      end
      tag = query_result.first
      return tag
    end
  end
  
  def gather_tags(tagnames)
    if(!tagnames)
      return nil
    end
    tags = Array.new
    tagnames.split(',').each do |tagname|
      tag = find_tag(tagname.strip)
      tags.push(tag) if tag
    end 
    return tags   
  end
  
  def add_tag(artifact,a_tag)
    
    if(nil!=artifact.tags)
      tags = artifact.tags.join(",")
      tags.concat(","+a_tag)
      puts "Got tags: #{tags}"
    else
      tags = a_tag
    end
    log_debug("RallyProject::add_tag(#{a_tag}) Start ")
    update_tags(artifact,tags)
  end
  
  def update_tags(artifact, tags)
    puts "In update_tags \n"
    if tags
      tagfields = {}
      tagfields[:tags] = gather_tags(tags)
      puts "Tagging #{artifact.name} with Tags:#{tagfields[:tags].length}\n"
      tagfields[:tags].each {|tag|
        puts "Tag: #{tag.name}\n"
        }
        artifact.update(tagfields)
    end
  end
  def update_name(artifact,a_name)
    @query.get_rally_object.update(artifact,{"Name" => a_name})
  end
  
  #create an array of rally changesets based on changeset id's from Bamboo
  def find_changesets(changeset_ids)
    sets = Array.new
    changeset_ids.each do |id|
      cs = find_changeset(id)
      if cs
        sets.push(cs)
      end
    end
    sets
  end
  #TO-DO move these
  def log_debug(info)
    @logger.debug(info)
    if true
      print(info+"\n")
    end
  end
  def log_info(info)
    @logger.info(info)
    if true
      print(info+"\n")
    end
  end
end