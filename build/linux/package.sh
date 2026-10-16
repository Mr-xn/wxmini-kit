#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
build_version="${1:-dev}"
release_dir="$root_dir/build/release"
staging_dir="$(mktemp -d)"
rpm_top="$staging_dir/rpm"
trap 'rm -rf "$staging_dir"' EXIT

if [[ "$build_version" == dev ]]; then
  deb_version="0.1.0+dev"
  rpm_version="0.1.0"
  rpm_release="0.dev"
else
  raw_version="${build_version#v}"
  rpm_version="${raw_version%%-*}"
  suffix="${raw_version#"$rpm_version"}"
  if [[ "$suffix" == "$raw_version" ]]; then
    deb_version="$rpm_version"
    rpm_release="1"
  else
    suffix="${suffix#-}"
    deb_version="${rpm_version}~${suffix}"
    rpm_release="0.${suffix//[^A-Za-z0-9._+]/.}"
  fi
fi

mkdir -p "$release_dir"
install_root="$staging_dir/root"
install -D -m 0755 "$root_dir/build/bin/wxmini-kit" "$install_root/usr/bin/wxmini-kit"
install -D -m 0644 "$root_dir/build/linux/wxmini-kit.desktop" "$install_root/usr/share/applications/wxmini-kit.desktop"
install -D -m 0644 "$root_dir/build/appicon.png" "$install_root/usr/share/icons/hicolor/512x512/apps/wxmini-kit.png"

mkdir -p "$install_root/DEBIAN"
cat > "$install_root/DEBIAN/control" <<EOF
Package: wxmini-kit
Version: $deb_version
Section: utils
Priority: optional
Architecture: amd64
Maintainer: CCCCY-ci
Description: WeChat mini-program package parser and source recovery tool
Depends: libc6 (>= 2.27), libgtk-3-0, libwebkit2gtk-4.0-37
EOF
dpkg-deb --build --root-owner-group "$install_root" "$release_dir/wxmini-kit-linux-amd64.deb"

mkdir -p "$rpm_top"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
cp "$root_dir/build/bin/wxmini-kit" "$rpm_top/SOURCES/"
cp "$root_dir/build/linux/wxmini-kit.desktop" "$rpm_top/SOURCES/"
cp "$root_dir/build/appicon.png" "$rpm_top/SOURCES/wxmini-kit.png"
cat > "$rpm_top/SPECS/wxmini-kit.spec" <<EOF
Name: wxmini-kit
Version: $rpm_version
Release: $rpm_release
Summary: WeChat mini-program package parser and source recovery tool
License: See project source
BuildArch: x86_64
Requires: glibc >= 2.27

%description
wxmini-kit parses and unpacks WeChat mini-program packages and restores source files.

%install
install -D -m 0755 %{_sourcedir}/wxmini-kit %{buildroot}/usr/bin/wxmini-kit
install -D -m 0644 %{_sourcedir}/wxmini-kit.desktop %{buildroot}/usr/share/applications/wxmini-kit.desktop
install -D -m 0644 %{_sourcedir}/wxmini-kit.png %{buildroot}/usr/share/icons/hicolor/512x512/apps/wxmini-kit.png

%files
/usr/bin/wxmini-kit
/usr/share/applications/wxmini-kit.desktop
/usr/share/icons/hicolor/512x512/apps/wxmini-kit.png
EOF
rpmbuild --define "_topdir $rpm_top" -bb "$rpm_top/SPECS/wxmini-kit.spec"
rpm_file="$(find "$rpm_top/RPMS" -type f -name '*.rpm' -print -quit)"
if [[ -z "$rpm_file" ]]; then
  echo "rpmbuild did not create an RPM package" >&2
  exit 1
fi
cp "$rpm_file" "$release_dir/wxmini-kit-linux-x86_64.rpm"
