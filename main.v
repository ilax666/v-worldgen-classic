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


struct Random {
	mut:
		seed int
}

/*
   Creates a pseudo-random value generator. The seed must be an integer.
   Uses an optimized version of the Park-Miller PRNG.
   http://www.firstpr.com.au/dsp/rand31/
*/
fn Random.new(seed int) &Random {
	mut r := &Random{seed}
	r.seed = seed % 2147483647

	if r.seed <= 0 {
		r.seed += 2147483646
	}

	return r
}

// Returns a pseudo-random value between 1 and 2^32 - 2.
fn Random.next(mut r Random) int {
	r.seed = r.seed * 16807 % 2147483647
	return r.seed
}

fn Random.next_int(mut r Random, max int) int {
	return int(math.floor(f32(Random.next(mut r)) / 2147483646.0 * f32(max)))
}

// Returns a pseudo-random floating point number in range [0, 1).
fn Random.next_float(mut r Random) f32 {
	// We know that result of next() will be 1 to 2147483646 (inclusive).
	return (f32(Random.next(mut r)) - 1.0) / 2147483646.0
}


/*

var RandomLevel = function () {

    [ ... ]

    this.createLevel = function(seed, xSize, zSize, ySize) {
		[ ... ]


        progress.string = "Watering..";
        //this.progressRenderer.progressStage("Watering..");
        //long i5 = System.nanoTime();
        var i5 = random.nextFloat();//Math.random();
        var j5 = 0;

        l = 7;//Tile.calmWater.id;
        //this.progress(0);

        // hack for floodfill to work...
        var extray = 64-35;
        if(xSize >= 256) extray = 128-36;
        if(xSize >= 512) extray = 256-37;

        //console.log(ySize / 2 - 1)

        for (i1 = 0; i1 < xSize; ++i1) {
            j5 = j5 + this.floodFill(i1, ySize / 2 - 1 + extray, 0, 0, l) + this.floodFill(i1, ySize / 2 - 1, zSize - 1 + extray, 0, l);
        }

        for (i1 = 0; i1 < zSize; ++i1) {
            j5 = j5 + this.floodFill(0, ySize / 2 - 1 + extray, i1, 0, l) + this.floodFill(xSize - 1, ySize / 2 - 1 + extray, i1, 0, l);
        }


        i1 = xSize * zSize / 200;

        for (l1 = 0; l1 < i1; ++l1) {
            if (l1 % 100 == 0) {
            //    progress(l1 * 100 / (i1 - 1));
            	progress.percent = l1 * 100 / (i1 - 1);
                self.postMessage(progress);
            }

            i2 = random.nextInt(xSize);
            l2 = ySize / 2 - 1 - random.nextInt(3) + extray;
            i3 = random.nextInt(zSize);
            if (this.tiles[(l2 * zSize + i3) * xSize + i2] == 0) {
                j5 += this.floodFill(i2, l2, i3, 0, l);
            }
        }
            	
        progress.percent = 100;
        self.postMessage(progress);

        progress.string = "Melting..";
        //this.progressRenderer.progressStage("Melting..");
        this.melt();
        progress.string = "Growing..";
        //this.progressRenderer.progressStage("Growing..");
        this.grow(aint);
        progress.string = "Planting..";
        //this.progressRenderer.progressStage("Planting..");
        this.plant(aint);

        progress.tiles = this.tiles;
        progress.string = "";
        self.postMessage(progress);

    }


}

*/
struct RandomLevel {
	mut:
		progress_str string
    	progress_percent int
    	tiles []int

		x_size int
		z_size int
		y_size int
		random &Random
		this_random f32
		fill_queue []int
}

fn RandomLevel.grow(mut rl &RandomLevel, aint []int) {
	i := rl.x_size
	j := rl.z_size
	k := rl.y_size
	perlinnoise := PerlinNoise.new(rl.this_random, 8)
	perlinnoise1 := PerlinNoise.new(rl.this_random, 8)

	for l := 0; l < i; l += 1 {
		rl.progress_percent = l * 100 / (rl.x_size - 1)
		// postMessage => rl.progress_percent

		for i1 := 0; i1 < j; i1 += 1 {
			flag := PerlinNoise.get_value(perlinnoise, l, i1) > 8.0
			flag1 := PerlinNoise.get_value(perlinnoise1, l, i1) > 12.0
			j1 := aint[l + i1 * i]
			k1 := ((j1 * rl.z_size + i1) * rl.x_size + l)

			l1 := rl.tiles[((j1 + 1) * rl.z_size + i1) * rl.x_size + l] & 255

			if l1 == 7 && j1 <= k / 2 - 1 && flag1 {
				rl.tiles[k1] = 12 // gravel
			}

			if l1 == 0 {
				mut i2 := 1 // grass
				if j1 <= k / 2 - 1 && flag {
					i2 = 11 // sand
				}
				rl.tiles[k1] = i2
			}
		}
	}
}

