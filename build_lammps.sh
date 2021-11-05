#!/bin/bash

# Version of LAMMPS to build.
LMP_VERSION=29Sep2021
# Architecture to build - must match a Makefile
#ARCH=mpi
ARCH=volta
# LAMMPS packages to install
LMP_PACKAGES="CLASS2 OPT KSPACE SHOCK QEQ PHONON REAXFF RIGID MOLECULE"

# Try to download LAMMPS zip file if it does not already exist.
# If this fails, you may need to update the link or download manually.
LMP_ZIP=stable_${LMP_VERSION}.zip
if [ ! -f $LMP_ZIP ]; then
  wget https://github.com/lammps/lammps/archive/refs/tags/${LMP_ZIP}
fi

if [ "$ARCH" == "volta" ]; then
  LMP_PACKAGES+=" KOKKOS"
fi
SRC_DIR=$PWD

LMP_YES=""
for p in ${LMP_PACKAGES}; do
  LMP_YES="$LMP_YES yes-$p"
done

echo "#!/bin/bash
#SBATCH -N 1
#SBATCH -n 48
#SBATCH -t 5
#SBATCH -p htc
##SBATCH -q wildfire

mkdir -p /tmp/lammps-temp && cd /tmp/lammps-temp
unzip ${SRC_DIR}/${LMP_ZIP} "lammps-stable_${LMP_VERSION}/src*"
unzip ${SRC_DIR}/${LMP_ZIP} "lammps-stable_${LMP_VERSION}/lib*"

cd lammps-stable_${LMP_VERSION}/src
cp ${SRC_DIR}/lmp-makefiles/* MAKE/MINE/

make ${LMP_YES}

module load openmpi/3.1.6-gnu-9.2.0
module load cuda/11.2.0

time make ${ARCH}_${LMP_VERSION} -j

cp lmp_${ARCH}_${LMP_VERSION} ${SRC_DIR}
cd ${SRC_DIR}
rm -r /tmp/lammps-temp
" | sbatch
