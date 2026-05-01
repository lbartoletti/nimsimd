type
  InstructionSet* = enum
    SSE3
    SSSE3
    SSE41
    SSE42
    AVX
    AVX2
    PCLMULQDQ
    SHA
    AES
    CMPXCHG16B
    F16C
    BMI1
    BMI2
    NEON

when defined(amd64):
  ## https://www.felixcloutier.com/x86/cpuid

  type
    InstructionSetCheckInfo = object
      leaf, register, bit: int

  const CheckInfos = [
    InstructionSetCheckInfo(leaf: 1, register: 2, bit: 0), # SSE3
    InstructionSetCheckInfo(leaf: 1, register: 2, bit: 9), # SSSE3
    InstructionSetCheckInfo(leaf: 1, register: 2, bit: 19), # SSE41
    InstructionSetCheckInfo(leaf: 1, register: 2, bit: 20), # SSE42
    InstructionSetCheckInfo(leaf: 1, register: 2, bit: 28), # AVX
    InstructionSetCheckInfo(leaf: 7, register: 1, bit: 5), # AVX2
    InstructionSetCheckInfo(leaf: 1, register: 2, bit: 1), # PCLMULQDQ
    InstructionSetCheckInfo(leaf: 7, register: 1, bit: 29), # SHA
    InstructionSetCheckInfo(leaf: 1, register: 2, bit: 25), # AES
    InstructionSetCheckInfo(leaf: 1, register: 2, bit: 13), # CMPXCHG16B
    InstructionSetCheckInfo(leaf: 1, register: 2, bit: 29), # F16C
    InstructionSetCheckInfo(leaf: 7, register: 1, bit: 3), # BMI1
    InstructionSetCheckInfo(leaf: 7, register: 1, bit: 8), # BMI2
  ]

  proc cpuid(eaxi, ecxi: int32): array[4, int32] = # eax, ebx, ecx, edx
    ## Returns x86 CPUID registers for the requested leaf.
    when defined(vcc):
      proc cpuid(cpuInfo: ptr int32, functionId, subFunctionId: int32)
        {.cdecl, importc: "__cpuidex", header: "intrin.h".}
      cpuid(cast[ptr int32](result.addr), eaxi, ecxi)
    else:
      var (eaxr, ebxr, ecxr, edxr) = (0'i32, 0'i32, 0'i32, 0'i32)
      asm """
        cpuid
        :"=a"(`eaxr`), "=b"(`ebxr`), "=c"(`ecxr`), "=d"(`edxr`)
        :"a"(`eaxi`), "c"(`ecxi`)"""
      [eaxr, ebxr, ecxr, edxr]

  proc checkInstructionSets*(instructionSets: set[InstructionSet]): bool =
    ## Returns true if all requested instruction sets are available.
    result = true

    let
      leaf1 = cpuid(1, 0)
      leaf7 = cpuid(7, 0)

    for instructionSet in instructionSets:
      if instructionSet == NEON:
        return false

      let checkInfo = CheckInfos[instructionSet.ord]
      if checkInfo.leaf == 1:
        if (leaf1[checkInfo.register] and (1 shl checkInfo.bit)) == 0:
          return false
      else:
        if (leaf7[checkInfo.register] and (1 shl checkInfo.bit)) == 0:
          return false

elif defined(arm64):
  proc checkInstructionSets*(instructionSets: set[InstructionSet]): bool =
    ## Returns true if all requested instruction sets are available.
    result = true

    for instructionSet in instructionSets:
      case instructionSet
      of NEON:
        discard
      else:
        return false

else:
  proc checkInstructionSets*(instructionSets: set[InstructionSet]): bool =
    ## Returns true if all requested instruction sets are available.
    result = true

    for instructionSet in instructionSets:
      return false
