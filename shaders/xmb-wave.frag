#version 440
/*
    XMB wave for the XMB PS3 theme (https://github.com/luk3h/xmb-ps3-theme)

    Original "PS3 Menu effect" by int_45h - https://www.shadertoy.com/view/tXy3DK
    (itself forked from "waves pt 2"). int_45h's note:

        I'm too lazy to copy the MIT license so like just do whatever you want with this shader
        but like if you can leave a comment or something or hit me up, that'd be dope. thxxx

    Updated as "Ps3 XMB 3.0 Background" by llmciv - https://www.shadertoy.com/view/fcf3Dn
    (dithering, smoothed raymarching, anti-aliasing, dark grey to blue by time of day).

    Starfield based on xaot88's: https://www.shadertoy.com/view/Md2SR3
    hash12 is Dave Hoskins' float "Hash without Sine" pattern (replaces the uint version so it
    compiles for every Qt shader target).

    Converted for Qt 6 / KDE Shader Wallpaper (qsb) for this theme.
    This version (the one the theme ships, compiled as xmb-wave.frag.qsb): the background colour
    drifts through a palette, one colour per hour, and is dimmer at night.

    Compile with qsb - see shaders/README.md.
*/

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float iTime;
    float iTimeDelta;
    float iFrameRate;
    float iSampleRate;
    int iFrame;
    vec4 iDate;
    vec4 iMouse;
    vec3 iResolution;
    float iChannelTime[4];
    vec3 iChannelResolution[4];
};

#define THRESHOLD .99
#define DUST
#define MIN_DIST .04
#define MAX_DIST 40.
#define MAX_DRAWS 40
// AA 1 = normal, AA 2 = 4x samples (much heavier, not needed at 4K)
#define AA 1
#define M_PI 3.1415926535897932384626433832795

// --- Colour cycle settings -------------------------------------------------
// How long each colour lasts, in hours. 1.0 = one colour per hour.
// For a quick test, set it to 0.005 (about 18 seconds per colour).
#define HOURS_PER_COLOUR 1.0
// How dark it gets at night: 1.0 = no change, 0.6 = 40% darker at midnight
#define NIGHT_BRIGHTNESS 0.65

// The palette, in order. Each is a mid-dark shade so the white wave stands out.
// (Written as if-checks rather than an array, so it compiles for every target.)
const int PALETTE_SIZE = 8;
vec3 palette(int i)
{
    if (i == 0) return vec3(0.149, 0.471, 0.569);  // blue (the original XMB colour)
    if (i == 1) return vec3(0.400, 0.240, 0.560);  // purple
    if (i == 2) return vec3(0.520, 0.220, 0.470);  // magenta
    if (i == 3) return vec3(0.560, 0.190, 0.200);  // crimson
    if (i == 4) return vec3(0.560, 0.450, 0.160);  // gold
    if (i == 5) return vec3(0.220, 0.460, 0.250);  // green
    if (i == 6) return vec3(0.110, 0.470, 0.440);  // teal
    return vec3(0.300, 0.300, 0.330);              // silver
}

