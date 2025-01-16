{
  stdenv,
  lib,
  fetchFromGitHub,
  wxGTK32,
  libusb1,
  xercesc,
  tcl,
  jdk ? null,
  javaSupport ? false,
}:

stdenv.mkDerivation {
  pname = "usbdm";
  version = "4.12.1.345";

  src = fetchFromGitHub {
    owner = "podonoghue";
    repo = "usbdm-eclipse-makefiles-build";
    rev = "0dee1dd3ac44c300e37630f6d3059e04283d1d5b";
    hash = "sha256-P3nHcmK+neocJXFUsxY/olAcrA4lzh8V4JtcU86J/OU=";
  };

  enableParallelBuilding = true;

  buildInputs = [
    wxGTK32
    libusb1
    xercesc
    tcl
  ] ++ lib.optional javaSupport jdk;

  hardeningDisable = [ "fortify" ];

  postPatch = ''
    patchShebangs .
    substituteInPlace Common.mk \
      --replace 'PKG_LIBDIR="/usr/lib/$(MULTIARCH)/''${PKG_NAME}"' 'PKG_LIBDIR="$out/lib"' \
      --replace \
        "JAVA_INC := -I/usr/lib/jvm/default-java/include -I/usr/lib/jvm/default-java/include/linux \$(jvm_includes)" \
        "${
          if javaSupport then
            "JAVA_INC := -I${jdk}/lib/openjdk/include -I${jdk}/lib/openjdk/include/linux \$(jvm_includes)"
          else
            ""
        }"
    substituteInPlace Library.mk \
      --replace 'USBDM_LIBDIR32="/usr/lib/i386-linux-gnu/usbdm"' "" \
      --replace 'USBDM_LIBDIR64="/usr/lib/x86_64-linux-gnu/usbdm"' \
        'USBDM_LIBDIR="$out/lib"' \
      --replace \
        "JAVA_INC := -I/usr/lib/jvm/default-java/include" \
        "${if javaSupport then "JAVA_INC := -I${jdk}/lib/openjdk/include" else ""}"
    for f in Makefile-x{32,64}.mk; do
        substituteInPlace "$f" \
            --replace "UsbdmJni_DLL" "${if javaSupport then "UsbdmJni_DLL" else ""}"
    done
    substituteInPlace Makefile-x64.mk \
        --replace "USBDM_API_Example" "" \
        --replace "USBDM_Programmer_API_Example" ""
    for f in PackageFiles/MiscellaneousLinux/*.desktop; do
      substituteInPlace "$f" \
          --replace "/usr/bin/" "$out/bin/"
    done
    for f in Shared/src/{PluginFactory,SingletonPluginFactory,Common}.h; do
        substituteInPlace "$f" \
            --replace '#define USBDM_INSTALL_DIRECTORY "/usr"' '#define USBDM_INSTALL_DIRECTORY "'$out'"'
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
