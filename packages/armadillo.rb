class Armadillo < PACKMAN::Package
  url 'http://sourceforge.net/projects/arma/files/armadillo-5.000.0.tar.gz'
  sha1 '86e4adfc8fdc32f55ccf1b97aa5ed76a2f332fb5'
  version '5.000.0'

  option 'use_mkl' => false

  depends_on 'cmake'
  if PACKMAN.linux? and not use_mkl?
    depends_on 'lapack'
    depends_on 'openblas'
  end
  depends_on 'arpack'
  depends_on 'hdf5'
  depends_on 'superlu'

  def install
    # The CMake find modules provided by Armadillo is so weak that
    # they can not find the dependent libraries just installed.
    if PACKMAN.linux? and not use_mkl?
      PACKMAN.replace 'cmake_aux/Modules/ARMA_FindLAPACK.cmake',
        /^  PATHS / => "  PATHS #{Lapack.lib} "
      PACKMAN.replace 'cmake_aux/Modules/ARMA_FindOpenBLAS.cmake',
        /^  PATHS / => "  PATHS #{Openblas.lib} "
    end
    PACKMAN.replace 'cmake_aux/Modules/ARMA_FindARPACK.cmake',
      /^  PATHS / => "  PATHS #{Arpack.lib} "
    PACKMAN.replace 'cmake_aux/Modules/ARMA_FindSuperLU.cmake', {
      'SET(SuperLU_FOUND NO)' =>
        "SET (SuperLU_INCLUDE_DIR #{Superlu.include}/superlu)\n"+
        "SET (SuperLU_LIBRARY #{Superlu.lib}/libsuperlu.a)"
    }
    # In some cases, the MKL does not work as expected.
    if not use_mkl?
      PACKMAN.replace 'CMakeLists.txt', /(include\(ARMA_FindMKL\))/ => '#\1'
    end
    args = %W[
      -DCMAKE_INSTALL_PREFIX=#{prefix}
      -DCMAKE_BUILD_TYPE="Release"
    ]
    PACKMAN.run 'cmake', *args
    PACKMAN.run 'make'
    PACKMAN.run 'make install'
  end
end
