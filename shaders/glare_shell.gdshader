shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_disabled, unshaded;

// オブジェクト個別のInspectorで調整可能（instance uniform）
instance uniform bool glare_enabled = true;                          // グレアのON/OFF
instance uniform bool use_flat_mesh = true;                          // 平面・画面用（true） / 立体物用（false）
instance uniform bool flip_normal = false;                           // 法線・オフセット方向の反転スイッチ

// シェル幅・オフセット制御
instance uniform float expand_size : hint_range(0.0, 0.5) = 0.05;    // シェルの広がり幅
instance uniform float depth_offset : hint_range(-0.1, 0.1) = 0.005; // 枠へのめり込みを防ぐ前後微調整

// カラー・揺らぎ制御
instance uniform vec4 custom_glare_color : source_color = vec4(0.4, 0.75, 1.0, 0.6); // 光の色
instance uniform float flicker_speed : hint_range(0.0, 20.0) = 3.0; // 点滅スピード（0で常時点灯）
instance uniform float min_alpha : hint_range(0.0, 1.0) = 0.2;     // 最小透明度
instance uniform float max_alpha : hint_range(0.0, 1.0) = 0.8;     // 最大透明度
instance uniform float randomness : hint_range(0.0, 1.0) = 0.3;    // パルスの不規則さ

float hash(float p) {
    return fract(sin(p * 127.1) * 43758.5453123);
}

float get_flicker(float time, vec3 world_pos, float speed, float min_val, float max_val, float randomness_val) {
    if (speed <= 0.001) return max_val;
    float offset = dot(world_pos, vec3(12.9898, 78.233, 45.164));
    float t = time * speed + offset;
    float wave = (sin(t) * 0.5 + 0.5) * 0.7 + (sin(t * 2.3 + offset) * 0.5 + 0.5) * 0.3;
    float noise = hash(floor(t * 4.0));
    float mix_val = mix(wave, noise, randomness_val);
    return mix(min_val, max_val, mix_val);
}

void vertex() {
    if (glare_enabled) {
        float dir = flip_normal ? -1.0 : 1.0;
        if (use_flat_mesh) {
            // 平面（板ポリ）: XY方向にスケールし、法線方向に微小オフセット
            VERTEX.xy *= (1.0 + expand_size);
            VERTEX += NORMAL * (depth_offset * dir);
        } else {
            // 立体物: 法線方向に均等押し出し
            VERTEX += NORMAL * (expand_size * dir);
        }
    } else {
        VERTEX = vec3(0.0);
    }
}

void fragment() {
    if (!glare_enabled) {
        discard;
    }
    float f = get_flicker(TIME, NODE_POSITION_WORLD, flicker_speed, min_alpha, max_alpha, randomness);
    ALBEDO = custom_glare_color.rgb;
    ALPHA = custom_glare_color.a * f;
}