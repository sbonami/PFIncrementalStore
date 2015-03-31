require 'xcodeproj'

module PFIncrementalStore
  class BuildPhaseManager
    PARSE_OSX_SDK_NAME = "ParseOSX.framework"
    COPY_PHASE_PARSE_OSX_SDK_NAME = "Copy Parse SDK Files to Product Folder"

    def self.generate_copy_phase_for_parse_osx_sdk!
      path_to_project = Dir.glob('*.xcodeproj').first
      if path_to_project
        project = Xcodeproj::Project.open(path_to_project)

        project.targets.each do |target|
          next if target.platform_name != :osx

          build_phase_for(target) if !copy_phase_for_parse_osx_sdk_exists?(target)
        end

        project.save
      end
    end

    def self.build_phase_for(target)
      target.new_copy_files_build_phase("Copy Parse SDK Files to Product Folder").tap do |phase|
        phase.dst_path = ''
        phase.dst_subfolder_spec = Xcodeproj::Constants::COPY_FILES_BUILD_PHASE_DESTINATIONS[:products_directory]

        phase.add_file_reference(parse_osx_file_ref_for(target), true)
      end
    end

    def self.parse_osx_file_ref_for(target)
      file_ref_for(PARSE_OSX_SDK_NAME, target) || new_parse_osx_file_to(target)
    end

    def self.file_ref_for(name, target)
      target.project.root_object.main_group.files.find do |file|
        file.name && file.name == name
      end
    end

    def self.new_parse_osx_file_to(target)
      target.project.new_file(parse_osx_file_from_pods)
    end

    def self.parse_osx_file_from_pods
      "Pods/Parse-OSX-SDK/ParseOSX.framework"
    end

    def self.copy_phase_for_parse_osx_sdk_exists?(target)
      phase_names_for(target.copy_files_build_phases).include?(COPY_PHASE_PARSE_OSX_SDK_NAME)
    end

    def self.phase_names_for(phases)
      phases.collect(&:name)
    end
  end
end

PFIncrementalStore::BuildPhaseManager.generate_copy_phase_for_parse_osx_sdk!
