#version 130

uniform mat2x4 color_xform;
uniform sampler2D palettetex;
uniform sampler2D framebuf;
uniform float palette;

uniform vec2 screensize;
uniform float timer;

varying vec2 worldPos;

const float saturation = 0.5;		// strength of radiation's added saturation
const float radiation_alpha = 0.3;	// opacity of radiation effect

#if COMPILING_VERTEX_PROGRAM

    void vert(){
        //gl_FrontColor = gl_Color * color_xform[0] + color_xform[1];
        vec4 outcolor = gl_Color * color_xform[0] + color_xform[1];
        gl_FrontColor = vec4(texture(palettetex, vec2((outcolor.r*15.0+.5)/16.0,(palette+.5)/64.0)).rgb, outcolor.a);
        gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
        worldPos = (gl_ModelViewMatrix * gl_Vertex).xy;
    }
    
#elif COMPILING_FRAGMENT_PROGRAM

    void frag(){
        vec4 screencoords = gl_FragCoord;

        screencoords.x /= screensize.x;
        screencoords.y /= screensize.y;

        
        float scale_x = screensize.x / 1280.0;
        float scale_y = screensize.y / 720.0;
        float scale_min = min(scale_x, scale_y);

        vec2 ratio = vec2(scale_min / scale_x, scale_min / scale_y);
        ratio.y *= (1280.0/720.0);

        vec2 off1 = vec2(1, -1)*ratio*.025* 0.7071;
        
        vec4 outcolor_main = texture(framebuf, screencoords.xy);

        float t_a = fract(timer*.9);
        float t_b = fract(timer*.9+.333);
        float t_c = fract(timer*.9+.666);

        vec4 outcolora = texture(framebuf, screencoords.xy + off1*t_a);
		outcolora.r += saturation;
		
        vec4 outcolorb = texture(framebuf, screencoords.xy + off1*t_b);
		outcolorb.g += saturation;
		
        vec4 outcolorc = texture(framebuf, screencoords.xy + off1*t_c);
		outcolorc.b += saturation;
		
		outcolora = mix(outcolor_main, outcolora, (1.0-t_a)*radiation_alpha);
		outcolorb = mix(outcolor_main, outcolorb, (1.0-t_b)*radiation_alpha);
		outcolorc = mix(outcolor_main, outcolorc, (1.0-t_c)*radiation_alpha);
		
        vec4 outcolor = min(
			min(outcolora, outcolorb), 
			min(outcolorc, outcolor_main)
		);

        outcolor.a = 1.0;
        gl_FragColor = outcolor;
    }
    
#endif