fn RandomLevel.melt(mut rl &RandomLevel) {
	mut i := 0
	j := rl.x_size * rl.z_size * rl.y_size / 10000

	for k := 0; k < j; k += 1 {
		if k % 100 == 0 {
			rl.progress_percent = k * 100 / (j - 1)
			// postMessage => rl.progress_percent
		}

		extray := 16

		l := Random.next_int(mut rl.random, rl.x_size)
		i1 := Random.next_int(mut rl.random, rl.y_size / 2 - 4) + extray
		j1 := Random.next_int(mut rl.random, rl.z_size)

		if rl.tiles[(i1 * rl.z_size + j1) * rl.x_size + l] == 0 {
			i = i + 1
			RandomLevel.flood_fill(mut rl, l, i1, j1, 0, 17)
		}
	}
}

fn RandomLevel.plant(mut rl &RandomLevel, aint []int) {
	i := rl.x_size
	j := rl.x_size * rl.z_size / 4000

	for k := 0; k < j; k += 1 {
		rl.progress_percent = k * 100 / (j - 1)
		// postMessage => rl.progress_percent

		l := Random.next_int(mut rl.random, rl.x_size)
		i1 := Random.next_int(mut rl.random, rl.z_size)

		for j1 := 0; j1 < 20; j1 += 1 {
			mut k1 := l
			mut l1 := i1

			for i2 := 0; i2 < 20; i2 += 1 {
				k1 = k1 + Random.next_int(mut rl.random, 6) - Random.next_int(mut rl.random, 6)
				l1 = l1 + Random.next_int(mut rl.random, 6) - Random.next_int(mut rl.random, 6)
				if k1 >= 0 && l1 >= 0 && k1 < rl.x_size && l1 < rl.z_size {
					j2 := aint[k1 + l1 * i] + 1
					k2 := Random.next_int(mut rl.random, 3) + 4
					mut flag := true

					mut l2 := 0
					mut i3 := 0
					mut j3 := 0

					for l2 = j2; l2 <= j2 + 1 + k2; l2 += 1 {
						mut b0 := 1

						if l2 >= j2 + 1 + k2 - 2 {
							b0 = 2
						}

						for i3 = k1 - b0; i3 <= k1 + b0 && flag; i3 += 1 {
							for j3 = l1 - b0; j3 <= l1 + b0 && flag; j3 += 1 {
								if i3 >= 0 && l2 >= 0 && j3 >= 0 && i3 < rl.x_size && l2 < rl.y_size && j3 < rl.z_size {
									if (rl.tiles[(l2 * rl.z_size + j3) * rl.x_size + i3] & 255) != 0 {
										flag = false
									}
								} else {
									flag = false
								}
							}
						}
					}

					if flag {
						l2 = (j2 * rl.z_size + l1) * rl.x_size + k1
						if (rl.tiles[((j2 - 1) * rl.z_size + l1) * rl.x_size + k1] & 255) == 1 && j2 < rl.y_size - k2 - 1 {
							rl.tiles[l2 - 1 * rl.x_size * rl.z_size] = 3

							for i3_c := j2 - 3 + k2; i3_c <= j2 + k2; i3_c += 1 {
								j3_c := i3_c - (j2 + k2)
								k3 := int(1 - j3_c / 2)

								for l3 := k1 - k3; l3 <= k1 + k3; l3 += 1 {
									i4 := int(l3 - k1)

									for j4 := l1 - k3; j4 <= l1 + k3; j4 += 1 {
										k4 := int(j4 - l1)

										if (math.abs(i4) != k3 || math.abs(k4) != k3 || Random.next_int(mut rl.random, 2) != 0) && j3_c != 0 {
											rl.tiles[(i3_c * rl.z_size + j4) * rl.x_size + l3] = 14
										}
									}
								}
							}

							for i3_c := 0; i3_c < k2; i3_c += 1 {
								rl.tiles[l2 + i3_c * rl.x_size * rl.z_size] = 13
							}
						}
					}
				}
			}
		}
	}
}

