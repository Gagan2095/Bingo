//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import "./IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Bingo is Initializable{
    /*
    turnDuration - minimum time to drawn number
    startDuration - timer to start the game
    winningPrice - winner price money
    entryFee - minimum entry fees for player to join the game
    playersLimit - keep track of how many player can join the game
    owner - creator of the game
    winner - winner of the game (initially zero address)
    generetedNumber - number which are already generated in the game
    */
    struct GameInfo {
        uint256 startDuration;
        uint8 turnDuration;
        uint8 winningPrice;
        uint8 entryFee;
        uint8 playersLimit;
        uint8 generatedNumber;
        address owner;
        address winner;
    }
    mapping(uint8 gameId => GameInfo) public games;
    mapping(uint8 gameId => mapping(address user => uint8[5][5] board)) public boards;
    mapping(uint8 gameId => mapping(address user => uint8[5][5] board)) public drawnBoards;
    mapping(uint8 gameId => mapping(address => bool)) public players;
    mapping(address creator => uint8 gameId) public creatorGame;

    uint8 private gameIndex;
    address private owner;

    IERC20 erc20;

    error InsufficientFund();
    error Unauthorized(address);
    error GameAlreadyStarted();
    error ZeroUserFound();

    /// @notice open zeppelin initializer function for transparent proxy
    function initialize(
        address erc20Address
    ) public payable initializer {
        erc20 = IERC20(erc20Address);
        gameIndex = 0;
        owner = msg.sender;
    }

    /// @notice create a new game and add in "games" mapping
    function createGame(
        uint8 _noOfUsers,
        uint8 _entryFee,
        uint256 _startDuration,
        uint8 _turnDuration
    ) public {
        if (_noOfUsers <= 0) 
            revert ZeroUserFound();
        else {
            gameIndex++;
            GameInfo memory game = GameInfo(
                block.timestamp + _startDuration,
                _turnDuration,
                0,
                _entryFee,
                _noOfUsers,
                0,
                msg.sender,
                address(0)
            );
            games[gameIndex] = game;
            creatorGame[msg.sender] = gameIndex;
        }
    }

    /// @notice update the entry fees of any game. Can only be access by owner of a game
    function updatefee(uint8 gameId, uint8 _fee) public  {
        if (games[gameId].owner != msg.sender) revert Unauthorized(msg.sender);
        games[gameId].entryFee = _fee;
    }

    /// @notice update the turn duration of any game. Can only be access by owner of a game
    function updateTurnDuration(uint8 gameId, uint8 duration) public {
        if (games[gameId].owner != msg.sender) revert Unauthorized(msg.sender);
        games[gameId].turnDuration = duration;
    }

    /// @notice update the start duration of any game. Can only be access by owner of a game
    function updateStartDuration(uint8 gameId, uint8 duration) public {
        if (games[gameId].owner != msg.sender) revert Unauthorized(msg.sender);
        games[gameId].startDuration = block.timestamp + duration;
    }

    /// @notice any user can join a game using the _gameId.
    function joinGame(uint8 _gameId) public {
        if (games[_gameId].startDuration > block.timestamp) {
            if (erc20.allowance(msg.sender,address(this)) < games[_gameId].entryFee) 
                revert InsufficientFund();
            else {
                erc20.transferFrom(msg.sender,address(this), games[_gameId].entryFee);
                games[_gameId].winningPrice += 10;
                for (uint256 j = 0; j < 5; j++) {
                    for (uint256 k = 0; k < 5; k++) {
                        if (j == 2 && k == 2)
                            boards[_gameId][msg.sender][j][k] = 100;
                        else{
                            boards[_gameId][msg.sender][j][k] = uint8(uint(keccak256(abi.encodePacked(block.timestamp,msg.sender))) %51);
                        }
                    }
                }
            }
            players[_gameId][msg.sender] = true;
        } else {
            revert GameAlreadyStarted();
        }
    }

    /// @notice generates a random number for difference games
    function generateRandomNumber(
        uint8 _gameId
    ) public{
        uint8 num = uint8(uint(
            keccak256(abi.encodePacked(block.timestamp, msg.sender))
        ) % 51);
        games[_gameId].generatedNumber = num;
    }

    /// @notice updates the drawnBoard of a user by the provided number. This will keep track of drawned number of any user in drawnBoards mapping.
    function drawnNumber(
        uint8 _gameId,
        uint8 _number
    ) public {
        if (!players[_gameId][msg.sender])
            revert Unauthorized(msg.sender);
        uint itr1 = 0;
        uint itr2 = 0;
        for (uint i = 0; i < 5; i++) {
            for (uint j = 0; j < 5; j++) {
                if (boards[_gameId][msg.sender][i][j] == _number) {
                    drawnBoards[_gameId][msg.sender][i][j] = 100;
                    itr1 = i;
                    itr2 = j;
                }
            }
        }
    }

    /// @notice returns a boolean value, whether game started or not.
    function isGameStarted(uint8 _gameId) public view returns (bool) {
        return games[_gameId].owner!=address(0) && block.timestamp >= games[_gameId].startDuration;
    }

    /// @notice user check whether it becomes the winner of the game or not.
    function checkWinner(uint8 _gameId) public returns(bool) {
        //checking rows
        uint8 row = 0;
        for(uint i = 0;i<drawnBoards[_gameId][msg.sender].length;i++) {
            bool temp_ = true;
            for(uint j = 0;j<drawnBoards[_gameId][msg.sender].length;j++) {
                if(drawnBoards[_gameId][msg.sender][i][j]!=100){
                    temp_ = false;
                    break;
                }
            }
            if(temp_) row++;
        }
        //checking column
        uint8 col = 0;
        for (uint256 i = 0; i < drawnBoards[_gameId][msg.sender].length; i++) {
            bool temp_ = true;
            for(uint j = 0;j<drawnBoards[_gameId][msg.sender].length;j++) {
                if(drawnBoards[_gameId][msg.sender][j][i]!=100){
                    temp_ = false;
                    break;
                }
            }
            if(temp_) col++;
        }
        //checking diagonal
        uint8 diagonal = 0;
        bool temp = true;
        for (uint256 i = 0; i < drawnBoards[_gameId][msg.sender].length; i++) {
            if(drawnBoards[_gameId][msg.sender][i][i]!=100){
                temp = false;
                break;
            }
        }
        if(temp) diagonal++;
        temp = true;
        for (uint256 i = drawnBoards[_gameId][msg.sender].length-1; i>=0; i++) {
            if(drawnBoards[_gameId][msg.sender][drawnBoards[_gameId][msg.sender].length-1-i][i]!=100){
                temp = false;
                break;
            }
        }
        if(temp) diagonal++;
        if(row+col+diagonal>=5) {
            erc20.transfer(msg.sender, games[_gameId].winningPrice);
            return true;
        }
        else return false;
    }
}