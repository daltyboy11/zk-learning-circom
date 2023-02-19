SHELL = zsh

circuit = threecoloring

circom = $(circuit).circom
r1cs = $(circuit).r1cs
wasm = $(circuit)_js/$(circuit).wasm
wit_gen = $(circuit)_js/generate_witness.js
compile_outputs = $(circuit)_js/witness_calculator.js $(r1cs) $(wasm) $(wit_gen)
pk = $(circuit).pk
vk = $(circuit).vk
ptau = $(circuit).ptau
keys = $(pk) $(vk)
p_input = $(circuit).input.json
wit = $(circuit).wtns
pf = $(circuit).pf.json
inst = $(circuit).inst.json
prove_outputs = $(pf) $(inst)

all: verify

$(compile_outputs): $(circom)
	circom $< --r1cs --wasm

$(ptau):
	npx snarkjs powersoftau new bn128 12 tmp.ptau
	npx snarkjs powersoftau prepare phase2 tmp.ptau $(ptau)
	rm tmp.ptau

$(keys): $(ptau) $(r1cs)
	npx snarkjs groth16 setup $(r1cs) $(ptau) $(pk)
	npx snarkjs zkey export verificationkey $(pk) $(vk)

$(wit): $(p_input) $(wasm) $(wit_gen)
	node $(wit_gen) $(wasm) $(p_input) $@

$(prove_outputs): $(wit) $(pk)
	npx snarkjs groth16 prove $(pk) $(wit) $(pf) $(inst)

.PHONY = verify clean

verify: $(pf) $(inst) $(vk)
	npx snarkjs groth16 verify $(vk) $(inst) $(pf)

clean:
	rm -f $(compile_outputs) $(ptau) $(keys) $(wit) $(prove_outputs)
	rmdir $(circuit)_js
