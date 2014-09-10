require "pty"
require "expect"

class Ncl < PACKMAN::Package
  url 'https://www.earthsystemgrid.org/download/fileDownload.htm?logicalFileId=474bb254-ba75-11e3-b322-00c0f03d5b7c'
  sha1 '9f7be65e0406a410b27d338309315deac2e64b6c'
  filename 'ncl_ncarg-6.2.0.tar.gz'
  version '6.2.0'

  depends_on 'freetype'
  depends_on 'cairo'
  depends_on 'jpeg'
  depends_on 'hdf4'
  depends_on 'netcdf_c'
  depends_on 'netcdf_fortran'
  depends_on 'hdf_eos2'
  depends_on 'hdf_eos5'
  depends_on 'grib2_c'
  depends_on 'gdal'
  depends_on 'proj'
  depends_on 'triangle'
  depends_on 'udunits'
  depends_on 'vis5dx'

  def install
    PACKMAN::RunManager.append_env "NCARG=#{PACKMAN::Package.prefix(self)}"
    # Copy Triangle codes into necessary place.
    PACKMAN.mkdir 'triangle'
    PACKMAN.cd 'triangle'
    PACKMAN.decompress "#{PACKMAN::ConfigManager.package_root}/triangle.zip"
    PACKMAN.cp 'triangle.h', '../ni/src/lib/hlu'
    PACKMAN.cp 'triangle.c', '../ni/src/lib/hlu'
    PACKMAN.cd_back
    # Check if system is supported by NCL.
    PACKMAN.cd 'config'
    PACKMAN.run 'make -f Makefile.ini'
    res ='./ymake -config `pwd`'
    if res == 'ymake: system unknown'
      PACKMAN.report_error "Current system is not supported by NCL!"
    end
    PACKMAN.cd_back
    # Configure NCL.
    # COMPLAIN: NCL should use more canonical method (e.g. Autoconf or CMake) to
    #           do configuration work!
    PTY.spawn('./Configure -v') do |reader, writer, pid|
      reader.expect(/Enter Return to continue, or q\(quit\) > /)
      writer.print("\n")
      reader.expect(/Enter Return to continue, or q\(quit\) > /)
      writer.print("\n")
      # Build NCL?
      reader.expect(/Enter Return \(default\), y\(yes\), n\(no\), or q\(quit\) > /)
      writer.print("y\n")
      # Parent installation directory?
      reader.expect(/Enter Return \(default\), new directory, or q\(quit\) >/)
      writer.print("#{PACKMAN::Package.prefix(self)}\n")
      # System temp space directory?
      reader.expect(/Enter Return \(default\), new directory, or q\(quit\) >/)
      writer.print("#{PACKMAN::Package.prefix(self)}/tmp\n")
      # Build NetCDF4 feature support (optional)?
      reader.expect(/Enter Return \(default\), y\(yes\), n\(no\), or q\(quit\) > /)
      writer.print("y\n")
      # Build HDF4 support (optional) into NCL?
      reader.expect(/Enter Return \(default\), y\(yes\), n\(no\), or q\(quit\) > /)
      writer.print("y\n")
      # Also build HDF4 support (optional) into raster library?
      reader.expect(/Enter Return \(default\), y\(yes\), n\(no\), or q\(quit\) > /)
      writer.print("y\n")
      # Did you build HDF4 with szip support?
      reader.expect(/Enter Return \(default\), y\(yes\), n\(no\), or q\(quit\) > /)
      writer.print("y\n")
      # Build Triangle support (optional) into NCL?
      reader.expect(/Enter Return \(default\), y\(yes\), n\(no\), or q\(quit\) > /)
      writer.print("y\n")
      # If you are using NetCDF V4.x, did you enable NetCDF-4 support?
      reader.expect(/Enter Return \(default\), y\(yes\), n\(no\), or q\(quit\) > /)
      writer.print("y\n")
      # Did you build NetCDF with OPeNDAP support (y)?
      reader.expect(/Enter Return \(default\), y\(yes\), n\(no\), or q\(quit\) > /)
      writer.print("y\n")
      # Build GDAL support (optional) into NCL?
      reader.expect(/Enter Return \(default\), y\(yes\), n\(no\), or q\(quit\) > /)
      writer.print("y\n")
      # Build Udunits-2 support (optional) into NCL?
      reader.expect(/Enter Return \(default\), y\(yes\), n\(no\), or q\(quit\) > /)
      writer.print("y\n")
      # Build Vis5d+ support (optional) into NCL?
      reader.expect(/Enter Return \(default\), y\(yes\), n\(no\), or q\(quit\) > /)
      writer.print("y\n")
      # Build HDF-EOS2 support (optional) into NCL?
      reader.expect(/Enter Return \(default\), y\(yes\), n\(no\), or q\(quit\) > /)
      writer.print("y\n")
      # Build HDF5 support (optional) into NCL?
      reader.expect(/Enter Return \(default\), y\(yes\), n\(no\), or q\(quit\) > /)
      writer.print("y\n")
      # Build HDF-EOS5 support (optional) into NCL?
      reader.expect(/Enter Return \(default\), y\(yes\), n\(no\), or q\(quit\) > /)
      writer.print("y\n")
      # Build GRIB2 support (optional) into NCL?
      reader.expect(/Enter Return \(default\), y\(yes\), n\(no\), or q\(quit\) > /)
      writer.print("y\n")
      # Enter local library search path(s).
      reader.expect(/Enter Return \(default\), new directories, or q\(quit\) > /)
      if PACKMAN::OS.distro == :Mac_OS_X
        writer.print "/usr/X11R6/lib "
      end
      [ Freetype, Cairo, Jpeg, Hdf4, Hdf5, Netcdf_c, Netcdf_fortran,
        Hdf_eos2, Hdf_eos5, Grib2_c, Gdal, Proj, Udunits, Vis5dx ].each do |lib|
        if not Dir.exist? "#{PACKMAN::Package.prefix(lib)}/lib"
          p "check #{lib} no lib"
        end
        writer.print "#{PACKMAN::Package.prefix(lib)}/lib "
      end
      writer.print "\n"
      # Enter local include search path(s).
      reader.expect(/Enter Return \(default\), new directories, or q\(quit\) > /)
      if PACKMAN::OS.distro == :Mac_OS_X
        writer.print "/usr/X11R6/include "
      end
      [ Freetype, Cairo, Jpeg, Hdf4, Hdf5, Netcdf_c, Netcdf_fortran, Hdf_eos5,
        Grib2_c, Gdal, Proj, Udunits, Vis5dx ].each do |lib|
        if not Dir.exist? "#{PACKMAN::Package.prefix(lib)}/include"
          p "check #{lib} no include"
        end
        writer.print "#{PACKMAN::Package.prefix(lib)}/include "
      end
      writer.print "#{PACKMAN::Package.prefix(Gcc)}/include "
      writer.print "\n"
      # Go back and make more changes or review?
      reader.expect(/Enter Return\(default\), y\(yes\), n\(no\), or q\(quit\) > /)
      writer.print "n\n"
      # Save current configuration?
      reader.expect(/Enter Return\(default\), y\(yes\), or q\(quit\) > /)
      writer.print "y\n"
      reader.expect(/make Everything/)
    end
    # Make NCL.
    PACKMAN.run 'make Everything'
    # Make sure command 'ncl' is built.
    # PACKMAN.run "ls #{PACKMAN::Package.prefix(self)}/bin/ncl"
    PACKMAN::RunManager.clean_env
  end
end