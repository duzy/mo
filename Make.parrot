# -*- makefile-gmake -*-
BASH := $(shell which bash)
CAT := $(shell which cat)
PARROT := $(shell which parrot)
NQP := $(shell which nqp-p) --module-path=gen/parrot

COMMON_PBC := gen/parrot/common.pbc
COMMON_PIR := gen/parrot/common.pir
COMMON_NQP := gen/parrot/common.nqp
COMMON_SOURCES := \
  src/mo/parrot/VMCall.nqp \
  src/core/Variable.nqp \
  src/core/Routine.nqp \
  src/how/NodeHOW.nqp \
  src/how/FilesystemNodeHOW.nqp \
  src/how/AttributeHOW.nqp \
  src/how/ClassHOW.nqp \
  src/how/RuleHashHOW.nqp \
  src/how/TemplateHOW.nqp \

JSON_PBC := gen/parrot/json.pbc
JSON_PIR := gen/parrot/json.pir
JSON_NQP := gen/parrot/json.nqp
JSON_SOURCES := \
  src/json/Grammar.nqp \

XML_PBC := gen/parrot/xml.pbc
XML_PIR := gen/parrot/xml.pir
XML_NQP := gen/parrot/xml.nqp
XML_SOURCES := \
  src/xml/Grammar.nqp \
  src/xml/Actions.nqp \
  src/xml/Compiler.nqp \
  src/xml/World.nqp \

MAKEFILE_PBC := gen/parrot/makefile.pbc
MAKEFILE_PIR := gen/parrot/makefile.pir
MAKEFILE_NQP := gen/parrot/makefile.nqp
MAKEFILE_SOURCES := \
  src/makefile/Grammar.nqp \
  src/makefile/Actions.nqp \
  src/makefile/Compiler.nqp \
  src/makefile/World.nqp \
  src/makefile/Builtin.nqp \

MODULELOADER_PBC := gen/parrot/mo/ModuleLoader.pbc
MODULELOADER_PIR := gen/parrot/mo/ModuleLoader.pir
MODULELOADER_NQP := gen/parrot/mo/ModuleLoader.nqp
MODULELOADER_SOURCES := \
  src/mo/parrot/VMCall.nqp \
  src/mo/ModuleLoader.nqp \

MO_PBC := gen/parrot/mo.pbc
MO_PIR := gen/parrot/mo.pir
MO_NQP := gen/parrot/mo.nqp
MO_SOURCES := \
  src/mo/Grammar.nqp \
  src/mo/Glob.nqp \
  src/mo/Actions.nqp \
  src/mo/Compiler.nqp \
  src/mo/Model.nqp \
  src/mo/World.nqp \
  src/mo/Builtin.nqp \
  \
  src/mo/parrot/Ops.nqp \
  src/mo/ModuleLoader.nqp \

$(MO_PBC): $(MO_PIR) $(MODULELOADER_PBC) $(MAKEFILE_PBC)
	@mkdir -p $(@D)
	$(PARROT) -t=pbc --output="$@" "$<" 2>/dev/null
	@[ -f $@ ]

$(MO_PIR): $(MO_NQP) $(XML_PBC) $(JSON_PBC)
	@mkdir -p $(@D)
	$(NQP) --combine --target=pir --output="$@" $<
	@[ -f $@ ]

$(MO_NQP): $(MO_SOURCES)
	@mkdir -p $(@D)
	$(CAT) $^ > "$@"
	@[ -f $@ ]

$(MODULELOADER_PBC): $(MODULELOADER_PIR)
	@mkdir -p $(@D)
	$(PARROT) -t=pbc --output="$@" "$<" 2>/dev/null
	@[ -f $@ ]

$(MODULELOADER_PIR): $(MODULELOADER_NQP)
	@mkdir -p $(@D)
	$(NQP) --target=pir --output="$@" $<
	@[ -f $@ ]

$(MODULELOADER_NQP): $(MODULELOADER_SOURCES)
	@mkdir -p $(@D)
	$(CAT) $^ > "$@"
	@[ -f $@ ]

$(XML_PBC): $(XML_PIR)
	@mkdir -p $(@D)
	$(PARROT) -t=pbc --output="$@" "$<" 2>/dev/null
	@[ -f $@ ]

$(XML_PIR): $(XML_NQP) $(COMMON_PBC)
	@mkdir -p $(@D)
	$(NQP) --combine --target=pir --output="$@" $<
	@[ -f $@ ]

$(XML_NQP): $(XML_SOURCES)
	@mkdir -p $(@D)
	$(CAT) $^ > "$@"
	@[ -f $@ ]

$(JSON_PBC): $(JSON_PIR)
	@mkdir -p $(@D)
	$(PARROT) -t=pbc --output="$@" "$<" 2>/dev/null
	@[ -f $@ ]

$(JSON_PIR): $(JSON_NQP)
	@mkdir -p $(@D)
	$(NQP) --combine --target=pir --output="$@" $^
	@[ -f $@ ]

$(JSON_NQP): $(JSON_SOURCES)
	@mkdir -p $(@D)
	$(CAT) $^ > "$@"
	@[ -f $@ ]

$(MAKEFILE_PBC): $(MAKEFILE_PIR)
	@mkdir -p $(@D)
	$(PARROT) -t=pbc --output="$@" "$<" 2>/dev/null
	@[ -f $@ ]

$(MAKEFILE_PIR): $(MAKEFILE_NQP) $(COMMON_PBC)
	@mkdir -p $(@D)
	$(NQP) --combine --target=pir --output="$@" $<
	@[ -f $@ ]

$(MAKEFILE_NQP): $(MAKEFILE_SOURCES)
	@mkdir -p $(@D)
	$(CAT) $^ > "$@"
	@[ -f $@ ]

$(COMMON_PBC): $(COMMON_PIR)
	@mkdir -p $(@D)
	$(PARROT) -t=pbc --output="$@" "$<" 2>/dev/null
	@[ -f $@ ]

$(COMMON_PIR): $(COMMON_NQP)
	@mkdir -p $(@D)
	$(NQP) --combine --target=pir --output="$@" "$^"
	@[ -f $@ ]

$(COMMON_NQP): $(COMMON_SOURCES)
	@mkdir -p $(@D)
	$(CAT) $^ > "$@"
	@[ -f $@ ]

test: test-xml test-json test-mo

test-xml: t/xml/run.bash $(XML_PBC)
	@$(BASH) $<

test-json: ; @echo "JSON..."

test-makefile: t/makefile/run.bash $(MAKEFILE_PBC)
	@$(BASH) $<

test-mo: t/mo/run.bash $(MO_PBC)
	@$(BASH) $<

test-examples: examples/test.bash $(MO_PBC)
	@$(BASH) $<

run-examples: examples/run.bash $(MO_PBC)
	@$(BASH) $<

run-apps: run-app-android-build run-app-protocol
run-app-android-build: apps/android-build/run.bash $(MO_PBC)
	@$(BASH) $<
run-app-protocol: apps/protocol/run.bash $(MO_PBC)
	@$(BASH) $<
