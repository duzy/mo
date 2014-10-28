LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := hello
LOCAL_MODULE_FILENAME := libhello
LOCAL_SRC_FILES := hello.cpp
LOCAL_C_INCLUDES :=
LOCAL_CFLAGS :=

include $(BUILD_SHARED_LIBRARY)

# $(call import-module,bindings)
