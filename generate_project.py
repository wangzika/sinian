#!/usr/bin/env python3
import os
import hashlib

def make_uuid(name: str) -> str:
    h = hashlib.md5(name.encode('utf-8')).hexdigest()[:24].upper()
    return h

# File definitions
app_sources = [
    ("SinianApp.swift", "Sinian/App/SinianApp.swift"),
    ("MissYouAttributes.swift", "Sinian/Models/MissYouAttributes.swift"),
    ("MissEvent.swift", "Sinian/Models/MissEvent.swift"),
    ("PairSession.swift", "Sinian/Models/PairSession.swift"),
    ("LiveActivityManager.swift", "Sinian/Services/LiveActivityManager.swift"),
    ("HapticManager.swift", "Sinian/Services/HapticManager.swift"),
    ("SyncService.swift", "Sinian/Services/SyncService.swift"),
    ("MainView.swift", "Sinian/Views/MainView.swift"),
    ("PairingView.swift", "Sinian/Views/PairingView.swift"),
    ("MemoryTimelineView.swift", "Sinian/Views/MemoryTimelineView.swift"),
    ("HeartbeatButton.swift", "Sinian/Views/Components/HeartbeatButton.swift"),
    ("IslandSimulatorCard.swift", "Sinian/Views/Components/IslandSimulatorCard.swift"),
]

widget_sources = [
    ("MissYouAttributes.swift", "Sinian/Models/MissYouAttributes.swift"),
    ("SinianIslandWidgetBundle.swift", "SinianIslandWidget/SinianIslandWidgetBundle.swift"),
    ("SinianIslandWidget.swift", "SinianIslandWidget/SinianIslandWidget.swift"),
    ("LockScreenActivityView.swift", "SinianIslandWidget/LockScreenActivityView.swift"),
]

all_file_paths = {}
for name, path in app_sources:
    all_file_paths[path] = name
for name, path in widget_sources:
    all_file_paths[path] = name

all_file_paths["Sinian/App/Info.plist"] = "Info.plist"
all_file_paths["SinianIslandWidget/Info.plist"] = "Info.plist"

# UUID mapping
file_ref_uuids = {path: make_uuid(f"FILE_REF_{path}") for path in all_file_paths}
app_build_file_uuids = {path: make_uuid(f"APP_BUILD_FILE_{path}") for _, path in app_sources}
widget_build_file_uuids = {path: make_uuid(f"WIDGET_BUILD_FILE_{path}") for _, path in widget_sources}

# Products
app_product_uuid = make_uuid("PROD_APP")
widget_product_uuid = make_uuid("PROD_WIDGET")
widget_embed_build_file_uuid = make_uuid("WIDGET_EMBED_BUILD_FILE")
widget_dependency_uuid = make_uuid("WIDGET_DEP")
widget_container_item_proxy_uuid = make_uuid("WIDGET_PROXY")

# Targets
app_target_uuid = make_uuid("TARGET_APP")
widget_target_uuid = make_uuid("TARGET_WIDGET")

# Build phases
app_sources_phase_uuid = make_uuid("PHASE_APP_SOURCES")
app_frameworks_phase_uuid = make_uuid("PHASE_APP_FRAMEWORKS")
app_resources_phase_uuid = make_uuid("PHASE_APP_RESOURCES")
app_embed_widget_phase_uuid = make_uuid("PHASE_APP_EMBED_WIDGET")

widget_sources_phase_uuid = make_uuid("PHASE_WIDGET_SOURCES")
widget_frameworks_phase_uuid = make_uuid("PHASE_WIDGET_FRAMEWORKS")
widget_resources_phase_uuid = make_uuid("PHASE_WIDGET_RESOURCES")

# Configs
proj_cfg_debug_uuid = make_uuid("CFG_PROJ_DEBUG")
proj_cfg_release_uuid = make_uuid("CFG_PROJ_RELEASE")
proj_cfg_list_uuid = make_uuid("CFG_LIST_PROJ")

