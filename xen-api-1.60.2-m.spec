Name:	xen-api		
Version:	1.60.2
Release:	1%{?dist}
Summary:	rpm xen-api modify

Group:		Application/test
License:	Share	
Source:		$RPM_SOURCE_DIR/xen-api-1.60.2_m.tar.gz


%description
print xen-api


%prep
rm -rf $RPM_BUILD_DIR/xen-api-1.60.2
zcat $RPM_SOURCE_DIR/xen-api-1.60.2_m.tar.gz | tar xvf -

%build
cd $RPM_BUILD_DIR/xen-api-1.60.2
./configure
make %{?_smp_mflags}


%install
cd $RPM_BUILD_DIR/xen-api-1.60.2
make install DESTDIR=%{buildroot}


%files
/etc
/var
/usr
/opt
%doc

