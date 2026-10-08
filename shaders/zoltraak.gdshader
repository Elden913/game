shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_opaque;

uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 glow_color : source_color = vec4(0.0, 0.5, 1.0, 1.0);
uniform float glow_intensity : hint_range(1.0, 20.0) = 5.0;
uniform float glow_power : hint_range(0.1, 5.0) = 2.0;

void fragment() {
    float fresnel = pow(1.0 - dot(NORMAL, VIEW), glow_power);
    
    vec3 final_color = mix(core_color.rgb, glow_color.rgb * glow_intensity, fresnel);
    
    ALBEDO = final_color;
}