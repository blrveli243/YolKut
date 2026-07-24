require 'xcodeproj'
project_path = 'frontend/ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)
runner_target = project.targets.find { |t| t.name == 'Runner' }

# Find the build phases
embed_phase = runner_target.build_phases.find { |p| p.isa == 'PBXCopyFilesBuildPhase' && p.symbol_dst_subfolder_spec == :plug_ins }
run_script_phases = runner_target.build_phases.select { |p| p.isa == 'PBXShellScriptBuildPhase' }

if embed_phase
  # Remove embed_phase from current position
  runner_target.build_phases.delete(embed_phase)
  
  # Find the first run script phase
  first_script_idx = runner_target.build_phases.index(run_script_phases.first) || runner_target.build_phases.length
  
  # Insert embed_phase before the run scripts
  runner_target.build_phases.insert(first_script_idx, embed_phase)
  
  project.save
  puts "Fixed Xcode build phase cycle!"
else
  puts "Embed phase not found."
end
