################################################################################
####     Dockerfile for creation of a ROOT/Python analysis environment      ####   
####     See ./README.md for details                                        ####
################################################################################

FROM centos:7
USER root

## Environment variables for installation
ENV CMAKEVER=3.15.2
ENV BOOSTVER=1.71.0
ENV BOOST_PATH=/opt/boost1.71
ENV ROOTVER=6.18.04
ENV ROOTSYS=/opt/root6.18

## Install system level packages
RUN yum -y upgrade && yum install -y \ 
        sudo wget make git which centos-release-scl patch net-tools binutils \
        gcc gcc-c++ g++  libcurl-devel libX11-devel \
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
        && yum clean all

## Anaconda 3
RUN wget --quiet https://repo.anaconda.com/archive/Anaconda3-2019.07-Linux-x86_64.sh -O /opt/anaconda.sh && \
    bash /opt/anaconda.sh -b -p /opt/anaconda3 && \
    rm /opt/anaconda.sh
RUN ln -s /opt/anaconda3/include/python3.7m /opt/anaconda3/include/python3.7

## Boost libraries
RUN . /opt/anaconda3/etc/profile.d/conda.sh && conda activate base && \
wget --quiet https://dl.bintray.com/boostorg/release/$BOOSTVER/source/boost_$(echo $BOOSTVER|tr . _).tar.gz -O /tmp/boost.tar.gz && \
        tar -zxf /tmp/boost.tar.gz --directory=/tmp && \
        cd /tmp/boost_$(echo $BOOSTVER|tr . _)/ && \
        ./bootstrap.sh && \
        ./b2 install --prefix=$BOOST_PATH -j 4 && \
        rm -r /tmp/boost*

# Create softlink for boost shared objects (for compatibility)
RUN ln -s $BOOST_PATH/lib/libboost_numpy37.so $BOOST_PATH/lib/libboost_numpy.so && \
        ln -s $BOOST_PATH/lib/libboost_python37.so $BOOST_PATH/lib/libboost_python.so

## Cern ROOT 
# ROOT Dependencies 
RUN yum install -y gcc-gfortran openssl-devel pcre-devel \
	mesa-libGL-devel mesa-libGLU-devel glew-devel ftgl-devel mysql-devel \
	fftw-devel cfitsio-devel graphviz-devel gsl-static\
	avahi-compat-libdns_sd-devel libldap-dev python-devel \
	libxml2-devel libXpm-devel libXft-devel 

# Install cmake v >=3.9 (required to build ROOT 6)
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
	-Dpython=ON \
	-DPYTHON_EXECUTABLE:PATH=/opt/anaconda3/bin/python \
	..  
RUN source /tmp/root-$ROOTVER/rootbuild/bin/thisroot.sh && \
	cd /tmp/root-$ROOTVER/rootbuild && \
	cmake --build . --target install -- -j4
RUN rm -r /tmp/rootsource.tar.gz /tmp/root-$ROOTVER

## Install some Anaconda packages
RUN . $ROOTSYS/bin/thisroot.sh && \
  . /opt/anaconda3/etc/profile.d/conda.sh && \
	conda activate base && \ 
	conda install jupyter jupyterlab metakernel \
	        h5py iminuit tensorflow pydot keras \
	        dask[complete] \
	        xlrd xlwt openpyxl && \
	#conda install -c conda-forge fish root && \
	pip install --upgrade pip setuptools && \
	pip --no-cache-dir install \
        memory-profiler papermill \
        tables zmq \
        root_pandas awkward awkward-numba uproot root_numpy

### Copy in custom code, repos, data, etc.
COPY repos/ /opt/
COPY scripts /opt/scripts
COPY data/pyCAP_reference_data data/pyTools_reference_data /data/

### Configure user, env, and entrypoint ###
RUN groupadd --gid 101 sudo
RUN useradd -ms /bin/bash -g root -G sudo,wheel -u 1000 loki && \
  echo 'loki:letmein' | chpasswd && \
  chown -R loki /home/loki && \ 
  chmod -R a+rw /opt
#  chown -R loki /opt 
RUN mkdir -p /data && chmod -R a+rw /data

RUN echo ". /opt/bash-env/main" >> /home/loki/.bashrc && \
  echo ". $ROOTSYS/bin/thisroot.sh" >> /home/loki/.bashrc && \
  echo ". /opt/anaconda3/etc/profile.d/conda.sh && conda activate base" >> /home/loki/.bashrc

USER loki
WORKDIR /home/loki
EXPOSE 8888
#ENTRYPOINT ["/bin/bash"]
