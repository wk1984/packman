class Wrf_model < PACKMAN::Package
  url 'http://www2.mmm.ucar.edu/wrf/src/WRFV3.6.1.TAR.gz'
  sha1 '21b398124041b9e459061605317c4870711634a0'
  version '3.6.1'

  label 'install_with_source'

  belongs_to 'wrf'

  option 'build_type' => 'serial'
  option 'use_nest' => 0
  option 'run_case' => 'em_real'
  option 'with_chem' => false

  attach do
    url 'http://www2.mmm.ucar.edu/wrf/src/WRFV3-Chem-3.6.1.TAR.gz'
    sha1 '72b56c7e76e8251f9bbbd1d2b95b367ad7d4434b'
    version '3.6.1'
  end

  depends_on 'netcdf'
  depends_on 'libpng'
  depends_on 'jasper'
  depends_on 'zlib'

  def decompress_to target_dir
    PACKMAN.mkdir target_dir
    PACKMAN.work_in target_dir do
      PACKMAN.decompress "#{PACKMAN::ConfigManager.package_root}/#{filename}"
      PACKMAN.mv Dir.glob('./WRFV3/*'), '.'
      PACKMAN.rm './WRFV3'
      if with_chem?
        chem = attachments.first
        PACKMAN.decompress "#{PACKMAN::ConfigManager.package_root}/#{chem.filename}"
      end
    end
  end

  def install
    # Prefix WRF due to some bugs.
    if build_type == 'serial' or build_type == 'smpar'
      PACKMAN.replace 'share/mediation_feedback_domain.F', {
        /(USE module_dm), only: local_communicator/ => '\1'
      }
    end
    # Set compilation environment.
    PACKMAN.append_env "CURL_PATH='#{PACKMAN.prefix Curl}'"
    PACKMAN.append_env "ZLIB_PATH='#{PACKMAN.prefix Zlib}'"
    PACKMAN.append_env "HDF5_PATH='#{PACKMAN.prefix Hdf5}'"
    PACKMAN.append_env "NETCDF='#{PACKMAN.prefix Netcdf}'"
    includes = []
    libs = []
    includes << "#{PACKMAN.prefix Jasper}/include" # NOTE: There is no '-I' ahead!
    libs << "#{PACKMAN.prefix Jasper}/lib" # NOTE: There is no '-L' ahead!
    includes << "-I#{PACKMAN.prefix Zlib}/include"
    libs << "-L#{PACKMAN.prefix Zlib}/lib"
    if not PACKMAN::OS.mac_gang?
      includes << "-I#{PACKMAN.prefix Libpng}"
      libs << "-L#{PACKMAN.prefix Libpng}"
    end
    PACKMAN.append_env "JASPERINC='#{includes.join(' ')}'"
    PACKMAN.append_env "JASPERLIB='#{libs.join(' ')}'"
    # Check input parameters.
    if not ['serial', 'smpar', 'dmpar', 'dm+sm'].include? build_type
      PACKMAN::CLI.report_error "Invalid build type #{PACKMAN::CLI.red build_type}!"
    end
    if not [0, 1, 2, 3].include? use_nest
      PACKMAN::CLI.report_error "Invalid nest option #{PACKMAN::CLI.red use_nest}!"
    end
    if not ['em_b_wave', 'em_esmf_exp', 'em_fire', 'em_grav2d_x',
            'em_heldsuarez', 'em_hill2d_x', 'em_les', 'em_quarter_ss',
            'em_real', 'em_scm_xy', 'em_seabreeze2d_x', 'em_squall2d_x',
            'em_squall2d_y', 'em_tropical_cyclone', 'exp_real',
            'nmm_real', 'nmm_tropical_cyclone'].include? run_case
      PACKMAN::CLI.report_error "Invalid run case #{PACKMAN::CLI.red run_case}!"
    end
    # Configure WRF model.
    print "#{PACKMAN::CLI.blue '==>'} "
    if PACKMAN::CommandLine.has_option? '-debug'
      print "#{PACKMAN::RunManager.default_command_prefix} ./configure\n"
    else
      print "./configure\n"
    end
    PTY.spawn("#{PACKMAN::RunManager.default_command_prefix} ./configure") do |reader, writer, pid|
      output = reader.expect(/Enter selection.*: /)
      writer.print("#{choose_platform output}\n")
      reader.expect(/Compile for nesting.*: /)
      writer.print("#{use_nest}\n")
      reader.expect(/\*/)
    end
    if not File.exist? 'configure.wrf'
      PACKMAN::CLI.report_error "#{PACKMAN::CLI.red 'configure.wrf'} is not generated!"
    end
    # Compile WRF model.
    PACKMAN.run './compile', run_case
    PACKMAN.clean_env
  end

  def choose_platform output
    c_vendor = PACKMAN.compiler_vendor 'c'
    fortran_vendor = PACKMAN.compiler_vendor 'fortran'
    build_type_ = build_type == 'dm+sm' ? 'dm\+sm' : build_type
    if c_vendor == 'gnu' and fortran_vendor == 'gnu'
      # gcc_version = PACKMAN::CompilerManager.compiler_group('gnu').version
      # if gcc_version <= '4.4.7'
      #   PACKMAN::CLI.report_error "GCC version (#{gcc_version}) is too low to build WRF!"
      # end
      output.each do |line|
        tmp = line.match(/(\d+)\.\s+.*gfortran compiler with gcc\s+\(#{build_type_}\)/)
        return tmp[1] if tmp
      end
    elsif c_vendor == 'intel' and fortran_vendor == 'intel'
      output.each do |line|
        tmp = line.match(/(\d+)\.\s+.*ifort compiler with icc\s+\(#{build_type_}\)/)
        return tmp[1] if tmp
      end
    else
      PACKMAN::CLI.report_error 'Unsupported compiler set!'
    end
  end
end