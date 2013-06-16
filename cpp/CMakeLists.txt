# Jiang Bian. Copyright (C) 2013. MIT.

#
# Project Properties
#
CMAKE_MINIMUM_REQUIRED (VERSION 2.8.10)

set(CONFIGURATE_CFLAGS "${CONFIGURATE_CFLAGS} -I/usr/local/include -I/usr/include")
set(CONFIGURATE_CXXFLAGS "${CONFIGURATE_CXXFLAGS} -I/usr/local/include -I/usr/include")
set(CONFIGURATE_LDFLAGS "${CONFIGURATE_LDFLAGS} -L/usr/local/lib -L/usr/lib ")

if (NOT _MAC_DEPENDENCY_PATHS)
set(_MAC_DEPENDENCY_PATHS)
    # As of CMake 2.8.3, Fink and MacPorts search paths are appended to the
    # default search prefix paths, but the nicer thing would be if they are
    # prepended to the default, so that is fixed here.
    if (APPLE)
    # this is using homebrew, change the paths to use MacPorts or Fink
      set(CMAKE_C_COMPILER /usr/local/bin/gcc-4.8)
      set(CMAKE_CXX_COMPILER /usr/local/bin/g++-4.8)
      set(CMAKE_OSX_ARCHITECTURES x86_64)
      #list(INSERT CMAKE_SYSTEM_PREFIX_PATH 0 /opt/local) # MacPorts
      #list(INSERT CMAKE_SYSTEM_PREFIX_PATH 0 /sw)        # Fink
      
      #Homebrew
      set(CONFIGURATE_CFLAGS "-arch x86_64 -I/usr/local/include -I/usr/include")
      set(CONFIGURATE_CXXFLAGS "-arch x86_64 -I/usr/local/include -I/usr/include")
      set(CONFIGURATE_LDFLAGS "-L/usr/local/lib -L/usr/lib ")
    endif ()
endif ()


PROJECT (deconvolvefilter)
SET (APPLICATION_NAME "Deconvolve filter")
SET (APPLICATION_CODENAME "${PROJECT_NAME}")
SET (APPLICATION_COPYRIGHT_YEARS "2013")
SET (APPLICATION_VERSION_MAJOR 0)
SET (APPLICATION_VERSION_MINOR 0)
SET (APPLICATION_VERSION_PATCH 1)
SET (APPLICATION_VERSION_TYPE SNAPSHOT)
SET (APPLICATION_VERSION_STRING "${APPLICATION_VERSION_MAJOR}.${APPLICATION_VERSION_MINOR}.${APPLICATION_VERSION_PATCH}-${APPLICATION_VERSION_TYPE}")
SET (APPLICATION_VENDOR_ID "edu.uams")
SET (APPLICATION_VENDOR_NAME "UAMS")
SET (APPLICATION_VENDOR_URL "uams.edu")
SET (APPLICATION_ID "${APPLICATION_VENDOR_ID}.${PROJECT_NAME}")

#
# Debugging Options
#
OPTION(DEBUG_MODE          "Enable debug output [default: ON]"                  ON)
OPTION(ENABLE_GPERF_TOOLS  "Enable google perftools [default: ON]"             ON)
OPTION(ENABLE_TCMALLOC  "Enable tcmalloc in the google perftools [default: OFF]"             OFF)

SET(CMAKE_CXX_FLAGS                "-Wall -std=c++11")
SET(CMAKE_CXX_FLAGS_DEBUG          "-O0 -g")
SET(CMAKE_CXX_FLAGS_RELEASE        "-O4")
SET(CMAKE_VERBOSE_MAKEFILE 0) # Use 1 for debugging, 0 for release

#select the release build type by default to get optimization flags
if(NOT CMAKE_BUILD_TYPE)
   set(CMAKE_BUILD_TYPE "Release")
   message(STATUS "Build type not specified: defaulting to release.")
endif(NOT CMAKE_BUILD_TYPE)
set(CMAKE_BUILD_TYPE ${CMAKE_BUILD_TYPE} CACHE STRING "")

# Prohibit in-source builds.
if ("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_BINARY_DIR}")
  message(FATAL_ERROR "In-source builds are not allowed. Please use "
    "./configure to choose a build directory and "
    "initialize the build configuration.")
