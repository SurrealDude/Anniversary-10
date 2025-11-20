#version 130

uniform mat2x4 color_xform;
uniform sampler2D framebuf;
uniform float timer;
uniform float waterheight;

varying vec2 worldPos;
varying vec2 screencoords;

const vec4  light_color = vec4(1.0, 0.31, 0.05, 0.1); 	// r, g, b, a. the gradient light that is above (and on top) of the lava
const vec4  glow_color = vec4(0.9, 0.7, 0.1, 0.5);  	// alpha is unused here. the color that white parts glow when near lava
const float glow_strength = 0.25;                      	// how strong the glow effect is
const float overexpose = 0.25;                       	// colors more than full bright bleed into other channels to make stuff whiter
const float light_distance = 0.75;                    	// less = farther distance

#if COMPILING_VERTEX_PROGRAM

void vert()
{
    vec4 outcolor = gl_Color * color_xform[0] + color_xform[1];
	
    gl_FrontColor = outcolor;
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    worldPos = (gl_ModelViewMatrix * gl_Vertex).xy;

    screencoords = (gl_Position.xy+vec2(1, 1)) * 0.5;
}

#elif COMPILING_FRAGMENT_PROGRAM

float hash(float x)
{
    return fract(sin(x) * 43758.5453);
}

float noise(float u)
{
    vec3 x = vec3(u, 0, 0);

    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f * f * (3.0 - 2.0 * f);
    float n = p.x + p.y * 57.0 + 113.0 * p.z;

    return mix(mix(mix(hash(n + 0.0), hash(n + 1.0),   f.x),
           mix(hash(n + 57.0), hash(n + 58.0), f.x),   f.y),
           mix(mix(hash(n + 113.0), hash(n + 114.0),   f.x),
           mix(hash(n + 170.0), hash(n + 171.0), f.x), f.y),
           f.z);
}

vec4 gblend(vec4 a, vec4 b)
{
    return 1.0 - (1.0 - a) * (1.0 - b);
}

void frag()
{
    vec4 basecolor = texture(framebuf, screencoords.xy);

    float dy = waterheight - worldPos.y;

    dy += noise(worldPos.x / 32.0 + timer *  2   ) * 6;
    dy += noise(worldPos.x / 16.0 + timer * -4.35) * 3;
    dy += noise(worldPos.x / 8.0  + timer *  1   ) * 1.5;

    float glowval = -(dy / 360.0);
    glowval = glowval * light_distance;
    glowval += 1;
    glowval = clamp(glowval, 0.0, 1.0);
    glowval = glowval * glowval;

    vec4 outcolor = basecolor;
    outcolor = gblend(outcolor, mix(vec4(0.0), light_color * light_color.a, glowval));

    vec4 glowcolor = (glow_color * glowval * glow_strength);
    outcolor = outcolor + glowcolor;

    float extra_green = max(outcolor.g - 1.0, 0.0);
    outcolor.r += extra_green * overexpose;
    outcolor.b += extra_green * overexpose;

    float extra_red = max(outcolor.r - 1.0, 0.0);
    outcolor.g += extra_red * overexpose;
    outcolor.b += extra_red * overexpose;

    float extra_blue = max(outcolor.b - 1.0, 0.0);
    outcolor.r += extra_blue * overexpose;
    outcolor.g += extra_blue * overexpose;

    outcolor.a = gl_Color.a;
    gl_FragColor = outcolor;
}

#endif
