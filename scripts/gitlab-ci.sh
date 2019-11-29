#before script:
#- git clone https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.com/supercdms/ReferenceData/pyTools_reference_data.git 
#- mv pyTools_reference_data/* /data && rm -rf pyTools_reference_data

export BOOST_PATH=/opt/boost1.71
source /opt/root6.18/bin/thisroot.sh
source /opt/anaconda3/etc/profile.d/conda.sh && conda activate base

#stages:
#  - build
#  - test
  
cd /opt/Analysis/scdmsPyTools/scdmsPyTools/BatTools
make
cd ../..
python setup.py install

mkdir -p /tmp/papermill
papermill demo/IO/demoIO.ipynb /tmp/papermill/output.ipynb -p filepath /data/SLAC/R51/Raw/09190321_1522/09190321_1522_F0001.mid.gz
#papermill demo/DIDV/demoDIDV.ipynb /tmp/papermill/output.ipynb
#papermill demo/Noise/demoNoise.ipynb /tmp/papermill/output.ipynb
rm -rf /tmp/papermill
