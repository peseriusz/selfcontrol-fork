source 'https://github.com/CocoaPods/Specs.git'

minVersion = '12.0'

platform :osx, minVersion

# cocoapods-prune-localizations doesn't appear to auto-detect pods properly, so using a manual list
supported_locales = ['Base', 'da', 'de', 'en', 'es', 'fr', 'it', 'ja', 'ko', 'nl', 'pt-BR', 'sv', 'tr', 'zh-Hans']
plugin 'cocoapods-prune-localizations', { :localizations => supported_locales }

target "SelfControl" do
    use_frameworks! :linkage => :static
    pod 'MASPreferences', '~> 1.1.4'
    pod 'TransformerKit', '~> 1.1.1'
    pod 'FormatterKit/TimeIntervalFormatter', '~> 1.8.0'
    pod 'LetsMove', '~> 1.24'
    pod 'Sentry', :git => 'https://github.com/getsentry/sentry-cocoa.git', :tag => '8.46.0'
    
    # Add test target
    target 'SelfControlTests' do
        inherit! :complete
    end
end

target "SelfControl Killer" do
    use_frameworks! :linkage => :static
    pod 'Sentry', :git => 'https://github.com/getsentry/sentry-cocoa.git', :tag => '8.46.0'
end

target "SCKillerHelper" do
    use_frameworks! :linkage => :static
    pod 'Sentry', :git => 'https://github.com/getsentry/sentry-cocoa.git', :tag => '8.46.0'
end
target "selfcontrol-cli" do
    use_frameworks! :linkage => :static
    pod 'Sentry', :git => 'https://github.com/getsentry/sentry-cocoa.git', :tag => '8.46.0'
end
target "org.eyebeam.selfcontrold" do
    use_frameworks! :linkage => :static
    pod 'Sentry', :git => 'https://github.com/getsentry/sentry-cocoa.git', :tag => '8.46.0'
end

CLI_TARGETS = ['selfcontrol-cli', 'org.eyebeam.selfcontrold', 'SCKillerHelper'].freeze
CLI_POD_RESOURCE_SCRIPTS = ['Pods-selfcontrol-cli', 'Pods-org.eyebeam.selfcontrold', 'Pods-SCKillerHelper'].freeze

def fix_maspreferences_resource_paths_in_user_project(project_dir)
    require 'xcodeproj'
    maspreferences_nib = '${PODS_CONFIGURATION_BUILD_DIR}/MASPreferences/MASPreferences.framework/Versions/A/Resources/en.lproj/MASPreferencesWindow.nib'
    old_paths = [
        '${BUILT_PRODUCTS_DIR}/MASPreferences/MASPreferences.framework/en.lproj/MASPreferencesWindow.nib',
        '${PODS_CONFIGURATION_BUILD_DIR}/MASPreferences/MASPreferences.framework/en.lproj/MASPreferencesWindow.nib'
    ]

    project = Xcodeproj::Project.open(File.join(project_dir, 'SelfControl.xcodeproj'))
    project.targets.each do |target|
        target.shell_script_build_phases.each do |phase|
            next unless phase.name == '[CP] Copy Pods Resources'
            phase.input_paths.map! do |path|
                old_paths.include?(path) ? maspreferences_nib : path
            end
        end
    end
    project.save
end

def strip_sentry_resource_bundle_from_cli_targets(project_dir)
    require 'xcodeproj'
    project = Xcodeproj::Project.open(File.join(project_dir, 'SelfControl.xcodeproj'))
    project.targets.each do |target|
        next unless CLI_TARGETS.include?(target.name)
        target.build_phases.delete_if do |phase|
            phase.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) &&
                phase.name == '[CP] Copy Pods Resources'
        end
    end
    project.save
end

