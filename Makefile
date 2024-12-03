-include .env

build:; forge build

deploy:; forge script script/DeployBestcrow.s.sol --rpc-url=${HOLESKY_RPC_URL} --private-key=${PRIVATE_KEY_1} --broadcast

verify:; forge verify-contract \
    0x8c2acF6Fb82305f19fbB3F60a53810b17df9BC9B \
    src/Bestcrow.sol:Bestcrow \
    --chain-id 17000 \

escrow-view:; cast call --rpc-url=${HOLESKY_RPC_URL} 0x8c2acF6Fb82305f19fbB3F60a53810b17df9BC9B "escrowDetails(uint256)(address,address,address,uint256,uint256,bool,bool,bool,bool)" $(escrowId)

escrow-create:; cast send --json --value=1005000000000000 --private-key=${PRIVATE_KEY_1} --rpc-url=${HOLESKY_RPC_URL} 0x8c2acF6Fb82305f19fbB3F60a53810b17df9BC9B "createEscrow(address,uint256,uint256,address)(uint256)" 0x0000000000000000000000000000000000000000 1000000000000000 1733191757 0x080B254104902A4621abe24A494441Df6260ebb1

escrow-accept:; cast send --value=1005000000000000 --private-key=${PRIVATE_KEY_2} --rpc-url=${HOLESKY_RPC_URL} 0x8c2acF6Fb82305f19fbB3F60a53810b17df9BC9B "acceptEscrow(uint256)" 4

escrow-e2e:; make escrow-create escrow-accept escrow-request escrow-approve escrow-withdraw