app_cfg_debug_uuid = make_uuid("CFG_APP_DEBUG")
app_cfg_release_uuid = make_uuid("CFG_APP_RELEASE")
app_cfg_list_uuid = make_uuid("CFG_LIST_APP")

widget_cfg_debug_uuid = make_uuid("CFG_WIDGET_DEBUG")
widget_cfg_release_uuid = make_uuid("CFG_WIDGET_RELEASE")
widget_cfg_list_uuid = make_uuid("CFG_LIST_WIDGET")

# Groups
main_group_uuid = make_uuid("GROUP_MAIN")
products_group_uuid = make_uuid("GROUP_PRODUCTS")
sinian_group_uuid = make_uuid("GROUP_SINIAN")
widget_group_uuid = make_uuid("GROUP_WIDGET")

project_uuid = make_uuid("PROJECT_ROOT")

content = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
"""

for _, path in app_sources:
    fname = os.path.basename(path)
    content += f"\t\t{app_build_file_uuids[path]} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuids[path]} /* {fname} */; }};\n"

for _, path in widget_sources:
    fname = os.path.basename(path)
    content += f"\t\t{widget_build_file_uuids[path]} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuids[path]} /* {fname} */; }};\n"

content += f"\t\t{widget_embed_build_file_uuid} /* SinianIslandWidget.appex in Embed App Extensions */ = {{isa = PBXBuildFile; fileRef = {widget_product_uuid} /* SinianIslandWidget.appex */; settings = {{ATTRIBUTES = (RemoveHeadersOnCopy, ); }}; }};\n"

content += """/* End PBXBuildFile section */

/* Begin PBXContainerItemProxy section */
"""
content += f"""\t\t{widget_container_item_proxy_uuid} /* PBXContainerItemProxy */ = {{
\t\t\tisa = PBXContainerItemProxy;
\t\t\tcontainerPortal = {project_uuid} /* Project object */;
\t\t\tproxyType = 1;
\t\t\tremoteGlobalIDString = {widget_target_uuid};
\t\t\tremoteInfo = SinianIslandWidget;
\t\t}};
"""
content += """/* End PBXContainerItemProxy section */

/* Begin PBXCopyFilesBuildPhase section */
"""
content += f"""\t\t{app_embed_widget_phase_uuid} /* Embed App Extensions */ = {{
\t\t\tisa = PBXCopyFilesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tdstPath = "";
\t\t\tdstSubfolderSpec = 13;
\t\t\tfiles = (
\t\t\t\t{widget_embed_build_file_uuid} /* SinianIslandWidget.appex in Embed App Extensions */,
\t\t\t);
\t\t\tname = "Embed App Extensions";
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
"""
content += """/* End PBXCopyFilesBuildPhase section */

/* Begin PBXFileReference section */
"""

for path, fname in all_file_paths.items():
    content += f"\t\t{file_ref_uuids[path]} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{path}\"; sourceTree = SOURCE_ROOT; }};\n"

content += f"\t\t{app_product_uuid} /* Sinian.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Sinian.app; sourceTree = BUILT_PRODUCTS_DIR; }};\n"
content += f"\t\t{widget_product_uuid} /* SinianIslandWidget.appex */ = {{isa = PBXFileReference; explicitFileType = \"wrapper.app-extension\"; includeInIndex = 0; path = SinianIslandWidget.appex; sourceTree = BUILT_PRODUCTS_DIR; }};\n"

content += """/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
"""
content += f"""\t\t{app_frameworks_phase_uuid} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
\t\t{widget_frameworks_phase_uuid} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
"""
content += """/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
"""

app_file_refs_str = "\n".join([f"\t\t\t\t{file_ref_uuids[path]} /* {os.path.basename(path)} */," for _, path in app_sources] + [f"\t\t\t\t{file_ref_uuids['Sinian/App/Info.plist']} /* Info.plist */,"])
widget_file_refs_str = "\n".join([f"\t\t\t\t{file_ref_uuids[path]} /* {os.path.basename(path)} */," for _, path in widget_sources if path.startswith("SinianIslandWidget")] + [f"\t\t\t\t{file_ref_uuids['SinianIslandWidget/Info.plist']} /* Info.plist */,"])

content += f"""\t\t{main_group_uuid} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{sinian_group_uuid} /* Sinian */,
\t\t\t\t{widget_group_uuid} /* SinianIslandWidget */,
\t\t\t\t{products_group_uuid} /* Products */,
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{products_group_uuid} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{app_product_uuid} /* Sinian.app */,
\t\t\t\t{widget_product_uuid} /* SinianIslandWidget.appex */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{sinian_group_uuid} /* Sinian */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{app_file_refs_str}
\t\t\t);
\t\t\tname = Sinian;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{widget_group_uuid} /* SinianIslandWidget */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{widget_file_refs_str}
\t\t\t);
\t\t\tname = SinianIslandWidget;
\t\t\tsourceTree = "<group>";
\t\t}};
"""
content += """/* End PBXGroup section */