def strip_sentry_from_cli_pod_resource_scripts(pods_root)
    CLI_POD_RESOURCE_SCRIPTS.each do |name|
        script = File.join(pods_root, 'Target Support Files', name, "#{name}-resources.sh")
        next unless File.exist?(script)

        contents = File.read(script)
        patched = contents.gsub(/^\s*install_resource.*Sentry\.bundle.*\n/, '')
        next if patched == contents

        File.write(script, patched)
        File.chmod(0o755, script)
    end
end

def ensure_pod_scripts_executable(pods_root)
    Dir.glob(File.join(pods_root, 'Target Support Files', '**', '*.sh')).each do |script|
        File.chmod(0o755, script)
    end
end

def fix_maspreferences_resource_paths(pods_root)
    maspreferences_nib = '${PODS_CONFIGURATION_BUILD_DIR}/MASPreferences/MASPreferences.framework/Versions/A/Resources/en.lproj/MASPreferencesWindow.nib'
    Dir.glob(File.join(pods_root, 'Target Support Files', '**', '*-resources.sh')).each do |script|
        contents = File.read(script)
        patched = contents
            .gsub('${BUILT_PRODUCTS_DIR}/MASPreferences/MASPreferences.framework/en.lproj/MASPreferencesWindow.nib', maspreferences_nib)
            .gsub('${PODS_CONFIGURATION_BUILD_DIR}/MASPreferences/MASPreferences.framework/en.lproj/MASPreferencesWindow.nib', maspreferences_nib)
        next if patched == contents

        File.write(script, patched)
        File.chmod(0o755, script)
    end
end

def allow_empty_cli_resource_copy_scripts(pods_root)
    CLI_POD_RESOURCE_SCRIPTS.each do |name|
        script = File.join(pods_root, 'Target Support Files', name, "#{name}-resources.sh")
        next unless File.exist?(script)

        contents = File.read(script)
        marker = 'if [[ ! -s "$RESOURCES_TO_COPY" ]]; then'
        next if contents.include?(marker)

        patched = contents.sub(
            "mkdir -p \"${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}\"",
            "#{marker}\n  rm -f \"$RESOURCES_TO_COPY\"\n  exit 0\nfi\n\nmkdir -p \"${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}\""
        )
        File.write(script, patched)
        File.chmod(0o755, script)
    end
end

def fix_duplicate_sentry_build_outputs(pods_project)
    pods_project.targets.each do |target|
        if target.name == 'Sentry-library' || target.name == 'Sentry-library-Sentry'
            target.build_configurations.each do |bc|
                bc.build_settings['ENABLE_APP_INTENTS_METADATA_GENERATION'] = 'NO'
            end
        end

        next unless target.name == 'Sentry-library-Sentry'

        target.build_configurations.each do |bc|
            bc.build_settings['PRODUCT_NAME'] = 'SentryLibraryResources'
        end
        target.product_reference.path = 'SentryLibraryResources.bundle' if target.product_reference
    end
end

def patch_transformer_kit_imports(pods_root)
    sources_dir = File.join(pods_root, 'TransformerKit/Sources')
    return unless File.directory?(sources_dir)

    Dir.glob(File.join(sources_dir, '**/*.{h,m}')).each do |file|
        contents = File.read(file)
        patched = contents
            .gsub('@import Darwin.Availability;', '#import <Availability.h>')
            .gsub('@import Darwin.C.time;', '#import <time.h>')
            .gsub('@import Darwin.C.xlocale;', '#import <xlocale.h>')
        if patched != contents
            File.chmod(0o644, file)
            File.write(file, patched)
        end
    end
end

post_install do |pi|
   patch_transformer_kit_imports(pi.sandbox.root)
   strip_sentry_from_cli_pod_resource_scripts(pi.sandbox.root)
   fix_maspreferences_resource_paths(pi.sandbox.root)
   allow_empty_cli_resource_copy_scripts(pi.sandbox.root)

   fix_duplicate_sentry_build_outputs(pi.pods_project)

   pi.pods_project.targets.each do |t|
       t.build_configurations.each do |bc|
           if Gem::Version.new(bc.build_settings['MACOSX_DEPLOYMENT_TARGET']) < Gem::Version.new(minVersion)
               bc.build_settings['MACOSX_DEPLOYMENT_TARGET'] = minVersion
           end
       end
   end

   ensure_pod_scripts_executable(pi.sandbox.root)
