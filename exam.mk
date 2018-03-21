# No implicit rules
MAKEFLAGS += -rR

## Get current directory where this very file is located
current_dir := $(dir $(lastword $(MAKEFILE_LIST)))

## Define and check external programs
PANDOC := pandoc
ifeq (,$(shell command -v $(PANDOC) 2>/dev/null))
$(error Could not find executable '$(PANDOC)' in PATH)
endif

## Find all files under a directory
find_files = $(shell find $(1) -maxdepth 1 -type f)

## List of markdown files and resulting PDF files
md := $(filter %.md,$(call find_files,$(src)))
pdf := $(md:%.md=%.pdf)
pdf_sol := $(md:%.md=%_sol.pdf)

## Extra dependencies for all targets
tmpl := $(addprefix $(current_dir),template.tex)
before := $(addprefix $(current_dir),latex.yaml cover.md)
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

## Our main rule building all our targets
all: $(pdf) $(pdf_sol)

## Template processing rule
quiet_cmd_tpl = TMPL $(@)
      cmd_tpl = pandoc \
				-M solution=$(2) \
				--template=$(tmpl) \
				$< -o $@

%.tpl: %.md $(tmpl)
	$(call cmd,tpl,no)
%_sol.tpl: %.md $(tmpl)
	$(call cmd,tpl,yes)

## Markdown to PDF rule
quiet_cmd_pandoc = PANDOC $(@)
      cmd_pandoc = pandoc -s \
				   -H $(2).tpl \
				   --filter $(addprefix $(current_dir),pandoc_latex_environment.py) \
				   --filter $(addprefix $(current_dir),pandoc_header_numbering.py) \
				   $(before) \
				   $< -o $@

%.pdf: %.md %.tpl $(before)
	$(call cmd,pandoc,$*)
%_sol.pdf: %.md %_sol.tpl $(before)
	$(call cmd,pandoc,$*_sol)

## Clean
clean:
	$(Q)rm -f $(pdf) $(pdf_sol)

distclean:
	$(Q)rm -f *.tpl
