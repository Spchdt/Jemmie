require 'xcodeproj'

project_path = 'Jemmie.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Check if Jemmie uses Synchronized Root Groups (Xcode 15+)
if project.main_group.children.any? { |c| c.class.name.include?("SynchronizedRootGroup") }
  puts "Project uses synchronized folder structure. Xcode will automatically include the new Swift files."
else
  # Fallback for older Xcode projects
  group = project.main_group.find_subpath('Jemmie/Extensions', true)
  service_group = project.main_group.find_subpath('Jemmie/Services', true)

  extensions_to_add = [
    'Jemmie/Extensions/Color+Theme.swift',
    'Jemmie/Extensions/View+Accessibility.swift'
  ]

  services_to_add = [
    'Jemmie/Services/LocationService.swift'
  ]

  extensions_to_add.each do |file_path|
    file_ref = group.new_reference(file_path)
    target.source_build_phase.add_file_reference(file_ref)
  end

  services_to_add.each do |file_path|
    file_ref = service_group.new_reference(file_path)
    target.source_build_phase.add_file_reference(file_ref)
  end

  project.save
  puts "Added files manually."
end
