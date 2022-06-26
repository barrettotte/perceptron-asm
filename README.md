# perceptron-asm

Implementation of a single-layer perceptron in x86 assembly.

I was inspired by the very simple perceptron algorithm described in [Veritasium's video on analog computers](https://youtu.be/GVsUOuSjvcg?t=221).
I've also never written any x86 floating point code before, so why not now.

## Run Locally

- dependencies: `apt install nasm feh ffmpeg`
- build: `make`
- build and run: `make run`
- run: `./bin/perceptron`

## Debug Notes

```text
p/x (float[20][20])weights
print (char*)&file_buffer
```

## References

- [x86 64-bit Linux System Calls](https://blog.rchapman.org/posts/Linux_System_Call_Table_for_x86_64/)
- [Feedforward Neural Network](https://en.wikipedia.org/wiki/Feedforward_neural_network)
- [Perceptron Wikipedia](https://en.wikipedia.org/wiki/Perceptron)
- [Compiler Explorer](https://godbolt.org/)
- [Veritasium - Future Computers Will Be Radically Different](https://www.youtube.com/watch?v=GVsUOuSjvcg)
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
