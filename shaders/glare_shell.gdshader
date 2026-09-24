shader_type spatial;
render_mode blend_add, depth_draw_never, cull_front, unshaded;

// --- 基本パラメータ ---
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

// --- 減衰・グラデーションパラメータ ---
// 各軸のフェードアウト距離（0.0 の場合は減衰なし）
instance uniform vec3 fade_distance_positive = vec3(0.0, 0.0, 0.0);
instance uniform vec3 fade_distance_negative = vec3(0.0, 0.0, 0.0);

// フレネル減衰
instance uniform float fresnel_power : hint_range(0.0, 10.0) = 0.0; // 0.0で無効
instance uniform bool fresnel_invert = false; // trueで正面側を強くフェード

varying vec3 v_local_pos;

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

// 軸ごとのグラデーション計算関数
float calculate_axis_fade(float pos, float fade_pos, float fade_neg) {
    if (pos >= 0.0) {
        if (fade_pos <= 0.0001) return 1.0;
        return clamp(1.0 - (pos / fade_pos), 0.0, 1.0);
    } else {
        if (fade_neg <= 0.0001) return 1.0;
        return clamp(1.0 - (-pos / fade_neg), 0.0, 1.0);
    }
}

void vertex() {
    if (glare_enabled) {
        float f = get_flicker_factor(TIME, NODE_POSITION_WORLD, flicker_speed, randomness);
        vec3 current_expand = mix(min_expand, max_expand, f);
        float dir = flip_normal ? -1.0 : 1.0;
        
        // 押し出し後のローカル頂点座標
        VERTEX += (NORMAL * current_expand * dir) + offset;
        v_local_pos = VERTEX;
    } else {
        VERTEX = vec3(0.0);
        v_local_pos = vec3(0.0);
    }
}

void fragment() {
    if (!glare_enabled) {
        discard;
    }

    // 1. 明滅ファクター
    float f = get_flicker_factor(TIME, NODE_POSITION_WORLD, flicker_speed, randomness);
    float base_alpha = custom_glare_color.a * mix(min_alpha, max_alpha, f);

    // 2. XYZ 軸方向の距離減衰
    float fade_x = calculate_axis_fade(v_local_pos.x, fade_distance_positive.x, fade_distance_negative.x);
    float fade_y = calculate_axis_fade(v_local_pos.y, fade_distance_positive.y, fade_distance_negative.y);
    float fade_z = calculate_axis_fade(v_local_pos.z, fade_distance_positive.z, fade_distance_negative.z);
    float axis_fade = fade_x * fade_y * fade_z;

    // 3. フレネル減衰
    float fresnel_factor = 1.0;
    if (fresnel_power > 0.001) {
        float normal_dot_view = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
        if (fresnel_invert) {
            fresnel_factor = pow(normal_dot_view, fresnel_power);
        } else {
            fresnel_factor = pow(1.0 - normal_dot_view, fresnel_power);
        }
    }

    ALBEDO = custom_glare_color.rgb;
    ALPHA = base_alpha * axis_fade * fresnel_factor;
}