fn RandomLevel.place_ore(mut rl &RandomLevel, tile int, j int, k int, _l int) {
	l := rl.x_size
	i1 := rl.z_size
	j1 := rl.y_size
	k1 := l * i1 * j1 / 256 / 64 * j / 100

	for l1 := 0; l1 < k1; l1 += 1 {
		rl.progress_percent = l1 * 100 / (k1 - 1) / 4 + k * 100 / 4
		// postMessage => rl.progress_percent

		mut f := Random.next_float(mut rl.random) * l
		mut f1 := Random.next_float(mut rl.random) * j1
		mut f2 := Random.next_float(mut rl.random) * i1
		i2 := int( ( (Random.next_float(mut rl.random) + Random.next_float(mut rl.random)) * 75.0 * j / 100.0) )
		mut f3 := (Random.next_float(mut rl.random) * math.pi * 2.0)
		mut f4 := 0.0
		mut f5 := (Random.next_float(mut rl.random) * math.pi * 2.0)
		mut f6 := 0.0

		for j2 := 0; j2 < i2; j2 += 1 {
			f = f32(f + math.sin(f3) * math.cos(f5))
			f2 = f32(f2 + math.cos(f3) * math.cos(f5))
			f1 = f32(f1 + math.sin(f5))
			f3 = f32(f3 + (f4 * 0.2))
			f4 = f32((f4 * 0.9) + (Random.next_float(mut rl.random) - Random.next_float(mut rl.random)))
			f5 = f32((f5 + f6 * 0.5) * 0.5)
			f6 = f32((f6 * 0.9) + (Random.next_float(mut rl.random) - Random.next_float(mut rl.random)))
			f7 := f32(math.sin(f32(j2) * math.pi / f32(i2)) * f32(j) / 100.0 + 1.0)

			for k2 := int(f - f7); k2 <= int(f + f7); k2 += 1 {
				for l2 := int(f1 - f7); l2 <= int(f1 + f7); l2 += 1 {
					for i3 := int(f2 - f7); i3 <= int(f2 + f7); i3 += 1 {
						f8 := f32(k2) - f
						f9 := f32(l2) - f1
						f10 := f32(i3) - f2

						if f8 * f8 + f9 * f9 * 2.0 + f10 * f10 < f7 * f7 && k2 >= 1 && l2 >= 1 && i3 >= 1 && k2 < rl.x_size - 1 && l2 < rl.y_size - 1 && i3 < rl.z_size - 1 {
							j3 := int( (l2 * rl.z_size + i3) * rl.x_size + k2 )

							//if (this.tiles[j3] == Tile.rock.id) {
							if rl.tiles[j3] == 2 {
								rl.tiles[j3] = tile
							}
						}
					}
				}
			}
		}
	}
}

