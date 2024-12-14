const { expect } = require("chai");
const {loadFixture} = require('@nomicfoundation/hardhat-network-helpers')
describe("Bingo", function () {
    async function deploy() {
        const [owner,addr1,addr2] = await ethers.getSigners();
        const Bingo = await ethers.getContractFactory("Bingo");
        const ERC20TOKEN = await ethers.getContractFactory("ERC20TOKEN");
        const erc20 = await ERC20TOKEN.deploy(owner.address);
        const bingo = await Bingo.deploy(erc20.getAddress());
        await erc20.transfer(addr1.address, 100);
        await erc20.transfer(addr2.address, 100);
        return {owner,addr1,addr2,bingo,erc20}
    }
    it("Should create a game", async function () {
        const {bingo,owner} = await loadFixture(deploy);
        await bingo.createGame(3, 10, 1000, 5);
        const gameId = await bingo.creatorGame(owner.address);
        const game = await bingo.games(gameId);
        expect(game.playersLimit).to.equal(3);
        expect(game.entryFee).to.equal(10);
        expect(game.owner).to.equal(owner.address);
    });
    it("Should update entry fee", async function () {
        const {bingo,owner} = await loadFixture(deploy);
        await bingo.createGame(3, 10, 1000, 5);
        const gameId = await bingo.creatorGame(owner.address);
        await bingo.updatefee(gameId, 15);
        const game = await bingo.games(gameId);
        expect(game.entryFee).to.equal(15);
    });
    it("Should update turn duration", async function () {
        const {bingo,owner} = await loadFixture(deploy);
        await bingo.createGame(3, 10, 1000, 5);
        const gameId = await bingo.creatorGame(owner.address);
        await bingo.updateTurnDuration(gameId, 10);
        const game = await bingo.games(gameId);
        expect(game.turnDuration).to.equal(10);
    });
    it("Should update start duration", async function () {
        const {bingo,owner} = await loadFixture(deploy);
        await bingo.createGame(3, 10, 120, 5);
        const gameId = await bingo.creatorGame(owner.address);
        await bingo.updateStartDuration(gameId, 200);
        const game = await bingo.games(gameId);
        expect(game.startDuration).to.be.closeTo((await ethers.provider.getBlock('latest')).timestamp + 200, 1);
    });
    it("Should allow a player to join a game", async function () {
        const {bingo,owner,addr1,erc20} = await loadFixture(deploy);
        await bingo.createGame(3, 10, 120, 5);
        const gameId = await bingo.creatorGame(owner.address);
        await erc20.connect(addr1).approve(bingo.getAddress(), 10);
        await bingo.connect(addr1).joinGame(gameId);
        const playerExists = await bingo.players(gameId, addr1.address);
        expect(playerExists).to.be.true;
        const board = await bingo.boards(gameId, addr1.address,0,0);
        expect(board).to.not.equal(0);
    });
        
    it("Should generate a random number", async function () {
        const {bingo,owner} = await loadFixture(deploy);
        await bingo.createGame(3, 10, 120, 5);
        const gameId = await bingo.creatorGame(owner.address);
        const randomNum = await bingo.generateRandomNumber(gameId);
        expect(randomNum).to.not.equal(0);
    });
    it("Should draw a number on the player's board", async function () {
        const {owner,addr1,bingo,erc20} = await loadFixture(deploy)
        await bingo.createGame(3, 10, 1000, 5);
        const gameId = await bingo.creatorGame(owner.address);
        await erc20.connect(addr1).approve(bingo.getAddress(), 10);
        await bingo.connect(addr1).joinGame(gameId);
        await bingo.generateRandomNumber(gameId);
        const game = await bingo.games(gameId);
        const result = await bingo.connect(addr1).drawnNumber(gameId, game.generatedNumber);
    });
    it.skip("Should correctly identify the winner", async function () {
        const {owner,addr1,bingo,erc20} = await loadFixture(deploy)
        await bingo.createGame(3, 10, 120, 5);
        const gameId = await bingo.creatorGame(owner.address);
        await erc20.connect(addr1).approve(bingo.getAddress(), 10);
        await bingo.connect(addr1).joinGame(gameId);
        const board = await bingo.boards(gameId, addr1.address);
        for (let i = 0; i < 5; i++) {
            await bingo.connect(addr1).drawnNumber(gameId, board[i][i]); // draw diagonal numbers
        }
        const isWinner = await bingo.connect(addr1).checkWinner(gameId);
        expect(isWinner).to.be.true;
    });
    it("Should revert if an unauthorized user tries to update game settings", async function () {
        const {owner,addr1,bingo} = await loadFixture(deploy)
        await bingo.createGame(3, 10, 1000, 5);
        const gameId = await bingo.creatorGame(owner.address);
        await expect(bingo.connect(addr1).updatefee(gameId, 15)).to.be.revertedWithCustomError(bingo,"Unauthorized").withArgs(addr1);
        await expect(bingo.connect(addr1).updateTurnDuration(gameId, 10)).to.be.revertedWithCustomError(bingo,"Unauthorized").withArgs(addr1);
        await expect(bingo.connect(addr1).updateStartDuration(gameId, 200)).to.be.revertedWithCustomError(bingo,"Unauthorized").withArgs(addr1);
    });
    it("Should revert if a player tries to join a started game", async function () {
        const {owner,addr1,bingo} = await loadFixture(deploy)
        await bingo.createGame(3, 10, 1, 5);
        const gameId = await bingo.creatorGame(owner.address);
        // Fast forward time to simulate the game starting
        await ethers.provider.send("evm_increaseTime", [2]);
        await ethers.provider.send("evm_mine", []);
        await expect(bingo.connect(addr1).joinGame(gameId)).to.be.revertedWithCustomError(bingo,"GameAlreadyStarted");
    });
    it("Should revert if a player doesn't have enough funds to join a game", async function () {
        const {owner,addr1,bingo,erc20} = await loadFixture(deploy)
        await bingo.createGame(3, 10, 1000, 5);
        const gameId = await bingo.creatorGame(owner.address);
        await erc20.connect(addr1).approve(bingo.getAddress(), 5); // Not enough funds
        await expect(bingo.connect(addr1).joinGame(gameId)).to.be.revertedWithCustomError(bingo,"InsufficientFund");
    });
});