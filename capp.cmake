set(CAPP_BUILD_TYPE Release)

if (WIN32)
  set(CMAKE_PROGRAM_PATH "C:/Program Files") #workaround a workaround for MSVC 2017 in FindGit.cmake
endif()
find_package(Git REQUIRED)

function(capp_execute)
  cmake_parse_arguments(PARSE_ARGV 0 capp_execute "" "WORKING_DIRECTORY;RESULT_VARIABLE;OUTPUT_VARIABLE;ERROR_VARIABLE" "COMMAND")
  string(REPLACE ";" " " capp_execute_printable "${capp_execute_COMMAND}")
  message("executing ${capp_execute_printable}")
  message("in ${capp_execute_WORKING_DIRECTORY}")
  execute_process(
      COMMAND ${capp_execute_COMMAND}
      WORKING_DIRECTORY "${capp_execute_WORKING_DIRECTORY}"
      RESULT_VARIABLE capp_execute_result
      OUTPUT_VARIABLE capp_execute_output
      ERROR_VARIABLE capp_execute_error
  )
  message("${capp_execute_output}")
  message("${capp_execute_error}")
  if (NOT capp_execute_result EQUAL 0)
    message("command ${capp_execute_printable} failed: ${capp_execute_result}")
  endif()
  set(${capp_execute_RESULT_VARIABLE} "${capp_execute_result}" PARENT_SCOPE)
  if (capp_execute_OUTPUT_VARIABLE)
    set(${capp_execute_OUTPUT_VARIABLE} "${capp_execute_output}" PARENT_SCOPE)
  endif()
  if (capp_execute_ERROR_VARIABLE)
    set(${capp_execute_ERROR_VARIABLE} "${capp_execute_error}" PARENT_SCOPE)
  endif()
endfunction()

function(capp_checkout)
  cmake_parse_arguments(PARSE_ARGV 0 capp_checkout "" "DIRECTORY;COMMIT;RESULT_VARIABLE" "")
  capp_execute(
    COMMAND "${GIT_EXECUTABLE}" checkout ${capp_checkout_COMMIT}
    WORKING_DIRECTORY "${CAPP_SOURCE_ROOT}/${capp_checkout_DIRECTORY}"
    RESULT_VARIABLE git_checkout_result
    )
  set(${capp_checkout_RESULT_VARIABLE} "${git_checkout_result}" PARENT_SCOPE)
endfunction()

function(capp_add_file)
  cmake_parse_arguments(PARSE_ARGV 0 capp_add_file "" "RESULT_VARIABLE;FILE" "")
  capp_execute(
    COMMAND "${GIT_EXECUTABLE}" add "${capp_add_file_FILE}"
    WORKING_DIRECTORY "${CAPP_ROOT}"
    RESULT_VARIABLE git_add_result
  )
  set(${capp_add_file_RESULT_VARIABLE} ${git_add_result} PARENT_SCOPE)
endfunction()

function(capp_commit)
  cmake_parse_arguments(PARSE_ARGV 0 capp_commit "" "RESULT_VARIABLE;MESSAGE" "")
  capp_execute(
    COMMAND "${GIT_EXECUTABLE}" commit -m "${capp_commit_MESSAGE}"
    WORKING_DIRECTORY "${CAPP_ROOT}"
    RESULT_VARIABLE git_commit_result
  )
  set(${capp_commit_RESULT_VARIABLE} ${git_commit_result} PARENT_SCOPE)
endfunction()

function(capp_clone)
  cmake_parse_arguments(PARSE_ARGV 0 capp_clone "" "DIRECTORY;GIT_URL;COMMIT;RESULT_VARIABLE" "")
  capp_execute(
    COMMAND "${GIT_EXECUTABLE}" clone -n ${capp_clone_GIT_URL} ${capp_clone_DIRECTORY}
    WORKING_DIRECTORY "${CAPP_SOURCE_ROOT}"
    RESULT_VARIABLE git_clone_result
    )
  if (NOT git_clone_result EQUAL 0)
    set(${capp_clone_RESULT_VARIABLE} "${git_clone_result}" PARENT_SCOPE)
    return()
  endif()
  capp_checkout(
      DIRECTORY ${capp_clone_DIRECTORY}
      COMMIT ${capp_clone_COMMIT}
      RESULT_VARIABLE capp_checkout_result
  )
  set(${capp_clone_RESULT_VARIABLE} "${capp_checkout_result}" PARENT_SCOPE)
