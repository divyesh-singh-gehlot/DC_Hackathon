package main

import rl "vendor:raylib"
import "core:math"

Vec2 :: struct {
    x, y: f32,
}

Circle :: struct {
    pos: Vec2,
    radius: f32,
    vel: Vec2,
}

Rect :: struct {
    pos: Vec2,   // top-left corner
    w, h: f32,
    vel: Vec2,
}

// --- Circle-Circle collision with momentum ---
circle_circle_collision :: proc(a: ^Circle, b: ^Circle) {
    dx := b.pos.x - a.pos.x
    dy := b.pos.y - a.pos.y
    dist := math.sqrt(dx*dx + dy*dy)
    if dist == 0 { dist = 0.001 }

    overlap := (a.radius + b.radius) - dist
    if overlap > 0 {
        nx := dx / dist
        ny := dy / dist

        a.pos.x -= nx * overlap/2
        a.pos.y -= ny * overlap/2
        b.pos.x += nx * overlap/2
        b.pos.y += ny * overlap/2

        rvx := b.vel.x - a.vel.x
        rvy := b.vel.y - a.vel.y
        vn := rvx*nx + rvy*ny

        if vn < 0 {
            restitution: f32 = 0.7
            impulse := -(cast(f32)(1.0) + restitution) * vn / cast(f32)(2.0)
            a.vel.x -= impulse * nx
            a.vel.y -= impulse * ny
            b.vel.x += impulse * nx
            b.vel.y += impulse * ny
        }
    }
}

// --- Rect-Rect collision with momentum ---
rect_rect_collision :: proc(a: ^Rect, b: ^Rect) {
    overlapX := math.min(a.pos.x+a.w, b.pos.x+b.w) - math.max(a.pos.x, b.pos.x)
    overlapY := math.min(a.pos.y+a.h, b.pos.y+b.h) - math.max(a.pos.y, b.pos.y)
    if overlapX > 0 && overlapY > 0 {
        nx, ny: f32 = 0, 0
        if overlapX < overlapY {
            if a.pos.x < b.pos.x {
                a.pos.x -= overlapX/2; b.pos.x += overlapX/2
                nx = -1.0
            } else {
                a.pos.x += overlapX/2; b.pos.x -= overlapX/2
                nx = 1.0
            }
        } else {
            if a.pos.y < b.pos.y {
                a.pos.y -= overlapY/2; b.pos.y += overlapY/2
                ny = -1.0
            } else {
                a.pos.y += overlapY/2; b.pos.y -= overlapY/2
                ny = 1.0
            }
        }

        restitution: f32 = 0.7
        if nx != 0 {
            a.vel.x = -a.vel.x*restitution
            b.vel.x = -b.vel.x*restitution
        }
        if ny != 0 {
            a.vel.y = -a.vel.y*restitution
            b.vel.y = -b.vel.y*restitution
        }
    }
}

// --- Circle-Rect collision with momentum ---
circle_rect_collision :: proc(c: ^Circle, r: ^Rect) {
    closestX := math.clamp(c.pos.x, r.pos.x, r.pos.x + r.w)
    closestY := math.clamp(c.pos.y, r.pos.y, r.pos.y + r.h)

    dx := c.pos.x - closestX
    dy := c.pos.y - closestY
    dist2 := dx*dx + dy*dy
    if dist2 < c.radius*c.radius {
        dist := math.sqrt(dist2)
        if dist == 0 { dist = 0.001 }

        nx := dx / dist
        ny := dy / dist
        overlap := c.radius - dist

        c.pos.x += nx * overlap
        c.pos.y += ny * overlap

        rvx := c.vel.x - r.vel.x
        rvy := c.vel.y - r.vel.y
        vn := rvx*nx + rvy*ny

        if vn < 0 {
            restitution: f32 = 0.7
            impulse := -(cast(f32)(1.0) + restitution) * vn / cast(f32)(2.0)
            c.vel.x += impulse * nx
            c.vel.y += impulse * ny
            r.vel.x -= impulse * nx
            r.vel.y -= impulse * ny
        }
    }
}

