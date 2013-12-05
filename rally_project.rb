=begin
Modified by: Rohan Dalvi(Rohan.Dalvi@emc.com)
Date: 12/5/2013
version: 2.0

Description: Modified earlier version to support the new version of Rally WSAPI.
This is being used by PFSAutomation and PIstate Automation scripts.
=end
require 'logger'
require 'date'
require 'rally_query.rb'

class RallyProject
  def initialize(workspace,project,logger,doc)
    @query = Query.new(workspace,project,doc)
    @logger=logger
    @workspace = workspace
    @project = project
    log_debug( "RallyProject::initialize Start: " + workspace + ", project: " + project)
  end
  
=begin
  Function name: get_workspace
  parameters: workspace_name -> type string
  returning: workspace reference  
=end

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
  
=begin

  Function Name: get_project
  parameter: project_name -> type string
  returning: project reference  
=end

  def get_project(project_name) #returns project_ref
    result = @query.build_query(:project, "Name","(Name = \"#{project_name}\")","")
    if(result!=nil)
      log_debug( "RallyProject::initialize found project: " + project_name )
    else
      log_debug( "RallyProject::initialize - project " + project_name + " not found!" )
    end
    project_ref = result.first._ref
    return project_ref
  end
  
=begin
  Function Name: find_story_by_tag
  parameter: trigger_tag -> type string
  returning: 1 or more stories set as 'result' 
=end
  
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
  
=begin
  Function Name: find_PI_feature_by_state
  parameter: state -> type string
  returning: entire query_result which may contain one more features
=end

  def find_PI_feature_by_state( state )
    log_debug( "find_PI_feature_by_state Start" ) 
    query_result = @query.build_query("portfolioitem/feature","FormattedID,State,Name,DirectChildrenCount","((State.Name = \"#{state}\") AND (DirectChildrenCount = 0))","")
    
    if query_result != nil && query_result.count != 0
      log_debug( "found PI results: " + query_result.results.count.to_s )
    else
      log_debug( "no PI feature found" )
    end

    log_debug( "find_PI_feature_by_state End" )
    return query_result
    
  end 
  
=begin
  Function name: find_portfolio_item_by_tag
  parameter: trigger_tag => type string
  returning: entire query_result which may contain one or more portfolio items.  
=end

  def find_portfolio_item_by_tag( trigger_tag )#here trigger_tag should be a string
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

  def find_portfolio_item_by_tag_sub(trigger_tag)
    log_debug( "find_portfolio_item_by_tag_sub Start" )
    
    query_result = @query.build_query("portfolioitem","FormattedID,Tags,Name","(Tags.Name = \"#{trigger_tag}\")","")
    if query_result!=nil && query_result.results.count!=0
      log_debug("Found parent count: #{query_result.results.count}, first story: #{query_result.results.first.FormattedID} ")
    else
      log_debug("no PI parent found")
    end
    
    log_debug("find_portfolio_item_by_tag_sub End ")
    return query_result
  end

=begin
  Function name: find_workspace
  parameter: name -> type string
  returning: first set of Workspace containing Name, ObjectID, _ref  
=end

  def find_workspace(name)#here name should be a string
     result = @query.build_query(:workspace,"Name","(Name = \"#{name}\")","")
     if(result!=nil)
      return result.first
     else
       log_debug("No project #{name} found")
     end  
  end
  
=begin
  Function name: find_project
  parameter: name -> type string
  returning: first set of Project containing Name, ObjectID, _ref  
=end

  def find_project(name) #here name should be a string
    result = @query.build_query(:project,"Name,Owner","(Name = \"#{name}\")","")
    return result.first
  end
  
=begin
  Function name: find_project_owner
  parameter: name -> type string
  returning: first set of Project with Name,Owner,ObjectID 
=end

  def find_project_owner(name) #here name should be a string
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
  
=begin
  Function name: find_changeset
  parameter: revision -> type string
  returning: first set of changeset with Revision  
=end

  def find_changeset(rev)
    result = @query.build_query(:changeset, "Revision","(Revision = \"#{rev}\")","")
    if result && result.length>0
      return result.first
    end
    return nil
  end
  
=begin
  Function name: find_objects_by_name
  parameter: type, name -> type string
  returning: entire result
  
  comments: Duplicates are highly likely here, for ex: type = HierarchicalRequirement, name = "Some duplicate story name"  
=end

  def find_objects_by_name(type,name)
     if name!="" && name!=nil
       result = @query.build_query(type,"Name","(Name = \"#{name}\")","")
       if(result==nil)
         puts "No object found of type #{type} and name #{name}"
       end
       return result
     end
  end
  
=begin
  Function name: find_story_by_id
  parameters: story_id (formattedID)
  returning: first set of story matching FormattedID
=end

  def find_story_by_id(story_id)
    if story_id!="" && story_id!=nil
    result = @query.build_query(:hierarchicalrequirement,"Name,FormattedID","(FormattedID = \"#{story_id}\")","")
    return result.first
    end
  end
  
=begin
  Function name: find_or_create_build_definition
  parameters: def_name -> type string
  returning: nil/nothing to return  
=end

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
  
=begin
  Function name: create_story
  parameters: story_name -> type string, story_parent -> type string
  returning: newly created user story as "result_story"   
