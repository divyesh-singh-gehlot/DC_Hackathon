# 2D Physics Sandbox (Odin + Raylib)

This project is a simple 2D physics engine demo written in [Odin](https://odin-lang.org/) using [Raylib](https://www.raylib.com/) for rendering. It demonstrates basic physics interactions between circles and rectangles, including gravity, collision detection, and momentum transfer.

## Features

- Circle-circle, rect-rect, and circle-rect collision detection and response
- Gravity and boundary checks
- Mouse dragging for both circles and rectangles (bonus feature)
- Simple random velocity generator (not used by default)
- Visual feedback for all objects

## Requirements

- [Odin compiler](https://odin-lang.org/docs/install/)
- [Raylib Odin bindings](https://github.com/odin-lang/Odin/tree/master/vendor/raylib) (included via `vendor:raylib` import)

## How to Run

1. **Clone this repository** (or copy the files to your machine).
2. **Build the project**:
    ```sh
    odin run hello.odin
    ```
3. **Controls**:
    - **Left Mouse Button**: Click and drag circles or rectangles.
    - Objects will bounce and interact with each other and the window boundaries.

## File Structure

```
DC_Hackathon/
├── hello.odin      # Main source code
```

## License

This project is for educational/demo
