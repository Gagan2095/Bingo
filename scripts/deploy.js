const {ethers,upgrades} = require("hardhat");

async function main() {
    try {
        const Bingo = await ethers.getContractFactory("Bingo");
        console.log("Deploying Bingo...")
        const proxy = await upgrades.deployProxy(Bingo,["0xd98B590ebE0a3eD8C144170bA4122D402182976f"]);
        console.log("bingo deployed to:", proxy.address);
    } catch (e) {
        console.log(e.message)
    }
}

main();