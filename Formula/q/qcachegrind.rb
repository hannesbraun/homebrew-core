class Qcachegrind < Formula
  desc "Visualize data generated by Cachegrind and Calltree"
  homepage "https://apps.kde.org/kcachegrind/"
  url "https://download.kde.org/stable/release-service/24.12.1/src/kcachegrind-24.12.1.tar.xz"
  sha256 "d38a1056daab0523955834648c9ce7e2e04536bad67f4f7b275834eaef336272"
  license "GPL-2.0-or-later"
  head "https://invent.kde.org/sdk/kcachegrind.git", branch: "master"

  # We don't match versions like 19.07.80 or 19.07.90 where the patch number
  # is 80+ (beta) or 90+ (RC), as these aren't stable releases.
  livecheck do
    url "https://download.kde.org/stable/release-service/"
    regex(%r{href=.*?v?(\d+\.\d+\.(?:(?![89]\d)\d+)(?:\.\d+)*)/?["' >]}i)
  end

  bottle do
    sha256 cellar: :any,                 arm64_sonoma:  "da15a7b9214a8f94ae7dee059f8bb46a0fa895de88d9323e72a0f3cd7da31c1a"
    sha256 cellar: :any,                 arm64_ventura: "a1222ebc8c62bc18d99f26d07a4e5738295e98dfd370a10ea732538e28cd0bb5"
    sha256 cellar: :any,                 sonoma:        "ead49aa294b6516f3016ca89f323e0743045a9d8ca24e545c154f710458cac8f"
    sha256 cellar: :any,                 ventura:       "16ea2f0cfc5828cd4484775a734928bcdbff9e987e0ba43c9d1f711c5de45c9a"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "0b13935365ebf0c286219cab62f21f3873afad575f5aa859a4b992bb16b8ef7a"
  end

  depends_on "graphviz"
  depends_on "qt"

  def install
    args = %w[-config release]
    if OS.mac?
      spec = (ENV.compiler == :clang) ? "macx-clang" : "macx-g++"
      args += %W[-spec #{spec}]
    end

    qt = Formula["qt"]
    system qt.opt_bin/"qmake", *args
    system "make"

    if OS.mac?
      prefix.install "qcachegrind/qcachegrind.app"
      bin.install_symlink prefix/"qcachegrind.app/Contents/MacOS/qcachegrind"
    else
      bin.install "qcachegrind/qcachegrind"
    end
  end
end
