// Jiang Bian. Copyright (C) 2013. MIT License.
#ifndef __TED_VERSION_H__
#define __TED_VERSION_H__

#ifdef __cplusplus
#   define EXTERNC extern "C"
#else
#   define EXTERNC
#endif

#include "./appinfo.h"

namespace df {
    EXTERNC int df_version_major() {
    	return APPLICATION_VERSION_MAJOR;
    }
    EXTERNC int df_version_minor() {
    	return APPLICATION_VERSION_MINOR;
    }
    EXTERNC int df_version_patch() {
    	return APPLICATION_VERSION_PATCH;
    }
}
#endif
