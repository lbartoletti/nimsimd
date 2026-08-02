when defined(amd64):
  import nimsimd/sse42, nimsimd/runtimecheck

  let
    a = mm_set1_ps(1.0)
    b = mm_set1_ps(2.0)
    c = mm_mul_ps(a, b)

  doAssert cast[array[4, float32]](c) == [2.0.float32, 2.0, 2.0, 2.0]

  echo checkInstructionSets({SSE3})
elif defined(macosx) and defined(arm64):
  import nimsimd/neon

  var
    input: array[16, uint8]
    output: array[16, uint8]

  for i in 0 ..< input.len:
    input[i] = uint8(i + 1)

  let bytes = vld1q_u8(input[0].addr)
  vst1q_u8(output[0].addr, bytes)

  doAssert output == input, "NEON load and store should preserve bytes."

  echo "macOS NEON pointer test passed"

  block: # vzip2q
    var
      lo = [1'u32, 2, 3, 4]
      hi = [5'u32, 6, 7, 8]
    let
      va = vld1q_u32(lo[0].addr)
      vb = vld1q_u32(hi[0].addr)
    doAssert cast[array[4, uint32]](vzip1q_u32(va, vb)) == [1'u32, 5, 2, 6]
    doAssert cast[array[4, uint32]](vzip2q_u32(va, vb)) == [3'u32, 7, 4, 8]

  block: # vrev32q_u16 swaps 16-bit halves inside each 32-bit lane (ror 16)
    var x = [0x11223344'u32, 0xAABBCCDD'u32, 0, 0]
    let v = vreinterpretq_u32_u16(vrev32q_u16(vreinterpretq_u16_u32(
      vld1q_u32(x[0].addr))))
    doAssert cast[array[4, uint32]](v)[0] == 0x33441122'u32
    doAssert cast[array[4, uint32]](v)[1] == 0xCCDDAABB'u32

  block: # vsriq_n: shift right + insert, combined with vshlq_n gives ror
    var x = [0x80000001'u32, 0, 0, 0]
    let v = vld1q_u32(x[0].addr)
    # rotate right by 12
    let r = vsriq_n_u32(vshlq_n_u32(v, 20), v, 12)
    doAssert cast[array[4, uint32]](r)[0] ==
      ((0x80000001'u32 shr 12) or (0x80000001'u32 shl 20))

  block: # vrev32q_u8 byte-swaps each 32-bit lane
    var x = [0x11223344'u32, 0, 0, 0]
    let v = vreinterpretq_u32_u8(vrev32q_u8(vreinterpretq_u8_u32(
      vld1q_u32(x[0].addr))))
    doAssert cast[array[4, uint32]](v)[0] == 0x44332211'u32

  block: # vqtbl4q_u8 gathers across a 64-byte table
    var table: array[64, uint8]
    for i in 0 ..< 64:
      table[i] = uint8(i * 2)
    var t: uint8x16x4
    t.val[0] = vld1q_u8(table[0].addr)
    t.val[1] = vld1q_u8(table[16].addr)
    t.val[2] = vld1q_u8(table[32].addr)
    t.val[3] = vld1q_u8(table[48].addr)
    var idx: array[16, uint8] = [0'u8, 17, 34, 51, 63, 48, 32, 16,
                                 1, 2, 3, 4, 60, 61, 62, 63]
    let r = vqtbl4q_u8(t, vld1q_u8(idx[0].addr))
    var got: array[16, uint8]
    vst1q_u8(got[0].addr, r)
    for i in 0 ..< 16:
      doAssert got[i] == table[idx[i]], "vqtbl4q_u8 lane " & $i

  block: # vdupq_n_u32 broadcasts a scalar to all lanes
    var got: array[4, uint32]
    vst1q_u32(got[0].addr, vdupq_n_u32(0xABCD1234'u32))
    for v in got:
      doAssert v == 0xABCD1234'u32, "vdupq_n_u32"

  block: # vcvtq_f32_u32 / vcvtq_u32_f32 round-trip
    let back = vcvtq_u32_f32(vcvtq_f32_u32(vdupq_n_u32(42'u32)))
    var got: array[4, uint32]
    vst1q_u32(got[0].addr, back)
    for v in got:
      doAssert v == 42'u32, "vcvtq u32<->f32 round-trip"

  echo "macOS NEON zip2/rev32/sri/tbl4 tests passed"