=end

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
      "Parent" => "#{story_parent}"
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

  def create_story_with_portfolio_item_parent( a_story_name, a_parent, a_project)
    log_debug("create_story_with_portfolio_item_parent start")
    result_story = nil
    
    #If children exist with the name, don't create them
    if child_exists(a_story_name,a_parent)
      log_info("Child #{a_story_name} exists -- skipping")
      return nil
    else
      log_info("Processing child #{a_story_name}")
    end
    log_info( "Creating story: #{a_story_name} ,Project: #{a_project._ref},  for parent: #{a_parent.class}, Owner: #{find_project_owner(a_project.to_s)}, PortfolioItem: #{a_parent._ref}, Project: #{a_project._ref} and class #{a_project.class}")   
    fields = {}
    fields["Name"]=a_story_name
    fields["Project"] = a_project
    fields["PortfolioItem"] = a_parent
    if(find_project_owner(a_project)!=nil)
      fields["Owner"] = a_project.Owner.Name
    end
    @query.get_rally_object.create(:hierarchicalrequirement,fields) do |user_story|
      log_info("New story created: #{user_story.FormattedID}")
      log_info("Parent: #{a_parent.FormattedID}")
      log_info("Project Name: #{a_project.Name}")
      log_info("Project Owner: #{a_project.Owner.Name}")
      
      result_story = user_story
    end 
    log_debug("_with_portfolio_item_parent end")
    return result_story
  end
  
  
=begin
  Function name: child_exists
  parameter: story -> type string, parent -> type string
  returning: true, if a parent has any children with name in story, false otherwise.  
  
  comments:
  this function may fail if there are duplicate stories with the same name or if the name has any "/ or \"
  a quick fix would be to query based on the objectid and not on the name
=end  

  def child_exists(story,parent)
    log_info("Inside child exists for: ")
    log_info("Story: #{story} & Parent: #{parent}")
    result = @query.build_query(:hierarchicalrequirement,"Name,FormattedID,ObjectID,Children","(Name = \"#{parent}\")","")
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
    
=begin
Function name: create_task_on_story
parameters: a_task_name -> type string, a_story -> story object
=end

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
  
=begin
  Function name: create_task 
  parameters: a_task_name -> type string, a_story_id -> FormattedID of story.
  returning: nothing/creating a task on story.
=end

  def create_task(a_task_name,a_story_id)
    log_info("Creating a task: #{a_task_name}, for user story: #{a_story_id} \n")
    user_story = find_story_by_id(a_story_id)

    log_info("Found Story: #{user_story.FormattedID}")
    create_task_on_story(a_task_name,user_story)
  end
  
=begin
  Function name: create_build
  parameters: 
  1. build_defs -> _ref of build_definition/ build_definition object
  2. changesets -> _ref of changesets / changesets object
  3. duration -> type string
  4. message -> type string
  5. number -> type number
  6. start -> type date
  7. status -> type string
  8. uri -> type uri
  
  returning: nothing/creating a build out of given arguments
=end

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
=begin
  Function name: remove_tag
  parameters: artifact -> type rally object, a_tag -> type string
  returning: nothing/ deleting "a_tag" from "artifact.tags" set.
=end

  def remove_tag(artifact, a_tag)
    log_debug("RallyProject::remove_tag( " + a_tag + ") Start ")
    if nil == artifact.tags 
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
  
=begin
  Function name: find_tag
  parameters: tag_name -> type string  
  returning: first tag object (if pre-existing), creating a new tag otherwise
=end

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
  
=begin
  Function name: gather_tags
  parameters: tagnames -> type string
  returning: Array of tag objects  
=end

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
  
=begin
  Function name: add_tag
  parameters: artifact -> Rally object containing tags, a_tag -> tag to be added to artifact
  returning: nothing/ updating artifact by adding new tag.
=end 

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
  
  def get_fid(artifact) #returns FormattedID of artifact, if not present,returns nil
    result = @query.build_query(artifact,"Name,FormattedID,ObjectID","(ObjectID = \"#{artifact.ObjectID}\")","")
    puts "Returning: #{result.first.FormattedID}"
    return result.first.FormattedID
  end
  
  def exists(artifact) #returns true if artifact exists
    result = @query.build_query(artifact._type,"Name,FormattedID","(FormattedID = \"#{artifact.FormattedID}\")","")
    if result!=nil
      return true
    else
      return false
    end
  end
  
  def update_tags(artifact, tags)
    puts "In update_tags \n"
    if exists(artifact) # can be updated only if artifact exists
      puts "Artifact exists"
      if tags
        tagfields = {}
        tagfields[:tags] = gather_tags(tags)
        puts "Artifact: #{artifact.FormattedID}, Tagging #{artifact.name} with Tags:#{tagfields[:tags].first._ref}\n"
        puts "Workspace: #{@workspace}"

         if tagfields[:tags]!=nil
          
          tagfields[:tags].each {|tag|
            fields = {
              "Tags" => tag
            }

            puts "Tag: #{tag._ref}\n"
            puts "FormattedID: #{fields}"
            
            
            @query.get_rally_object.update(artifact._type,"FormattedID|#{artifact.FormattedID}",fields)
            puts "Updated #{fields}"
          }
         
        end
      end
    else # if artifact doesn't exist
      puts "Aborting"
      exit
    end
  end
  
=begin
  Function name: update_name
  parameters: artifact -> type object, a_name -> type string
  returning: nothing/updating artifact with a new name  
=end

  def update_name(artifact,a_name)
    @query.get_rally_object.update(artifact,{"Name" => a_name})
  end
    
  
=begin
  Function name: find_changesets
  parameters: changeset_ids -> type revision object
  returning: Collection containing all changeset objects
  comments: create an array of rally changesets based on changeset id's from Bamboo
=end
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
  def log_debug(info) #debug logger
    @logger.debug(info)
    if true
      print(info+"\n")
    end
  end
  
  def log_info(info) #info logger
    @logger.info(info)
    if true
      print(info+"\n")
    end
  end
end