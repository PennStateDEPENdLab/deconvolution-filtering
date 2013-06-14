set (deconvolvefilter_test_SRCS
  deconvolvefilter_test.cc
  )

SET (deconvolvefilter_test_LIBS ${Boost_LIBRARIES} ${glog_LIBRARIES} pthread gmock_main ${gflags_LIBRARIES} ${PROJECT_NAME})
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


