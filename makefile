MAIN_FILE = my_chapter
MAIN_FILE_COMPILE=$(MAIN_FILE).tex
PRECOMPIELD_NAME=precompiled
PRECOMPIELD_DEP=$(shell ./find-deps.bash "template_settings/ch_static_preamble.tex")
TIKZFLD = ./tikz/

RMFILESLIST = *.mtc* *.aux *.bak *.bbl *.bcf *.blg *.log *.out *.toc *.tdo _region.* *.run.xml *.flg *.idx *.maf _region_.* *~ *.ilg *.ind  *.fls *.fdb_latexmk *.M* *.gz *.fmt \#* *.nav *.snm precompiled.pdf
RMFILESCMD = $(patsubst %,-iname "%" -o,$(RMFILESLIST)) -false

TIME     = /usr/bin/time -p
LATEXMK  = latexmk -halt-on-error -pdf -pdflatex="pdflatex --shell-escape -fmt $(PRECOMPIELD_NAME) --synctex=1 -interaction=nonstopmode" # -shell-escape" 
FMTPDFLATEX=pdftex -ini -jobname="$(PRECOMPIELD_NAME)" -interaction=nonstopmode "&pdflatex" mylatexformat.ltx 

PDFLATEX = pdflatex -interaction=nonstopmode -output-directory 
PDFCROP  = pdfcrop
RM       = /bin/rm -f

StandAloneGraphicsTeXFiles = $(wildcard $(TIKZFLD)/*.tex)

PDFGraphics = $(patsubst %.tex,%.pdf,$(StandAloneGraphicsTeXFiles))

#LatexFiles = $(shell find . -path $(TIKZFLD) -prune -o -type f -iname '*.tex')
LatexFiles = $(shell ./find-deps.bash "$(MAIN_FILE).tex")

CurrentInclude = $(shell ./find-include.bash "$(MAIN_FILE).tex" "" $(CurrentFile))
CurrentIncludeGUARDSuffix = \#INCLUDE\#
CurrentIncludeGUARD = $(patsubst %,%$(CurrentIncludeGUARDSuffix),$(CurrentInclude))

#Includes = $(shell ./extract-includes.bash '\input{$(MAIN_FILE)}')
#IncludesPDF = $(patsubst %.tex,%.pdf,$(Includes))
#IncludesAUX = $(patsubst %.tex,%.aux,$(Includes))

COMPILE = $(TIME) $(LATEXMK) -jobname=$(MAIN_FILE) $(MAIN_FILE_COMPILE)
COMPILE_ALL = $(COMPILE) 

#----------------------init done--------------------------------

default : $(MAIN_FILE).pdf

# No difference for fast and standard in the case of small documents
#fast : $(CurrentIncludeGUARD)
fast : $(MAIN_FILE).pdf

# Forcing to recompile every time, latexmk will make a check
.PHONY : FORCE_MAKE
$(MAIN_FILE).pdf : $(MAIN_FILE).bcf $(PRECOMPIELD_NAME).fmt $(MAIN_FILE).tex $(LatexFiles) $(PDFGraphics) FORCE_MAKE
	/home/leshyk/PhD/GitDB/scripts-linux/correct-library-mendeley.bash
	/home/leshyk/PhD/GitDB/scripts-linux/clear-library.sh
	$(COMPILE_ALL)

$(MAIN_FILE).bcf : FORCE_MAKE
	test ! -f $(MAIN_FILE).bcf || grep '</bcf:controlfile>' $(MAIN_FILE).bcf || ( echo 'BCF file is corrupted, removing...' && rm $(MAIN_FILE).bcf )

$(PRECOMPIELD_NAME).fmt : $(PRECOMPIELD_DEP)
	touch $(PRECOMPIELD_NAME).mtc0
	$(FMTPDFLATEX)  $(MAIN_FILE_COMPILE)

$(TIKZFLD)%.pdf : $(TIKZFLD)%.tex
	$(PDFLATEX) $(TIKZFLD) $< 

clean : .PHONY
	@find $(RMFILESCMD) | xargs -I{} rm -r '{}'

depclean : clean
	$(RM) $(TIKZFLD)*.pdf
	#$(RM) $(IncludesPDF)

distclean : depclean
	$(RM) $(MAIN_FILE).pdf

noop : .PHONY
	@echo 'noop DONE'
#------------------------------------------------------
# for fast compiling of one include
.SECONDEXPANSION:

$(CurrentIncludeGUARD) : %$(CurrentIncludeGUARDSuffix) : $$(shell ./find-deps.bash %.tex) $(PRECOMPIELD_NAME).fmt $(MAIN_FILE).tex $(PDFGraphics) FORCE_MAKE
	@sed -i 's+\\begin{document}+\\includeonly{$(patsubst %$(CurrentIncludeGUARDSuffix),%,$@)}\\begin{document}+' $(MAIN_FILE_COMPILE)
	$(COMPILE) && echo "Compiled" >> $@

#--------------------------------------------------------
# For fast compiling of chapters. Syncinc will not work.

#incr: $(IncludesPDF) 
	#pdftk $(IncludesPDF) cat output $(MAIN_FILE).pdf

#.SECONDEXPANSION:

#$(IncludesPDF): %.pdf: %.tex $$(shell ./find-deps.bash %.tex) $(MAIN_FILE).tex $(PRECOMPIELD_NAME).fmt  $(PDFGraphics) 
## Checking if all aux exists. If not should recompile all.
#$(CHECK_AUX_COMPILE_ALL)
#cp $(MAIN_FILE).tex $(MAIN_FILE_COMPILE)
#sed -i 's+\\begin{document}+\\includeonly{$(patsubst %.pdf,%,$@)}\\begin{document}+' $(MAIN_FILE_COMPILE)
#$(TIME) $(LATEXMK) '-jobname=$(MAIN_FILE)' $(MAIN_FILE_COMPILE)
#cp $(MAIN_FILE).pdf $@