endif ()

#
# Debugging Options
#
IF(DEBUG_MODE MATCHES "ON")
  SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CMAKE_CXX_FLAGS_DEBUG}")
ELSE()
  SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CMAKE_CXX_FLAGS_RELEASE}")
ENDIF(DEBUG_MODE MATCHES "ON")

if("${CMAKE_CXX_COMPILER_ID}" MATCHES "GNU")
  execute_process(
    COMMAND ${CMAKE_CXX_COMPILER} -dumpversion OUTPUT_VARIABLE GCC_VERSION)
  if (NOT (GCC_VERSION VERSION_GREATER 4.8 OR GCC_VERSION VERSION_EQUAL 4.8))
    message(FATAL_ERROR "${PROJECT_NAME} requires g++ 4.8 or greater.")
  endif ()
elseif("${CMAKE_CXX_COMPILER_ID}" MATCHES "Clang")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
else()
  message(FATAL_ERROR "Your C++ compiler does not support C++11.")
endif ()


#
# Project Output Paths
#
SET (MAINFOLDER ${PROJECT_SOURCE_DIR})
SET (EXECUTABLE_OUTPUT_PATH "${MAINFOLDER}/bin")
SET (LIBRARY_OUTPUT_PATH "${MAINFOLDER}/lib")

#
# Project Search Paths
#
LIST (APPEND CMAKE_PREFIX_PATH "${MAINFOLDER}")
LIST (APPEND CMAKE_PREFIX_PATH "${MAINFOLDER}/tools")
LIST (APPEND CMAKE_PREFIX_PATH "${MAINFOLDER}/thirdparty")
#list(APPEND CMAKE_MODULE_PATH "${MAINFOLDER}/tools/share/cmake/")
SET (CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${MAINFOLDER}/cmake ${MAINFOLDER}/tools/share/cmake/)
INCLUDE_DIRECTORIES("${MAINFOLDER}/include")
INCLUDE_DIRECTORIES("${MAINFOLDER}/src")
#
# Locate Project Prerequisites 
#
################################
# Boost
################################

if("$ENV{BOOST_ROOT}" STREQUAL "")
  message("BOOST_ROOT not found")
else("$ENV{BOOST_ROOT}" STREQUAL "")
  set(BOOST_ROOT "$ENV{BOOST_ROOT}")
endif("$ENV{BOOST_ROOT}" STREQUAL "")
IF (BOOST_ROOT)
  message("found BOOST_ROOT at ${BOOST_ROOT}")
  # Prevent falling back to system paths when using a custom Boost prefix.
  set(Boost_NO_SYSTEM_PATHS true)
ENDIF ()

SET (Boost_ADDITIONAL_VERSIONS "1.53" "1.53.0" "1.52" "1.52.0")
set(Boost_USE_STATIC_LIBS ON)
set(Boost_USE_MULTITHREADED ON) 
#set(Boost_USE_STATIC_RUNTIME ON)
FIND_PACKAGE (Boost 1.52 COMPONENTS "date_time" "filesystem" "iostreams" "regex" "serialization" "system" REQUIRED)
IF (Boost_FOUND)
  INCLUDE_DIRECTORIES(${Boost_INCLUDE_DIRS})
  LINK_DIRECTORIES(${Boost_LIBRARY_DIRS})
  SET (USE_STD_CXX_11 0) # mainly for future compatabilitiy... in case when std:: concurrency is complete...
ELSE (Boost_FOUND)
  message(FATAL_ERROR "Could not find Boost")
ENDIF (Boost_FOUND)

