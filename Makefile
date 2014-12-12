export vm := $(or $(VM),parrot,moar)

COMMON_SOURCES := \
  src/mo/$(vm)/VMCall.nqp \
  src/core/Variable.nqp \
  src/core/Routine.nqp \
  src/how/NodeHOW.nqp \
  src/how/FilesystemNodeHOW.nqp \
  src/how/AttributeHOW.nqp \
  src/how/ClassHOW.nqp \
  src/how/RuleHashHOW.nqp \
  src/how/TemplateHOW.nqp \

MODULELOADER_SOURCES := \
  src/mo/$(vm)/VMCall.nqp \
  src/mo/ModuleLoader.nqp \

MO_SOURCES := \
  src/mo/Grammar.nqp \
  src/mo/Glob.nqp \
  src/mo/Actions.nqp \
  src/mo/Compiler.nqp \
  src/mo/Model.nqp \
  src/mo/World.nqp \
  src/mo/Builtin.nqp \
  \
  src/mo/$(vm)/Ops.nqp \
  src/mo/ModuleLoader.nqp \

JSON_SOURCES := \
  src/json/Grammar.nqp \

XML_SOURCES := \
  src/xml/Grammar.nqp \
  src/xml/Actions.nqp \
  src/xml/Compiler.nqp \
  src/xml/World.nqp \

MAKEFILE_SOURCES := \
  src/makefile/Grammar.nqp \
  src/makefile/Actions.nqp \
  src/makefile/Compiler.nqp \
  src/makefile/World.nqp \
  src/makefile/Builtin.nqp \


include Make.$(vm)
