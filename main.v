module main
import math


/*


WARNING: this code is probably a mess and innefficient but i lowkey dont care i just wanted to port the classic.minecraft.net world gen to V
i did want to kms on the way there cuz like what are some of these expressions TwT but i survived i guess

good luck with in your journey through this shitty ahh code *salutes*


*/




struct Distort {
	source &PerlinNoise @[required]
	distort &PerlinNoise @[required]
}

fn Distort.get_value(self &Distort, x f32, y f32) f32 {
	return PerlinNoise.get_value(self.source, x + PerlinNoise.get_value(self.distort, x, y), y)
}


struct ImprovedNoise {
	mut:
		p []int
}

fn ImprovedNoise.new(random f32) &ImprovedNoise {
	mut improved_noise := &ImprovedNoise{}
	improved_noise.p = []int{len: 512}

	for i in 0 .. 256 {
		improved_noise.p[i] = i
	}

	for i in 0 .. 256 {
		j := int(random * f32(256 - i)) + i
		tmp := improved_noise.p[i]
		improved_noise.p[i] = improved_noise.p[j]
		improved_noise.p[j] = tmp
		improved_noise.p[i + 256] = improved_noise.p[i]
	}

	return improved_noise
}

fn ImprovedNoise.fade_curve(d0 f32) f32 {
	return d0 * d0 * d0 * (d0 * (d0 * 6.0 - 15.0) + 10.0)
}

fn ImprovedNoise.lerp(d0 f32, d1 f32, d2 f32) f32 {
	return d1 + d0 * (d2 - d1)
}

// Someone PLEASE kill me TwT
fn ImprovedNoise.grad(i int, d0 f32, d1 f32, d2 f32) f32 {
	mut ii := i & 15
	var_d3 := if ii < 8 { d0 } else { d1 }
	var_d4 := if ii < 4 { d1 } else { if ii != 12 && ii != 14 { d2 } else { d0 } }

	mut res := if (ii & 1) == 0 { var_d3 } else { -var_d3 }
	res += if (ii & 2) == 0 { var_d4 } else { -var_d4 }
	return res
}

fn ImprovedNoise.get_value(self &ImprovedNoise, d0 f32, d1 f32) f32 {
	mut d2 := 0.0
	mut d3 := d1
	mut d4 := d0
	i := int(math.floorf(f32(d0))) & 255
	j := int(math.floorf(f32(d1))) & 255
	k := int(math.floorf(f32(0.0))) & 255

	d4 -= math.floorf(f32(d4))
	d3 -= math.floorf(f32(d3))
	d2 -= math.floorf(f32(d2))
	d5 := ImprovedNoise.fade_curve(d4)
	d6 := ImprovedNoise.fade_curve(d3)
	d7 := ImprovedNoise.fade_curve(f32(d2))
	mut l := self.p[i] + j
	i1 := self.p[l] + k

	l = self.p[l + 1] + k
	mut i2 := self.p[i + 1] + j
	j2 := self.p[i2] + k
	i2 = self.p[i2 + 1] + k
	return ImprovedNoise.lerp(d7, ImprovedNoise.lerp(d6, ImprovedNoise.lerp(d5, ImprovedNoise.grad(self.p[i1], d4, d3, f32(d2)), ImprovedNoise.grad(self.p[j2], d4 - 1.0, d3, f32(d2))), ImprovedNoise.lerp(d5, ImprovedNoise.grad(self.p[l], d4, d3 - 1.0, f32(d2)), ImprovedNoise.grad(self.p[j], d4 - 1.0, d3 - 1.0, f32(d2)))), ImprovedNoise.lerp(d6, ImprovedNoise.lerp(d5, ImprovedNoise.grad(self.p[i1 + 1], d4, d3, f32(d2 - 1.0)), ImprovedNoise.grad(self.p[j2 + 1], d4 - 1.0, d3, f32(d2 - 1.0))), ImprovedNoise.lerp(d5, ImprovedNoise.grad(self.p[l + 1], d4, d3 - 1.0, f32(d2 - 1.0)), ImprovedNoise.grad(self.p[i2 + 1], d4 - 1.0, d3 - 1.0, f32(d2 - 1.0)))))
}


struct PerlinNoise {
	mut:
		noise_levels []&ImprovedNoise
}

fn PerlinNoise.new(random f32, levels int) &PerlinNoise {
	mut perlin_noise := &PerlinNoise{}
	perlin_noise.noise_levels = unsafe { []&ImprovedNoise{len: levels} }

	for i in 0 .. levels {
		perlin_noise.noise_levels[i] = ImprovedNoise.new(random)
	}

	return perlin_noise
}

fn PerlinNoise.get_value(self &PerlinNoise, x f32, y f32) f32 {
	mut value := 0.0
	mut pow := 1.0

	for i in 0 .. self.noise_levels.len {
		value += ImprovedNoise.get_value(self.noise_levels[i], f32(x * pow), f32(y * pow)) / pow
		pow /= 2.0
	}

	return f32(value)
}


fn main() {
	println('Hello World!')
}
