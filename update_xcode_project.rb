require 'xcodeproj'

project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first # Runner target

# 1. Update Known Regions
['zh-Hans', 'zh-Hant'].each do |region|
  unless project.root_object.known_regions.include?(region)
    project.root_object.known_regions << region
  end
end

# 2. Get the 'Runner' group
runner_group = project.main_group.find_subpath('Runner', true)

# 3. Create or Find InfoPlist.strings Variant Group
# Check if it already exists
variant_group = runner_group.children.find { |c| c.kind_of?(Xcodeproj::Project::Object::PBXVariantGroup) && c.name == 'InfoPlist.strings' }

if variant_group.nil?
  puts "Creating InfoPlist.strings variant group..."
  variant_group = runner_group.new_variant_group('InfoPlist.strings')
  # Add to Resources Build Phase
  target.resources_build_phase.add_file_reference(variant_group)
else
  puts "Found existing InfoPlist.strings variant group."
end

# 4. Add Localized Files to the Variant Group
['Base', 'zh-Hans', 'zh-Hant'].each do |lang|
  file_name = "#{lang}.lproj/InfoPlist.strings"
  
  # Check if this language is already in the variant group
  existing_ref = variant_group.files.find { |f| f.path == file_name || (f.name == lang && f.path.end_with?("InfoPlist.strings")) }
  
  if existing_ref
    puts "  Reference for #{lang} already exists."
  else
    puts "  Adding reference for #{lang}..."
    # The path should be relative to the project or group. Since Runner group has path 'Runner',
    # and files are in 'ios/Runner/<lang>.lproj', relative path is '<lang>.lproj/InfoPlist.strings'
    ref = variant_group.new_reference(file_name)
    ref.name = lang
  end
end

project.save
puts "Project saved."