endfunction()

function(capp_configure)
  cmake_parse_arguments(PARSE_ARGV 0 capp_configure "" "DIRECTORY;RESULT_VARIABLE" "OPTIONS")
  make_directory("${CAPP_BUILD_ROOT}/${capp_configure_DIRECTORY}")
  capp_execute(
      COMMAND
      "${CMAKE_COMMAND}"
      "${CAPP_SOURCE_ROOT}/${capp_configure_DIRECTORY}"
      "-DCMAKE_INSTALL_PREFIX=${CAPP_INSTALL_ROOT}/${capp_configure_DIRECTORY}"
      ${capp_configure_OPTIONS}
      WORKING_DIRECTORY "${CAPP_BUILD_ROOT}/${capp_configure_DIRECTORY}"
      RESULT_VARIABLE cmake_configure_result
  )
  set(${capp_configure_RESULT_VARIABLE} "${cmake_configure_result}" PARENT_SCOPE)
endfunction()

function(capp_build)
  cmake_parse_arguments(PARSE_ARGV 0 capp_build "" "DIRECTORY;RESULT_VARIABLE" "")
  capp_execute(
      COMMAND
      "${CMAKE_COMMAND}"
      "--build"
      "."
      "--config"
      ${CAPP_BUILD_TYPE}
      WORKING_DIRECTORY "${CAPP_BUILD_ROOT}/${capp_build_DIRECTORY}"
      RESULT_VARIABLE cmake_build_result
  )
  set(${capp_build_RESULT_VARIABLE} "${cmake_build_result}" PARENT_SCOPE)
endfunction()

function(capp_install)
  cmake_parse_arguments(PARSE_ARGV 0 capp_install "" "DIRECTORY;RESULT_VARIABLE" "")
  capp_execute(
      COMMAND
      "${CMAKE_COMMAND}"
      "--install"
      "."
      "--config"
      ${CAPP_BUILD_TYPE}
      WORKING_DIRECTORY "${CAPP_BUILD_ROOT}/${capp_install_DIRECTORY}"
      RESULT_VARIABLE cmake_install_result
  )
  set(${capp_install_RESULT_VARIABLE} "${cmake_install_result}" PARENT_SCOPE)
endfunction()

function(capp_package)
  cmake_parse_arguments(PARSE_ARGV 0 capp_package "" "NAME;GIT_URL;COMMIT" "OPTIONS;DEPENDENCIES")
  set(CAPP_PACKAGE_NAME ${capp_package_NAME} PARENT_SCOPE)
  set(${capp_package_NAME}_GIT_URL ${capp_package_GIT_URL} PARENT_SCOPE)
  set(${capp_package_NAME}_COMMIT ${capp_package_COMMIT} PARENT_SCOPE)
  set(${capp_package_NAME}_OPTIONS "${capp_package_OPTIONS}" PARENT_SCOPE)
  set(${capp_package_NAME}_DEPENDENCIES "${capp_package_DEPENDENCIES}" PARENT_SCOPE)
endfunction()

function(capp_clone_package)
  cmake_parse_arguments(PARSE_ARGV 0 capp_clone_package "" "NAME;RESULT_VARIABLE" "")
  capp_clone(
      DIRECTORY ${${capp_clone_package_NAME}_DIRECTORY}
      GIT_URL ${${capp_clone_package_NAME}_GIT_URL}
      COMMIT ${${capp_clone_package_NAME}_COMMIT}
      RESULT_VARIABLE capp_clone_result
  )
  set(${capp_clone_package_RESULT_VARIABLE} ${capp_clone_result} PARENT_SCOPE)
endfunction()

function(capp_configure_package)
  cmake_parse_arguments(PARSE_ARGV 0 capp_configure_package "" "NAME;RESULT_VARIABLE" "")
  capp_configure(
      DIRECTORY ${${capp_configure_package_NAME}_DIRECTORY}
      OPTIONS ${${capp_configure_package_NAME}_OPTIONS}
      RESULT_VARIABLE capp_configure_result
  )
  set(${capp_configure_package_RESULT_VARIABLE} ${capp_configure_result} PARENT_SCOPE)
endfunction()

