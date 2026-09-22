shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// Project Settings (Shader Globals) から参照される環境影色
global uniform vec4 global_shadow_tint : source_color = vec4(0.65, 0.72, 0.88, 1.0);

uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D main_texture : source_color, filter_nearest_mipmap;

// 影の境界位置としきい値のぼかし幅
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.45;
uniform float shadow_softness : hint_range(0.001, 0.1) = 0.02;

void fragment() {
    vec4 tex = texture(main_texture, UV);
    ALBEDO = base_color.rgb * tex.rgb;
}

void light() {
    // 1. 光の向きと法線の内積（ランバート反射）
    float NdotL = dot(NORMAL, LIGHT);

    // 2. ATTENUATION（影情報）と NdotL を一体化
    float light_intensity = clamp(NdotL, 0.0, 1.0) * ATTENUATION;

    // 3. パキッとしたトゥーン境界（ハードエッジ）の判定
    float toon_factor = smoothstep(
        shadow_threshold - shadow_softness, 
        shadow_threshold + shadow_softness, 
        light_intensity
    );

    // 4. 光が当たる部分と、環境影色を合成
    // ※Godot 4では LIGHT_COLOR にライトの強さ(Energy)が自動計算されています
    vec3 lit_color = LIGHT_COLOR;
    vec3 shade_color = global_shadow_tint.rgb;

    // 固有色にライティングを適用
    DIFFUSE_LIGHT += ALBEDO * mix(shade_color, lit_color, toon_factor);
}