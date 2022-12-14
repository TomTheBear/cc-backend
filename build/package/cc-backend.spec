Name:           cc-backend
Version:        %{VERS}
Release:        1%{?dist}
Summary:        ClusterCockpit backend and web frontend

License:        MIT
Source0:        %{name}-%{version}.tar.gz

#BuildRequires:  go-toolset
#BuildRequires:  systemd-rpm-macros
#BuildRequires:  npm

Provides:       %{name} = %{version}

%description
ClusterCockpit backend and web frontend

%global debug_package %{nil}

%prep
%autosetup


%build
#cd web/frontend/ && npm install --save-dev svelte rollup-plugin-svelte && npm audit fix && cd -
mkdir ./var
touch ./var/job.db
cd web/frontend && yarn build
cd web/frontend && yarn install
go build -ldflags=${LD_FLAGS} ./cmd/cc-backend


%install
# Install cc-backend
#make PREFIX=%{buildroot} install
install -Dpm 755 cc-backend %{buildroot}/%{_bindir}/%{name}
# Integrate into system
install -Dpm 0644 build/package/%{name}.service %{buildroot}%{_unitdir}/%{name}.service
install -Dpm 0600 build/package/%{name}.config %{buildroot}%{_sysconfdir}/default/%{name}
install -Dpm 0644 build/package/%{name}.sysusers %{buildroot}%{_sysusersdir}/%{name}.conf


%check
# go test should be here... :)

%pre
%sysusers_create_package scripts/%{name}.sysusers

%post
%systemd_post %{name}.service

%preun
%systemd_preun %{name}.service

%files
# Binary
%attr(-,clustercockpit,clustercockpit) %{_bindir}/%{name}
# Config
%dir %{_sysconfdir}/%{name}
%attr(0600,clustercockpit,clustercockpit) %config(noreplace) %{_sysconfdir}/%{name}/%{name}.json
# Systemd
%{_unitdir}/%{name}.service
%{_sysconfdir}/default/%{name}
%{_sysusersdir}/%{name}.conf

%changelog
* Mon Mar 07 2022 Thomas Gruber - 0.1
- Initial metric store implementation

