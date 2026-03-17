uniform float time;

vec4 effect(vec4 diffuse, Image tex, vec2 texture_coords, vec2 screen_coords) {
  vec4 col = Texel(tex, texture_coords);
  float sine = sin((screen_coords.x + screen_coords.y) / 12. + time * 8.) * 0.5 + 0.5;
  float add = floor(sine + 0.6);
  return vec4(col.rgb * diffuse.rgb + add * 0.2, col.a * diffuse.a);
}