// Float-only hash (replaces the uint version so it compiles for all targets)
float hash12(vec2 p)
{
    p = floor(mod(p, 8192.0));
    vec3 p3 = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float value2d(vec2 p)
{
    vec2 pg = floor(p), pc = p - pg, k = vec2(0, 1);
    pc *= pc * pc * (3. - 2. * pc);
    return mix(
        mix(hash12(pg + k.xx), hash12(pg + k.yx), pc.x),
        mix(hash12(pg + k.xy), hash12(pg + k.yy), pc.x),
        pc.y
    );
}

float get_stars_rough(vec2 p)
{
    float s = smoothstep(THRESHOLD, 1., hash12(p));
    if (s >= THRESHOLD)
        s = pow((s - THRESHOLD) / (1. - THRESHOLD), 10.);
    return s;
}

float get_stars(vec2 p, float a, float t)
{
    vec2 pg = floor(p), pc = p - pg, k = vec2(0, 1);
    pc *= pc * pc * (3. - 2. * pc);

    float s = mix(
        mix(get_stars_rough(pg + k.xx), get_stars_rough(pg + k.yx), pc.x),
        mix(get_stars_rough(pg + k.xy), get_stars_rough(pg + k.yy), pc.x),
        pc.y
    );
    return smoothstep(a, a + t, s) * pow(value2d(p * .1 + iTime) * .5 + .5, 8.3);
}

float get_dust(vec2 p, vec2 size, float f)
{
    vec2 ar = vec2(iResolution.x / iResolution.y, 1);
    vec2 pp = p * size * ar;
    return
        pow(.64 + .46 * cos(p.x * 6.28), 1.7) *
        f *
        (
            get_stars(.1 * pp + iTime * vec2(20., -10.1), .11, .71) * 4. +
            get_stars(.2 * pp + iTime * vec2(30., -10.1), .1, .31) * 5. +
            get_stars(.32 * pp + iTime * vec2(40., -10.1), .1, .91) * 2.
        );
}

float sdf(vec3 p)
{
    p *= 2.;
    float o = 8.2 * sin(.05 * p.x + iTime * .25) +
        (.04 * p.z) *
        sin(p.x * .11 + iTime) *
        2. * sin(p.z * .2 + iTime) *
        value2d(vec2(.03, .4) * p.xz + vec2(iTime * .5, 0));
    return abs(dot(p, normalize(vec3(0, 1, 0.05))) + 2.5 + o * .5);
}

vec2 raymarch(vec3 o, vec3 d, float jitter)
{
    float t = jitter * 2.0;
    float a = 0.0;
    float g = MAX_DIST;
    int dr = 0;

    for (int i = 0; i < 100; i++)
    {
        vec3 p = o + d * t;
        float ndt = sdf(p);
        g = (t > 10.0) ? min(g, abs(ndt)) : MAX_DIST;

        if (t >= MAX_DIST) break;

        if (abs(ndt) < MIN_DIST)
        {
            if (dr > MAX_DRAWS) break;
            dr++;
            float f = smoothstep(0.0, 0.3, (p.z * 0.9) / 100.0);
            a += 0.015 * f;
            t += 0.05;
        }
        else
        {
            t += abs(ndt) * 0.8;
        }
    }

    g /= 3.0;
    return vec2(a, max(1.0 - g, 0.0));
}

float dither(vec2 pos)
{
    return fract(52.9829189 * fract(dot(pos, vec2(0.06711056, 0.00583715))));
}

// Current base colour: steps through the palette, blending smoothly
vec3 cycle_colour()
{
    float steps = (iDate.w / 3600.0) / HOURS_PER_COLOUR;
    int idx = int(mod(floor(steps), float(PALETTE_SIZE)));
    int nxt = int(mod(float(idx + 1), float(PALETTE_SIZE)));
    float blend = smoothstep(0.0, 1.0, fract(steps));
    return mix(palette(idx), palette(nxt), blend);
}

vec3 render(vec2 U)
{
    vec2 ires = iResolution.xy;
    vec2 uv = U / ires;

    vec3 o = vec3(0.0);
    vec3 d = vec3((U - 0.5 * ires) / ires.y, 1.0);

    vec2 mg = raymarch(o, d, dither(U));
    float m = mg.x;

    // Brightness from the time of day: 0 at midnight, 1 at noon
    float q = iDate.w / 86400.0;
    float day = 0.5 - 0.5 * cos(2. * M_PI * q);
    float bright = mix(NIGHT_BRIGHTNESS, 1.0, day);

    // Four slightly different shades of the current colour, one per corner,
    // like the original's subtle gradient
    vec3 base = cycle_colour() * bright;
    vec3 l1 = base;
    vec3 l2 = base * 0.72;
    vec3 l3 = base * 0.68;
    vec3 l4 = base * 1.05;

    vec3 c = mix(mix(l1, l2, uv.x), mix(l3, l4, uv.x), uv.y);
    c = mix(c, vec3(1.0), clamp(m, 0.0, 1.0));

#ifdef DUST
    c += get_dust(uv, vec2(2000.0), mg.y) * 0.3;
#endif

    return c;
}

void mainImage(out vec4 O, in vec2 U)
{
    vec3 totalColor = vec3(0.0);
#if AA > 1
    for (int m = 0; m < AA; m++) {
        for (int n = 0; n < AA; n++) {
            vec2 offset = vec2(float(m), float(n)) / float(AA) - 0.5;
            totalColor += render(U + offset);
        }
    }
    totalColor /= float(AA * AA);
#else
    totalColor = render(U);
#endif
    totalColor += (dither(U) - 0.5) / 255.0;
    O = vec4(totalColor, 1.0);
}

void main()
{
    // Qt's texture coords start top-left; Shadertoy's start bottom-left
    vec2 fragCoord = vec2(qt_TexCoord0.x, 1.0 - qt_TexCoord0.y) * iResolution.xy;
    vec4 color;
    mainImage(color, fragCoord);
    fragColor = color * qt_Opacity;
}