fn RandomLevel.flood_fill(mut rl &RandomLevel, xc int, yc int, zc int, unused int, tile int) int {
	w_bits := 1
	h_bits := 1

	mut w_b := w_bits
	mut h_b := h_bits

	for (1 << w_b) < rl.x_size {
		w_b += 1
	}
	for (1 << h_b) < rl.y_size {
		h_b += 1
	}

	z_mask := rl.z_size - 1
	x_mask := rl.x_size - 1
	mut count := 1

	// note: if theres a problem with flood_fill in the future try to remove the u32 casts, i put them so the compiler wouldnt whine like a bitch :3 - ilax666
	// i do really HATE that part tho cuz i feel like theres a better way to do it TwT
	if rl.fill_queue.len == 0 {
		// og line was rl.fill_queue << ((yc << h_b) + zc << w_b) + xc
		rl.fill_queue << int(((u32(yc) << h_b) + u32(zc) << w_b)) + xc
	} else {
		// og line was rl.fill_queue[0] = ((yc << h_b) + zc << w_b) + xc
		rl.fill_queue[0] = int(((u32(yc) << h_b) + u32(zc) << w_b)) + xc
	}

	mut k2 := 0

	offset := rl.x_size * rl.z_size

	for count > 0 {
		count -= 1
		mut val := rl.fill_queue[count]

		z := (val >> w_b) & z_mask
		l2 := val >> (w_b + h_b)

		mut i3 := val & x_mask
		mut j3 := i3

		for i3 > 0 && rl.tiles[val - 1] == 0 {
			val -= 1
			i3 -= 1
		}

		for j3 < rl.x_size && rl.tiles[val + j3 - i3] == 0 {
			j3 += 1
		}

		k3 := (val >> w_b) & z_mask
		l3 := val >> (w_b + h_b)

		if k3 != z || l3 != l2 {
			println('hoooly fuck')
		}

		mut flag := false
		mut flag1 := false
		mut flag2 := false

		k2 += (j3 - i3)


		for i3 = i3; i3 < j3; i3++ {
			rl.tiles[val] = tile
			mut flag3 := false

			if z > 0 {
				flag3 = rl.tiles[val - rl.x_size] == 0
				if flag3 && !flag {
					rl.fill_queue << (val - rl.x_size)
				}

				flag = flag3
			}

			if z < rl.z_size - 1 {
				flag3 = rl.tiles[val + rl.x_size] == 0
				if flag3 && !flag1 {
					rl.fill_queue << (val + rl.x_size)
				}

				flag1 = flag3
			}

			if l2 > 0 {
				b2 := rl.tiles[val - offset]

				//if (( tile == Tile.lava.id || tile == Tile.calmLava.id) && (b2 == Tile.water.id || b2 == Tile.calmWater.id)) {
				if (tile == 17) && (b2 == 7) {
					rl.tiles[val - offset] = 2 // Tile.rock.id
				}

				flag3 = b2 == 0
				if flag3 && !flag2 {
					rl.fill_queue << (val - offset)
				}

				flag2 = flag3
			}

			val += 1
		}
	}

	return k2
}

