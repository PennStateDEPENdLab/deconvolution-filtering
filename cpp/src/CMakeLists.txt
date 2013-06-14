SET(project_SRCS
    ../include/deconvolvefilter/config.h    
    ../include/deconvolvefilter/version.hpp
    ../include/deconvolvefilter/deconvolvefilter.hpp
    ../include/deconvolvefilter/internal/singleton.hpp
    ../include/deconvolvefilter/internal/thread_pool.hpp
    ../include/deconvolvefilter/internal/utils.hpp
    ../include/deconvolvefilter/internal/deconvolvefilter.hpp
	)


SET (project_LIBS ${Boost_LIBRARIES} ${glog_LIBRARIES} ${ARMADILLO_LIBRARIES})
SET (project_BIN ${PROJECT_NAME})

IF(WITH_GPERF_TOOLS)
	SET (project_LIBS ${project_LIBS} ${GPERFTOOLS_PROFILER})
ENDIF(WITH_GPERF_TOOLS)

IF(WITH_TCMALLOC)
	SET (project_LIBS ${project_LIBS} ${GPERFTOOLS_TCMALLOC})
ENDIF(WITH_TCMALLOC)

IF (NOT DEFINED project_build_shared)
   IF (CMAKE_CROSSCOMPILING)
       SET(project_build_shared 0)
   ELSE (CMAKE_CROSSCOMPILING)
       SET(project_build_shared 1)
   ENDIF (CMAKE_CROSSCOMPILING)
ENDIF (NOT DEFINED project_build_shared)

IF (NOT DEFINED project_build_static)
   SET(project_build_static 1)
ENDIF (NOT DEFINED project_build_static)


###### header only library... no build
set(project_build_static 0)
set(project_build_shared 0)

IF (project_build_static)
	ADD_LIBRARY(staticlib STATIC ${project_SRCS})
	TARGET_LINK_LIBRARIES(staticlib ${project_LIBS})
	SET_TARGET_PROPERTIES(staticlib PROPERTIES VERSION "${APPLICATION_VERSION_MAJOR}.${APPLICATION_VERSION_MINOR}" OUTPUT_NAME ${project_BIN} CLEAN_DIRECT_OUTPUT 1)
	INSTALL(TARGETS staticlib DESTINATION lib)
ENDIF(project_build_static)

IF (project_build_shared)
	ADD_LIBRARY(sharedlib SHARED ${project_SRCS})
	TARGET_LINK_LIBRARIES(sharedlib ${project_LIBS})
	SET_TARGET_PROPERTIES(sharedlib PROPERTIES VERSION "${APPLICATION_VERSION_MAJOR}.${APPLICATION_VERSION_MINOR}" OUTPUT_NAME ${project_BIN} CLEAN_DIRECT_OUTPUT 1)
	INSTALL(TARGETS sharedlib DESTINATION lib)
ENDIF(project_build_shared)
