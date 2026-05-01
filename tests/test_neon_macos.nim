when defined(macosx) and defined(arm64):
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
else:
  echo "Skipping macOS NEON pointer test"
