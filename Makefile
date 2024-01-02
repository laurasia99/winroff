# Neatroff for Microsoft Windows - Master build script
# 
# See README for detailed instructions

# Establish installation defaults
#  - values of FDIR & MDIR are compiled into roff.exe and post.exe
#    binaries
#  *** Change for your setup in NMakefile-local

!IF EXIST(NMakefile-local)
!INCLUDE NMakefile-local
!ENDIF

# [roff.exe post.exe] default font and macro directories
!IFNDEF FDIR
FDIR = C:/troff/font
!ENDIF
!IFNDEF MDIR
MDIR = C:/troff/tmac
!ENDIF

# Object and intermediate files placed under $OBJ
!IFNDEF OBJ
OBJ = obj
!ENDIF

# Default target
all::

# Targets git-all & git-<subproject>
# Target git-<subproject> glued into default 'all' target if missing
# and _GIT_TARGET is set to 1 during the makefile preprocessing.
# If, at the end of the preprocessing, _GIT_TARGET>0, then add a
# dummy target to let the user know that they need to run NMake
# again to perform the build
_GIT_TARGET = 0
!INCLUDE NMakefile-gitclone

# Don't assume that all of the subprojects have been downloaded
!IF EXIST(eqn\NMakefile)
S = .\eqn
O = $(OBJ)\eqn
!INCLUDE eqn\NMakefile
!ELSE
all:: git-eqn
_GIT_TARGET = 1
_GIT_PROJECT = $(_GIT_PROJECT) neateqn
!ENDIF

# Configuring devutf depends on mkfn
!IF EXIST(mkfn\NMakefile)
S = .\mkfn
O = $(OBJ)\mkfn
!INCLUDE mkfn\NMakefile
!INCLUDE NMakefile-devutf
!ELSE
all:: git-mkfn
_GIT_TARGET = 1
_GIT_PROJECT = $(_GIT_PROJECT) neatmkfn
!ENDIF

# soin.exe pdfbb.exe & download/unzip font packages
!IF !EXIST(other\NMakefile)
all:: git-other
_GIT_TARGET = 1
_GIT_PROJECT = $(_GIT_PROJECT) neatrother
!ELSE
S = .\other\soin
O = $(OBJ)\other\soin
!INCLUDE other\NMakefile-soin
S = .\other\pdfbb
O = $(OBJ)\other\pdfbb
!INCLUDE other\NMakefile-pdfbb

# Downloading/unzipping the raw fonts uses helper scripts
# These are distributed in the 'neatrother' project, and are located
# in other\. To simplify the build process, pull up copies into
# this directory (avoids complex path setting)
do-curl.bat: other\$(@F)
    copy /y other\$(@F) $@
do-unzip.bat: other\$(@F)
    copy /y other\$(@F) $@
all:: do-curl.bat do-unzip.bat

!IF DEFINED(USE_URW35_FONTS) && $(USE_URW35_FONTS) > 0
!INCLUDE other\NMakefile-urw35
!ENDIF
!IF DEFINED(USE_AMS_FONTS) && $(USE_AMS_FONTS) > 0
!INCLUDE other\NMakefile-ams
!ENDIF
!ENDIF # other\

# pic & tbl originally from Plan9; distributed together
# Use sub-project makefiles directly
!IF EXIST(pictbl\Makefile)
S = .\pictbl\pic
O = $(OBJ)\pic
!INCLUDE pictbl\NMakefile-pic
S = .\pictbl\tbl
O = $(OBJ)\tbl
!INCLUDE pictbl\NMakefile-tbl
!ELSE
all:: git-pictbl
_GIT_TARGET = 1
_GIT_PROJECT = $(_GIT_PROJECT) troffp9
!ENDIF

# Default is to only build pdf.exe (and not post.exe)
!IF EXIST(post\NMakefile)
S = .\post
O = $(OBJ)\post
!INCLUDE post\NMakefile
!ELSE
all:: git-post
_GIT_TARGET = 1
_GIT_PROJECT = $(_GIT_PROJECT) neatpost
!ENDIF

!IF EXIST(refer\NMakefile)
S = .\refer
O = $(OBJ)\refer
!INCLUDE refer\NMakefile
!ELSE
all:: git-refer
_GIT_TARGET = 1
_GIT_PROJECT = $(_GIT_PROJECT) neatrefer
!ENDIF

!IF EXIST(roff\NMakefile)
S = .\roff
O = $(OBJ)\roff
!INCLUDE roff\NMakefile
!ELSE
all:: git-roff
_GIT_TARGET = 1
_GIT_PROJECT = $(_GIT_PROJECT) neatroff
!ENDIF

# sed used during installation; invoke submake
!IF EXIST(sed\Makefile)
all:: sed.exe
sed.exe:
    pushd sed && nmake /nologo /f Makefile && popd
    copy sed\sed.exe $@
