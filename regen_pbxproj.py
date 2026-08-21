#!/usr/bin/env python3
"""重新生成完整且正确的 Xcode project.pbxproj"""

import os
import hashlib
import textwrap

PROJECT_DIR = "/Users/wang/Documents/minke/JSKeyboard"

def uid(name):
    """生成稳定唯一 ID"""
    h = hashlib.md5(name.encode()).hexdigest()[:8].upper()
    return h

# 所有源文件
SRC_FILES = {
    # 主应用 Swift 文件
    ("JSKeyboard/AppDelegate.swift", "sourcecode.swift"),
    ("JSKeyboard/SceneDelegate.swift", "sourcecode.swift"),
    ("JSKeyboard/Models/DataManager.swift", "sourcecode.swift"),
    ("JSKeyboard/Models/TextCategory.swift", "sourcecode.swift"),
    ("JSKeyboard/Models/ClipboardEntry.swift", "sourcecode.swift"),
    ("JSKeyboard/Models/JSFunction.swift", "sourcecode.swift"),
    ("JSKeyboard/Models/Settings.swift", "sourcecode.swift"),
    ("JSKeyboard/ViewControllers/TabBarController.swift", "sourcecode.swift"),
    ("JSKeyboard/ViewControllers/TextTabViewController.swift", "sourcecode.swift"),
    ("JSKeyboard/ViewControllers/ClipboardTabViewController.swift", "sourcecode.swift"),
    ("JSKeyboard/ViewControllers/JSTabViewController.swift", "sourcecode.swift"),
    ("JSKeyboard/ViewControllers/SettingsTabViewController.swift", "sourcecode.swift"),
    ("JSKeyboard/Extensions/ViewModelExtensions.swift", "sourcecode.swift"),
    # 资源文件
    ("JSKeyboard/Info.plist", "text.plist.xml"),
    ("JSKeyboard/JSKeyboard.entitlements", "text.plist.entitlements"),
    ("JSKeyboard/Assets.xcassets/Contents.json", "text.json"),
    ("JSKeyboard/Assets.xcassets/AppIcon.appiconset/Contents.json", "text.json"),
    # 键盘扩展
    ("JSKeyboardExtension/KeyboardViewController.swift", "sourcecode.swift"),
    ("JSKeyboardExtension/JSKeyboardView.swift", "sourcecode.swift"),
    ("JSKeyboardExtension/Info.plist", "text.plist.xml"),
    ("JSKeyboardExtension/JSKeyboardExtension.entitlements", "text.plist.entitlements"),
}

# 生成文件引用映射
file_refs = {}
for fp, ft in SRC_FILES:
    file_refs[(fp, ft)] = uid(fp + ft)

# 关键 ID
proj_uuid       = uid("project_root")
root_group      = uid("root_group")
app_group       = uid("app_group")
ext_group       = uid("ext_group")
fwk_group       = uid("fwk_group")
lib_group       = uid("lib_group")
prod_group      = uid("prod_group")
assets_group    = uid("assets_group")
models_group    = uid("models_group")
vc_group        = uid("vc_group")
extn_group      = uid("extn_group")

target_app      = uid("target_app")
target_ext      = uid("target_ext")
prod_app        = uid("prod_app")
prod_ext        = uid("prod_ext")

cfg_app_dbg     = uid("cfg_app_dbg")
cfg_app_rel     = uid("cfg_app_rel")
cfg_ext_dbg     = uid("cfg_ext_dbg")
cfg_ext_rel     = uid("cfg_ext_rel")
list_app        = uid("list_app")
list_ext        = uid("list_ext")
list_proj       = uid("list_proj")

src_ph_app      = uid("src_ph_app")
res_ph_app      = uid("res_ph_app")
fwk_ph_app      = uid("fwk_ph_app")
src_ph_ext      = uid("src_ph_ext")
res_ph_ext      = uid("res_ph_ext")
fwk_ph_ext      = uid("fwk_ph_ext")

proj_uuid2 = proj_uuid  # same

L = []

def w(s=""):
    L.append(s)

