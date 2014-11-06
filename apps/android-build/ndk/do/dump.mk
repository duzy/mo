_map := NDK_APP.$(_app)
$(info NDK_APPS: $(NDK_APPS))
$(info NDK_APP_NAME: $(NDK_APP_NAME))
$(info NDK_APP_VARS: $(NDK_APP_VARS))
$(info #------------------------------------------------)
$(foreach __name,$(NDK_APP_VARS),\
  $(eval NDK_$(__name) := $(call get,$(_map),$(__name)))\
  $(info NDK_$(__name): $(NDK_$(__name)))\
 )
$(info #------------------------------------------------)
$(info modules: $(modules-get-list))
$(foreach __name,$(modules-get-list),\
  $(info -----------------)\
  $(info module: $(__name))\
  $(info class: $(call module-get-class,$(__name)))\
  $(info built: $(call module-get-built,$(__name)))\
  $(info is-shared-library: $(call module-is-shared-library,$(__name)))\
  $(info is-static-library: $(call module-is-static-library,$(__name)))\
  $(info export: $(call module-get-export,$(__name)))\
  $(info shared-libs: $(call module-get-shared-libs,$(__name)))\
  $(info static-libs: $(call module-get-static-libs,$(__name)))\
  $(info whole-static-libs: $(call module-get-whole-static-libs,$(__name)))\
  $(info depends: $(call module-get-depends,$(__name)))\
  $(info installed: $(call module-get-installed,$(__name)))\
  $(info c++-sources: $(call module-get-c++-sources,$(__name)))\
  $(info c++-flags: $(call module-get-c++-flags,$(__name)))\
 )
$(info #------------------------------------------------)
$(modules-dump-database)
