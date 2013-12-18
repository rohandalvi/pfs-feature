require 'logger'
#require 'rally_api'
require 'logger'
require '../rally_query.rb'

class Artifact
	def initialize(doc,logger)
		@doc = doc
		@project =   @doc.elements['/pfs-scoping-automate/projects/project/rally-project'].text.strip
		@workspace = @doc.elements['/pfs-scoping-automate/projects/project/rally-workspace'].text.strip
		@logger = logger
		@query_result = Query.new(@workspace,@project,@doc)
		if(@query_result)
			puts "Query Result object initiated under Artifact"
		end


	end

=begin
Function name: get_all_features_of_project
parameters:
1. project:  Name of Project, type-> string
2. stateName: Name of current State, type-> string

returning: nil / processing each epic level story associated to every feature
=end

	def get_all_features_of_project(project,stateName)
		result = @query_result.build_query("portfolioitem/feature","Name,FormattedID,UserStories","((State.Name = \"#{stateName}\") AND (Project.Name = \"#{project}\"))","FormattedID Asc")
		if(result!=nil)
			result.each do |res|
				res.read
				@feature_id = res.FormattedID
				if(res.UserStories.results.length>0)
				  @logger.info(res.UserStories.results.inspect)
					res.UserStories.results.each {|story|
					  @logger.info("ObjectID of epic_story is #{story.ObjectID} for feature id: #{@feature_id}")
						process_stories_of_feature(story.ObjectID.to_s.strip) #,project.to_s.strip
					}
				end
			end
		end
	end
	
=begin
Function name: process_stories_of_feature
parameters: 
1. epicStory: This is the OBJECTID of epic level story of a feature, type-> string
returning: nil / processing child stories of each epic level story  
=end

	def process_stories_of_feature(epicStory)
		
		puts "epic story is #{epicStory} and project is #{@project}"
		result = @query_result.build_query("hierarchicalrequirement","Name,ObjectID,FormattedID,Children,Project","(ObjectID = \"#{epicStory}\")","")
		
		if(result!=nil)
			result.each do |res|
				res.read
				#if the epic level story has children
				if res.Children.results!=nil
					res.Children.results.each do |child_of_epic| #scan through each child to see if its any of those 6 automatically generated stories
						if isDataPath(child_of_epic)
							get_estimate_value(child_of_epic.ObjectID.to_s.strip,"c_EstDP".strip)
							@logger.info("Data path found for #{child_of_epic}")
						elsif isControlPath(child_of_epic)
							get_estimate_value(child_of_epic.ObjectID.to_s.strip,"c_EstCP".strip)
							@logger.info("Control Path found for #{child_of_epic}")
						elsif isPlatform(child_of_epic)
							get_estimate_value(child_of_epic.ObjectID.to_s.strip,"c_EstPltfm".strip)
							@logger.info("Platform found for #{child_of_epic}")
						elsif isTestEstimate(child_of_epic)
							get_estimate_value(child_of_epic.ObjectID.to_s.strip,"c_EstTest".strip)
							@logger.info("Test estimate found for #{child_of_epic}")
						elsif isPerformance(child_of_epic)
							get_estimate_value(child_of_epic.ObjectID.to_s.strip,"c_EstPerformance".strip)
							@logger.info("Performance found for #{child_of_epic}")
						elsif isDoc(child_of_epic)
							get_estimate_value(child_of_epic.ObjectID.to_s.strip,"c_EstDoc".strip)
							@logger.info("DOC/IDD found for #{child_of_epic}")
						end
					end
					puts "calling addup_total"
					addup_total
				end
			end
		end
	end
	def isDataPath(child_story)
		if child_story.to_s.start_with? "US" and child_story.to_s.end_with? "Data Path"
			return true
		else
			return false
		end
	end
	def isControlPath(child_story)
		if child_story.to_s.start_with? "US" and child_story.to_s.end_with? "Control Path"
			return true
		else
			return false
		end
	end
	def isPlatform(child_story)
		if child_story.to_s.start_with? "US" and (child_story.to_s.end_with? "Platform" or child_story.to_s.end_with? "platform")
			return true
		else
			return false
		end
	end
	def isTestEstimate(child_story)
		if child_story.to_s.start_with? "US" and child_story.to_s.end_with? "Test Estimate"
			return true
		else return false
		end
	end
	def isPerformance(child_story)
		if child_story.to_s.start_with? "US" and (child_story.to_s.end_with? "performance" or child_story.to_s.end_with? "Performance")
			return true
		else return false
		end
	end

	def isDoc(child_story)
		if child_story.to_s.start_with? "US" and (child_story.to_s.end_with? "DOC" or child_story.to_s.end_with? "IDD")
			return true
		else return false
		end
	end
	
