# Programming-gel-automata-shapes-using-DNA-instructions

## File Description
* The `.np` nupack file for activator sequence design could be found in `Sequence-Design`
* The imaging software for controlling the pi-imager could be found in `Imaging-Software`
* The CNN model for output scoring could be found in `Model-Training`
* The numeric simulation for simulating the outputs of gel automata could be found in `Gel-Automata-Sim`
* The genetic algorithm for optimizing gel automata designs could be found in `Genetic-Algorithm`

## Project Summary

### Gel-Automata-Sim
#### Summary:
Using data from the swelling characterization of bilayer DNA-co-polymerized hydrogel, we developed a numeric simulation that could accurately predict the geometric outputs of the strip automata. 

We characterized the radius of curvature of bilayer gels upon different actuation combination along with the change in contour length. The values were stored in callable `RoC` tables and `contour-length` tables that were used to retrieve values during geometric output simulation. 

We assumed the stack of bilayer gels do not interfere with each other upon actuation given limited interference between the operating actuators and also ignoring the minimal shear stress during swelling. 

We started with taking a 1d array `segment_lengths` and a 2d array `identities` as inputs, and generated an strip automata object. The `segment_lengths` array encoded the information of the **length** in each segment. The `identities` encoded the information of the **actuator pattern** in each segment. We then simulated the 16 possible states given our 4 switchable actuator system ($2^{4}=16$), thus every automata object contained 16 output images in the end. Upon simulation, we first retrievde the values for radius of curvature and delta contour length with the callable RoC tables and contour length tables, and obtained a 1d array `rocs` for the radius of curvature of each segments and a 1d array `ctls` for the delta contour length of each segments. We next used these values and integrated over the length and angle to derive the final shape. Starting at (x, y) = (0, 0) and $\theta = 0$, we used `delta = 20um` as a mesh size and an iterator object to generate the next (x, y) point. Points were generated with the following rules:

$\Delta \theta = \frac{delta}{radius-of-curvature}$

$\theta = \theta + \Delta \theta$

$\Delta x = delta \cdot sin(\theta)$

$\Delta y = delta \cdot cos(\theta)$

$x = \theta + \Delta x$

$y = \theta + \Delta y$

The iterator generated new point until reaching segment length limit $(segment\_length \cdot (1 + \Delta contour\_length))$ and went on generating new points for next segments until all segments were generated. We next compiled a 28 x 28 pixel images using the shape of the x, y points and applied Gaussian filters to the final generated images representing the actuator geometric outputs, so the images emulated the shape of MNIST digits prior to training and classification.  

### Genetic-Algorithm
#### Summary:
We developed a genetic algorithm to efficiently search through large parameter space for designing our digit automata. 

The algorithm started with an initial population of automata designs generated from a random seed. Each design within the population was then simulated to find all possible geometric outputs upon sixteen actuation combination and scored with a deep learning model. During the scoring process, to fully utilize each image, all images were rotated with twenty different degrees and the image with the highest score as a digit was selected to represent the final class and score of the image. We thus got a 2d array documenting what digits were formed and the score for each digits. 

We next developed a custom loss function to evaluate the performance of each design. We defined the loss function as such:

$Loss = 5000 * (NumberOfDigitsFormed) * \sum_{I = 0 ... 9}[1.001 - (ScoreForDigitI)]$

The loss function computed the **diversity** and the **similarity to real digits** for the digits formed. Designs that outputs images resembling a larger number of high-quality digits would be more likely to be preserved. During the selection stage, we eliminated 80% of the designs within the population, by selecting the designs that have the 20% lowest loss score. These designs were sent into a mutation function to repopulate a new generation.

For the mutation function, we used the **single-parent mutation method** where the genetic information of each descendant come from a single survived design from previous selection. During mutation, each design had a fifty percent chance to randomly update the strip segment lengths, preserving the actuator pattern information; each design also had a fifty percent chance of mutating the actuator pattern, where we randomly mutated half of the pattern. Each survivor design generated four descendants, so the population could return to its original size after every round of selection and mutation. 

Finally, the algorithm would iterate the cylce of population generation, selection and mutation until reaching generation limit and outputs the optimized designs.

For our even digit automata and odd digit automata search, we slighlty tweaked the loss function and mutation function to obtain fabricable results. We first included an additional rule within the mutation function to ensure new design are within reasonable patterning steps to avoid generating designs overly complex and un-patternable. We developed a custom fabrication step calculation function `fab_steps_strip_requires` - calculating the sumulative sum of unique actuator systems within each layer, and eliminating mutations that requires more than six fabrication steps. As this step limited the complexity of outputs formed, we aimed to search for patterning an even digit automata and an odd digit automata, changing the loss functions for the two search and derived the final optimized outputs.

$Loss = 5000 * (NumberOfDigitsFormed) * \sum_{I = 1, 3, 5, 7, 9}[1.001 - (ScoreForDigitI)]$

$Loss = 5000 * (NumberOfDigitsFormed) * \sum_{I = 0, 2, 4, 6, 8}[1.001 - (ScoreForDigitI)]$







