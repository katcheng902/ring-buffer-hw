# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.7

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:


#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:


# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES =

.SUFFIXES: .hpux_make_needs_suffix_list


# Suppress display of executed commands.
$(VERBOSE).SILENT:


# A target that is always out of date.
cmake_force:

.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/bin/cmake

# The command to remove a file.
RM = /usr/bin/cmake -E remove -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /root/bf-sde-9.8.0/p4studio

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /root/ring-buffer/build

# Utility rule file for ring_buffer.

# Include the progress variables for this target.
include CMakeFiles/ring_buffer.dir/progress.make

ring_buffer: CMakeFiles/ring_buffer.dir/build.make

.PHONY : ring_buffer

# Rule to build all files generated by this target.
CMakeFiles/ring_buffer.dir/build: ring_buffer

.PHONY : CMakeFiles/ring_buffer.dir/build

CMakeFiles/ring_buffer.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/ring_buffer.dir/cmake_clean.cmake
.PHONY : CMakeFiles/ring_buffer.dir/clean

CMakeFiles/ring_buffer.dir/depend:
	cd /root/ring-buffer/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /root/bf-sde-9.8.0/p4studio /root/bf-sde-9.8.0/p4studio /root/ring-buffer/build /root/ring-buffer/build /root/ring-buffer/build/CMakeFiles/ring_buffer.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/ring_buffer.dir/depend
