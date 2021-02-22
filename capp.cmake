set(CAPP_BUILD_TYPE Release)
set(CAPP_TRUE TRUE)

if (WIN32)
  set(CMAKE_PROGRAM_PATH "C:/Program Files") #workaround a workaround for MSVC 2017 in FindGit.cmake
endif()
find_package(Git REQUIRED QUIET)

function(capp_subdirectories)
  cmake_parse_arguments(PARSE_ARGV 0 capp_subdirectories "" "PARENT_DIRECTORY;RESULT_VARIABLE" "")
  file(GLOB children RELATIVE "${capp_subdirectories_PARENT_DIRECTORY}" "${capp_subdirectories_PARENT_DIRECTORY}/*")
  set(dirlist "")
  foreach (child ${children})
    if (IS_DIRECTORY "${capp_subdirectories_PARENT_DIRECTORY}/${child}")
      list(APPEND dirlist ${child})
    endif()
  endforeach()
  set(${capp_subdirectories_RESULT_VARIABLE} ${dirlist} PARENT_SCOPE)
endfunction()

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
  cmake_parse_arguments(PARSE_ARGV 0 capp_clone "" "PACKAGE;RESULT_VARIABLE" "")
  make_directory("${CAPP_SOURCE_ROOT}")
  capp_execute(
    COMMAND "${GIT_EXECUTABLE}" clone -n ${${capp_clone_PACKAGE}_GIT_URL} ${capp_clone_PACKAGE}
    WORKING_DIRECTORY "${CAPP_SOURCE_ROOT}"
    RESULT_VARIABLE git_clone_result
    )
  if (NOT git_clone_result EQUAL 0)
    set(${capp_clone_RESULT_VARIABLE} "${git_clone_result}" PARENT_SCOPE)
    return()
  endif()
  capp_execute(
    COMMAND "${GIT_EXECUTABLE}" checkout ${${capp_clone_PACKAGE}_COMMIT}
    WORKING_DIRECTORY "${CAPP_SOURCE_ROOT}/${capp_clone_PACKAGE}"
    RESULT_VARIABLE git_checkout_result
    )
  set(${capp_clone_RESULT_VARIABLE} "${git_checkout_result}" PARENT_SCOPE)
  if (git_checkout_result EQUAL 0)
    set(${capp_clone_PACKAGE}_IS_CLONED TRUE PARENT_SCOPE)
  endif()
endfunction()

function(capp_configure)
  cmake_parse_arguments(PARSE_ARGV 0 capp_configure "" "PACKAGE;RESULT_VARIABLE" "")
  make_directory("${CAPP_BUILD_ROOT}/${capp_configure_PACKAGE}")
  if (WIN32)
    set(build_type_option)
  else()
    set(build_type_option "-DCMAKE_BUILD_TYPE=${CAPP_BUILD_TYPE}")
  endif()
  capp_execute(
      COMMAND
      "${CMAKE_COMMAND}"
      "${CAPP_SOURCE_ROOT}/${capp_configure_PACKAGE}"
      "-DCMAKE_INSTALL_PREFIX=${CAPP_INSTALL_ROOT}/${capp_configure_PACKAGE}"
      ${build_type_option}
      ${${capp_configure_PACKAGE}_OPTIONS}
      WORKING_DIRECTORY "${CAPP_BUILD_ROOT}/${capp_configure_PACKAGE}"
      RESULT_VARIABLE cmake_configure_result
  )
  set(${capp_configure_RESULT_VARIABLE} "${cmake_configure_result}" PARENT_SCOPE)
  if (cmake_configure_result EQUAL 0)
    set(${capp_configure_PACKAGE}_IS_CONFIGURED TRUE PARENT_SCOPE)
    file(WRITE "${CAPP_BUILD_ROOT}/${capp_configure_PACKAGE}/capp_configured.txt" "Yes")
  endif()
endfunction()

function(capp_build)
  cmake_parse_arguments(PARSE_ARGV 0 capp_build "" "PACKAGE;RESULT_VARIABLE" "")
  capp_execute(
      COMMAND
      "${CMAKE_COMMAND}"
      "--build"
      "."
      "--config"
      ${CAPP_BUILD_TYPE}
      WORKING_DIRECTORY "${CAPP_BUILD_ROOT}/${capp_build_PACKAGE}"
      RESULT_VARIABLE cmake_build_result
  )
  set(${capp_build_RESULT_VARIABLE} "${cmake_build_result}" PARENT_SCOPE)
endfunction()

