{
  stdenv,
  lib,
  fetchFromGitHub,
  wxGTK32,
  libusb,
  xercesc,
  tcl,
  jdk ? null,
  javaSupport ? false,
}:

stdenv.mkDerivation {
  pname = "usbdm";
  version = "4.12.1.330";

  src = fetchFromGitHub {
    owner = "podonoghue";
    repo = "usbdm-eclipse-makefiles-build";
    rev = "1e4e79133ca8e28e8355b43d0cafd83dbf723609";
    sha256 = "sha256-U17Fj7Vx8I7k0fHhcUlJWM+J5F6hj31w69HqNPm3r2E=";
  };

  enableParallelBuilding = true;

  buildInputs = [
    wxGTK32
    libusb
    xercesc
    tcl
  ] ++ lib.optional javaSupport jdk;

  hardeningDisable = [ "fortify" ];

  postPatch = ''
    patchShebangs .
    substituteInPlace Common.mk \
        --replace-fail "PKG_LIBDIR="/usr/lib/${PKG_NAME}"" "PKG_LIBDIR="$out/lib""
        --replace-fail \
          "JAVA_INC := -I/usr/lib/jvm/default-java/include -I/usr/lib/jvm/default-java/include/linux $(jvm_includes)"
          ${
            if javaSupport then
              "JAVA_INC := -I${jdk}/lib/openjdk/include -I${jdk}/lib/openjdk/include/linux $(jvm_includes)"
            else
              ""
          }
    substituteInPlace Library.mk \
      --replace-fail "USBDM_LIBDIR32="/usr/lib/i386-linux-gnu/usbdm"" ""
      --replace-fail "USBDM_LIBDIR64="/usr/lib/x86_64-linux-gnu/usbdm"" \
        "USBDM_LIBDIR="$out/lib""
      --replace-fail "JAVA_INC := -I/usr/lib/jvm/default-java/include" \
        ${if javaSupport then "JAVA_INC := -I${jdk}/lib/openjdk/include" else ""}
    for f in Makefile-x{32,64}.mk; do
        substituteInPlace "$f" \
            --replace-fail "UsbdmJni_DLL" "${if javaSupport then "UsbdmJni_DLL" else ""}"
    done
    substituteInPlace Makefile-x64.mk \
        --replace-fail "USBDM_API_Example" "" \
        --replace-fail "USBDM_Programmer_API_Example" ""
    for f in PackageFiles/MiscellaneousLinux/*.desktop; do
      substituteInPlace "$f" \
          --replace-fail "/usr/bin/" "$out/bin/"
    done
    for f in Shared/src/{PluginFactory,SingletonPluginFactory,Common}.h; do
        substituteInPlace "$f" \
            --replace-fail '#define USBDM_INSTALL_DIRECTORY "/usr"' '#define USBDM_INSTALL_DIRECTORY "'$out'"'
    done
  '';

  buildPhase = ''
    ./MakeAll
  '';

  installPhase = ''
    mkdir -p $out/{share/{applications,pixmaps,doc/usbdm,usbdm,man/man1},etc/udev/rules.d}
    cp PackageFiles/MiscellaneousLinux/Hardware-Chip.png $out/share/pixmaps
    cp PackageFiles/MiscellaneousLinux/*.desktop $out/share/applications
    cp PackageFiles/MiscellaneousLinux/usbdm.rules $out/etc/udev/rules.d/46-usbdm.rules
    cp PackageFiles/MiscellaneousLinux/{changelog.Debian.gz,copyright} $out/share/doc/usbdm
    cp PackageFiles/Miscellaneous/{nano.specs,*.xlkr,error.wav} $out/share/usbdm
    cp PackageFiles/MiscellaneousLinux/{TryProgrammer,usbdm.rules} $out/share/usbdm
    cp PackageFiles/Scripts/*.tcl $out/share/usbdm
    cp -r PackageFiles/{WizardPatches,DeviceData,Stationery,Examples,FlashImages,LaunchConfig} $out/share/usbdm
    cp -r PackageFiles/lib $out/lib
    cp -r PackageFiles/bin $out/bin
    rm -f $out/bin/{CopyFlash,*TestImage,*Example,Test*}
    for f in Documentation/ManPages/*; do
      cp $f $f.1
      gzip --best -f $f.1
      mv $f.1.gz $out/share/man/man1
    done
  '';

  meta = {
    description = "USBDM drivers";
    homepage = "https://sourceforge.net/projects/usbdm";
    license = lib.licenses.gpl2Only;
  };
}
