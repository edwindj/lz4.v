module lz4

import os

fn test_compress()?{
	data := "
	Aap
	Aap
	Aap
	Aap
	Aap
	Aap
	Noot
	Noot
	Noot
	".bytes()

	compressed := compress(data)?

	// println(compressed)
	mut f := os.create("test.txt.lz4")?
	f.write(compressed)?
	f.close()

	// println("compressed.len: ${compressed.len}, data.len: ${data.len}")

	org := decompress(compressed)?
	assert(org == data)

}