function(capp_install)
  cmake_parse_arguments(PARSE_ARGV 0 capp_install "" "PACKAGE;RESULT_VARIABLE" "")
  capp_execute(
      COMMAND
      "${CMAKE_COMMAND}"
      "--install"
      "."
      "--config"
      ${CAPP_BUILD_TYPE}
      WORKING_DIRECTORY "${CAPP_BUILD_ROOT}/${capp_install_PACKAGE}"
      RESULT_VARIABLE cmake_install_result
  )
  set(${capp_install_RESULT_VARIABLE} "${cmake_install_result}" PARENT_SCOPE)
endfunction()

function(capp_app)
  cmake_parse_arguments(PARSE_ARGV 0 capp_app "" "NAME" "ROOT_PACKAGES")
  set(CAPP_APP_NAME ${capp_app_NAME} PARENT_SCOPE)
  set(CAPP_ROOT_PACKAGES "${capp_app_ROOT_PACKAGES}" PARENT_SCOPE)
endfunction()

function(capp_package)
  cmake_parse_arguments(PARSE_ARGV 0 capp_package "" "GIT_URL;COMMIT" "OPTIONS;DEPENDENCIES")
  set(${CAPP_PACKAGE}_GIT_URL ${capp_package_GIT_URL} PARENT_SCOPE)
  set(${CAPP_PACKAGE}_COMMIT ${capp_package_COMMIT} PARENT_SCOPE)
  set(${CAPP_PACKAGE}_OPTIONS "${capp_package_OPTIONS}" PARENT_SCOPE)
  set(${CAPP_PACKAGE}_DEPENDENCIES "${capp_package_DEPENDENCIES}" PARENT_SCOPE)
endfunction()

function(capp_build_install)
  cmake_parse_arguments(PARSE_ARGV 0 capp_build_install "" "PACKAGE;RESULT_VARIABLE" "")
  capp_build(
    PACKAGE ${capp_build_install_PACKAGE}
    RESULT_VARIABLE capp_build_result
  )
  if (NOT capp_build_result EQUAL 0)
    set(${capp_build_install_RESULT_VARIABLE} ${capp_build_result} PARENT_SCOPE)
    return()
  endif()
  capp_install(
    PACKAGE ${capp_build_install_PACKAGE}
    RESULT_VARIABLE capp_install_result
  )
  set(${capp_build_install_RESULT_VARIABLE} ${capp_install_result} PARENT_SCOPE)
  if (capp_install_result EQUAL 0)
    set(${capp_build_install_PACKAGE}_IS_INSTALLED TRUE PARENT_SCOPE)
    file(WRITE "${CAPP_INSTALL_ROOT}/${capp_configure_PACKAGE}/capp_installed.txt" "Yes")
  endif()
endfunction()

function(capp_read_package_file)
  cmake_parse_arguments(PARSE_ARGV 0 capp_read_package_file "" "PACKAGE" "")
  set(CAPP_PACKAGE ${capp_read_package_file_PACKAGE})
  set(capp_read_package_file_path "${CAPP_PACKAGE_ROOT}/${CAPP_PACKAGE}/package.cmake")
  include("${capp_read_package_file_path}")
  set(${CAPP_PACKAGE}_GIT_URL ${${CAPP_PACKAGE}_GIT_URL} PARENT_SCOPE)
  set(${CAPP_PACKAGE}_COMMIT ${${CAPP_PACKAGE}_COMMIT} PARENT_SCOPE)
  set(${CAPP_PACKAGE}_OPTIONS "${${CAPP_PACKAGE}_OPTIONS}" PARENT_SCOPE)
  set(${CAPP_PACKAGE}_DEPENDENCIES "${${CAPP_PACKAGE}_DEPENDENCIES}" PARENT_SCOPE)
  set(CAPP_PACKAGES ${CAPP_PACKAGES} ${CAPP_PACKAGE} PARENT_SCOPE)
endfunction()

macro(capp_find_root)
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
endmacro()

macro(capp_recursive_read_package_file package)
  list(FIND CAPP_PACKAGES ${package} list_index)
  if (list_index EQUAL -1)
    capp_read_package_file(PACKAGE ${package})
    foreach(dependency IN LISTS ${package}_DEPENDENCIES)
      capp_recursive_read_package_file(${dependency})
    endforeach()
  endif()
endmacro()

macro(capp_read_package_files)
  foreach(root_package IN LISTS CAPP_ROOT_PACKAGES)
    capp_recursive_read_package_file(${root_package})
  endforeach()
endmacro()

