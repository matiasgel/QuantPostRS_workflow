var("b")

Dxi = [SR.var("Dxi_%d" % mu) for mu in range(4)]
residue = [expand(b * Dxi[mu] - b * Dxi[mu]) for mu in range(4)]

print("CLAIM-0001 SageMath residue:")
print(residue)

if any(component != 0 for component in residue):
    raise RuntimeError("CLAIM-0001 TESTED_FAIL: non-zero SageMath residue")

print("CLAIM-0001 SageMath result: PASS")
