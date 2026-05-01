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