=begin
  Function Name: addup_total
  returning: nil / updating total variable 
=end

	def addup_total
		get_total
		update_total = {}
		update_total["c_ExpScopingTotal"] = @total
		if(@total>0)
			rally = @query_result.get_rally_object
			update = rally.update("portfolioitem","FormattedID|#{@feature_id}",update_total)
			if(update)
				@logger.info("Total for #{@feature_id} is updated to #{@total}")
			else
				@logger.info("Total could not be updated")
			end
		end
	end
	
=begin
Function Name: get_estimate_value()  
parameters: 
1. objectid: ObjectID of the story from which the estimate is to be extracted
2. variablename: gives variable name to be updated. For ex: c_EstCP for Control Path, c_EstDP for Data Path
=end

	def get_estimate_value(objectid,variablename)
		result = @query_result.build_query("hierarchicalrequirement","Name,ObjectID,FormattedID,#{variablename},PlanEstimate","(ObjectID = \"#{objectid}\")","")
		if(result!=nil)
			result.each do |res| 
				if(res["PlanEstimate"]==nil)
					value=0
				else
					value = res["PlanEstimate"].to_i
				end
				@logger.info("#{variablename} for story #{objectid} is #{value}")
				@story_ref = res["_ref"]
				case variablename
					when "c_EstCP"
			            update(value,"c_ExpScopingCP".strip)
			        when "c_EstDP"
			            update(value,"c_ExpScopingDP".strip)
			        when "c_EstPltfm"
			            update(value,"c_ExpScopingPlatform".strip)
			        when "c_EstTest"
			            update(value,"c_ExpScopingTest".strip)
			        when "c_EstPerformance"
			            update(value,"c_ExpScopingPerf".strip)
			        when "c_EstDoc"
			            update(value,"c_ExpScopingDoc".strip)
			        else
			            
			        end
			end
		end
	end 
	
=begin
Function Name: get_total
returning: total of all scoping variable values for that feature.
=end

	def get_total
		@total = 0
		result = @query_result.build_query("portfolioitem/feature","c_ExpScopingCP,c_ExpScopingDP,c_ExpScopingPlatform,c_ExpScopingTest,c_ExpScopingPerf,c_ExpScopingDoc","(FormattedID = #{@feature_id})","")
		puts "getting total for #{@feature_id}"
		if(result!=nil)
			result.each do |res| 
				@total = res["c_ExpScopingCP"].to_i
		        @total += res["c_ExpScopingDP"].to_i
		        @total += res["c_ExpScopingPlatform"].to_i
		        @total += res["c_ExpScopingTest"].to_i
		        @total += res["c_ExpScopingPerf"].to_i
		        @total += res["c_ExpScopingDoc"].to_i
			end
		end
	end
	
=begin
 Function Name: update
 parameters:
 1. value: value of estimate extracted from story
 2. variable: feature level scoping variable, For eg:c_ExpScopingDP -> if value is extracted from c_EstDP  
=end

	def update(value,variable)
		update_fields = {}
		update_fields[variable]=value
		rally = @query_result.get_rally_object
		updated = rally.update("portfolioitem","FormattedID|#{@feature_id}",update_fields)
		if updated
			rally.delete(@story_ref)
			@logger.info("#{@story_ref} deleted")
		else
			@logger.info("Could not update #{value} for #{variable}")
		end
	end
end