################################
# glog
################################

  set(glog_VERSION trunk)
  set(glog_CONFIGURE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/glog/glog-${glog_VERSION}/configure)
  include(ExternalProject)
  ExternalProject_Add(
          glog-${glog_VERSION}
          PREFIX ${CMAKE_CURRENT_BINARY_DIR}/glog-${glog_VERSION}
          SVN_REPOSITORY http://google-glog.googlecode.com/svn/trunk/
          SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/glog/glog-${glog_VERSION}
          BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/glog-${glog_VERSION}
          CONFIGURE_COMMAND ${glog_CONFIGURE} --prefix=${CMAKE_CURRENT_BINARY_DIR}/glog-${glog_VERSION} CC=${CMAKE_C_COMPILER} CXX=${CMAKE_CXX_COMPILER} CFLAGS=${CONFIGURATE_CFLAGS} CXXFLAGS=${CONFIGURATE_CXXFLAGS} LDFLAGS=${CONFIGURATE_LDFLAGS}
          BUILD_COMMAND make && make install
          UPDATE_COMMAND ""
          PATCH_COMMAND ""
          INSTALL_COMMAND ""
     )
  # Set up variables
     set(glog_INCLUDE_DIRS
          ${CMAKE_CURRENT_BINARY_DIR}/glog-${glog_VERSION}/include
     )
     set(glog_LIBRARIES
          ${CMAKE_CURRENT_BINARY_DIR}/glog-${glog_VERSION}/lib/${CMAKE_FIND_LIBRARY_PREFIXES}glog.a
     )
     set(glog_LIBRARY_DIRS
          ${CMAKE_CURRENT_BINARY_DIR}/glog-${glog_VERSION}/lib
     )
INCLUDE_DIRECTORIES(${glog_INCLUDE_DIRS})
LINK_DIRECTORIES(${glog_LIBRARY_DIRS})

################################
# gmock and gtest
################################
  set(ep_common_compiler_args
   -DCMAKE_CXX_COMPILER:FILEPATH=${CMAKE_CXX_COMPILER} 
   -DCMAKE_C_COMPILER:FILEPATH=${CMAKE_C_COMPILER}
   )

  set(gmock_VERSION trunk)
  include(ExternalProject)
  ExternalProject_Add(
          gmock-${gmock_VERSION}
          PREFIX ${CMAKE_CURRENT_BINARY_DIR}/gmock-${gmock_VERSION}
          SVN_REPOSITORY http://googlemock.googlecode.com/svn/trunk/
          SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/gmock/gmock-${gmock_VERSION}
          BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/gmock-${gmock_VERSION}
          CMAKE_ARGS ${ep_common_compiler_args}
          BUILD_COMMAND make all install
          UPDATE_COMMAND ""
          PATCH_COMMAND ""
          INSTALL_COMMAND ""
     )
# Set up variables
     set(gmock_INCLUDE_DIRS
          ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/gmock/gmock-${gmock_VERSION}/include
     )
     set(gmock_LIBRARY_DIRS
          ${CMAKE_CURRENT_BINARY_DIR}/gmock-${gmock_VERSION}
     )
     set(gtest_INCLUDE_DIRS
          ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/gmock/gmock-${gmock_VERSION}/gtest/include
     )
     set(gtest_LIBRARY_DIRS
          ${CMAKE_CURRENT_BINARY_DIR}/gmock-${gmock_VERSION}/gtest
     )

INCLUDE_DIRECTORIES(${gmock_INCLUDE_DIRS})
LINK_DIRECTORIES(${gmock_LIBRARY_DIRS})

#INCLUDE_DIRECTORIES(${gtest_INCLUDE_DIRS})
#LINK_DIRECTORIES(${gtest_LIBRARY_DIRS})


################################################################################
# gflags - http://code.google.com/p/gflags/
################################################################################

