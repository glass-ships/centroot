################################################################################
####     Dockerfile for creation of a ROOT/Python analysis environment      ####   
####     See ./README.md for details                                        ####
################################################################################

FROM centos:7
USER root

COPY repos /opt

### Environment variables for installation
ENV CONDAVER=2020.11
ENV CONDADIR=/opt/anaconda3
ENV CMAKEVER=3.19.2
ENV BOOSTVER=1.75.0
ENV BOOST_PATH=/opt/boost1.75
ENV ROOTVER=6.22.06
ENV ROOTSYS=/opt/root6.22

### Install system packages
RUN yum -y upgrade && yum install -y \ 
        sudo wget which make git centos-release-scl libcurl-devel patch net-tools \
        blas-devel lapack-devel libarchive-devel fuse-sshfs jq dvipng \
        bazel http-parser nodejs perl-Digest-MD5 perl-ExtUtils-MakeMaker gettext \
        # LaTeX tools
        pandoc texlive texlive-collection-xetex texlive-ec texlive-upquote texlive-adjustbox \
        # Data formats
        hdf5-devel \
        # Compression tools
        bzip2 unzip lrzip zip zlib-devel \
        # Terminal utilities
        fish tree ack screen tmux vim-enhanced neovim nano pico emacs emacs-nox \
        # Cern ROOT dependencies
        binutils gcc gcc-c++ g++ \
        libcurl-devel libX11-devel libXpm-devel libXft-devel libXext-devel \
        # Cern ROOT optional dependencies
        gcc-gfortran openssl-devel pcre-devel \
        mesa-libGL-devel mesa-libGLU-devel glew-devel ftgl-devel mysql-devel \
        fftw-devel cfitsio-devel graphviz-devel \
        avahi-compat-libdns_sd-devel libldap-dev python-devel \
        libxml2-devel gsl-static \
        && yum clean all

### Install Anaconda 3
RUN wget --quiet https://repo.anaconda.com/archive/Anaconda3-$CONDAVER-Linux-x86_64.sh -O /opt/anaconda.sh && \
    bash /opt/anaconda.sh -b -p $CONDADIR && \
    rm /opt/anaconda.sh
RUN ln -s /opt/anaconda3/include/python3.7m /opt/anaconda3/include/python3.7

## Install Boost libraries
RUN . /opt/anaconda3/etc/profile.d/conda.sh && conda activate base && \
wget --quiet https://dl.bintray.com/boostorg/release/$BOOSTVER/source/boost_$(echo $BOOSTVER|tr . _).tar.gz -O /tmp/boost.tar.gz && \
        tar -zxf /tmp/boost.tar.gz --directory=/tmp && \
        cd /tmp/boost_$(echo $BOOSTVER|tr . _)/ && \
        ./bootstrap.sh && \
        ./b2 install --prefix=$BOOST_PATH -j 4 && \
        rm -r /tmp/boost*

# Softlink Boost shared objects (for compatibility)
RUN ln -s $BOOST_PATH/lib/libboost_numpy37.so $BOOST_PATH/lib/libboost_numpy.so && \
        ln -s $BOOST_PATH/lib/libboost_python37.so $BOOST_PATH/lib/libboost_python.so

# Install cmake ver >=3.9 (required to build ROOT 6)
RUN wget --quiet https://github.com/Kitware/CMake/releases/download/v$CMAKEVER/cmake-$CMAKEVER.tar.gz -O /tmp/cmake.tar.gz && \
	tar -zxf /tmp/cmake.tar.gz --directory=/tmp  && cd /tmp/cmake-$CMAKEVER/ && \
	./bootstrap && \
	make -j 4  && make install && \
	rm -r /tmp/cmake* 

# Build ROOT 
RUN wget --quiet https://root.cern.ch/download/root_v$ROOTVER.source.tar.gz -O /tmp/rootsource.tar.gz && \
	tar -zxf /tmp/rootsource.tar.gz --directory=/tmp
RUN mkdir -p /tmp/root-$ROOTVER/rootbuild && cd /tmp/root-$ROOTVER/rootbuild && \
	cmake -j 4 \
	-Dxml:BOOL=ON \
	-Dvdt:BOOL=OFF \
	-Dbuiltin_fftw3:BOOL=ON \
	-Dfitsio:BOOL=OFF \
	-Dfftw:BOOL=ON \
	-Dxrootd:BOOL=OFF \
	-DCMAKE_INSTALL_PREFIX:PATH=$ROOTSYS \
	-Dpython3=ON \
	-Dpyroot=ON \
	-DPYTHON_EXECUTABLE:PATH=/opt/anaconda3/bin/python \
	..  
RUN source /tmp/root-$ROOTVER/rootbuild/bin/thisroot.sh && \
	cd /tmp/root-$ROOTVER/rootbuild && \
	cmake --build . --target install -- -j4
RUN rm -r /tmp/rootsource.tar.gz /tmp/root-$ROOTVER

### Anaconda - Install extra packages
RUN . $ROOTSYS/bin/thisroot.sh && \
  . /opt/anaconda3/etc/profile.d/conda.sh && \
	conda activate base && \ 
	conda install jupyter jupyterlab metakernel \
	        h5py iminuit tensorflow pydot keras \
	        dask[complete] \
	        xlrd xlwt openpyxl && \
	pip install --upgrade pip setuptools && \
	pip --no-cache-dir install \
        memory-profiler papermill \
        tables zmq \
        root_pandas awkward awkward-numba uproot root_numpy

### Anaconda - Enable interactive matplotlib widget
RUN . $ROOTSYS/bin/thisroot.sh && \
  . /opt/anaconda3/etc/profile.d/conda.sh && \
  conda activate base && \
  conda install -c conda-forge nodejs ipympl && \
  conda update --all && \
  jupyter labextension install @jupyter-widgets/jupyterlab-manager && \
  jupyter lab build
  
### Configure user, env, and entrypoint ###
RUN groupadd --gid 101 sudo
RUN useradd -ms /bin/bash -g root -G sudo,wheel -u 1000 eris && \
  echo 'eris:letmein' | chpasswd && \
  chown -R eris /home/eris && \ 
  chmod -R a+rw /opt
RUN mkdir -p /data && chmod -R a+rw /data

RUN echo ". /opt/bash-env/main" >> /home/eris/.bashrc && \
  echo ". $ROOTSYS/bin/thisroot.sh" >> /home/eris/.bashrc && \
  echo "source /opt/anaconda3/etc/profile.d/conda.sh && conda activate base" >> /home/eris/.bashrc 

USER eris
WORKDIR /home/eris
EXPOSE 8888
ENTRYPOINT ["/bin/bash"]
