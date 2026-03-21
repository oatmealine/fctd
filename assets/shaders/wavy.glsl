uniform float time;

vec4 effect(vec4 diffuse, Image tex, vec2 texture_coords, vec2 screen_coords) {
  float length = floor(texture_coords.x * 64.) / 64.;
  vec4 col = Texel(tex, texture_coords + floor(vec2(0.0, sin(length * 7. + time * 2.) * mix(0.0, 0.2, length)) * 32.) / 32.);
  return col * diffuse;
}