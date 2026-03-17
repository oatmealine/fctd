uniform vec4 diff;

vec4 effect(vec4 diffuse, Image tex, vec2 texture_coords, vec2 screen_coords) {
  vec4 col = Texel(tex, texture_coords);
  return vec4(mix(col.rgb * diff.rgb, diffuse.rgb, diffuse.a), col.a * diff.a);
}