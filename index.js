const { ethers } = require("hardhat");

(async () => {
    const Bingo = await ethers.getContractFactory('Bingo');
    const bingo = await Bingo.attach('0x5fbdb2315678afecb367f032d93f642f64180aa3');
    
    // Use callStatic to simulate the function call and get the return value
    await bingo.createGame(4, 10, 600, 10);
    const result = await bingo.startGame(1n);
    console.log(result)
})();
