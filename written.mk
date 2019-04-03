# No implicit rules
MAKEFLAGS += -rR

## Get current directory where this very file is located
current_dir := $(dir $(lastword $(MAKEFILE_LIST)))

## Define and check external programs
PANDOC := pandoc
ifeq (,$(shell command -v $(PANDOC) 2>/dev/null))
$(error Could not find executable '$(PANDOC)' in PATH)
endif

pdf := $(src:%.md=%.pdf)
pdf_key := $(src:%.md=%_key.pdf)

## Extra dependencies for all targets
tmpl := $(addprefix $(current_dir),template.tex)
before := $(addprefix $(current_dir),latex.yaml cover_$(type).md)
dep += $(tmpl) $(before)

## Command management and quiet mode
ifneq ($(V),1)
Q = @
quiet = quiet_
else
Q =
quiet =
endif

echo-cmd = $(if $($(quiet)cmd_$(1)),\
	echo '  $($(quiet)cmd_$(1))';)
cmd = @$(echo-cmd) $(cmd_$(1))

## Type of document
ifeq ($(type),exam)
exam := True
else
exam := False
endif

## Our main rule building all our targets
all: $(pdf) $(pdf_key)

## Template processing rule
quiet_cmd_tpl = TMPL $(@)
      cmd_tpl = pandoc \
				-M key=$(2) \
				-M exam=$(exam) \
				--template=$(tmpl) \
				$< -o $@

%.tpl: %.md $(tmpl)
	$(call cmd,tpl,False)
%_key.tpl: %.md $(tmpl)
	$(call cmd,tpl,True)

## Markdown to PDF rule
quiet_cmd_pandoc = PANDOC $(@)
      cmd_pandoc = pandoc -s \
				   -H $(2).tpl \
				   --filter $(addprefix $(current_dir),pandoc_latex_environment.py) \
				   --filter $(addprefix $(current_dir),pandoc_header_numbering.py) \
				   --highlight-style=monochrome \
				   $(before) \
				   $< -o $@

%.pdf: %.md %.tpl $(before)
	$(call cmd,pandoc,$*)
%_key.pdf: %.md %_key.tpl $(before)
	$(call cmd,pandoc,$*_key)

## Clean
clean:
	$(Q)rm -f $(pdf) $(pdf_key)

distclean:
	$(Q)rm -f *.tpl