function(capp_initialize_needs)
  foreach(package IN LISTS CAPP_PACKAGES)
    if (IS_DIRECTORY "${CAPP_SOURCE_ROOT}/${package}")
      set(${package}_IS_CLONED TRUE)
    else()
      set(${package}_IS_CLONED FALSE)
    endif()
  endforeach()
  foreach(package IN LISTS CAPP_PACKAGES)
    if (${package}_IS_CLONED AND EXISTS "${CAPP_BUILD_ROOT}/${package}/capp_configured.txt")
      set(${package}_IS_CONFIGURED TRUE)
    else()
      set(${package}_IS_CONFIGURED FALSE)
    endif()
  endforeach()
  foreach(package IN LISTS CAPP_PACKAGES)
    if (${package}_IS_CONFIGURED AND EXISTS "${CAPP_INSTALL_ROOT}/${package}/capp_installed.txt")
      set(${package}_IS_INSTALLED TRUE)
    else()
      set(${package}_IS_INSTALLED FALSE)
    endif()
  endforeach()
  foreach(package IN LISTS CAPP_PACKAGES)
    set(${package}_IS_CLONED ${${package}_IS_CLONED} PARENT_SCOPE)
    set(${package}_IS_CONFIGURED ${${package}_IS_CONFIGURED} PARENT_SCOPE)
    set(${package}_IS_INSTALLED ${${package}_IS_INSTALLED} PARENT_SCOPE)
  endforeach()
endfunction()

function(capp_fulfill_needs)
  cmake_parse_arguments(PARSE_ARGV 0 capp_fulfill_needs "" "RESULT_VARIABLE" "")
  while (CAPP_TRUE)
    foreach(package IN LISTS CAPP_PACKAGES)
      if (NOT ${package}_IS_CLONED)
        capp_clone(
          PACKAGE ${package}
          RESULT_VARIABLE capp_clone_result
        )
        if (NOT capp_clone_result EQUAL 0)
          set(${capp_fulfill_needs_RESULT_VARIABLE} "${capp_clone_result}" PARENT_SCOPE)
          return()
        endif()
      endif()
      set(dependencies_installed TRUE)
      foreach (dependency IN LISTS ${package}_DEPENDENCIES)
        if (NOT IS_DIRECTORY "${CAPP_PACKAGE_ROOT}/${dependency}")
          message(FATAL_ERROR "${package} depends on ${dependency}, which is not a package")
        endif()
        if (NOT ${dependency}_IS_INSTALLED)
          set(dependencies_installed FALSE)
        endif()
      endforeach()
      if (NOT dependencies_installed)
        continue()
      endif()
      if (NOT ${package}_IS_CONFIGURED)
        capp_configure(
          PACKAGE ${package}
          RESULT_VARIABLE capp_configure_result
        )
        if (NOT capp_configure_result EQUAL 0)
          set(${capp_fulfill_needs_RESULT_VARIABLE} "${capp_configure_result}" PARENT_SCOPE)
          return()
        endif()
        set(${package}_IS_CONFIGURED ${${package}_IS_CONFIGURED} PARENT_SCOPE)
      endif()
      if (NOT ${package}_IS_INSTALLED)
        capp_build_install(
          PACKAGE ${package}
          RESULT_VARIABLE capp_build_install_result
        )
        if (NOT capp_build_install_result EQUAL 0)
          set(${capp_fulfill_needs_RESULT_VARIABLE} "${capp_build_install_result}" PARENT_SCOPE)
          return()
        endif()
        set(${package}_IS_INSTALLED ${${package}_IS_INSTALLED} PARENT_SCOPE)
      endif()
    endforeach()
    set(all_done TRUE)
    foreach(package IN LISTS CAPP_PACKAGES)
      if (NOT ${package}_IS_INSTALLED)
        set(all_done FALSE)
      endif()
    endforeach()
    if (all_done)
      break()
    endif()
  endwhile()
  set(${capp_fulfill_needs_RESULT_VARIABLE} 0 PARENT_SCOPE)
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

function(capp_get_commit)
  cmake_parse_arguments(PARSE_ARGV 0 capp_get_commit "" "PACKAGE;COMMIT_VARIABLE;RESULT_VARIABLE" "")
  capp_execute(
    COMMAND "${GIT_EXECUTABLE}" rev-parse HEAD
    WORKING_DIRECTORY "${CAPP_SOURCE_ROOT}/${capp_get_commit_PACKAGE}"
    RESULT_VARIABLE git_rev_parse_result
    OUTPUT_VARIABLE git_rev_parse_output
    )
  set(${capp_get_commit_RESULT_VARIABLE} ${git_rev_parse_result} PARENT_SCOPE)
  if (git_rev_parse_result EQUAL 0)
    string(STRIP "${git_rev_parse_output}" git_commit)
    set(${capp_get_commit_COMMIT_VARIABLE} ${git_commit} PARENT_SCOPE)
  endif()
