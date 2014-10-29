$(info <?xml version="1.0"?>)
$(info <android top = "$(modules-get-top-list)">)
    $(info $(space4)<app name = "$(NDK_APP_NAME)")\
    $(foreach __name,$(NDK_APP_VARS),\
        $(eval __value := $(call get,NDK_APP.$(_app),$(__name)))\
        $(info $(space4)$(space4)$(__name) = "$(__value)")\
     )
    $(info $(space4)/>)\
    $(foreach __mod,$(modules-get-list),\
        $(info $(space4)<module name = "$(__mod)")\
        $(foreach __field,$(modules-fields),\
            $(eval __fieldval := $(strip $(__ndk_modules.$(__mod).$(__field))))\
            $(if $(__fieldval),\
                $(info $(space4)$(space4)$(__field) = "$(__fieldval)"),\
             )\
         )\
        $(info $(space4)/>)\
     )
$(info </android>)

#                $(if $(filter 1,$(words $(__fieldval))),\
#                    $(info $(space4)$(space4)$(__field)="$(__fieldval)"),\
#                    $(info $(space4)$(space4)$(__field): )\
#                    $(foreach __fielditem,$(__fieldval),\
#                        $(info $(space4)$(space4)$(space4)$(__fielditem))\
#                    )\
#                )\
