# What is it? [![Build Status](https://travis-ci.org/drug007/nanogui.svg?branch=develop)](https://travis-ci.org/drug007/nanogui)

D port of [nanogui](https://github.com/wjakob/nanogui)

The port is incomplete - not all widgets are ported, but all ported widgets are fully usable.

There is difference with origin. For example:
- instead of const references passing by value is used
- as a color and vector implementation gfm.math is used (in origin eigen used as a vector implementation and own implementation of color type)
- no locking on glfw, instead two backends are available - arsd.simpledisplay (no external dependencies) and SDL2 (depends on SDL2 library obviously), SDL backend is more developed than arsd one (due to lack of time). Other backend like glfw, sfml etc can be easily added, nanogui is agnostic to underlying layer.

## Cloning source

The project at the moment uses [arsd](https://github.com/adamdruppe/arsd) as a submodule. For cloning please use either

```
git clone --recursive https://github.com/drug007/nanogui.git
```

or 
```
git clone https://github.com/drug007/nanogui.git
cd nanogui
git submodule update --init
```

# Examples

Directory `examples` contains two packages, providing examples for `arsd` and `sdl` backends. To run example `cd` to corresponding directory and run `dub` command. For example:
```
cd examples/sdl
dub
```

# Screenshot

![Screenshot](https://github.com/drug007/nanogui/blob/cursor/resources/readme/nanogui_001.gif)