/* Begin PBXNativeTarget section */
"""

app_sources_refs_str = "\n".join([f"\t\t\t\t{app_build_file_uuids[path]} /* {os.path.basename(path)} in Sources */," for _, path in app_sources])
widget_sources_refs_str = "\n".join([f"\t\t\t\t{widget_build_file_uuids[path]} /* {os.path.basename(path)} in Sources */," for _, path in widget_sources])

content += f"""\t\t{app_target_uuid} /* Sinian */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {app_cfg_list_uuid} /* Build configuration list for PBXNativeTarget "Sinian" */;
\t\t\tbuildPhases = (
\t\t\t\t{app_sources_phase_uuid} /* Sources */,
\t\t\t\t{app_frameworks_phase_uuid} /* Frameworks */,
\t\t\t\t{app_resources_phase_uuid} /* Resources */,
\t\t\t\t{app_embed_widget_phase_uuid} /* Embed App Extensions */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t\t{widget_dependency_uuid} /* PBXTargetDependency */,
\t\t\t);
\t\t\tname = Sinian;
\t\t\tproductName = Sinian;
\t\t\tproductReference = {app_product_uuid} /* Sinian.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
\t\t{widget_target_uuid} /* SinianIslandWidget */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {widget_cfg_list_uuid} /* Build configuration list for PBXNativeTarget "SinianIslandWidget" */;
\t\t\tbuildPhases = (
\t\t\t\t{widget_sources_phase_uuid} /* Sources */,
\t\t\t\t{widget_frameworks_phase_uuid} /* Frameworks */,
\t\t\t\t{widget_resources_phase_uuid} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = SinianIslandWidget;
\t\t\tproductName = SinianIslandWidget;
\t\t\tproductReference = {widget_product_uuid} /* SinianIslandWidget.appex */;
\t\t\tproductType = "com.apple.product-type.app-extension";
\t\t}};
"""
content += """/* End PBXNativeTarget section */

/* Begin PBXProject section */
"""
content += f"""\t\t{project_uuid} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1500;
\t\t\t\tLastUpgradeCheck = 1500;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{app_target_uuid} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;
\t\t\t\t\t}};
\t\t\t\t\t{widget_target_uuid} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {proj_cfg_list_uuid} /* Build configuration list for PBXProject "Sinian" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = {main_group_uuid};
\t\t\tproductRefGroup = {products_group_uuid} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{app_target_uuid} /* Sinian */,
\t\t\t\t{widget_target_uuid} /* SinianIslandWidget */,
\t\t\t);
\t\t}};
"""
content += """/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
"""
content += f"""\t\t{app_resources_phase_uuid} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
\t\t{widget_resources_phase_uuid} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
"""
content += """/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
"""
content += f"""\t\t{app_sources_phase_uuid} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{app_sources_refs_str}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
\t\t{widget_sources_phase_uuid} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{widget_sources_refs_str}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
"""
content += """/* End PBXSourcesBuildPhase section */

