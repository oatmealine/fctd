uniform float time;
uniform vec2 size;

vec4 effect(vec4 diffuse, Image tex, vec2 texture_coords, vec2 screen_coords) {
  vec2 uv = floor(texture_coords * size) / size;

  uv.x += sin(uv.y * 12.0 + time) * 0.03;

  float amp = 0.025 + sin(uv.y * 40.0 + time * 4.0) * 0.01;
  uv.y += sin(uv.y * 14.0 + time * 1.2) * 0.02;

  float width = 0.2;
  width += sin(abs(uv.y - 0.5)) * 0.5;

  float sine = sin((uv.y * size.y) / 12. + time * 1.2);
  float dist1 = abs(uv.x - 0.5 + sine * amp);
  float a = dist1 < width ? 1.0 : 0.0;
  float dist2 = abs(uv.x - 0.5 + sine * -amp + sin(uv.y * 18.0 + time * 0.8) * amp * 0.9);
  vec3 col = dist2 < width * 0.6 ? vec3(0.3, 0.75, 0.4) : vec3(0.4, 1.0, 0.5);
  return vec4(col, a);
}