function(capp_build_install_package)
  cmake_parse_arguments(PARSE_ARGV 0 capp_build_install_package "" "NAME;RESULT_VARIABLE" "")
  message("${capp_build_install_package_NAME}_DIRECTORY=${${capp_build_install_package_NAME}_DIRECTORY}")
  capp_build(
      DIRECTORY ${${capp_build_install_package_NAME}_DIRECTORY}
      RESULT_VARIABLE capp_build_result
  )
  if (NOT capp_build_result EQUAL 0)
    message("capp_build_install_packages sees that capp_build failed!")
    set(${capp_build_configure_package_RESULT_VARIABLE} ${capp_build_result} PARENT_SCOPE)
    return()
  else()
    message("capp_build_install_packages sees that capp_build succeeded!")
  endif()
  capp_install(
      DIRECTORY ${${capp_build_install_package_NAME}_DIRECTORY}
      RESULT_VARIABLE capp_install_result
  )
  set(${capp_build_configure_package_RESULT_VARIABLE} ${capp_install_result} PARENT_SCOPE)
endfunction()

function(capp_read_package_file)
  cmake_parse_arguments(PARSE_ARGV 0 capp_read_package_file "" "DIRECTORY" "")
  set(capp_read_package_file_path "${CAPP_ROOT}/packages/${capp_read_package_file_DIRECTORY}/package.cmake")
  include("${capp_read_package_file_path}")
  set(CAPP_PACKAGE_NAME ${CAPP_PACKAGE_NAME} PARENT_SCOPE)
  set(${CAPP_PACKAGE_NAME}_GIT_URL ${${CAPP_PACKAGE_NAME}_GIT_URL} PARENT_SCOPE)
  set(${CAPP_PACKAGE_NAME}_COMMIT ${${CAPP_PACKAGE_NAME}_COMMIT} PARENT_SCOPE)
  set(${CAPP_PACKAGE_NAME}_OPTIONS "${${CAPP_PACKAGE_NAME}_OPTIONS}" PARENT_SCOPE)
  set(${CAPP_PACKAGE_NAME}_DEPENDENCIES "${${CAPP_PACKAGE_NAME}_DEPENDENCIES}" PARENT_SCOPE)
  set(${CAPP_PACKAGE_NAME}_DIRECTORY ${capp_read_package_file_DIRECTORY} PARENT_SCOPE)
endfunction()

function(capp_write_package_file)
  cmake_parse_arguments(PARSE_ARGV 0 capp_write_package_file "" "NAME" "")
  set(file_contents)
  set(file_contents "${file_contents}capp_package(\n")
  set(file_contents "${file_contents}  NAME ${capp_write_package_file_NAME}\n")
  set(file_contents "${file_contents}  GIT_URL ${${capp_write_package_file_NAME}_GIT_URL}\n")
  set(file_contents "${file_contents}  COMMIT ${${capp_write_package_file_NAME}_COMMIT}\n")
  set(file_contents "${file_contents}  OPTIONS ${${capp_write_package_file_NAME}_OPTIONS}\n")
  set(file_contents "${file_contents}  DEPENDENCIES ${${capp_write_package_file_NAME}_DEPENDENCIES}\n")
  set(file_contents "${file_contents})\n")
  set(full_directory "${CAPP_PACKAGE_ROOT}/${${capp_write_package_file_NAME}_DIRECTORY}")
  make_directory("${full_directory}")
  file(WRITE "${full_directory}/package.cmake" "${file_contents}")
endfunction()

function(capp_update_package_commit)
  cmake_parse_arguments(PARSE_ARGV 0 capp_update_package_commit "" "NAME;RESULT_VARIABLE" "")
  capp_execute(
    COMMAND "${GIT_EXECUTABLE}" rev-parse HEAD
    WORKING_DIRECTORY "${CAPP_SOURCE_ROOT}/${${capp_update_package_commit_NAME}_DIRECTORY}"
    RESULT_VARIABLE git_rev_parse_result
    OUTPUT_VARIABLE git_rev_parse_output
    )
  set(${capp_update_package_commit_RESULT_VARIABLE} ${git_rev_parse_result} PARENT_SCOPE)
  if (git_rev_parse_result EQUAL 0)
    string(STRIP "${git_rev_parse_output}" git_commit)
    set(${capp_update_package_commit_NAME}_COMMIT ${git_commit} PARENT_SCOPE)
  endif()
