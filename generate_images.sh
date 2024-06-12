#Generate Dockerfile.

#!/bin/sh

 set -e

generate_docker() {
  yes | docker run -i --rm repronim/neurodocker:1.0.0 generate docker \
             --base-image ubuntu:20.04 \
             --pkg-manager apt \
	     --env DEBIAN_FRONTEND=noninteractive \
             --install git num-utils gcc g++ curl yarn build-essential nano git-annex npm \
             --run-bash "curl -sL https://deb.nodesource.com/setup_18.x | bash - && apt update && apt-get install -y nodejs"\
             --run-bash "npm install -g bids-validator@1.14.6" \
             --fsl version=6.0.7.4 method=binaries \
             --miniconda \
                version=latest \
                env_name='bidsonym' \
		env_exists=false \
		conda_install="python=3.11 numpy nipype nibabel pandas datalad deno" \
                pip_install='tensorflow scikit-image pydeface==2.0.2 nobrainer==1.2.1 quickshear==1.2.0 datalad-osf pybids==0.16.5' \
             --run-bash "git config --global user.email 'bidsonym@example.com' && git config --global user.name 'BIDSonym'" \
             --run-bash "mkdir -p /opt/nobrainer/models && cd /opt/nobrainer/models && source activate bidsonym && datalad clone https://github.com/neuronets/trained-models && cd trained-models && git-annex enableremote osf-storage && datalad get -s osf-storage neuronets/brainy/0.1.0/weights/brain-extraction-unet-128iso-model.h5" \
             --run-bash "mkdir /home/mri-deface-detector && cd /home/mri-deface-detector && npm install sharp --unsafe-perm && npm install -g mri-deface-detector --unsafe-perm && cd ~" \
             --run-bash "git clone https://github.com/miykael/gif_your_nifti && cd gif_your_nifti && source activate bidsonym && python setup.py install" \
             --copy . /home/bm \
             --run-bash "chmod a+x /home/bm/bidsonym/fs_data/mri_deface" \
             --run-bash "source activate bidsonym && cd /home/bm && pip install -e ." \
             --env IS_DOCKER=1 \
             --workdir '/tmp/' \
             --entrypoint "/neurodocker/startup.sh  bidsonym"
}

# generate files
generate_docker > Dockerfile

# check if images should be build locally or not
if [[ $1 == 'local' ]]; then
    echo "docker image will be build locally"
    # build image using the saved files
    docker build -t bidsonym:local .
else
  echo "Image(s) won't be build locally."
fi
