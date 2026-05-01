import nimsimd/runtimecheck

when defined(amd64):
  import nimsimd/sse42

  let
    a = mm_set1_ps(1.0)
    b = mm_set1_ps(2.0)
    c = mm_mul_ps(a, b)

  doAssert cast[array[4, float32]](c) == [2.0.float32, 2.0, 2.0, 2.0]

  echo checkInstructionSets({SSE3})
elif defined(arm64):
  doAssert checkInstructionSets({NEON})
  doAssert not checkInstructionSets({SSE3})

  echo checkInstructionSets({NEON})
else:
  doAssert not checkInstructionSets({SSE3})

  echo checkInstructionSets({})
