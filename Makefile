-include .env

build:; forge build --root contracts

deploy:; forge script contracts/script/DeployBestcrow.s.sol:DeployBestcrow --rpc-url=${HOLESKY_RPC_URL} --private-key=${PRIVATE_KEY_ADMIN} --broadcast --root contracts

verify:; forge verify-contract \
    0xB133765B8beCaf440bAD4f4534a6Dc4BbE87234A \
    src/Bestcrow.sol:Bestcrow \
    --chain-id 17000 \
    --compiler-version 0.8.24 \
    --verifier-url https://api-holesky.etherscan.io/api \
    --etherscan-api-key ${ETHERSCAN_API_KEY} \
    --root contracts

escrow-view:; cast call --rpc-url=${HOLESKY_RPC_URL} 0xB133765B8beCaf440bAD4f4534a6Dc4BbE87234A "escrowDetails(uint256)(address,address,address,uint256,uint256,bool,bool,bool,bool)" 4

escrow-next-id:; cast call --rpc-url=${HOLESKY_RPC_URL} 0xB133765B8beCaf440bAD4f4534a6Dc4BbE87234A "nextEscrowId()(uint256)"

escrow-get-depositor:; cast call --rpc-url=${HOLESKY_RPC_URL} 0xB133765B8beCaf440bAD4f4534a6Dc4BbE87234A "getEscrowDepositor(uint256)(address)" 1


escrow-m-create:; cast send --json --value=1005000000000000 --private-key=${PRIVATE_KEY_1} --rpc-url=${HOLESKY_RPC_URL} 0xB133765B8beCaf440bAD4f4534a6Dc4BbE87234A "createEscrow(address,uint256,uint256,address)(uint256)" 0x0000000000000000000000000000000000000000 1000000000000000 $$(( $$(date +%s) + 86400 )) ${DEV_2}

escrow-m-accept:; cast send --value=500000000000000 --private-key=${PRIVATE_KEY_2} --rpc-url=${HOLESKY_RPC_URL} 0xB133765B8beCaf440bAD4f4534a6Dc4BbE87234A "acceptEscrow(uint256)" 9

escrow-m-request:; cast send --private-key=${PRIVATE_KEY_2} --rpc-url=${HOLESKY_RPC_URL} 0xB133765B8beCaf440bAD4f4534a6Dc4BbE87234A "requestRelease(uint256)" 9

escrow-m-approve:; cast send --private-key=${PRIVATE_KEY_1} --rpc-url=${HOLESKY_RPC_URL} 0xB133765B8beCaf440bAD4f4534a6Dc4BbE87234A "approveRelease(uint256)" 9

escrow-m-withdraw:; cast send --private-key=${PRIVATE_KEY_ADMIN} --rpc-url=${HOLESKY_RPC_URL} 0xB133765B8beCaf440bAD4f4534a6Dc4BbE87234A "withdrawFees(address)" 0x0000000000000000000000000000000000000000

escrow-m-refund:; cast send --private-key=${PRIVATE_KEY_1} --rpc-url=${HOLESKY_RPC_URL} 0xB133765B8beCaf440bAD4f4534a6Dc4BbE87234A "refundExpiredEscrow(uint256)" 2

 
escrow-create:; cast send --json --value=1005000000000000 --private-key=${PRIVATE_KEY_1} --rpc-url=${HOLESKY_RPC_URL} 0xB133765B8beCaf440bAD4f4534a6Dc4BbE87234A "createEscrow(address,uint256,uint256,address)(uint256)" 0x0000000000000000000000000000000000000000 1000000000000000 $$(( $$(date +%s) + 86400 )) ${DEV_2} | jq -r '.logs[0].topics[1]' | cast --to-dec > .escrow-id

escrow-accept:; cast send --value=500000000000000 --private-key=${PRIVATE_KEY_2} --rpc-url=${HOLESKY_RPC_URL} 0xB133765B8beCaf440bAD4f4534a6Dc4BbE87234A "acceptEscrow(uint256)" $$(cat .escrow-id)

escrow-request:; cast send --private-key=${PRIVATE_KEY_2} --rpc-url=${HOLESKY_RPC_URL} 0xB133765B8beCaf440bAD4f4534a6Dc4BbE87234A "requestRelease(uint256)" $$(cat .escrow-id)

escrow-approve:; cast send --private-key=${PRIVATE_KEY_1} --rpc-url=${HOLESKY_RPC_URL} 0xB133765B8beCaf440bAD4f4534a6Dc4BbE87234A "approveRelease(uint256)" $$(cat .escrow-id)

escrow-withdraw:; cast send --private-key=${PRIVATE_KEY_ADMIN} --rpc-url=${HOLESKY_RPC_URL} 0xB133765B8beCaf440bAD4f4534a6Dc4BbE87234A "withdrawFees(address)" 0x0000000000000000000000000000000000000000

escrow-e2e:; make escrow-create && sleep 5 && make escrow-accept && sleep 5 && make escrow-request && sleep 5 && make escrow-approve && sleep 5 && make escrow-withdraw

escrow-e2e-active:; make escrow-create && sleep 5 && make escrow-accept

escrow-e2e-request:; make escrow-create && sleep 5 && make escrow-accept && sleep 5 && make escrow-request


escrow-r-create:; cast send --json --value=1005000000000000 --private-key=${PRIVATE_KEY_1} --rpc-url=${HOLESKY_RPC_URL} 0xB133765B8beCaf440bAD4f4534a6Dc4BbE87234A "createEscrow(address,uint256,uint256,address)(uint256)" 0x0000000000000000000000000000000000000000 1000000000000000 $$(( $$(date +%s) + 60 )) ${DEV_2} | jq -r '.logs[0].topics[1]' | cast --to-dec > .escrow-id

escrow-r-refund:; cast send --private-key=${PRIVATE_KEY_1} --rpc-url=${HOLESKY_RPC_URL} 0xB133765B8beCaf440bAD4f4534a6Dc4BbE87234A "refundExpiredEscrow(uint256)" $$(cat .escrow-id)

escrow-r-e2e:; make escrow-r-create && sleep 70 && make escrow-r-refund


escrow-ca:; make escrow-create && cat .escrow-id && sleep 5 && make escrow-accept