require 'logger'
#require 'rally_api'
require 'C:\Rally\common\setup'
require './project.rb'
require './artifact.rb'

class Automaton

	@doc = nil

	def initialize(doc,filename,logger)
		@filename = filename
		@doc = doc
		@logger = logger
		@project_name =   @doc.elements['/pfs-scoping-automate/projects/project/rally-project'].text.strip                   
		@rally_url      = @doc.elements['/pfs-scoping-automate/rally/server'].text.strip
		@workspace_name = @doc.elements['/pfs-scoping-automate/projects/project/rally-workspace'].text.strip
#		@user_name      = @doc.elements['/PIstates-rally-automate/rally/user'].text.strip
#		@password  		= @doc.elements['/PIstates-rally-automate/rally/password'].text.strip
		# check passwords for obfuscation
		
		#get_creds
		
	end
	def process
		
		#@doc.elements.each('/pfs-scoping-automate/projects/project') do |project|
			allprojects = Project.new(@doc,@workspace_name,@project_name)
			entire_branch_of_projects = []
			entire_branch_of_projects = allprojects.get_all_projects(@project_name)
			if entire_branch_of_projects.length == 0
				@logger.info( "No results matching '" + @project_name + "' and zero projects found" )
			else
				entire_branch_of_projects.each do |project|

					process_each_feature_of_project(project)
					@logger.info("Project Name: #{project.strip}")
				end
			end
		#end
	end

	def process_each_feature_of_project(project)
		@doc.elements.each('/pfs-scoping-automate/allowed-states/allowed-state') do |allowed|
			@logger.info("state #{allowed.text.strip}")
			artifact = Artifact.new(@doc,@logger)
			artifact.get_all_features_of_project(project,allowed.text.strip)
			
		end

	end
end