class Dvisvgm < Formula
  desc "Fast DVI to SVG converter"
  homepage "https://dvisvgm.de"
  url "https://github.com/mgieseki/dvisvgm/releases/download/3.5/dvisvgm-3.5.tar.gz"
  sha256 "41ea2e10fe6bdc4ce7672519cfc2998e5c30c8b29fbcd8901915c7dac7fa494c"
  license "GPL-3.0-or-later"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build
  depends_on "freetype"
  depends_on "ghostscript"
  depends_on "texlive"
  depends_on "woff2"
  uses_from_macos "zlib"

  def install
    # Set environment variables to use LLVM clang
    llvm_bin = Formula["llvm"].opt_bin
    llvm_include = Formula["llvm"].opt_include
    llvm_lib = Formula["llvm"].opt_lib

    ENV["CC"] = "#{llvm_bin}/clang"
    ENV["CXX"] = "#{llvm_bin}/clang++"
    ENV["LDFLAGS"] = "-L#{llvm_lib} -L#{Formula["texlive"].opt_lib}"
    ENV["CPPFLAGS"] = "-I#{llvm_include} -I#{Formula["texlive"].opt_include}"
    ENV["CXXFLAGS"] = "-stdlib=libc++ -I#{llvm_include}/c++/v1"

    system "./configure", *std_configure_args, "--disable-silent-rules"
    # Optional: "--with-ttfautohint" if ttfautohint is a dependency
    system "make"
    system "make", "install"
    
    # Install test data files for use in tests
    pkgshare.install "tests/data"
  end

  test do
    # Set up TeX environment variables to point to the texlive installation
    texlive_prefix = Formula["texlive"].opt_prefix
    texlive_bin = Formula["texlive"].opt_bin
    
    ENV["TEXMFROOT"] = "#{texlive_prefix}/share/texmf-dist"
    ENV["TEXMFDIST"] = "#{texlive_prefix}/share/texmf-dist"
    ENV["TEXMFLOCAL"] = "#{texlive_prefix}/share/texmf-local"
    ENV["TEXMFVAR"] = testpath/"texmf-var"
    ENV["TEXMFCONFIG"] = testpath/"texmf-config"
    ENV["TEXMFCACHE"] = testpath/"texmf-cache"
    ENV["TEXMFHOME"] = testpath/"texmf-home"
    ENV["SELFAUTOPARENT"] = texlive_prefix.to_s
    ENV["SELFAUTODIR"] = texlive_bin.to_s
    ENV["SELFAUTOLOC"] = texlive_bin.to_s
    
    # Use the sample DVI file from the installed test data
    sample_dvi = pkgshare/"data/sample.dvi"
    cp sample_dvi, testpath/"sample.dvi"
    assert_path_exists testpath/"sample.dvi"
    
    # Test basic functionality of dvisvgm
    output = shell_output("#{bin}/dvisvgm --version")
    assert_match "dvisvgm", output
    
    # Convert DVI to SVG with minimal dependencies
    system bin/"dvisvgm", "--no-fonts", "--no-specials", "sample.dvi"
    assert_path_exists testpath/"sample.svg"
    
    # Verify SVG content
    svg_content = File.read(testpath/"sample.svg")
    assert_match /<svg/, svg_content
  end
end
