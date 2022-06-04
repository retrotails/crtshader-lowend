#version 450

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
} params;


layout(std140, set = 0, binding = 0) uniform UBO
{
	mat4 MVP;
} global;

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;





// 0.5 is the smallest value, and suitable for 720p/1080p displays
// 1.5 or 2.0 is good for a 4k display if you want to simulate a low-res TV with a very noticable dot-mask
// most other values look bad
const float dotmask_scale = 0.5;

// dot mask is a hexagon shape
// 2.0 is inaccurate, but maps better to pixels and is less likely to have moire effects
//const float dm_aspect = 1.7320508;
const float dm_aspect = 2.0;

// 0.0 is probably undesirable
// 1.0 is very bright
// ~0.75 is a good value
// you may also want to raise this when using strong scanlines
const float brightness = 0.75;

// 0 is weak scanlines, 1 is obscenely strong
// scanlines often don't look great at lower resolutions,
// so it might be best to keep this value lower at 1080p
const float scanline_str = 0.5;

float dm(vec2 uv) {
    uv += vec2(0.5);
    uv = mod(uv*vec2(1.0/3.0,0.5) + 1.0, vec2(2.0,dm_aspect) ) - 1.0;
    return max(-length(uv*vec2(3,2)) + 1.0 + brightness*2.0 , 0);
}

void main()
{
    float fields = params.SourceSize.y;
    vec2 pc = vTexCoord.xy*params.OutputSize.xy;
    // get texel, linear interpolation horizontally, nearest vertically
    vec3 src = texture(Source,vec2(vTexCoord.x,floor(vTexCoord.y*fields)/fields + 0.5/fields)).rgb;
    // simple triangle-wave scanlines
    src *= vec3(abs(mod(vTexCoord.y*fields*2.0-1.0,2.0)-1.0) + 1.0 - scanline_str) * (0.5+scanline_str*0.5);
    // dot mask
    src *= vec3(
        dm( pc/dotmask_scale           ) + dm( pc/dotmask_scale + vec2(3,dm_aspect) ),
        dm( pc/dotmask_scale+vec2(4,0) ) + dm( pc/dotmask_scale + vec2(1,dm_aspect) ),
        dm( pc/dotmask_scale+vec2(2,0) ) + dm( pc/dotmask_scale + vec2(5,dm_aspect) )
    );
    FragColor = vec4(src, 1.0);
}
