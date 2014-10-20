vm := $(or $(VM),parrot,moar)
include Make.$(vm)
