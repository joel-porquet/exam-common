# No implicit rules
MAKEFLAGS += -rR

## Get current directory where this very file is located
current_dir := $(dir $(lastword $(MAKEFILE_LIST)))

## Define and check external programs
PANDOC := pandoc
ifeq (,$(shell command -v $(PANDOC) 2>/dev/null))
$(error Could not find executable '$(PANDOC)' in PATH)
endif

pdf_exam := $(src:%.md=%_exam.pdf)
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
all: $(pdf_exam) $(pdf_key)

## Template processing rule
quiet_cmd_tmpl = TMPL $(@)
      cmd_tmpl = pandoc \
				-M key=$(2) \
				-M exam=$(exam) \
				--template=$(tmpl) \
				--mathjax \
				$< -o $@

%_exam.tmpl: %.md $(tmpl)
	$(call cmd,tmpl,False)
%_key.tmpl: %.md $(tmpl)
	$(call cmd,tmpl,True)

## Markdown to PDF rule
quiet_cmd_pandoc = PANDOC $(@)
      cmd_pandoc = pandoc -s \
				   -H $(2).tmpl \
				   --resource-path=.:$(GIT_DIR):$(current_dir) \
				   --filter $(addprefix $(current_dir),pandoc_latex_environment.py) \
				   --filter $(addprefix $(current_dir),pandoc_header_numbering.py) \
				   --highlight-style=monochrome \
				   $(before) \
				   $< -o $@

%_exam.pdf: %.md %_exam.tmpl $(before)
	$(call cmd,pandoc,$*_exam)
%_key.pdf: %.md %_key.tmpl $(before)
	$(call cmd,pandoc,$*_key)

## Clean
clean:
	$(Q)rm -f $(pdf_exam) $(pdf_key)

distclean:
	$(Q)rm -f *.tmpl