INCLUDE(FindPkgConfig)
IF(PKG_CONFIG_FOUND)
  PKG_CHECK_MODULES(gflags libgflags)
  if(NOT gflags_FOUND)
  message (" gflags library has not been found.")
    message (" gflags will be downloaded and built automatically ")
    message (" when doing 'make'. ")
    include(ExternalProject)
    set(gflags_VERSION trunk)
    message ("${CMAKE_CURRENT_SOURCE_DIR}")
      ExternalProject_Add(
            gflags-${gflags_VERSION}
            PREFIX ${CMAKE_CURRENT_BINARY_DIR}/gflags-${gflags_VERSION}
            SVN_REPOSITORY http://gflags.googlecode.com/svn/trunk/
            DOWNLOAD_DIR ${CMAKE_CURRENT_BINARY_DIR}/download/gflags-${gflags_VERSION}
            SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/gflags/gflags-${gflags_VERSION}
            BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/gflags-${gflags_VERSION}
            CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=${CMAKE_CURRENT_BINARY_DIR}/gflags-${gflags_VERSION} CC=${CMAKE_C_COMPILER} CXX=${CMAKE_CXX_COMPILER} CFLAGS=${CONFIGURATE_CFLAGS} CXXFLAGS=${CONFIGURATE_CXXFLAGS} LDFLAGS=${CONFIGURATE_LDFLAGS}
            BUILD_COMMAND make && make install
            UPDATE_COMMAND ""
            PATCH_COMMAND ""
            INSTALL_COMMAND ""
       )
       set(gflags_INCLUDE_DIRS 
            ${CMAKE_CURRENT_BINARY_DIR}/gflags-${gflags_VERSION}/include CACHE PATH "Local Gflags headers"      
       )
       set(gflags_LIBRARIES 
            ${CMAKE_CURRENT_BINARY_DIR}/gflags-${gflags_VERSION}/lib/${CMAKE_FIND_LIBRARY_PREFIXES}gflags.a
       )
       set(gflags_SHARED_LIBRARIES
            ${CMAKE_CURRENT_BINARY_DIR}/gflags-${gflags_VERSION}/lib/${CMAKE_FIND_LIBRARY_PREFIXES}gflags.so
       )
       set(gflags_LIBRARY_DIRS
            ${CMAKE_CURRENT_BINARY_DIR}/gflags-${gflags_VERSION}/lib
       )
  endif(NOT gflags_FOUND)
ENDIF(PKG_CONFIG_FOUND)
INCLUDE_DIRECTORIES(${gflags_INCLUDE_DIRS})
LINK_DIRECTORIES(${gflags_LIBRARY_DIRS})


################################
# Google performance tools
################################

SET(WITH_GPERF_TOOLS false)
SET(WITH_TCMALLOC false)

IF(ENABLE_GPERF_TOOLS MATCHES "ON")
  find_package(Gperftools)
  IF (GPERFTOOLS_FOUND)
      SET(WITH_GPERF_TOOLS true)
      INCLUDE_DIRECTORIES(BEFORE ${GPERFTOOLS_INCLUDE_DIR})
      IF (ENABLE_TCMALLOC MATCHES "ON")
        SET(WITH_TCMALLOC true)
      ENDIF(ENABLE_TCMALLOC MATCHES "ON")
  ENDIF (GPERFTOOLS_FOUND)
ENDIF(ENABLE_GPERF_TOOLS MATCHES "ON")

################################################################################
# armadillo - http://arma.sourceforge.net/download.html
################################################################################

  set(ep_common_compiler_args
   -DCMAKE_CXX_COMPILER:FILEPATH=${CMAKE_CXX_COMPILER} 
   -DCMAKE_C_COMPILER:FILEPATH=${CMAKE_C_COMPILER}
   )

  set(armadillo_VERSION 3.900.4)
  set(ep_armadillo_compiler_args
    ${ep_common_compiler_args}
    -DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_CURRENT_BINARY_DIR}/armadillo-${armadillo_VERSION}
  )
  include(ExternalProject)
  ExternalProject_Add(
          armadillo-${armadillo_VERSION}
          PREFIX ${CMAKE_CURRENT_BINARY_DIR}/armadillo-${armadillo_VERSION}
          URL http://sourceforge.net/projects/arma/files/armadillo-${armadillo_VERSION}.tar.gz
          DOWNLOAD_DIR ${CMAKE_CURRENT_BINARY_DIR}/download/armadillo-${armadillo_VERSION}
          SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/armadillo/armadillo-${armadillo_VERSION}
          BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/armadillo-${armadillo_VERSION}
          CMAKE_ARGS ${ep_armadillo_compiler_args}
          BUILD_COMMAND make all install
          UPDATE_COMMAND ""
          PATCH_COMMAND ""
          INSTALL_COMMAND ""
     )
     set(armadillo_INCLUDE_DIRS
          ${CMAKE_CURRENT_BINARY_DIR}/armadillo-${armadillo_VERSION}/include     
     )
     set(armadillo_LIBRARIES
          armadillo
     )     
     set(armadillo_LIBRARY_DIRS
          ${CMAKE_CURRENT_BINARY_DIR}/armadillo-${armadillo_VERSION}/lib
     )