endfunction()

function(capp_get_git_url)
  cmake_parse_arguments(PARSE_ARGV 0 capp_get_git_url "" "PACKAGE;GIT_URL_VARIABLE;RESULT_VARIABLE" "")
  capp_execute(
    COMMAND "${GIT_EXECUTABLE}" remote show -n origin
    WORKING_DIRECTORY "${CAPP_SOURCE_ROOT}/${capp_get_git_url_PACKAGE}"
    RESULT_VARIABLE git_remote_show_result
    OUTPUT_VARIABLE git_remote_show_output
    )
  set(${capp_get_git_url_RESULT_VARIABLE} ${git_remote_show_result} PARENT_SCOPE)
  if (NOT git_remote_show_result EQUAL 0)
    return()
  endif()
  string(REGEX MATCH "Fetch URL: [^\n]+\n" git_fetch_url "${git_remote_show_output}")
  string(LENGTH "Fetch URL: " header_length)
  string(SUBSTRING "${git_fetch_url}" ${header_length} -1 git_url_newline)
  string(STRIP "${git_url_newline}" git_url)
  set(${capp_get_git_url_GIT_URL_VARIABLE} ${git_url} PARENT_SCOPE)
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
  file(WRITE "${CAPP_ROOT}/app.cmake" "capp_app(\n  NAME ${capp_init_command_NAME}\n  ROOT_PACKAGES\n  )")
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
  capp_get_git_url(
    PACKAGE ${CAPP_PACKAGE_NAME}
    GIT_URL_VARIABLE ${CAPP_PACKAGE_NAME}_GIT_URL
    RESULT_VARIABLE capp_get_git_url_result
  )
  if (NOT capp_get_git_url_result EQUAL 0)
    set(${capp_clone_command_RESULT_VARIABLE} ${capp_get_git_url_result} PARENT_SCOPE)
    return()
  endif()
  capp_get_commit(
    PACKAGE ${CAPP_PACKAGE_NAME}
    COMMIT_VARIABLE ${CAPP_PACKAGE_NAME}_COMMIT
    RESULT_VARIABLE capp_get_commit_result
  )
  if (NOT capp_get_commit_result EQUAL 0)
    set(${capp_clone_command_RESULT_VARIABLE} ${capp_get_commit_result} PARENT_SCOPE)
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
  set(${capp_clone_command_RESULT_VARIABLE} 0 PARENT_SCOPE)
endfunction()

function(capp_commit_command)
  cmake_parse_arguments(PARSE_ARGV 0 capp_commit_command "" "PACKAGE;RESULT_VARIABLE" "")
  capp_get_git_url(
    PACKAGE ${capp_commit_command_PACKAGE}
    GIT_URL_VARIABLE new_git_url
    RESULT_VARIABLE capp_get_git_url_result
  )
  if (NOT capp_get_git_url_result EQUAL 0)
    set(${capp_commit_command_RESULT_VARIABLE} ${capp_get_git_url_result} PARENT_SCOPE)
    return()
  endif()
  capp_get_commit(
    PACKAGE ${capp_commit_command_PACKAGE}
    COMMIT_VARIABLE new_commit
    RESULT_VARIABLE capp_get_commit_result
  )
  if (NOT capp_get_commit_result EQUAL 0)
    set(${capp_commit_command_RESULT_VARIABLE} ${capp_get_commit_result} PARENT_SCOPE)
    return()
  endif()
  file(READ "${CAPP_PACKAGE_ROOT}/${capp_commit_command_PACKAGE}/package.cmake" old_package_contents)
  string(REGEX REPLACE "COMMIT [a-z0-9]+" "COMMIT ${new_commit}" commit_package_contents "${old_package_contents}")
  string(REGEX REPLACE "GIT_URL [a-z0-9:@/\\.-]+" "GIT_URL ${new_git_url}" new_package_contents "${commit_package_contents}")
  file(WRITE "${CAPP_PACKAGE_ROOT}/${capp_commit_command_PACKAGE}/package.cmake" "${new_package_contents}")
  set(${capp_commit_command_RESULT_VARIABLE} 0 PARENT_SCOPE)
  capp_add_file(
    FILE "${CAPP_PACKAGE_ROOT}/${capp_commit_command_PACKAGE}/package.cmake"
    RESULT_VARIABLE capp_add_file_result
  )
  if (NOT capp_add_file_result EQUAL 0)
    set(${capp_commit_command_RESULT_VARIABLE} ${capp_add_file_result} PARENT_SCOPE)
    return()
  endif()
  set(${capp_commit_command_RESULT_VARIABLE} 0 PARENT_SCOPE)