// --- Boundary checks ---
check_boundaries_circle :: proc(c: ^Circle, w: f32, h: f32) {
    restitution: f32 = 0.7
    stop_threshold: f32 = 5.0  // velocities below this are set to zero
    friction: f32 = 0.5

    // Left/Right
    if c.pos.x - c.radius < 0 {
        c.pos.x = c.radius
        c.vel.x *= -restitution
    }
    if c.pos.x + c.radius > w {
        c.pos.x = w - c.radius
        c.vel.x *= -restitution
    }

    // Top/Bottom
    if c.pos.y - c.radius < 0 {
        c.pos.y = c.radius
        c.vel.y *= -restitution
    }
    if c.pos.y + c.radius > h {
        c.pos.y = h - c.radius
        c.vel.y *= -restitution
    }

    // Stop tiny velocities
    if math.abs(c.vel.x) < stop_threshold { c.vel.x = 0 }
    if math.abs(c.vel.y) < stop_threshold { c.vel.y = 0 }
}

check_boundaries_rect :: proc(r: ^Rect, w: f32, h: f32) {
    restitution: f32 = 0.7
    stop_threshold: f32 = 10.0
    friction: f32 = 0.5

    // Left/Right
    if r.pos.x < 0 { r.pos.x = 0; r.vel.x *= -restitution }
    if r.pos.x + r.w > w { r.pos.x = w - r.w; r.vel.x *= -restitution; r.vel.x *= friction }

    // Top/Bottom
    if r.pos.y < 0 { r.pos.y = 0; r.vel.y *= -restitution }
    if r.pos.y + r.h > h { r.pos.y = h - r.h; r.vel.y *= -restitution; r.vel.x *= friction }

    // Stop tiny velocities
    if math.abs(r.vel.x) < stop_threshold { r.vel.x = 0 }
    if math.abs(r.vel.y) < stop_threshold { r.vel.y = 0 }
}

random_velocity :: proc() -> Vec2 {
    return Vec2{
        x = (random_f32() - 0.5) * 600.0,       // -300..+300
        y = -(200.0 + random_f32() * 400.0),    // -200..-600
    }
}

rng_state: u64 = 88172645463325252

random_f32 :: proc() -> f32 {
    rng_state = rng_state * 6364136223846793005 + 1
    return f32((rng_state >> 32) & 0xFFFFFFFF) / 4294967295.0
}