INCLUDE_DIRECTORIES(${armadillo_INCLUDE_DIRS})
LINK_DIRECTORIES(${armadillo_LIBRARY_DIRS})


#
# Configure Files
#
FILE (GLOB_RECURSE CONFIGINPUTS1 include/*.in.h.cmake)
FILE (GLOB_RECURSE CONFIGINPUTS2 include/*.h.in.cmake)
FILE (GLOB_RECURSE CONFIGINPUTS3 src/*.in.h.cmake)
FILE (GLOB_RECURSE CONFIGINPUTS4 src/*.h.in.cmake)
FILE (GLOB_RECURSE CONFIGINPUTS5 test/*.in.h.cmake)
FILE (GLOB_RECURSE CONFIGINPUTS6 test/*.h.in.cmake)
LIST (APPEND CONFIGINPUTS "${CONFIGINPUTS1}")
LIST (APPEND CONFIGINPUTS "${CONFIGINPUTS2}")
LIST (APPEND CONFIGINPUTS "${CONFIGINPUTS3}")
LIST (APPEND CONFIGINPUTS "${CONFIGINPUTS4}")
LIST (APPEND CONFIGINPUTS "${CONFIGINPUTS5}")
LIST (APPEND CONFIGINPUTS "${CONFIGINPUTS6}")
FOREACH (CONFIGINPUT ${CONFIGINPUTS})
    STRING (REPLACE ".in.h.cmake" ".h" CONFIGOUTPUT1 "${CONFIGINPUT}")
    STRING (REPLACE ".h.in.cmake" ".h" CONFIGOUTPUT2 "${CONFIGOUTPUT1}")
    CONFIGURE_FILE ("${CONFIGINPUT}" "${CONFIGOUTPUT2}")
ENDFOREACH (CONFIGINPUT ${CONFIGINPUTS})

#
# Add Build Targets
#
ADD_SUBDIRECTORY(src)
ADD_SUBDIRECTORY(test)

#
# Add Install Targets
#
IF (EXISTS "${MAINFOLDER}/include/${PROJECT_NAME}" AND IS_DIRECTORY "${MAINFOLDER}/include/${PROJECT_NAME}")
    INSTALL(DIRECTORY "${MAINFOLDER}/include/${PROJECT_NAME}" DESTINATION "include")
ENDIF (EXISTS "${MAINFOLDER}/include/${PROJECT_NAME}" AND IS_DIRECTORY "${MAINFOLDER}/include/${PROJECT_NAME}")

#
# Add Documentation Targets
#
INCLUDE (DocumentationTargets)

set(build_summary
    "\n====================|  Build Summary  |===================="
    "\n"
    "\n${APPLICATION_NAME}:     ${APPLICATION_VERSION_STRING}"
    "\n"
    "\nPlatform:         ${CMAKE_HOST_SYSTEM_NAME} ${CMAKE_HOST_SYSTEM_VERSION} ${CMAKE_HOST_SYSTEM_PROCESSOR}"
    "\nCMAKE_C_COMPILER: ${CMAKE_C_COMPILER}"
    "\nCMAKE_CXX_COMPILER: ${CMAKE_CXX_COMPILER}"
    "\nSource directory: ${CMAKE_SOURCE_DIR}"
    "\nBuild directory:  ${CMAKE_BINARY_DIR}"
    "\nInstall prefix:   ${CMAKE_INSTALL_PREFIX}"
    "\nDebug mode:       ${DEBUG_MODE}"
    "\n"
    "\nCXX:              ${CMAKE_CXX_COMPILER} ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}"
    "\nCXXFLAGS:         ${CMAKE_CXX_FLAGS}"
    "\n"
    "\nglog:             ${glog_VERSION}"
    "\nBoost:            ${Boost_VERSION}: ${Boost_LIBRARY_DIRS}; ${Boost_LIBRARIES}"
    "\nGperftools:       ${WITH_GPERF_TOOLS}"
    "\narmadillo:        ${armadillo_INCLUDE_DIRS}"
    "\nDoxygen:          ${DOXYGEN_VERSION}"
    "\n"
    "\n===========================================================\n")

message(${build_summary})

ADD_SUBDIRECTORY(cmd)
