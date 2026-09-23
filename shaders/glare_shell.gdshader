shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_front, unshaded;

// パラメータ宣言（ご指定の並び順）
instance uniform vec4 custom_glare_color : source_color = vec4(0.3, 0.7, 1.0, 0.6);
instance uniform bool glare_enabled = true;
instance uniform bool flip_normal = false;
instance uniform vec3 offset = vec3(0.0, 0.0, 0.0);
instance uniform vec3 max_expand = vec3(0.04, 0.04, 0.04);
instance uniform vec3 min_expand = vec3(0.01, 0.01, 0.01);
instance uniform float max_alpha : hint_range(0.0, 1.0) = 0.8;
instance uniform float min_alpha : hint_range(0.0, 1.0) = 0.2;
instance uniform float flicker_speed : hint_range(0.0, 20.0) = 3.0;
instance uniform float randomness : hint_range(0.0, 1.0) = 0.2;

float hash(float p) {
    return fract(sin(p * 127.1) * 43758.5453123);
}

float get_flicker_factor(float time, vec3 world_pos, float speed, float randomness_val) {
    if (speed <= 0.001) return 1.0;
    float offset_val = dot(world_pos, vec3(12.9898, 78.233, 45.164));
    float t = time * speed + offset_val;
    float wave = (sin(t) * 0.5 + 0.5) * 0.7 + (sin(t * 2.3 + offset_val) * 0.5 + 0.5) * 0.3;
    float noise = hash(floor(t * 4.0));
    return clamp(mix(wave, noise, randomness_val), 0.0, 1.0);
}

void vertex() {
    if (glare_enabled) {
        float f = get_flicker_factor(TIME, NODE_POSITION_WORLD, flicker_speed, randomness);
        vec3 current_expand = mix(min_expand, max_expand, f);
        float dir = flip_normal ? -1.0 : 1.0;
        
        // 素直な法線押し出し + XYZオフセット
        VERTEX += (NORMAL * current_expand * dir) + offset;
    } else {
        VERTEX = vec3(0.0);
    }
}

void fragment() {
    if (!glare_enabled) {
        discard;
    }
    float f = get_flicker_factor(TIME, NODE_POSITION_WORLD, flicker_speed, randomness);
    ALBEDO = custom_glare_color.rgb;
    ALPHA = custom_glare_color.a * mix(min_alpha, max_alpha, f);
}