w("// !$*UTF$!*")
w("objectVersion = 56;")
w("objects = {")

# ─── PBXBuildFile ───
w("\t/* Begin PBXBuildFile section */")
for fp, ft in SRC_FILES:
    fid = file_refs[(fp, ft)]
    fn = os.path.basename(fp)
    w(f'\t\t{fid} /* {fn} in Resources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {fn} */; }};')
w("\t/* End PBXBuildFile section */")

# ─── PBXFileReference ───
w("\n\t/* Begin PBXFileReference section */")
for fp, ft in SRC_FILES:
    fid = file_refs[(fp, ft)]
    fn = os.path.basename(fp)
    rel = os.path.relpath(fp, PROJECT_DIR)
    w(f'\t\t{fid} /* {fn} */ = {{isa = PBXFileReference; path = {rel}; sourceTree = "<group>"; }};')

# 产品引用
w(f'\t\t{prod_app} /* JSKeyboard.app */ = {{isa = PBXProductReference; explicitFileType = application.identifier; path = JSKeyboard.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
w(f'\t\t{prod_ext} /* JSKeyboardExtension.appex */ = {{isa = PBXProductReference; explicitFileType = "com.apple.product-type.bundle"; path = JSKeyboardExtension.appex; sourceTree = BUILT_PRODUCTS_DIR; }};')
w("\t/* End PBXFileReference section */")

# ─── PBXFrameworksBuildPhase ───
w("\n\t/* Begin PBXFrameworksBuildPhase section */")
w(f'\t\t{fwk_ph_app} /* Frameworks */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (\n\t\t); runOnlyForDeploymentPostprocessing = 0; }};')
w(f'\t\t{fwk_ph_ext} /* Frameworks */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (\n\t\t); runOnlyForDeploymentPostprocessing = 0; }};')
w("\t/* End PBXFrameworksBuildPhase section */")

# ─── PBXGroup ───
w("\n\t/* Begin PBXGroup section */")

# Root
w(f'\t\t{root_group} /* JSKeyboard */ = {{isa = PBXGroup; children = (\n\t\t\t{app_group} /* JSKeyboard */;\n\t\t\t{ext_group} /* JSKeyboardExtension */;\n\t\t\t{fwk_group} /* Frameworks */;\n\t\t\t{lib_group} /* Libraries */;\n\t\t\t{prod_group} /* Products */;\n\t\t); sourceTree = "<group>"; }};')

# App group
app_src = [fp for fp, ft in SRC_FILES if fp.startswith("JSKeyboard/") and ft == "sourcecode.swift"]
app_res = [fp for fp, ft in SRC_FILES if fp.startswith("JSKeyboard/") and ft != "sourcecode.swift"]

src_refs = "\n".join(f'\t\t\t{file_refs[(fp,"sourcecode.swift")]} /* {os.path.basename(fp)} */;' for fp in app_src)
res_refs = "\n".join(f'\t\t\t{file_refs[(fp,ft)]} /* {os.path.basename(fp)} */;' for fp,ft in [(fp,ft) for fp,ft in SRC_FILES if fp.startswith("JSKeyboard/") and ft != "sourcecode.swift"])

w(f'\t\t{app_group} /* JSKeyboard */ = {{isa = PBXGroup; children = (\n{src_refs}\n{res_refs}\n\t\t\t{assets_group} /* Assets.xcassets */;\n\t\t\t{models_group} /* Models */;\n\t\t\t{vc_group} /* ViewControllers */;\n\t\t\t{extn_group} /* Extensions */;\n\t\t); name = JSKeyboard; sourceTree = "<group>"; }};')

# Models
model_files = [fp for fp, ft in SRC_FILES if "Models/" in fp]
model_refs = "\n".join(f'\t\t\t{file_refs[(fp,ft)]} /* {os.path.basename(fp)} */;' for fp,ft in model_files)
w(f'\t\t{models_group} /* Models */ = {{isa = PBXGroup; children = (\n{model_refs}\n\t\t); name = Models; sourceTree = "<group>"; }};')

# ViewControllers
vc_files = [fp for fp, ft in SRC_FILES if "ViewControllers/" in fp]
vc_refs = "\n".join(f'\t\t\t{file_refs[(fp,ft)]} /* {os.path.basename(fp)} */;' for fp,ft in vc_files)
w(f'\t\t{vc_group} /* ViewControllers */ = {{isa = PBXGroup; children = (\n{vc_refs}\n\t\t); name = ViewControllers; sourceTree = "<group>"; }};')

# Extensions
extn_files = [fp for fp, ft in SRC_FILES if fp.startswith("JSKeyboard/Extensions/")]
extn_refs = "\n".join(f'\t\t\t{file_refs[(fp,ft)]} /* {os.path.basename(fp)} */;' for fp,ft in extn_files)
w(f'\t\t{extn_group} /* Extensions */ = {{isa = PBXGroup; children = (\n{extn_refs}\n\t\t); name = Extensions; sourceTree = "<group>"; }};')

# Assets
assets_files = [fp for fp, ft in SRC_FILES if "Assets.xcassets" in fp]
assets_refs = "\n".join(f'\t\t\t{file_refs[(fp,ft)]} /* {os.path.basename(fp)} */;' for fp,ft in assets_files)
w(f'\t\t{assets_group} /* Assets.xcassets */ = {{isa = PBXGroup; children = (\n{assets_refs}\n\t\t); name = Assets.xcassets; sourceTree = "<group>"; }};')

# Extension group
ext_src = [fp for fp, ft in SRC_FILES if fp.startswith("JSKeyboardExtension/")]
ext_refs = "\n".join(f'\t\t\t{file_refs[(fp,ft)]} /* {os.path.basename(fp)} */;' for fp,ft in ext_src)
w(f'\t\t{ext_group} /* JSKeyboardExtension */ = {{isa = PBXGroup; children = (\n{ext_refs}\n\t\t); path = JSKeyboardExtension; sourceTree = "<group>"; }};')

w(f'\t\t{fwk_group} /* Frameworks */ = {{isa = PBXGroup; sourceTree = "<group>"; }};')
w(f'\t\t{lib_group} /* Libraries */ = {{isa = PBXGroup; sourceTree = "<group>"; }};')
w(f'\t\t{prod_group} /* Products */ = {{isa = PBXGroup; children = (\n\t\t\t{prod_app} /* JSKeyboard.app */;\n\t\t\t{prod_ext} /* JSKeyboardExtension.appex */;\n\t\t); name = Products; sourceTree = "<group>"; }};')
w("\t/* End PBXGroup section */")

# ─── PBXNativeTarget ───
w("\n\t/* Begin PBXNativeTarget section */")
w(f'''\t\t{target_app} /* JSKeyboard */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {list_app} /* Configurations */;
\t\t\tbuildPhases = (
\t\t\t\t{src_ph_app} /* Sources */;
\t\t\t\t{fwk_ph_app} /* Frameworks */;
\t\t\t\t{res_ph_app} /* Resources */;
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = JSKeyboard;
\t\t\tproductName = JSKeyboard;
\t\t\tproductReference = {prod_app} /* JSKeyboard.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};''')
w(f'''\t\t{target_ext} /* JSKeyboardExtension */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {list_ext} /* Configurations */;
\t\t\tbuildPhases = (
\t\t\t\t{src_ph_ext} /* Sources */;
\t\t\t\t{fwk_ph_ext} /* Frameworks */;
\t\t\t\t{res_ph_ext} /* Resources */;
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = JSKeyboardExtension;
\t\t\tproductName = JSKeyboardExtension;
\t\t\tproductReference = {prod_ext} /* JSKeyboardExtension.appex */;
\t\t\tproductType = "com.apple.product-type.bundle";
\t\t}};''')
w("\t/* End PBXNativeTarget section */")

# ─── PBXProject ───
w("\n\t/* Begin PBXProject section */")
w(f'''\t\t{proj_uuid} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1500;
\t\t\t\tLastUpgradeCheck = 1500;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{target_app} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;
\t\t\t\t\t}};
\t\t\t\t\t{target_ext} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {list_proj} /* Configurations */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t\tzh-Hans,
\t\t\t);
\t\t\tmainGroup = {root_group};
\t\t\tproductRefGroup = {prod_group} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{target_app} /* JSKeyboard */,
\t\t\t\t{target_ext} /* JSKeyboardExtension */,
\t\t\t);
\t\t}};''')
w("\t/* End PBXProject section */")

# ─── PBXSourcesBuildPhase ───
w("\n\t/* Begin PBXSourcesBuildPhase section */")
# App sources
app_swift = [fp for fp, ft in SRC_FILES if fp.startswith("JSKeyboard/") and ft == "sourcecode.swift"]
app_src_items = "\n".join(f'\t\t\t\t{file_refs[(fp,"sourcecode.swift")]} /* {os.path.basename(fp)} in Sources */;' for fp in app_swift)
w(f'\t\t{src_ph_app} /* Sources */ = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (\n{app_src_items}\n\t\t); runOnlyForDeploymentPostprocessing = 0; }};')

# Ext sources
ext_swift = [fp for fp, ft in SRC_FILES if fp.startswith("JSKeyboardExtension/") and ft == "sourcecode.swift"]
ext_src_items = "\n".join(f'\t\t\t\t{file_refs[(fp,"sourcecode.swift")]} /* {os.path.basename(fp)} in Sources */;' for fp in ext_swift)
w(f'\t\t{src_ph_ext} /* Sources */ = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (\n{ext_src_items}\n\t\t); runOnlyForDeploymentPostprocessing = 0; }};')
w("\t/* End PBXSourcesBuildPhase section */")

# ─── PBXResourcesBuildPhase ───
w("\n\t/* Begin PBXResourcesBuildPhase section */")
app_res_files = [(fp, ft) for fp, ft in SRC_FILES if fp.startswith("JSKeyboard/") and ft != "sourcecode.swift"]
app_res_items = "\n".join(f'\t\t\t\t{file_refs[(fp,ft)]} /* {os.path.basename(fp)} in Resources */;' for fp,ft in app_res_files)
w(f'\t\t{res_ph_app} /* Resources */ = {{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (\n{app_res_items}\n\t\t); runOnlyForDeploymentPostprocessing = 0; }};')

ext_res_files = [(fp, ft) for fp, ft in SRC_FILES if fp.startswith("JSKeyboardExtension/") and ft != "sourcecode.swift"]
ext_res_items = "\n".join(f'\t\t\t\t{file_refs[(fp,ft)]} /* {os.path.basename(fp)} in Resources */;' for fp,ft in ext_res_files)
w(f'\t\t{res_ph_ext} /* Resources */ = {{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (\n{ext_res_items}\n\t\t); runOnlyForDeploymentPostprocessing = 0; }};')
w("\t/* End PBXResourcesBuildPhase section */")

# ─── XCBuildConfiguration ───
w("\n\t/* Begin XCBuildConfiguration section */")
w(f'\t\t{cfg_app_dbg} /* Debug */ = {{isa = XCBuildConfiguration; buildSettings = {{ ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon; CLANG_ENABLE_MODULES = YES; COPY_PHASE_STRIP = NO; DEBUG_INFORMATION_FORMAT = dwarf; GCC_OPTIMIZATION_LEVEL = 0; IPHONEOS_DEPLOYMENT_TARGET = 15.0; MTLS_LANGUAGE_OPTIONS = (ObjC); ONLY_ACTIVE_ARCH = YES; PRODUCT_BUNDLE_IDENTIFIER = com.jskeyboard.app; SDKROOT = iphoneos; SWIFT_ACTIVE_COMPILATION_CONDITIONS = (DEBUG ); SWIFT_OPTIMIZATION_LEVEL = "-Onone"; TARGETED_DEVICE_FAMILY = "1,2"; VALID_ARCHS = arm64; }}; name = Debug; }};')
w(f'\t\t{cfg_app_rel} /* Release */ = {{isa = XCBuildConfiguration; buildSettings = {{ ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon; CLANG_ENABLE_MODULES = YES; COPY_PHASE_STRIP = NO; DEBUG_INFORMATION_FORMAT = dwarf-with-dsym; ENABLE_NS_ASSERTIONS = YES; IPHONEOS_DEPLOYMENT_TARGET = 15.0; MTLS_LANGUAGE_OPTIONS = (ObjC); PRODUCT_BUNDLE_IDENTIFIER = com.jskeyboard.app; SDKROOT = iphoneos; SWIFT_COMPILATION_MODE = wholemodule; SWIFT_OPTIMIZATION_LEVEL = "-O"; TARGETED_DEVICE_FAMILY = "1,2"; VALID_ARCHS = arm64; }}; name = Release; }};')
w(f'\t\t{cfg_ext_dbg} /* Debug */ = {{isa = XCBuildConfiguration; buildSettings = {{ CLANG_ENABLE_MODULES = YES; DEBUG_INFORMATION_FORMAT = dwarf; IPHONEOS_DEPLOYMENT_TARGET = 15.0; MTLS_LANGUAGE_OPTIONS = (ObjC); PRODUCT_BUNDLE_IDENTIFIER = com.jskeyboard.app.keyboard; SDKROOT = iphoneos; SWIFT_ACTIVE_COMPILATION_CONDITIONS = (DEBUG ); SWIFT_OPTIMIZATION_LEVEL = "-Onone"; TARGETED_DEVICE_FAMILY = "1,2"; VALID_ARCHS = arm64; }}; name = Debug; }};')
w(f'\t\t{cfg_ext_rel} /* Release */ = {{isa = XCBuildConfiguration; buildSettings = {{ CLANG_ENABLE_MODULES = YES; DEBUG_INFORMATION_FORMAT = dwarf-with-dsym; ENABLE_NS_ASSERTIONS = YES; IPHONEOS_DEPLOYMENT_TARGET = 15.0; MTLS_LANGUAGE_OPTIONS = (ObjC); PRODUCT_BUNDLE_IDENTIFIER = com.jskeyboard.app.keyboard; SDKROOT = iphoneos; SWIFT_COMPILATION_MODE = wholemodule; SWIFT_OPTIMIZATION_LEVEL = "-O"; TARGETED_DEVICE_FAMILY = "1,2"; VALID_ARCHS = arm64; }}; name = Release; }};')
w("\t/* End XCBuildConfiguration section */")

# ─── XCConfigurationList ───
w("\n\t/* Begin XCConfigurationList section */")
w(f'\t\t{list_app} /* Configurations */ = {{isa = XCConfigurationList; buildConfigurations = (\n\t\t\t{cfg_app_dbg} /* Debug */,\n\t\t\t{cfg_app_rel} /* Release */,\n\t\t); defaultConfigurationIsVisible = 0; defaultConfigurationName = Debug; }};')
w(f'\t\t{list_ext} /* Configurations */ = {{isa = XCConfigurationList; buildConfigurations = (\n\t\t\t{cfg_ext_dbg} /* Debug */,\n\t\t\t{cfg_ext_rel} /* Release */,\n\t\t); defaultConfigurationIsVisible = 0; defaultConfigurationName = Debug; }};')
w(f'\t\t{list_proj} /* Configurations */ = {{isa = XCConfigurationList; buildConfigurations = (\n\t\t\t{cfg_app_dbg} /* Debug */,\n\t\t\t{cfg_app_rel} /* Release */,\n\t\t); defaultConfigurationIsVisible = 0; defaultConfigurationName = Debug; }};')
w("\t/* End XCConfigurationList section */")

w("\t};")
w(f"rootObject = {proj_uuid} /* Project object */;")
w("}")

# 写入
proj_path = os.path.join(PROJECT_DIR, "JSKeyboard.xcodeproj", "project.pbxproj")
os.makedirs(os.path.dirname(proj_path), exist_ok=True)
with open(proj_path, "w") as f:
    f.write("\n".join(L))

print(f"✅ project.pbxproj 已重新生成 ({len(L)} 行)")
print(f"📁 {proj_path}")
