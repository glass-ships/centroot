# CentROOT

A pre-built CentOS / Cern ROOT / Anconda 3 environment for scientific analysis. 

This image can be used as a base environment into which you can install analysis packages that depend on ROOT. 

You can also build in an installation of JupyterLab and set it up to run through your local host. 
(This is black magic to me though, I recommend looking into [this repository](https://github.com/slaclab/slac-jupyterhub) as an example)

# Usage

The image is built and pushed to Docker Hub regularly. I avoid using the `latest` tag on principle, so you'll need to specify the image version,  
`glasslabs/centroot:X.Y` where X.Y is the version number. 

You can use the image itself as is:  
`$ docker run -v $HOME/.ssh:"/home/loki/.ssh" -p 8091:8091 -it glasslabs/centroot:X.Y`

Or you can use it as a base image for your own Docker image:
```
FROM glasslabs/centroot:X.Y

# The rest of your Dockerfile
```

# Contribution 

If you'd like to make contributions to or have suggested changes for this image, clone the repository and create a new branch, then create a merge request.
