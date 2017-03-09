pkg_name=k8s-sup-bootstrap
pkg_origin=moretea
pkg_version=0.1.0
pkg_source="nope.gif"
pkg_maintainer="The Habitat Maintainers <humans@habitat.sh>"
pkg_description="Habitat supervisor gossip bootstrap"
pkg_build_deps=(core/ruby)
pkg_expose=(9638)
pkg_deps=(core/ruby)

do_download() {
  return 0
}

do_verify() {
  return 0
}

do_unpack() {
  return 0
}

do_configure() {
  return 0
}

do_build() {
  return 0
}

do_install() {
  mkdir -p $pkg_prefix/bin
  cp -r $HAB_BUILD_CONTEXT/src/src/sup-bootstrap-init.rb $pkg_prefix/bin/sup-bootstrap-init
  fix_interpreter $pkg_prefix/bin/sup-bootstrap-init core/ruby
}
