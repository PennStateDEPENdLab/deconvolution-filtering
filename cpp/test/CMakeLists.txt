FILE (GLOB_RECURSE test_SRCS *.cpp *.cxx *.cc *.C *.c *.h *.hpp)
SET (test_LIBS ${Boost_LIBRARIES} ${glog_LIBRARIES} pthread gmock_main) ### ${PROJECT_NAME} header only don't link ${PROJECT_NAME}
SET (test_BIN ${PROJECT_NAME}_sanity_check_test)

IF (NOT CMAKE_CROSSCOMPILING)
    LINK_DIRECTORIES(${MAINFOLDER}/lib)
    ADD_EXECUTABLE(${test_BIN} ${test_SRCS})
    TARGET_LINK_LIBRARIES(${test_BIN} ${test_LIBS})
    ADD_CUSTOM_TARGET(check ALL "${MAINFOLDER}/bin/${test_BIN}" DEPENDS ${test_BIN} COMMENT "Executing unit tests..." VERBATIM SOURCES ${test_SRCS})
    ADD_CUSTOM_TARGET(test "${MAINFOLDER}/bin/${test_BIN}" DEPENDS ${test_BIN} COMMENT "Executing unit tests..." VERBATIM SOURCES ${test_SRCS})
ENDIF (NOT CMAKE_CROSSCOMPILING)