fn RandomLevel.create_level(mut rl &RandomLevel, seed int, x_size int, z_size int, y_size int) {
	mut random := Random.new(seed);

	rl.x_size = x_size;
	rl.z_size = z_size;
	rl.y_size = 64;
	rl.random = random
	rl.this_random = Random.next_float(mut random);
	rl.tiles = [];
	rl.fill_queue = [];


	rl.progress_str = "Raising..";
	mut distort := Distort{PerlinNoise.new(rl.this_random, 8), PerlinNoise.new(rl.this_random, 8)}
	mut distort1 := Distort{PerlinNoise.new(rl.this_random, 8), PerlinNoise.new(rl.this_random, 8)}
	mut perlinnoise := PerlinNoise.new(rl.this_random, 8)
	mut aint := []int{}
	f := 1.3

	for l := 0; l < x_size; l += 1 {
		rl.progress_percent = l * 100 / (x_size - 1)
		// postMessage => rl.progress_percent

		for i1 := 0; i1 < z_size; i1 += 1 {
			d0 := Distort.get_value(&distort, f32(l * f), f32(i1 * f)) / 8.0 - 8.0
			mut d1 := Distort.get_value(&distort1, f32(l * f), f32(i1 * f)) / 6.0 + 6.0

			if PerlinNoise.get_value(perlinnoise, f32(l), f32(i1)) / 8.0 > 0.0 {
				d1 = d0
			}

			mut d2 := math.max(d0, d1) / 2.0
			if d2 < 0.0 {
				d2 *= 0.8
			}

			aint[l + i1 * x_size] = int(d2)
		}
	}


	rl.progress_str = "Eroding..";
	mut aint1 := aint.clone()

	distort1 = Distort{PerlinNoise.new(rl.this_random, 8), PerlinNoise.new(rl.this_random, 8)}
	distort2 := Distort{PerlinNoise.new(rl.this_random, 8), PerlinNoise.new(rl.this_random, 8)}

	for j1 := 0; j1 < x_size; j1 += 1 {
		rl.progress_percent = j1 * 100 / (x_size - 1)
		// postMessage => rl.progress_percent

		// note: same u32 bullshit as in flood_fill - fraise
		for k1 := 0; k1 < z_size; k1 += 1 {
			d3 := Distort.get_value(&distort1, f32(u32(j1) << 1), f32(u32(k1) << 1)) / 8.0

			l1 := if Distort.get_value(&distort2, f32(u32(j1) << 1), f32(u32(k1) << 1)) > 0.0 { 1 } else { 0 }
			if d3 > 2.0 {
				i2 := int(u32((aint1[j1 + k1 * x_size] - l1) / 2) << 1) + l1
				aint1[j1 + k1 * x_size] = i2
			}
		}
	}


	rl.progress_str = "Soiling..";
	aint1 = aint.clone()
	j2 := x_size
	mut k2 := z_size

	mut j1 := y_size
	perlinnoise1 := PerlinNoise.new(rl.this_random, 8)

	mut l2 := 0
	mut i3 := 0

	for l := 0; l < j2; l += 1 {
		rl.progress_percent = l * 100 / (x_size - 1)
		// postMessage => rl.progress_percent

		for i1 := 0; i1 < k2; i1 += 1 {
			l1 := (PerlinNoise.get_value(perlinnoise1, f32(l), f32(i1)) / 24.0) - 4.0
			i2 := aint1[l + i1 * j2] + j1 / 2
			l2 = int(f32(i2) + l1)
			aint1[l + i1 * j2] = math.max(i2, l2)

			for i3 = 0; i3 < j1; i3 += 1 {
				j3 := (i3 * z_size + i1) * x_size + l
				mut k3 := 0

				if i3 <= i2 {
					k3 = 3 // Tile.dirt.id
				}

				if i3 <= l2 {
					k3 = 2 // Tile.rock.id
				}

				rl.tiles[j3] = k3
			}
		}
	}


	rl.progress_str = "Carving..";

	k2 = rl.x_size
	j1 = rl.z_size
	mut k1 := rl.y_size
	mut l := k2 * j1 * k1 / 256 / 64

	for i1 := 0; i1 < l; i1 += 1 {
		rl.progress_percent = i1 * 100 / (l - 1) / 4
		// postMessage => rl.progress_percent

		mut f1 := Random.next_float(mut random) * k2
		mut f2 := Random.next_float(mut random) * k1
		mut f3 := Random.next_float(mut random) * j1

		i3 = int( ( (Random.next_float(mut random) + Random.next_float(mut random)) * 75.0) )
		mut f4 := (Random.next_float(mut random) * math.pi * 2.0)
		mut f5 := 0.0
		mut f6 := (Random.next_float(mut random) * math.pi * 2.0)
		mut f7 := 0.0

		for l3 := 0; l3 < i3; l3 += 1 {
			f1 = f32(f1 + math.sin(f4) * math.cos(f6))
			f3 = f32(f3 + math.cos(f4) * math.cos(f6))
			f2 = f32(f2 + math.sin(f6))
			f4 = f32(f4 + f5 * 0.2)
			f5 = f32((f5 * 0.9) + (Random.next_float(mut random) - Random.next_float(mut random)))
			f6 = f32((f6 + f7 * 0.5) * 0.5)
			f7 = f32((f7 * 0.9) + (Random.next_float(mut random) - Random.next_float(mut random)))

			if Random.next_float(mut random) >= 0.3 {
				f8 := f32(f1 + Random.next_float(mut random) * 4.0 - 2.0)
				f9 := f32(f2 + Random.next_float(mut random) * 4.0 - 2.0)
				f10 := f32(f3 + Random.next_float(mut random) * 4.0 - 2.0)
				f11 := f32(math.sin(f32(l3) * math.pi / f32(i3)) * 2.5 + 1.0)

				for i4 := int(f8 - f11); i4 <= int(f8 + f11); i4 += 1 {
					for j4 := int(f9 - f11); j4 <= int(f9 + f11); j4 += 1 {
						for k4 := int(f10 - f11); k4 <= int(f10 + f11); k4 += 1 {
							f12 := f32(i4) - f8
							f13 := f32(j4) - f9
							f14 := f32(k4) - f10

							if f12 * f12 + f13 * f13 * 2.0 + f14 * f14 < f11 * f11 && i4 >= 1 && j4 >= 1 && k4 >= 1 && i4 < x_size - 1 && j4 < y_size - 1 && k4 < z_size - 1 {
								l4 := (j4 * rl.z_size + k4) * rl.x_size + i4

								//if (tiles[l4] == Tile.rock.id) {
								if rl.tiles[l4] == 2 {
									rl.tiles[l4] = 0
								}
							}
						}
					}
				}
			}
		}
	}

	RandomLevel.place_ore(mut rl, 20, 90, 1, 4) // coal
	RandomLevel.place_ore(mut rl, 19, 70, 2, 4) // iron
	RandomLevel.place_ore(mut rl, 18, 50, 3, 4) // gold
}




fn main() {
	println('Hello World!')
}
