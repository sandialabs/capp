message("CMAKE_CURRENT_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}")
set(CAPP_BUILD_TYPE Release)
set(CAPP_ROOT "${CMAKE_CURRENT_SOURCE_DIR}")
set(CAPP_SOURCE_ROOT "${CAPP_ROOT}/source")
set(CAPP_BUILD_ROOT "${CAPP_ROOT}/build")
set(CAPP_INSTALL_ROOT "${CAPP_ROOT}/install")
make_directory("${CAPP_SOURCE_ROOT}")
make_directory("${CAPP_BUILD_ROOT}")
make_directory("${CAPP_INSTALL_ROOT}")
set(CMAKE_PROGRAM_PATH "C:/Program Files") #workaround a workaround for MSVC 2017 in FindGit.cmake
find_package(Git REQUIRED)
message("Git is at ${GIT_EXECUTABLE}")

function(capp_execute)
  cmake_parse_arguments(PARSE_ARGV 0 capp_execute "" "WORKING_DIRECTORY;RESULT_VARIABLE" "COMMAND")
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
  cmake_parse_arguments(PARSE_ARGV 0 capp_package "" "NAME;GIT_URL;COMMIT" "OPTIONS")
  set(${capp_package_NAME}_GIT_URL ${capp_package_GIT_URL} PARENT_SCOPE)
  set(${capp_package_NAME}_COMMIT ${capp_package_COMMIT} PARENT_SCOPE)
  set(${capp_package_NAME}_OPTIONS "${capp_package_OPTIONS}" PARENT_SCOPE)
  set(${capp_package_NAME}_DIRECTORY "${CAPP_PACKAGE_DIRECTORY}" PARENT_SCOPE)
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

set(CAPP_PACKAGE_DIRECTORY trivial-mpi)
capp_package(
    NAME TrivialMPI
    GIT_URL git@cee-gitlab.sandia.gov:daibane/trivial-mpi.git
    COMMIT a340978950cc0a455abeb7d34b2812d8400bbf46
)
message("now TrivialMPI_GIT_URL is ${TrivialMPI_GIT_URL}")

capp_clone_package(
    NAME TrivialMPI
    RESULT_VARIABLE capp_clone_package_result
)

capp_configure_package(
    NAME TrivialMPI
    RESULT_VARIABLE capp_configure_package_result
    )

capp_build(
    DIRECTORY trivial-mpi
    RESULT_VARIABLE capp_build_result
)

capp_install(
    DIRECTORY trivial-mpi
    RESULT_VARIABLE capp_install_result
)