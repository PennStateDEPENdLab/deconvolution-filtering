set (deconvolvefilter_test_SRCS
  deconvolvefilter_test.cc
  )

SET (deconvolvefilter_test_LIBS ${Boost_LIBRARIES} ${glog_LIBRARIES} pthread gmock_main ${gflags_LIBRARIES}) # ${PROJECT_NAME} header only library, don't need to link
SET (deconvolvefilter_test_BIN deconvolvefilter_test)

IF(WITH_GPERF_TOOLS)
  SET (deconvolvefilter_test_LIBS ${deconvolvefilter_test_LIBS} ${GPERFTOOLS_PROFILER})
ENDIF(WITH_GPERF_TOOLS)

#set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-unused-local-typedefs -Wno-unused-variable")

IF (NOT CMAKE_CROSSCOMPILING)
    LINK_DIRECTORIES(${MAINFOLDER}/lib)
    ADD_EXECUTABLE(${deconvolvefilter_test_BIN} ${deconvolvefilter_test_SRCS})
    TARGET_LINK_LIBRARIES(${deconvolvefilter_test_BIN} ${deconvolvefilter_test_LIBS})
ENDIF (NOT CMAKE_CROSSCOMPILING)


### deconvolvefilter cmd

set (deconvolvefilter_SRCS
  deconvolvefilter.cc
  )

SET (deconvolvefilter_LIBS ${Boost_LIBRARIES} ${glog_LIBRARIES} pthread ${gflags_LIBRARIES}) # ${PROJECT_NAME} header only library, don't need to link
SET (deconvolvefilter_BIN deconvolvefilter)

IF(WITH_GPERF_TOOLS)
  SET (deconvolvefilter_LIBS ${deconvolvefilter_LIBS} ${GPERFTOOLS_PROFILER})
ENDIF(WITH_GPERF_TOOLS)

### release mode, compiler flag
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O4 -Wno-unused-local-typedefs -Wno-unused-variable")

IF (NOT CMAKE_CROSSCOMPILING)
    LINK_DIRECTORIES(${MAINFOLDER}/lib)
    ADD_EXECUTABLE(${deconvolvefilter_BIN} ${deconvolvefilter_SRCS})
    TARGET_LINK_LIBRARIES(${deconvolvefilter_BIN} ${deconvolvefilter_LIBS})
ENDIF (NOT CMAKE_CROSSCOMPILING)


