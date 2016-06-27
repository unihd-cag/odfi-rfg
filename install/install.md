---
layout: default
title: RFG install
---

# Install the RFG

## Install using the Binary 

Download the latest release from the [Releases page](https://github.com/unihd-cag/odfi-rfg/releases) 
and make it executable with:

    chmod +x RFG-vx.x.x
    
It is recommanded to put the executable to the search path for an easy to use in the command line.

One recommanded way to do this is to create a bin folder in your home directory and add it to the PATH variable.

1.To create the bin directory:

    mkdir ~/bin
    
2.Copy the executable to this folder.

3.To add the ~\bin directory to the search PATH modify your .bashrc and add:

    export PATH=$PATH:~/bin

## Install from Source

1. Clone the repository 

2. Move to the build folder in the repo and invoke the build script:

    sh build.sh