/* Begin PBXTargetDependency section */
"""
content += f"""\t\t{widget_dependency_uuid} /* PBXTargetDependency */ = {{
\t\t\tisa = PBXTargetDependency;
\t\t\ttarget = {widget_target_uuid} /* SinianIslandWidget */;
\t\t\ttargetProxy = {widget_container_item_proxy_uuid} /* PBXContainerItemProxy */;
\t\t}};
"""
content += """/* End PBXTargetDependency section */

/* Begin XCBuildConfiguration section */
"""

common_settings = """
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_NO_COMMON_BLOCKS = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MTL_FAST_MATH = YES;
				SDKROOT = iphoneos;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1";
"""

content += f"""\t\t{proj_cfg_debug_uuid} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
{common_settings}
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_TESTABILITY = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				ONLY_ACTIVE_ARCH = YES;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			}};
			name = Debug;
		}};
\t\t{proj_cfg_release_uuid} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
{common_settings}
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				SWIFT_COMPILATION_MODE = "wholemodule";
				SWIFT_OPTIMIZATION_LEVEL = "-O";
			}};
			name = Release;
		}};
		{app_cfg_debug_uuid} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = L45Z34Z4Y8;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = Sinian/App/Info.plist;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.wangzhibo.sinian;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
			}};
			name = Debug;
		}};
		{app_cfg_release_uuid} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = L45Z34Z4Y8;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = Sinian/App/Info.plist;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.wangzhibo.sinian;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
			}};
			name = Release;
		}};
		{widget_cfg_debug_uuid} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = L45Z34Z4Y8;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = SinianIslandWidget/Info.plist;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
					"@executable_path/../../Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.wangzhibo.sinian.island;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SKIP_INSTALL = YES;
				SWIFT_EMIT_LOC_STRINGS = YES;
			}};
			name = Debug;
		}};
		{widget_cfg_release_uuid} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = L45Z34Z4Y8;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = SinianIslandWidget/Info.plist;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
					"@executable_path/../../Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.wangzhibo.sinian.island;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SKIP_INSTALL = YES;
				SWIFT_EMIT_LOC_STRINGS = YES;
			}};
			name = Release;
		}};
"""
content += """/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
"""
content += f"""\t\t{proj_cfg_list_uuid} /* Build configuration list for PBXProject "Sinian" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{proj_cfg_debug_uuid} /* Debug */,
\t\t\t\t{proj_cfg_release_uuid} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{app_cfg_list_uuid} /* Build configuration list for PBXNativeTarget "Sinian" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{app_cfg_debug_uuid} /* Debug */,
\t\t\t\t{app_cfg_release_uuid} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{widget_cfg_list_uuid} /* Build configuration list for PBXNativeTarget "SinianIslandWidget" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{widget_cfg_debug_uuid} /* Debug */,
\t\t\t\t{widget_cfg_release_uuid} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
"""
content += """/* End XCConfigurationList section */

	};
"""
content += f"\trootObject = {project_uuid} /* Project object */;\n}}\n"

os.makedirs("Sinian.xcodeproj", exist_ok=True)
with open("Sinian.xcodeproj/project.pbxproj", "w") as f:
    f.write(content)

print("Generated Sinian.xcodeproj/project.pbxproj successfully!")

# Also generate shared xcscheme for Sinian so xcodebuild can build scheme "Sinian"
scheme_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{app_target_uuid}"
               BuildableName = "Sinian.app"
               BlueprintName = "Sinian"
               ReferencedContainer = "container:Sinian.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{widget_target_uuid}"
               BuildableName = "SinianIslandWidget.appex"
               BlueprintName = "SinianIslandWidget"
               ReferencedContainer = "container:Sinian.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{app_target_uuid}"
            BuildableName = "Sinian.app"
            BlueprintName = "Sinian"
            ReferencedContainer = "container:Sinian.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
</Scheme>
"""

schemes_dir = "Sinian.xcodeproj/xcshareddata/xcschemes"
os.makedirs(schemes_dir, exist_ok=True)
with open(f"{schemes_dir}/Sinian.xcscheme", "w") as f:
    f.write(scheme_content)

print("Generated Sinian.xcscheme successfully!")
