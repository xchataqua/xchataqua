#
# makefile for generating xchat documentation pdf
#

all: xchat-german

xchat-german: xchat-german.tex Makefile
	pdflatex xchat-german.tex
	makeindex xchat-german.idx
	pdflatex xchat-german.tex
clean::
	rm -rf *.aux *.toc *.glo *.log *.ilg *.idx *.ind *.out
