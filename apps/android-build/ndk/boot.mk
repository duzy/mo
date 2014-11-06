__me := $(lastword $(MAKEFILE_LIST))

NDK_ROOT := $(strip $(or\
    $(wildcard /open/android/android-ndk-r9d),\
    $(wildcard /home/zhan/tools/android-ndk-r9d)))
include $(NDK_ROOT)/build/core/init.mk
__my_dir := $(call parent-dir,$(__me))

ifndef NDK_PROJECT_PATH
    NDK_PROJECT_PATH := $(call find-project-dir,.,jni/Android.mk)
endif
ifndef NDK_PROJECT_PATH
    NDK_PROJECT_PATH := $(call find-project-dir,.,AndroidManifest.xml)
endif

NDK_APPLICATION_MK := $(strip $(wildcard $(NDK_PROJECT_PATH)/jni/Application.mk))
ifndef NDK_APPLICATION_MK
    NDK_APPLICATION_MK := $(NDK_ROOT)/build/core/default-application.mk
endif

NDK_APP_OUT := $(strip $(or $(NDK_OUT),$(NDK_PROJECT_PATH)/obj))
NDK_APP_LIBS_OUT := $(strip $(or $(NDK_LIBS_OUT),$(NDK_PROJECT_PATH)/libs))

_app            := local
_application_mk := $(NDK_APPLICATION_MK)
NDK_APPS        := $(_app)
include $(BUILD_SYSTEM)/add-application.mk

include $(BUILD_SYSTEM)/setup-imports.mk


# ($(BUILD_SYSTEM)/build-all.mk)
# 
# These macros are used in Android.mk to include the corresponding
# build script that will parse the LOCAL_XXX variable definitions.
#
CLEAR_VARS                := $(BUILD_SYSTEM)/clear-vars.mk
BUILD_HOST_EXECUTABLE     := $(BUILD_SYSTEM)/build-host-executable.mk
BUILD_HOST_STATIC_LIBRARY := $(BUILD_SYSTEM)/build-host-static-library.mk
BUILD_STATIC_LIBRARY      := $(BUILD_SYSTEM)/build-static-library.mk
BUILD_SHARED_LIBRARY      := $(BUILD_SYSTEM)/build-shared-library.mk
BUILD_EXECUTABLE          := $(BUILD_SYSTEM)/build-executable.mk
PREBUILT_SHARED_LIBRARY   := $(BUILD_SYSTEM)/prebuilt-shared-library.mk
PREBUILT_STATIC_LIBRARY   := $(BUILD_SYSTEM)/prebuilt-static-library.mk

ANDROID_MK_INCLUDED := \
  $(CLEAR_VARS) \
  $(BUILD_HOST_EXECUTABLE) \
  $(BUILD_HOST_STATIC_LIBRARY) \
  $(BUILD_STATIC_LIBRARY) \
  $(BUILD_SHARED_LIBRARY) \
  $(BUILD_EXECUTABLE) \
  $(PREBUILT_SHARED_LIBRARY) \

# ($(BUILD_SYSTEM)/setup-app.mk)
#
# Setup the app..
# 
$(foreach _app,$(NDK_APPS),\
  $(eval include $(BUILD_SYSTEM)/setup-app.mk)\
 )

include $(__my_dir)/do/$(DO).mk