endfunction()

function(capp_checkout_command)
  cmake_parse_arguments(PARSE_ARGV 0 capp_checkout_command "" "RESULT_VARIABLE" "")
  foreach(package IN LISTS CAPP_PACKAGES)
    set(needs_reclone FALSE)
    if (EXISTS "${CAPP_INSTALL_ROOT}/${package}")
      capp_get_git_url(
        PACKAGE ${package}
        GIT_URL_VARIABLE current_git_url
        RESULT_VARIABLE get_git_url_result
        )
      if (NOT get_git_url_result EQUAL 0)
        set(${capp_checkout_command_RESULT_VARIABLE} "${get_git_url_result}" PARENT_SCOPE)
        return()
      endif()
      if (NOT current_git_url STREQUAL ${package}_GIT_URL)
        set(needs_reclone TRUE)
      endif()
    else()
      set(needs_reclone TRUE)
    endif()
    if (needs_reclone)
      file(REMOVE_RECURSE "${CAPP_SOURCE_ROOT}/${package}")
      capp_clone(
        PACKAGE ${package}
        RESULT_VARIABLE clone_result
        )
      if (NOT clone_result EQUAL 0)
        set(${capp_checkout_command_RESULT_VARIABLE} "${clone_result}" PARENT_SCOPE)
        return()
      endif()
    endif()
    capp_get_commit(
      PACKAGE ${package}
      COMMIT_VARIABLE current_commit
      RESULT_VARIABLE get_commit_result
      )
    if (NOT get_commit_result EQUAL 0)
      set(${capp_checkout_command_RESULT_VARIABLE} "${get_commit_result}" PARENT_SCOPE)
      return()
    endif()
    if (NOT current_commit STREQUAL ${package}_COMMIT)
      capp_execute(
        COMMAND "${GIT_EXECUTABLE}" fetch origin
        WORKING_DIRECTORY "${CAPP_SOURCE_ROOT}/${package}"
        RESULT_VARIABLE fetch_result
        )
      if (NOT fetch_result EQUAL 0)
        set(${capp_checkout_command_RESULT_VARIABLE} "${fetch_result}" PARENT_SCOPE)
        return()
      endif()
      capp_execute(
        COMMAND "${GIT_EXECUTABLE}" checkout ${${package}_COMMIT}
        WORKING_DIRECTORY "${CAPP_SOURCE_ROOT}/${package}"
        RESULT_VARIABLE checkout_result
        )
      if (NOT checkout_result EQUAL 0)
        set(${capp_checkout_command_RESULT_VARIABLE} "${checkout_result}" PARENT_SCOPE)
        return()
      endif()
      file(REMOVE "${CAPP_INSTALL_ROOT}/${package}/capp_installed.txt")
    endif()
  endforeach()
  set(${capp_checkout_command_RESULT_VARIABLE} 0 PARENT_SCOPE)
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
  capp_find_root()
  capp_read_package_files()
  capp_initialize_needs()
  if (CAPP_COMMAND STREQUAL "clone")
    capp_clone_command(
      GIT_ARGUMENTS ${CAPP_COMMAND_ARGUMENTS}
      RESULT_VARIABLE capp_command_result
    )
  elseif(CAPP_COMMAND STREQUAL "build")
    capp_fulfill_needs(
      RESULT_VARIABLE capp_command_result
    )
  elseif(CAPP_COMMAND STREQUAL "commit")
    capp_commit_command(
      PACKAGE ${CAPP_COMMAND_ARGUMENTS}
      RESULT_VARIABLE capp_command_result
    )
  elseif(CAPP_COMMAND STREQUAL "checkout")
    capp_checkout_command(
      RESULT_VARIABLE capp_command_result
    )
  else()
    message("packages:${CAPP_PACKAGES}")
    message(FATAL_ERROR "Unknown command ${CAPP_COMMAND}!")
  endif()
endif()

if (NOT capp_command_result EQUAL 0)
  message(FATAL_ERROR "CApp command ${CAPP_COMMAND} failed")
endif()
