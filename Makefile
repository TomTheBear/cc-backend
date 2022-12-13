TARGET = ./cc-backend
VAR = ./var
FRONTEND = ./web/frontend
VERSION = 0.1
GIT_HASH := $(shell git rev-parse --short HEAD || echo 'development')
CURRENT_TIME = $(shell date +"%Y-%m-%d:T%H:%M:%S")
LD_FLAGS = '-s -X main.buildTime=${CURRENT_TIME} -X main.version=${VERSION} -X main.hash=${GIT_HASH}'

SVELTE_COMPONENTS = status   \
					analysis \
					node     \
					systems  \
					job      \
					list     \
					user     \
					jobs     \
					header

SVELTE_TARGETS = $(addprefix $(FRONTEND)/public/build/,$(addsuffix .js, $(SVELTE_COMPONENTS)))
SVELTE_SRC = $(wildcard $(FRONTEND)/src/*.svelte)         \
			 $(wildcard $(FRONTEND)/src/*.js)             \
			 $(wildcard $(FRONTEND)/src/filters/*.svelte) \
			 $(wildcard $(FRONTEND)/src/plots/*.svelte)   \
			 $(wildcard $(FRONTEND)/src/joblist/*.svelte)

.PHONY: clean test $(TARGET)

.NOTPARALLEL:

$(TARGET): $(VAR) $(SVELTE_TARGETS)
	$(info ===>  BUILD cc-backend)
	@go build -ldflags=${LD_FLAGS} ./cmd/cc-backend

clean:
	$(info ===>  CLEAN)
	@go clean
	@rm $(TARGET)

test:
	$(info ===>  TESTING)
	@go build ./...
	@go vet ./...
	@go test ./...

$(SVELTE_TARGETS): $(SVELTE_SRC)
	$(info ===>  BUILD frontend)
	cd web/frontend && yarn build

$(VAR):
	@mkdir $(VAR)
	@touch ./var/job.db
	cd web/frontend && yarn install

install: $(TARGET)
	@WORKSPACE=$(PREFIX)
	@if [ -z "$${WORKSPACE}" ]; then exit 1; fi
	@mkdir --parents --verbose $${WORKSPACE}/usr/$(BINDIR)
	@install -Dpm 755 $(TARGET) $${WORKSPACE}/usr/$(BINDIR)/$(TARGET)
	@install -Dpm 600 configs/config.json $${WORKSPACE}/etc/$(TARGET)/$(TARGET).json

.ONESHELL:
.PHONY: RPM
RPM: build/package/cc-backend.spec
	@WORKSPACE="$${PWD}"
	@SPECFILE="$${WORKSPACE}/build/package/cc-backend.spec"
	# Setup RPM build tree
	@eval $$(rpm --eval "ARCH='%{_arch}' RPMDIR='%{_rpmdir}' SOURCEDIR='%{_sourcedir}' SPECDIR='%{_specdir}' SRPMDIR='%{_srcrpmdir}' BUILDDIR='%{_builddir}'")
	@mkdir --parents --verbose "$${RPMDIR}" "$${SOURCEDIR}" "$${SPECDIR}" "$${SRPMDIR}" "$${BUILDDIR}"
	# Create source tarball
	@COMMITISH="HEAD"
	@VERS=$$(git describe --tags $${COMMITISH})
	@VERS=$${VERS#v}
	@VERS=$$(echo $$VERS | sed -e s+'-'+'_'+g)
	@if [ "$${VERS}" = "" ]; then VERS="$(VERSION)"; fi
	@eval $$(rpmspec --query --queryformat "NAME='%{name}' VERSION='%{version}' RELEASE='%{release}' NVR='%{NVR}' NVRA='%{NVRA}'" --define="VERS $${VERS}" "$${SPECFILE}")
	@PREFIX="$${NAME}-$${VERSION}"
	@FORMAT="tar.gz"
	@SRCFILE="$${SOURCEDIR}/$${PREFIX}.$${FORMAT}"
	@git archive --verbose --format "$${FORMAT}" --prefix="$${PREFIX}/" --output="$${SRCFILE}" $${COMMITISH}
	# Build RPM and SRPM
	@rpmbuild -ba --define="VERS $${VERS}" --rmsource --clean "$${SPECFILE}"
	# Report RPMs and SRPMs when in GitHub Workflow
	@if [ "$${GITHUB_ACTIONS}" = true ]; then
	@     RPMFILE="$${RPMDIR}/$${ARCH}/$${NVRA}.rpm"
	@     SRPMFILE="$${SRPMDIR}/$${NVR}.src.rpm"
	@     echo "RPM: $${RPMFILE}"
	@     echo "SRPM: $${SRPMFILE}"
	@     echo "::set-output name=SRPM::$${SRPMFILE}"
	@     echo "::set-output name=RPM::$${RPMFILE}"
	@fi

.ONESHELL:
.PHONY: DEB
DEB: build/package/cc-backend.deb.control $(APP)
	@BASEDIR=$${PWD}
	@WORKSPACE=$${PWD}/.dpkgbuild
	@DEBIANDIR=$${WORKSPACE}/debian
	@DEBIANBINDIR=$${WORKSPACE}/DEBIAN
	@mkdir --parents --verbose $$WORKSPACE $$DEBIANBINDIR
	#@mkdir --parents --verbose $$DEBIANDIR
	@CONTROLFILE="$${BASEDIR}/build/package/cc-backend.deb.control"
	@COMMITISH="HEAD"
	@VERS=$$(git describe --tags --abbrev=0 $${COMMITISH})
	@VERS=$${VERS#v}
	@VERS=$$(echo $$VERS | sed -e s+'-'+'_'+g)
	@if [ "$${VERS}" = "" ]; then VERS="0.0.1"; fi
	@ARCH=$$(uname -m)
	@ARCH=$$(echo $$ARCH | sed -e s+'_'+'-'+g)
	@if [ "$${ARCH}" = "x86-64" ]; then ARCH=amd64; fi
	@PREFIX="$${NAME}-$${VERSION}_$${ARCH}"
	@SIZE_BYTES=$$(du -bcs --exclude=.dpkgbuild "$$WORKSPACE"/ | awk '{print $$1}' | head -1 | sed -e 's/^0\+//')
	@SIZE="$$(awk -v size="$$SIZE_BYTES" 'BEGIN {print (size/1024)+1}' | awk '{print int($$0)}')"
	#@sed -e s+"{VERSION}"+"$$VERS"+g -e s+"{INSTALLED_SIZE}"+"$$SIZE"+g -e s+"{ARCH}"+"$$ARCH"+g $$CONTROLFILE > $${DEBIANDIR}/control
	@sed -e s+"{VERSION}"+"$$VERS"+g -e s+"{INSTALLED_SIZE}"+"$$SIZE"+g -e s+"{ARCH}"+"$$ARCH"+g $$CONTROLFILE > $${DEBIANBINDIR}/control
	@make PREFIX=$${WORKSPACE} install
	@DEB_FILE="cc-metric-store_$${VERS}_$${ARCH}.deb"
	@dpkg-deb -b $${WORKSPACE} "$$DEB_FILE"
	@rm -r "$${WORKSPACE}"
	@if [ "$${GITHUB_ACTIONS}" = "true" ]; then
	@     echo "::set-output name=DEB::$${DEB_FILE}"
	@fi
