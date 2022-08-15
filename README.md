# perceptron-asm

Implementation of a single-layer perceptron in x86 assembly.

I was inspired by the very simple perceptron algorithm described in [Veritasium's video on analog computers](https://youtu.be/GVsUOuSjvcg?t=221).
I also wanted another assembly challenge and I've never written any x86 floating point code before.

## Results

Model trained with 500 samples and 3000 training rounds resulted in 90% success rate.

<div align="center">
  <img style="width:240px; height:240px" src="docs/model.png"/>
  <p>
    See <a href="model.ppm">model.ppm</a> for the raw image file.
    <br>I also generated a video of the training process <a href="docs/training.mp4">docs/training.mp4</a>
  </p>
</div>

## Perceptron Summary

A perceptron is a simple mathematical model attempting to mimic how a biological neuron works.
A neuron fires or activates when the dot product of inputs and weights is larger than the specified bias.

Frank Rosenblatt built the first implementation of a perceptron as a specialized machine in 1958.
Read more about the history of the perceptron [here](https://en.wikipedia.org/wiki/Perceptron#History).

A single-layer perceptron is the simplest neural network you can make.

## Run Locally

- dependencies: `apt install nasm ffmpeg imagemagick`
- build: `make`
- build and run: `make run`
- build assets: `make assets`

## References

- [x86 64-bit Linux System Calls](https://blog.rchapman.org/posts/Linux_System_Call_Table_for_x86_64/)
- [Feedforward Neural Network](https://en.wikipedia.org/wiki/Feedforward_neural_network)
- [Perceptron Wikipedia](https://en.wikipedia.org/wiki/Perceptron)
- [Compiler Explorer](https://godbolt.org/)
- [Veritasium - Future Computers Will Be Radically Different](https://www.youtube.com/watch?v=GVsUOuSjvcg)
- [Linear Congruential Generator (Easy random numbers in ASM)](https://en.wikipedia.org/wiki/Linear_congruential_generator)
- PPM files
  - https://manpages.ubuntu.com/manpages/bionic/man5/ppm.5.html
  - https://people.cs.clemson.edu/~dhouse/courses/405/notes/ppm-files.pdf
  - [Netpbm](https://en.wikipedia.org/wiki/Netpbm#File_formats=)
- Floating point
  - https://en.wikibooks.org/wiki/X86_Assembly/Floating_Point
  - http://www.ray.masmcode.com/tutorial/index.html
  - [IEEE-754 Floating Point Converter](https://www.h-schmidt.net/FloatConverter/IEEE754.html)
  - https://www.cs.cornell.edu/~tomf/notes/cps104/floating.html
  - http://mathcenter.oxford.emory.edu/site/cs170/ieee754/
  - [The Art of Assembly Language. Randall Hyde - Chapter 14](https://www.amazon.com/Art-Assembly-Language-2nd/dp/1593272073)
