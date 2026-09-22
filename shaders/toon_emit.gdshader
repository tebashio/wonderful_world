shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// Project Settings (Shader Globals) から参照される環境影色
global uniform vec4 global_shadow_tint : source_color = vec4(0.65, 0.72, 0.88, 1.0);

uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D main_texture : source_color, filter_nearest_mipmap;

// 影の境界位置としきい値のぼかし幅
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.45;
uniform float shadow_softness : hint_range(0.001, 0.1) = 0.02;

// 発光（Emission）制御
uniform float emission_energy : hint_range(0.0, 5.0) = 1.8; // HDR領域（1.0超でGlow対象）
uniform float flicker_speed = 3.0;
uniform float min_flicker : hint_range(0.0, 1.0) = 0.85;
uniform float max_flicker : hint_range(0.0, 1.0) = 1.0;
uniform float randomness : hint_range(0.0, 1.0) = 0.2;

float hash(float p) {
    return fract(sin(p * 127.1) * 43758.5453123);
}

float get_flicker(float time, vec3 world_pos, float speed, float min_val, float max_val, float randomness_val) {
    float offset = dot(world_pos, vec3(12.9898, 78.233, 45.164));
    float t = time * speed + offset;
    float wave = (sin(t) * 0.5 + 0.5) * 0.7 + (sin(t * 2.3 + offset) * 0.5 + 0.5) * 0.3;
    float noise = hash(floor(t * 4.0));
    float mix_val = mix(wave, noise, randomness_val);
    return mix(min_val, max_val, mix_val);
}

void fragment() {
    vec4 tex = texture(main_texture, UV);
    vec3 col = base_color.rgb * tex.rgb;
    ALBEDO = col;
    
    // ワールド座標ベースの微細な明滅発光（HDR）
    float f = get_flicker(TIME, NODE_POSITION_WORLD, flicker_speed, min_flicker, max_flicker, randomness);
    EMISSION = col * (emission_energy * f);
}

void light() {
    float NdotL = dot(NORMAL, LIGHT);
    float light_intensity = clamp(NdotL, 0.0, 1.0) * ATTENUATION;
    float toon_factor = smoothstep(shadow_threshold - shadow_softness, shadow_threshold + shadow_softness, light_intensity);
    
    vec3 lit_color = LIGHT_COLOR;
    vec3 shade_color = global_shadow_tint.rgb;
    DIFFUSE_LIGHT += ALBEDO * mix(shade_color, lit_color, toon_factor);
}