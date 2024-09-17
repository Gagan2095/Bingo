const {ethers,upgrades} = require("hardhat");

async function main() {
    try {
        const Bingo = await ethers.getContractFactory("Bingo");
        console.log("Deploying Bingo...")
        const proxy = await upgrades.deployProxy(Bingo,["0xCFeE20fb1D3F342b1A67C7e522A3492D6b2Cc835"]);
        console.log("bingo deployed to:", await proxy.getAddress());
    } catch (e) {
        console.log(e.message)
    }
}

main();