!ELSE
all:: git-sed
!MESSAGE _GIT_TARGET [sed]
_GIT_TARGET = 1
!ENDIF

# A little bit of ugliness is needed to find the current
# working directory - creates temporary file _NMakefile-cwd
# Required for building demonstration documents
!IF [.\getcwd.bat] == 0
!IF EXIST(_NMakefile-cwd)
!INCLUDE _NMakefile-cwd
!IF [del _NMakefile-cwd] == 0
!ENDIF
!ENDIF
!ENDIF
_xCWD = x$(_CWD)
!IF !DEFINED(_CWD) || "$(_xCWD)" == "x"
!ERROR Error: current working directory not set?
!ENDIF

# Demonstration documents (other\demo)
DEMOPDFS = demo.pdf neatroff.pdf neateqn.pdf neatstart.pdf neatcc.pdf

!IF $(_GIT_TARGET) > 0
all:: git-rebuild-required

git-rebuild-required:
    @echo +----------------------------------------------------------
    @echo |
    @echo | Subprojects updated - rerun ^"nmake^" to complete the build
    @echo | Fetched: $(_GIT_PROJECT)
    @echo |
    @echo +----------------------------------------------------------
!ENDIF

demo: $(EXES) $(DEMOPDFS)

clean::
    if exist obj rmdir /s /q obj
    if exist devutf rmdir /s /q devutf
    -del /q *.pdf *.ps

scrub:: clean
    if exist do-curl.bat del do-curl.bat
    if exist do-unzip.bat del do-unzip.bat
    if exist sed.exe del sed.exe

# Demonstration files
# Note use of command line arguments to override compiled paths (FDIR MDIR)
BASE = $(_CWD)
FONTS = $(BASE)/other/fonts
TMAC = $(BASE)/other/tmac
ROFFOPTS = -F$(BASE) -M$(TMAC)
ROFFMACS = -mpost -mtbl -mkeep -men -msrefs
POSTOPTS = -F$(BASE) -pa4
REFROPTS = -m -e -o ct -p ref.bib

# Assumes ghostscript installed
GS = "C:\Program Files\gs\gs10.02.1\bin\gswin64c.exe"
GSOPTS = -q -P- -dSAFER -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dEmbedAllFonts=true

D=other\demo
demo.pdf: $D\demo.tr
	@echo Generating $@
	roff.exe $(ROFFOPTS) $D\$(@B).tr | pdf $(POSTOPTS) > $(@B).ps
    $(GS) $(GSOPTS) -sOutputFile=$@ $(@B).ps
neatroff.pdf: $D\neatroff.ms
	@echo Generating $@
	soin.exe -I $D $(@B).ms | refer.exe $(REFROPTS) | pic.exe | tbl.exe | eqn.exe | roff.exe $(ROFFOPTS) $(ROFFMACS) | pdf $(POSTOPTS) > $(@B).ps
    $(GS) $(GSOPTS) -sOutputFile=$@ $(@B).ps
neateqn.pdf: $D\neateqn.ms
	@echo Generating $@
	soin.exe -I $D $(@B).ms | refer.exe $(REFROPTS) | pic.exe | tbl.exe | eqn.exe | roff.exe $(ROFFOPTS) $(ROFFMACS) | pdf $(POSTOPTS) > $(@B).ps
    $(GS) $(GSOPTS) -sOutputFile=$@ $(@B).ps
neatstart.pdf: $D\neatstart.ms
	@echo Generating $@
	soin.exe -I $D $(@B).ms | refer.exe $(REFROPTS) | pic.exe | tbl.exe | eqn.exe | roff.exe $(ROFFOPTS) $(ROFFMACS) | pdf $(POSTOPTS) > $(@B).ps
    $(GS) $(GSOPTS) -sOutputFile=$@ $(@B).ps
neatcc.pdf: $D\neatcc.ms
	@echo Generating $@
	soin.exe -I $D $(@B).ms | refer.exe $(REFROPTS) | pic.exe | tbl.exe | eqn.exe | roff.exe $(ROFFOPTS) $(ROFFMACS) | pdf $(POSTOPTS) > $(@B).ps
    $(GS) $(GSOPTS) -sOutputFile=$@ $(@B).ps

ligature.pdf: roff.exe pdf.exe tests\ligature.ms
	@echo Generating $@
	roff.exe $(ROFFOPTS) tests\$(@B).ms > $(@B).roff
    type $(@B).roff | pdf $(POSTOPTS) > $(@B).ps
    $(GS) $(GSOPTS) -sOutputFile=$@ $(@B).ps
    @rem $(PS2PDF) $(PS2PDFOPTS) $(@B).ps $(@B).pdf

## Git support

git-status:
    pushd eqn && git status && popd
    pushd mkfn && git status && popd
    pushd other && git status && popd
    pushd pictbl && git status && popd
    pushd post && git status && popd
    pushd refer && git status && popd
    pushd roff && git status && popd
    pushd sed && git status && popd
    git status