endfunction()

function(capp_update_package_git_url)
  cmake_parse_arguments(PARSE_ARGV 0 capp_update_package_git_url "" "NAME;RESULT_VARIABLE" "")
  capp_execute(
    COMMAND "${GIT_EXECUTABLE}" remote show -n origin
    WORKING_DIRECTORY "${CAPP_SOURCE_ROOT}/${${capp_update_package_git_url_NAME}_DIRECTORY}"
    RESULT_VARIABLE git_remote_show_result
    OUTPUT_VARIABLE git_remote_show_output
    )
  set(${capp_update_package_git_url_RESULT_VARIABLE} ${git_remote_show_result} PARENT_SCOPE)
  if (NOT git_remote_show_result EQUAL 0)
    return()
  endif()
  string(REGEX MATCH "Fetch URL: [^\n]+\n" git_fetch_url "${git_remote_show_output}")
  string(LENGTH "Fetch URL: " header_length)
  string(SUBSTRING "${git_fetch_url}" ${header_length} -1 git_url_newline)
  string(STRIP "${git_url_newline}" git_url)
  set(${capp_update_package_git_url_NAME}_GIT_URL ${git_url} PARENT_SCOPE)
endfunction()

function(capp_clone_command)
  cmake_parse_arguments(PARSE_ARGV 0 capp_clone_command "" "RESULT_VARIABLE" "GIT_ARGUMENTS")
  make_directory("${CAPP_SOURCE_ROOT}")
  capp_execute(
    COMMAND "${GIT_EXECUTABLE}" clone ${capp_clone_command_GIT_ARGUMENTS}
    WORKING_DIRECTORY "${CAPP_SOURCE_ROOT}"
    RESULT_VARIABLE git_clone_result
    ERROR_VARIABLE git_clone_error
  )
  if (NOT git_clone_result EQUAL 0)
    set(${capp_clone_command_RESULT_VARIABLE} ${git_clone_result} PARENT_SCOPE)
    return()
  endif()
  string(REGEX MATCH "'[^']+'" git_directory_quoted "${git_clone_error}")
  string(LENGTH "${git_directory_quoted}" git_directory_quoted_length)
  math(EXPR git_directory_length "${git_directory_quoted_length} - 2")
  string(SUBSTRING "${git_directory_quoted}" 1 ${git_directory_length} git_directory)
  string(REPLACE "-" "_" name_guess "${git_directory}")
  set(CAPP_PACKAGE_NAME ${name_guess})
  set(${CAPP_PACKAGE_NAME}_DIRECTORY "${git_directory}")
  capp_update_package_git_url(
    NAME ${CAPP_PACKAGE_NAME}
    RESULT_VARIABLE capp_update_package_git_url_result
  )
  if (NOT capp_update_package_git_url_result EQUAL 0)
    set(${capp_clone_command_RESULT_VARIABLE} ${capp_update_package_git_url_result} PARENT_SCOPE)
    return()
  endif()
  capp_update_package_commit(
    NAME ${CAPP_PACKAGE_NAME}
    RESULT_VARIABLE capp_update_package_commit_result
  )
  if (NOT capp_update_package_commit_result EQUAL 0)
    set(${capp_clone_command_RESULT_VARIABLE} ${capp_update_package_commit_result} PARENT_SCOPE)
    return()
  endif()
  capp_write_package_file(NAME ${CAPP_PACKAGE_NAME})
  set(${capp_clone_command_RESULT_VARIABLE} 0 PARENT_SCOPE)
  capp_add_file(
    FILE "${CAPP_PACKAGE_ROOT}/${${CAPP_PACKAGE_NAME}_DIRECTORY}/package.cmake"
    RESULT_VARIABLE capp_add_file_result
  )
  if (NOT capp_add_file_result EQUAL 0)
    set(${capp_clone_command_RESULT_VARIABLE} ${capp_add_file_result} PARENT_SCOPE)
    return()
  endif()
  capp_commit(
    MESSAGE "Create skeleton package ${CAPP_PACKAGE_NAME}"
    RESULT_VARIABLE capp_commit_result
  )
  if (NOT capp_commit_result EQUAL 0)
    set(${capp_clone_command_RESULT_VARIABLE} ${capp_commit_result} PARENT_SCOPE)
    return()
  endif()
  set(${capp_clone_command_RESULT_VARIABLE} 0 PARENT_SCOPE)
