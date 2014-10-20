# -*- makefile-gmake -*-
PARROT := $(shell which parrot)
BASH := $(shell which bash)
NQP := $(shell which nqp-p) --module-path=gen/parrot
CAT := $(shell which cat)

COMMON_PBC := gen/parrot/common.pbc
COMMON_PIR := gen/parrot/common.pir
COMMON_NQP := gen/parrot/common.nqp
COMMON_SOURCES := \
  src/core/Variable.nqp \
  src/core/Routine.nqp \
  src/how/NodeHOW.nqp \
  src/how/Node.nqp \
  src/how/FilesystemNodeHOW.nqp \
  src/how/FilesystemNode.nqp \
  src/how/AttributeHOW.nqp \
  src/how/ClassHOW.nqp \
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

MODULELOADER_PBC := gen/parrot/mo/ModuleLoader.pbc
MODULELOADER_PIR := gen/parrot/mo/ModuleLoader.pir
MODULELOADER_NQP := src/mo/ModuleLoader.nqp

MO_PBC := gen/parrot/mo.pbc
MO_PIR := gen/parrot/mo.pir
MO_NQP := gen/parrot/mo.nqp
MO_SOURCES := \
  src/mo/Grammar.nqp \
  src/mo/Actions.nqp \
  src/mo/Compiler.nqp \
  src/mo/Model.nqp \
  src/mo/World.nqp \
  \
  src/mo/ModuleLoader.nqp \

MO_SOURCES += src/mo/parrot/Ops.nqp

$(MO_PBC): $(MO_PIR) $(MODULELOADER_PBC)
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

test-mo: t/mo/run.bash $(MO_PBC)
	@$(BASH) $<

test-examples: examples/test.bash $(MO_PBC)
	@$(BASH) $<

run-examples: examples/run.bash $(MO_PBC)
	@$(BASH) $<

run-apps: apps/android-build/run.bash $(MO_PBC)
	@$(BASH) $<