VKR ?= vkr
TALK ?= talk
ENGINE ?= xelatex # Only `xelatex` or `lualatex` are allowed here

.PHONY: $(NAME).pdf clean dist-clean format depext depext-deb
.SUFFIXES: .pdf .tex

all: $(VKR).pdf $(TALK).pdf

SRCS = $(sort $(wildcard [0-9][0-9][0-9]_*.tex))
# Цель: собрать все куски в один файл __vkr.tex
__vkr.tex: $(SRCS)
	@echo "Собираю $(words $^) файлов в $@"
	@rm -f $@
	@for f in $^; do \
		echo "% __SPLIT_MARKER__ $$f" >> $@; \
		cat "$$f" >> $@; \
		echo "" >> $@; \
	done

# Цель: разобрать __vkr.tex обратно на файлы с суффиксом '2'
split: __vkr.tex
	@echo "Разделяю $< на отдельные файлы (суффикс '2')"
	@awk 'BEGIN { out = "" } \
	/^% __SPLIT_MARKER__ / { \
		if (out) close(out); \
		split($$0, a, " "); \
		orig = a[3]; \
		out = gensub(/\.tex$$/, "2.tex", "g", orig); \
		print "  Создаю " out; \
		next; \
	} \
	out { print > out }' $<

# ----------------------------------------------------------------------

%.pdf: %.tex *.bib *.tex
	latexmk -$(ENGINE) -synctex=1 -interaction=nonstopmode -file-line-error -shell-escape $<

clean:
	latexmk -c $(VKR).tex $(TALK).tex
	@$(RM) *.pdf *.nav *.snm *.vrb *.synctex.gz _
	@$(RM) -r _minted-*

dist-clean:
	latexmk -C $(NAME).tex

# https://stackoverflow.com/a/12959694
# Make does not offer a recursive wildcard function, so here's one:
rwildcard=$(wildcard $1$2) $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))

FILES_TO_FORMAT := $(call rwildcard,./,*.tex) \
		   $(call rwildcard,./,*.cls) \
		   $(call rwildcard,./,*.bib)
#$(info $(FILES_TO_FORMAT))

format:
	$(foreach file, $(FILES_TO_FORMAT), latexindent -l -s -o=$(file) -m $(file);)

aspell:
	aspell --mode=tex -l ru --home-dir=. --personal=personal_dict.txt  -c $(FILE)

depext: depext-deb

# Not a full list of external dependencies. To be extended...
depext-deb:
	sudo apt install fonts-cmu texlive-lang-cyrillic texlive-xetex texlive-bibtex-extra texlive-science texlive-plain-generic latexmk python3-pygments --yes
	# for pzdr font
	sudo apt install texlive-fonts-recommended --yes
	sudo apt install hunspell-ru --yes