main :: proc() {
    rl.InitWindow(1280, 720, "Physics Engine Demo")
    rl.SetTargetFPS(60)

    gravity: f32 = 800.0

    // 3 circles
    circles := []Circle{
    Circle{pos = Vec2{390, 20}, radius = 30, vel = Vec2{0, 0}},
    Circle{pos = Vec2{430, 120},  radius = 40, vel = Vec2{0, 0}},
    Circle{pos = Vec2{460, 120}, radius = 25, vel = Vec2{0, 0}},
}


    // 2 rectangles
    rects := []Rect{
    Rect{pos = Vec2{490, 100}, w = 100, h = 50, vel = Vec2{0, 0}},
    Rect{pos = Vec2{620, 120}, w = 80, h = 80, vel = Vec2{0, 0}},
    Rect{pos = Vec2{950, 120}, w = 80, h = 40, vel = Vec2{0, 0}},
}


dragging_circle: i32 = -1
dragging_rect: i32 = -1
drag_offset: Vec2 = Vec2{0, 0}      // Offset between mouse pos and object center

point_in_circle :: proc(px: f32, py: f32, c: Circle) -> bool {
    dx := px - c.pos.x
    dy := py - c.pos.y
    return (dx*dx + dy*dy) <= c.radius * c.radius
}

point_in_rect :: proc(px: f32, py: f32, r: Rect) -> bool {
    return px >= r.pos.x && px <= r.pos.x + r.w &&
           py >= r.pos.y && py <= r.pos.y + r.h
}


    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime()

        // --- Update circles ---
        for i in 0..<len(circles) {
            c := &circles[i]

            c.vel.y += gravity * dt
            c.pos.y += c.vel.y * dt
            c.pos.x += c.vel.x * dt

            check_boundaries_circle(c, 1280, 720)
        }

        // --- Update rects ---
        for i in 0..<len(rects) {
            r := &rects[i]

            r.vel.y += gravity * dt
            r.pos.y += r.vel.y * dt
            r.pos.x += r.vel.x * dt

            check_boundaries_rect(r, 1280, 720)
}

        // --- Collisions ---

// Circle-Circle collisions
for i in 0..<len(circles) {
    for j in i+1..<len(circles) {
        circle_circle_collision(&circles[i], &circles[j])
    }
}

// Rect-Rect collisions
for i in 0..<len(rects) {
    for j in i+1..<len(rects) {
        rect_rect_collision(&rects[i], &rects[j]) // fixed typo
    }
}

// Circle-Rect collisions
for i in 0..<len(circles) {
    for j in 0..<len(rects) {
        circle_rect_collision(&circles[i], &rects[j])
    }
}

mx := rl.GetMouseX()
my := rl.GetMouseY()

if rl.IsMouseButtonPressed(.LEFT) {
    // Try to pick circle
    for i in 0..<len(circles) {
        if point_in_circle(f32(mx), f32(my), circles[i]) {
            dragging_circle = cast(i32) i
            drag_offset = Vec2{
                x = f32(mx) - circles[i].pos.x,
                y = f32(my) - circles[i].pos.y,
            }
            circles[i].vel = Vec2{0,0} // Cancel velocity while dragging
            break
        }
    }
    // Try to pick rect
    for i in 0..<len(rects) {
        if point_in_rect(f32(mx), f32(my), rects[i]) {
            dragging_rect = cast(i32) i
            drag_offset = Vec2{
                x = f32(mx) - rects[i].pos.x,
                y = f32(my) - rects[i].pos.y,
            }
            rects[i].vel = Vec2{0,0}
            break
        }
    }
}

if rl.IsMouseButtonDown(.LEFT) {
    if dragging_circle != -1 {
        circles[dragging_circle].pos.x = f32(mx) - drag_offset.x
        circles[dragging_circle].pos.y = f32(my) - drag_offset.y
        circles[dragging_circle].vel = Vec2{0,0}
    }
    if dragging_rect != -1 {
        rects[dragging_rect].pos.x = f32(mx) - drag_offset.x
        rects[dragging_rect].pos.y = f32(my) - drag_offset.y
        rects[dragging_rect].vel = Vec2{0,0}
    }
}

if rl.IsMouseButtonReleased(.LEFT) {
    dragging_circle = -1
    dragging_rect = -1
}

        // --- Draw ---
        rl.BeginDrawing()
        rl.ClearBackground(rl.Color{ 40, 10, 62, 255 })

        for c in circles {
            rl.DrawCircle(cast(i32)c.pos.x, cast(i32)c.pos.y, c.radius,  rl.Color{247, 141, 96, 255})
            rl.DrawCircleLines(cast(i32)c.pos.x, cast(i32)c.pos.y, c.radius, rl.Color{221, 218, 208, 255})
        }

        for r in rects {
            rl.DrawRectangle(
                cast(i32)r.pos.x,
                cast(i32)r.pos.y,
                cast(i32)r.w,
                cast(i32)r.h,
                rl.Color{234, 34, 100, 255},
            )

            rl.DrawRectangleLines(
                cast(i32)r.pos.x,
                cast(i32)r.pos.y,
                cast(i32)r.w,
                cast(i32)r.h,
                rl.WHITE,
            )
        }

        rl.EndDrawing()
    }

    rl.CloseWindow()
}
