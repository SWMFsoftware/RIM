include Makefile.def

install:
	touch src/Makefile.DEPEND

LIB:
	cd src; make LIB

# WARNING: Some functions dependent on existence of UA.
rundir:
	cd ${IEDIR}/src; make POST # Make postprocessing tool.
	mkdir -p ${RUNDIR}/IE/Output
	cd ${RUNDIR}/IE; ln -s ${DIR}/UA/GITM2/srcData Input; cd ${DIR}
	cd ${RUNDIR}; ln -s ${IEDIR}/src/PostRIM.exe PostRIM.exe; cd ${DIR}
	cd ${RUNDIR}/IE; ln -s ${IEDIR}/src/pIE .; cd ${DIR}
	cd ${RUNDIR};    ln -s ${EMPIRICALIEDIR}/data EIE

clean:
	@touch src/Makefile.DEPEND src/Makefile.RULES
	cd src; make clean

distclean: 
	./Config.pl -uninstall

allclean:
	@touch src/Makefile.DEPEND src/Makefile.RULES
	cd src; make distclean
	rm -f *~

test:
	echo "There is no test for IE/RIM" > notest.diff

test_tmp:
	cd ${RUNDIR}; cp ${DIR}/Param/LAYOUT.in.test.RIM.Weimer LAYOUT.in; cd ${DIR}
	cd ${RUNDIR}; cp ${DIR}/Param/PARAM.in.test.RIM.Weimer PARAM.in; cd ${DIR}
	cd ${RUNDIR}; ./SWMF.exe
