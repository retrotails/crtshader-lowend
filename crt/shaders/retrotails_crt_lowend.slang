#version 450

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	float BRIGHTBOOST;
	float INTENSITY;
	float SCANTHICK;
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


const float dotmask_scale = 0.5;
float dm(vec2 uv)
{
    uv += vec2(0.5);
    uv = mod(uv*vec2(1.0/3.0,0.5) + 1.0, 2.0) - 1.0;
    return clamp(-length(uv*vec2(3,2)) + 2.375 , 0, 1);
}

void main()
{
    float fields = params.SourceSize.y;
    vec2 pc = vTexCoord.xy*params.OutputSize.xy;
    // get texel, linear interpolation horizontally, nearest vertically
    vec3 src = texture(Source,vec2(vTexCoord.x,floor(vTexCoord.y*fields)/fields + 0.5/fields)).rgb;
    // lazy approximate linearize
    src = pow(src,vec3(1.0/2.2));
    // simple triangle-wave scanlines
    src *= vec3(abs(mod(vTexCoord.y*fields*2-1.0,2)-1) + 1.2)*0.5;
    // dot mask
    src *= vec3(
        dm( pc/dotmask_scale           ) + dm( pc/dotmask_scale + vec2(3,2) ),
        dm( pc/dotmask_scale+vec2(4,0) ) + dm( pc/dotmask_scale + vec2(1,2) ),
        dm( pc/dotmask_scale+vec2(2,0) ) + dm( pc/dotmask_scale + vec2(5,2) )
    );
    // transform back to approximated sRGB
    FragColor = vec4(pow(src,vec3(2.2)), 1.0);

}