endfunction()

function(capp_init_command)
  cmake_parse_arguments(PARSE_ARGV 0 capp_init_command "" "NAME;RESULT_VARIABLE" "")
  capp_execute(
    COMMAND "${GIT_EXECUTABLE}" init
    WORKING_DIRECTORY "${CAPP_ROOT}"
    RESULT_VARIABLE git_init_result
  )
  if (NOT git_init_result EQUAL 0)
    set(${capp_init_command_RESULT_VARIABLE} ${git_init_result} PARENT_SCOPE)
    return()
  endif()
  file(WRITE "${CAPP_ROOT}/app.cmake" "set(CAPP_APP ${capp_init_command_NAME})")
  capp_add_file(
    FILE "${CAPP_ROOT}/app.cmake"
    RESULT_VARIABLE capp_add_file_result
  )
  if (NOT capp_add_file_result EQUAL 0)
    set(${capp_init_command_RESULT_VARIABLE} ${capp_add_file_result} PARENT_SCOPE)
    return()
  endif()
  file(WRITE "${CAPP_ROOT}/.gitignore" "source\nbuild\ninstall")
  capp_add_file(
    FILE "${CAPP_ROOT}/.gitignore"
    RESULT_VARIABLE capp_add_file_result
  )
  if (NOT capp_add_file_result EQUAL 0)
    set(${capp_init_command_RESULT_VARIABLE} ${capp_add_file_result} PARENT_SCOPE)
    return()
  endif()
  capp_commit(
    MESSAGE "Creating app ${capp_init_command_NAME}"
    RESULT_VARIABLE capp_commit_result
  )
  set(${capp_init_command_RESULT_VARIABLE} ${capp_commit_result} PARENT_SCOPE)
endfunction()

math(EXPR ARGC_MINUS_ONE "${CMAKE_ARGC} - 1")
if (CMAKE_ARGC LESS 4)
  message(FATAL_ERROR "No command specified!")
  return()
endif()
set(CAPP_COMMAND "${CMAKE_ARGV3}")
set(CAPP_COMMAND_ARGUMENTS)
foreach(argi RANGE 4 ${ARGC_MINUS_ONE})
  set(CAPP_COMMAND_ARGUMENTS ${CAPP_COMMAND_ARGUMENTS} "${CMAKE_ARGV${argi}}")
endforeach()

set(CAPP_ROOT "${CMAKE_CURRENT_SOURCE_DIR}")
if (CAPP_COMMAND STREQUAL "init")
  capp_init_command(
    NAME ${CAPP_COMMAND_ARGUMENTS}
    RESULT_VARIABLE capp_command_result
  )
else()
  set(CAPP_TRUE TRUE)
  while (CAPP_TRUE)
    get_filename_component(CAPP_ROOT_PARENT "${CAPP_ROOT}" DIRECTORY)
    if (CAPP_ROOT_PARENT STREQUAL CAPP_ROOT)
      message(FATAL_ERROR "Could not find app.cmake in ${CMAKE_CURRENT_SOURCE_DIR} or any parent directories: Run capp init first")
      return()
    endif()
    if (EXISTS "${CAPP_ROOT}/app.cmake")
      include("${CAPP_ROOT}/app.cmake")
      break()
    endif()
    set(CAPP_ROOT "${CAPP_ROOT_PARENT}")
  endwhile()
  set(CAPP_SOURCE_ROOT "${CAPP_ROOT}/source")
  set(CAPP_BUILD_ROOT "${CAPP_ROOT}/build")
  set(CAPP_INSTALL_ROOT "${CAPP_ROOT}/install")
  set(CAPP_PACKAGE_ROOT "${CAPP_ROOT}/package")
  if (CAPP_COMMAND STREQUAL "clone")
    capp_clone_command(
      GIT_ARGUMENTS ${CAPP_COMMAND_ARGUMENTS}
      RESULT_VARIABLE capp_command_result
    )
  else()
    message(FATAL_ERROR "Unknown command ${CAPP_COMMAND}!")
  endif()
endif()

if (NOT capp_command_result EQUAL 0)
  message(FATAL_ERROR "CApp command ${CAPP_COMMAND} failed")
endif()
