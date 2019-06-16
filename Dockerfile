################################################################################
####     Dockerfile for creation of a ROOT/Python analysis environment      ####   
####     See ./README.md for details                                        ####
################################################################################

FROM centos:7
USER root

## ROOT and Boost dependencies
RUN yum -y upgrade && yum -y install sudo wget make bzip2 git && \
    sudo yum install -y avahi-compat-libdns_sd-devel binutils \
    	cfitsio-devel fftw-devel graphviz-devel \
        ftgl-devel gcc gcc-c++ gcc-gfortran gsl-static libldap-dev \
	    libxml2-devel libXpm-devel libXft-devel libX11-devel libXext-devel \
	    mesa-libGL-devel mesa-libGLU-devel mysql-devel \
 	    openssl-devel pcre-devel python-devel

## Install CMake 3.12 (required to build ROOT 6)
RUN wget --quiet https://cmake.org/files/v3.12/cmake-3.12.0-rc3.tar.gz -O /tmp/cmake.tar.gz && \
	tar -zxf /tmp/cmake.tar.gz --directory=/tmp  && cd /tmp/cmake-3.12.0-rc3/ && \
	./bootstrap && \
	make -j 4  && sudo make install && \
	rm -r /tmp/cmake.tar.gz /tmp/cmake-3.12.0-rc3 

## Build Boost 1.70 (this version required by scdmsPyTools, not packaged in centos 7)
RUN wget --quiet https://dl.bintray.com/boostorg/release/1.70.0/source/boost_1_70_0.tar.gz -O ~/boost.tar.gz && \
	tar -zxf ~/boost.tar.gz --directory=$HOME && \
	cd ~/boost_1_70_0/ && \
	./bootstrap.sh && \
	./b2 install --prefix=/packages/boost1.70 -j 4

## Install Anaconda 3
RUN wget --quiet https://repo.anaconda.com/archive/Anaconda3-2019.03-Linux-x86_64.sh -O /packages/anaconda.sh && \
    /bin/bash /packages/anaconda.sh -b -p /packages/anaconda3 && \
    rm /packages/anaconda.sh

## Build ROOT 6.16
RUN . /packages/anaconda3/etc/profile.d/conda.sh && conda activate base && \
    wget --quiet https://root.cern.ch/download/root_v6.16.00.source.tar.gz -O ~/rootsource.tar.gz && \
    tar -zxf ~/rootsource.tar.gz --directory=$HOME && \
    mkdir -p $HOME/root-6.16.00/rootbuild && cd $HOME/root-6.16.00/rootbuild && \
	cmake -j 4 \
	-Dxml:BOOL=ON \
	-Dvdt:BOOL=OFF \
	-Dbuiltin_fftw3:BOOL=ON \
	-Dfitsio:BOOL=OFF \
	-Dfftw:BOOL=ON \
	-Dxrootd:BOOL=OFF \
	-DCMAKE_INSTALL_PREFIX:PATH=/packages/root6.16 \
	-Dpython3=ON \
	-Dpython=ON \
	-DPYTHON_EXECUTABLE:PATH=/packages/anaconda3/bin/python \
	..  
RUN . /packages/anaconda3/etc/profile.d/conda.sh && conda activate base && \
    source $HOME/root-6.16.00/rootbuild/bin/thisroot.sh && \
	cd $HOME/root-6.16.00/rootbuild && \
	cmake --build . --target install -- -j4 && \
	rm -r ~/rootsource.tar.gz ~/root-6.16.00

## Create softlink for boost shared objects (for compatibility) 
RUN ln -s /packages/boost1.70/lib/libboost_numpy36.so /packages/boost1.70/lib/libboost_numpy.so && \
	ln -s /packages/boost1.70/lib/libboost_python36.so /packages/boost1.70/lib/libboost_python.so

### Extra packages ###

## Install additional system packages
RUN sudo yum install -y \
	centos-release-scl patch net-tools binutils \
	gcc libcurl-devel libX11-devel shadow-utils \
	blas-devel libarchive-devel fuse-sshfs jq graphviz dvipng \
	libXext-devel bazel http-parser nodejs perl-Digest-MD5 perl-ExtUtils-MakeMaker gettext \
	# LaTeX tools
	pandoc texlive texlive-collection-xetex texlive-ec texlive-upquote texlive-adjustbox \ 
	# Data formats
	hdf5-devel \ 
	# Compression tools
	bzip2 unzip lrzip zip zlib-devel \ 
	# Terminal utilities
	fish tree ack screen tmux vim-enhanced neovim nano pico emacs emacs-nox \  
	&& sudo yum clean all

RUN . /packages/anaconda3/etc/profile.d/conda.sh &&  conda activate base && \
	. /packages/root6.16/bin/thisroot.sh && \
       conda install jupyter jupyterlab metakernel \
                h5py iminuit tensorflow pydot keras \
                dask[complete] \
                xlrd xlwt openpyxl && \
        pip install --upgrade pip setuptools && \
        pip --no-cache-dir install memory-profiler tables \
                zmq root_pandas awkward awkward-numba uproot root_numpy

COPY analysis-tools /packages/analysis-tools

## Configure user and entrypoint

RUN groupadd --gid 101 sudo
RUN useradd -ms /bin/bash -g root -G sudo -u 1000 jotunn
RUN echo ". /packages/anaconda3/etc/profile.d/conda.sh && conda activate base" >> /home/jotunn/.bashrc
#ENTRYPOINT ["/bin/bash"]
USER jotunn
WORKDIR /home/jotunn
