# Hydrogel-Automata-Directed-By-DNA-Codes

## File Description
* The `.np` nupack file for activator sequence design could be found in `Sequence-Design`
* The imaging software for controlling the pi-imager could be found in `Imaging-Software`
* The CNN model for output scoring could be found in `Model-Training`
* The numeric simulation for simulating the outputs of gel automata could be found in `Gel-Automata-Sim`
* The genetic algorithm for optimizing gel automata designs could be found in `Genetic-Algorithm`

## Project Description

### Gel-Automata-Sim
#### Summary:

Using data from the swelling characterization of bilayer DNA-co-polymerized hydrogel, we developed numeric simulation that accurately predicts the geometric outputs of the strip automata. 

We characterized the radius of curvature of bilayer gels upon different actuation combination along with the change in contour length. The values are stored in callable RoC tables and contour length tables that are used to retrieve values during geometric output simulation. 

We assumed the stack of bilayer gels do not interfere with each other upon actuation given the orthogonal operating actuators and also ignoring the minimal shear stress during swelling. 

We start with taking a 1d array `segment_lengths` and a 2d array `identities` as inputs, and generate an strip automata object. The `segment_lengths` array encodes the information of the **length** in each segment. The `identities` encodes the information of the **actuator pattern** in each segment. We then simulate the 16 possible states given our 4 switchable actuator system ($2^{4}=16$), thus every automata object contains 16 output images in the end. Upon simulation, we first retrieve the values for radius of curvature and delta contour length with the callable RoC tables and contour length tables, and obtain a 1d array `rocs` for the radius of curvature of each segments and a 1d array `ctls` for the delta contour length of each segments. We next use these values and integrate over the length and angle to derive the final shape. Starting at (x, y) = (0, 0) and $\theta = 0$, we use `delta = 20um` as a mesh size and an iterator object to generate the next (x, y) point. Points are generated with the following rules:

$\Delta \theta = \frac{delta}{radius-of-curvature}$

$\theta = \theta + \Delta \theta$

$\Delta x = delta \cdot sin(\theta)$

$\Delta y = delta \cdot cos(\theta)$

$x = \theta + \Delta x$

$y = \theta + \Delta y$

The iterator generates new point until reaching segment length limit $(segment\_length \cdot (1 + \Delta contour\_length))$ and goes on generating new points for next segments until all segments are generated. We next compile a 28 x 28 pixel images using the shape of the x, y points and apply Gaussian filters to the final generated images representing the actuator geometric outputs, so the images emulate the shape of MNIST digits prior to training and classification.  



