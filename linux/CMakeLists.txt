# Project-level configuration.
cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
set(BINARY_NAME "wing")
# The unique GTK application identifier for this application. See:
# https://wiki.gnome.org/HowDoI/ChooseApplicationID
set(APPLICATION_ID "com.trebuchetdynamics.hermes.wing")

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(SET CMP0063 NEW)

# Load bundled libraries from the lib/ directory relative to the binary.
set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

# Root filesystem for cross-building.
if(FLUTTER_TARGET_PLATFORM_SYSROOT)
  set(CMAKE_SYSROOT ${FLUTTER_TARGET_PLATFORM_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
  set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
endif()

# Define build configuration options.
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE "Debug" CACHE
    STRING "Flutter build mode" FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
    "Debug" "Profile" "Release")
endif()

# Compilation settings that should be applied to most targets.
#
# Be cautious about adding new options here, as plugins use this function by
# default. In most cases, you should add new options to specific targets instead
# of modifying this function.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_14)
  target_compile_options(${TARGET} PRIVATE -Wall -Werror)
  target_compile_options(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:-O3>")
  target_compile_definitions(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:NDEBUG>")
endfunction()

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# System-level dependencies.
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)

# Application build; see runner/CMakeLists.txt.
add_subdirectory("runner")

# Build the bounded Linux host supervisor from source and bundle it beside Wing.
# The Flutter process invokes only this sibling binary, never a PATH candidate.
find_program(GO_EXECUTABLE go REQUIRED)
file(GLOB WING_LINK_GO_SOURCES CONFIGURE_DEPENDS
  "${CMAKE_SOURCE_DIR}/../wing_link/*.go")
set(WING_LINK_BUNDLE_BINARY "${CMAKE_BINARY_DIR}/wing-link")
if(DEFINED FLUTTER_VERSION_NAME AND NOT FLUTTER_VERSION_NAME STREQUAL "")
  set(WING_LINK_VERSION "${FLUTTER_VERSION_NAME}")
else()
  set(WING_LINK_VERSION "dev")
endif()
add_custom_command(
  OUTPUT "${WING_LINK_BUNDLE_BINARY}"
  COMMAND "${CMAKE_COMMAND}" -E env CGO_ENABLED=0
    "${GO_EXECUTABLE}" build -trimpath
    "-ldflags=-s -w -X main.version=${WING_LINK_VERSION}"
    -o "${WING_LINK_BUNDLE_BINARY}" .
  WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}/../wing_link"
  DEPENDS ${WING_LINK_GO_SOURCES}
    "${CMAKE_SOURCE_DIR}/../wing_link/go.mod"
    "${CMAKE_SOURCE_DIR}/../wing_link/go.sum"
  COMMENT "Building bundled Wing Link host supervisor"
  VERBATIM)
add_custom_target(wing_link_host ALL DEPENDS "${WING_LINK_BUNDLE_BINARY}")
add_dependencies(${BINARY_NAME} wing_link_host)

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)

# Only the install-generated bundle's copy of the executable will launch
# correctly, since the resources must in the right relative locations. To avoid
# people trying to run the unbundled copy, put it in a subdirectory instead of
# the default top-level location.
set_target_properties(${BINARY_NAME}
  PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/intermediates_do_not_run"
)


# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
include(flutter/generated_plugins.cmake)

# Flutter plugins are copied into the bundle rather than installed as CMake
# targets. Give every generated plugin a sibling-relative runtime path so the
# release cannot fall back to Flutter's checkout-specific ephemeral directory.
foreach(plugin ${FLUTTER_PLUGIN_LIST})
  if(TARGET ${plugin}_plugin)
    set_target_properties(${plugin}_plugin PROPERTIES
      BUILD_WITH_INSTALL_RPATH TRUE
      INSTALL_RPATH "$ORIGIN")
  endif()
endforeach()


# === Installation ===
# By default, "installing" just makes a relocatable bundle in the build
# directory.
set(BUILD_BUNDLE_DIR "${PROJECT_BINARY_DIR}/bundle")
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

# Start with a clean build bundle directory every time.
install(CODE "
  file(REMOVE_RECURSE \"${BUILD_BUNDLE_DIR}/\")
  " COMPONENT Runtime)

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}/lib")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)
install(PROGRAMS "${WING_LINK_BUNDLE_BINARY}"
  DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

foreach(bundled_library ${PLUGIN_BUNDLED_LIBRARIES})
  install(FILES "${bundled_library}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
  # flutter_onnxruntime links against libonnxruntime.so.1, while its downloaded
  # bundle input is named libonnxruntime.so. Keep both names in the release.
  if("${bundled_library}" MATCHES
      "flutter_onnxruntime/onnxruntime/.*/libonnxruntime\\.so$")
    get_filename_component(onnxruntime_library_dir
      "${bundled_library}" DIRECTORY)
    get_filename_component(onnxruntime_runtime_file
      "${bundled_library}" REALPATH)
    target_link_options(${BINARY_NAME} PRIVATE
      "-Wl,-rpath-link,${onnxruntime_library_dir}")
    install(FILES "${onnxruntime_runtime_file}"
      DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
      RENAME "libonnxruntime.so.1"
      COMPONENT Runtime)
  endif()
endforeach(bundled_library)

# Copy the native assets provided by the build.dart from all packages.
set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/linux/")
install(DIRECTORY "${NATIVE_ASSETS_DIR}"
   DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
   COMPONENT Runtime)

# Fully re-copy the assets directory on each build to avoid having stale files
# from a previous install.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# Install the AOT library on non-Debug builds only.
if(NOT CMAKE_BUILD_TYPE MATCHES "Debug")
  install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()
