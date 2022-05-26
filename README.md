# perceptron-asm

Implementation of a single-layer perceptron in x86 assembly.

I was inspired by the very simple perceptron algorithm described in [Veritasium's video on analog computers](https://youtu.be/GVsUOuSjvcg?t=221).
I've also never written any x86 floating point code before, so why not now.

## Build

- `apt install nasm feh ffmpeg`
- `make all`

## References

- [x86 64-bit Linux System Calls](https://blog.rchapman.org/posts/Linux_System_Call_Table_for_x86_64/)
- [Perceptron Wikipedia](https://en.wikipedia.org/wiki/Perceptron)
- [Veritasium - Future Computers Will Be Radically Different](https://www.youtube.com/watch?v=GVsUOuSjvcg)
- ppm
  - https://manpages.ubuntu.com/manpages/bionic/man5/ppm.5.html
  - [Netpbm](https://en.wikipedia.org/wiki/Netpbm#File_formats=)
- floating point
  - https://en.wikibooks.org/wiki/X86_Assembly/Floating_Point
  - http://www.ray.masmcode.com/tutorial/index.html
  - [IEEE-754 Floating Point Converter](https://www.h-schmidt.net/FloatConverter/IEEE754.html)
  - https://www.cs.cornell.edu/~tomf/notes/cps104/floating.html
  - http://mathcenter.oxford.emory.edu/site/cs170/ieee754/
