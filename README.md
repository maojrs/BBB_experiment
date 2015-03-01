## A Computational Experiment for Blood-Brain Barrier Disruption 

This is the code to supplement the paper: "Computational and in vitro studies of blast-induced blood-brain barrier disruption". It is a 3D computational version of a blood-brain-barrier disruption experiment. It employs 2D axisymmetric Euler equations coupled with a Tammann equation of state. It includes implementations of new algorithms for the Lagrangian/Eulerian coupling of the air/water interfaces.

The code is designed to work with the Clawpack 5 software. For more information visit [the Clawpack webpage](http://www.clawpack.org/ ). The Clawpack software is open source, and the code is openly available at [Clawpack on GitHub](https://github.com/clawpack/clawpack). Some of the main algorithms used in this project can be found in the book [Finite Volume Methods for Hyperbolic Problems](http://depts.washington.edu/clawpack/book.html).

### Software dependencies
**All the required software is open source.**
* gfortran 4.8.1 
* python 2.7.5
* clawpack 5.2.2 : [Clawpack](http://www.clawpack.org/ )
* git: to clone this repository

--Clawpack 5.0 or higher is required, other versions of gfortran and python might work as well.

**Operating system.**
* Linux
* Mac OS X

### How to run this code?
**Install Clawpack 5.2.2:**
  * Go to: http://www.clawpack.org/installing.html#installation-instructions
  * Follow the download and installation intructions on the section: Install all Clawpack packages and Set environment variables.
  * Test your installation running an example for Classic Clawpack on the section: Testing your installation.
  * If your installation works, you already have python and gfortran installed.

**Clone this repository to your local machine**

    git clone https://github.com/maojrs/BBB_experiment.git

**Run the code**
Go to the folder code_no_hydrophone or code_hydrophone and run

    make .plots

The code will produce two new folders: _output and _plots. The first one contains all the output files, while the latter one contains the plots and interactive visualization apps. It will also produced 4 new gauge files saved in _code_(what_you_chose)/_gauges.

### Folder organization
* **_gauges:** contains the four output gauges of both codes (no_hydrophone and hydrophone) as well as the plotting routine used to produce the figure in the paper. The output figures are also in this folder.

* **_code_hydrophone:** contains the code to run the simulation with an hydrophone. The internal folders: _gauges, _initfiles and _plots_hydrophone, contain the output gauge data for this case, the initial condition data for the incoming shock wave and the plots produced included in the paper.

* **_code_no_hydrophone:**  contains the code to run the simulation without an hydrophone. The internal folders: _gauges, _initfiles and _plots_original, contain the output gauge data for this case, the initial condition data for the incoming shock wave and the plots produced included in the paper.

* **invitro_data:** contains some of the experimental data, along a report on the experimental statistical analysis using SPSS software package. 

### Changing the output
Although changing the output might require getting more involved with the code, there are some simple tweaks that will allow the user to see different output. The main code files to edit are setrun.py and setplot.py

**setrun.py**
* Change domain boundaries:


    clawdata.lower[0] = -0.03                 # xlower
    clawdata.upper[0] = 0.03                  # xupper
    clawdata.lower[1] = 0.000000e+00          # ylower
    clawdata.upper[1] = 0.020000e+00          # yupper

* Change grid size (from 600x60 to new values):


    clawdata.num_cells[0] = 600
    clawdata.num_cells[1] = 60

* Change output times:


    clawdata.num_output_times = 500 # number of output frames
    clawdata.tfinal = 0.0002 # final time in seconds

**setplot.py**

* Change main properties of figure 7 (the one showing in the paper):


    plotfigure = plotdata.new_plotfigure(name='Contour & Slice', figno=7)
    plotaxes = plotfigure.new_plotaxes() # Set up for axes in this figure:
    plotaxes.xlimits = [-3,3] 
    plotaxes.ylimits = [-20,30]
    plotaxes.title = 'Pressure'    
    plotaxes.afteraxes = MirrorPressurecontour_N_Pressureslice    
    
* Change plotting output:


    plotdata.printfigs = True                # print figures
    plotdata.print_format = 'png'            # file format
    plotdata.print_framenos =  [75,150,158,174,212,336] #list of frames to print. Use 'all' to print all #
    plotdata.print_fignos = 'all'            # list of figures to print