end

def add_codesign_fixup_phase(project_dir)
    require 'xcodeproj'
    project = Xcodeproj::Project.open(File.join(project_dir, 'SelfControl.xcodeproj'))
    target = project.targets.find { |t| t.name == 'SelfControl' }
    return unless target

    phase = target.shell_script_build_phases.find { |p| p.name == 'Re-sign App Bundle' }
    unless phase
        phase = target.new_shell_script_build_phase('Re-sign App Bundle')
        cp_index = target.build_phases.index { |p| p.name == '[CP] Copy Pods Resources' }
        target.build_phases.move(phase, cp_index + 1) if cp_index
    end

    phase.shell_script = <<~'SCRIPT'
      set -e
      APP_PATH="${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}"
      [ -d "${APP_PATH}" ] || exit 0

      SIGN_IDENTITY="${EXPANDED_CODE_SIGN_IDENTITY:--}"
      SIGN_OPTS="${OTHER_CODE_SIGN_FLAGS}"
      if [ -d "${APP_PATH}/Contents/Frameworks" ]; then
        find "${APP_PATH}/Contents/Frameworks" -type d -name '*.framework' | while read -r framework; do
          EXEC_NAME="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "${framework}/Resources/Info.plist" 2>/dev/null || true)"
          if [ -z "${EXEC_NAME}" ]; then
            EXEC_NAME="$(basename "${framework}" .framework)"
          fi
          EXEC_PATH="${framework}/Versions/A/${EXEC_NAME}"
          if [ -f "${EXEC_PATH}" ]; then
            /usr/bin/codesign --remove-signature "${EXEC_PATH}" 2>/dev/null || true
            /usr/bin/codesign --force ${SIGN_OPTS} --sign "${SIGN_IDENTITY}" "${EXEC_PATH}" || true
          fi
          /usr/bin/codesign --force ${SIGN_OPTS} --sign "${SIGN_IDENTITY}" "${framework}" || true
        done
      fi
      /usr/bin/codesign --force --deep ${SIGN_OPTS} --sign "${SIGN_IDENTITY}" "${APP_PATH}"
    SCRIPT

    project.save
end

def fix_cli_framework_search_paths(project_dir)
    require 'xcodeproj'
    project = Xcodeproj::Project.open(File.join(project_dir, 'SelfControl.xcodeproj'))
    project.targets.each do |target|
        next unless CLI_TARGETS.include?(target.name)
        target.build_configurations.each do |bc|
            bc.build_settings['FRAMEWORK_SEARCH_PATHS'] = [
                '$(inherited)',
                '$(PLATFORM_DIR)/Developer/Library/Frameworks'
            ]
        end
    end
    project.save
end

def disable_swift_stdlib_embed_for_cli_tools(project_dir)
    require 'xcodeproj'
    project = Xcodeproj::Project.open(File.join(project_dir, 'SelfControl.xcodeproj'))
    project.targets.each do |target|
        next unless CLI_TARGETS.include?(target.name)
        target.build_configurations.each do |bc|
            bc.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'NO'
            bc.build_settings['ENABLE_DEBUG_DYLIB'] = 'NO'
        end
    end
    project.save
end

post_integrate do |_pi|
   fix_maspreferences_resource_paths_in_user_project(__dir__)
   strip_sentry_resource_bundle_from_cli_targets(__dir__)
   disable_swift_stdlib_embed_for_cli_tools(__dir__)
   fix_cli_framework_search_paths(__dir__)
   add_codesign_fixup_phase(__dir__)
end
