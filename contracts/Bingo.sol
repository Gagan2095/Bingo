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

    /// @notice Stores game information using gameId as the key
    /// @dev Maps a uint8 gameId to the GameInfo struct
    mapping(uint8 gameId => GameInfo) public games;

    /// @notice Stores the player's bingo board for each game
    /// @dev Maps a uint8 gameId and an address (user) to a 5x5 uint8 board for the game
    mapping(uint8 gameId => mapping(address user => uint8[5][5] board)) public boards;

    /// @notice Stores the numbers that have been drawn for each player in a specific game
    /// @dev Maps a uint8 gameId and an address (user) to a 5x5 uint8 drawn board
    mapping(uint8 gameId => mapping(address user => uint8[5][5] board)) public drawnBoards;

    /// @notice Keeps track of the players who have joined a game
    /// @dev Maps a uint8 gameId and an address to a boolean indicating if the player is in the game
    mapping(uint8 gameId => mapping(address => bool)) public players;

    /// @notice Stores the gameId created by each user
    /// @dev Maps an address (creator) to the uint8 gameId that the user created
    mapping(address creator => uint8 gameId) public creatorGame;

    uint8 private gameIndex;
    address private owner;

    IERC20 erc20;


    /// @notice Thrown when the funds provided are insufficient for the operation
    error InsufficientFund();

    /// @notice Thrown when an unauthorized user tries to perform an action
    /// @param user The address of the unauthorized user
    error Unauthorized(address user);

    /// @notice Thrown when attempting to start a game that has already started
    error GameAlreadyStarted();

    /// @notice Thrown when a zero or invalid user is found in the operation
    error ZeroUserFound();

    modifier checkUsers(uint8 _noOfUsers) {
        if (_noOfUsers <= 0) 
            revert ZeroUserFound();
        _;
    }

    modifier checkAuthorization(uint8 gameId) {
        if (games[gameId].owner != msg.sender) 
            revert Unauthorized(msg.sender);
        _;
    }

    /// @notice open zeppelin initializer function for transparent proxy
    /// @param erc20Address The address of the ERC20 token contract
    function initialize(
        address erc20Address
    ) public payable initializer {
        erc20 = IERC20(erc20Address);
        gameIndex = 0;
        owner = msg.sender;
    }

    /// @notice create a new game and add in "games" mapping
    /// @param _noOfUsers The number of users that can join the game
    /// @param _entryFee The entry fee for players to join the game
    /// @param _startDuration The time (in seconds) before the game starts
    /// @param _turnDuration The duration of each turn in the game
    function createGame(
        uint8 _noOfUsers,
        uint8 _entryFee,
        uint256 _startDuration,
        uint8 _turnDuration
    ) external checkUsers(_noOfUsers){
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

    /// @notice update the entry fees of any game. Can only be access by owner of a game
    /// @param gameId The ID of the game to update
    /// @param _fee The new entry fee for the game
    function updatefee(uint8 gameId, uint8 _fee) public  checkAuthorization(gameId){
        games[gameId].entryFee = _fee;
    }

    /// @notice update the turn duration of any game. Can only be access by owner of a game
    /// @param gameId The ID of the game to update
    /// @param duration The new turn duration in seconds
    function updateTurnDuration(uint8 gameId, uint8 duration) public checkAuthorization(gameId){
        games[gameId].turnDuration = duration;
    }

    /// @notice update the start duration of any game. Can only be access by owner of a game
    /// @param gameId The ID of the game to update
    /// @param duration The new start duration in seconds
    function updateStartDuration(uint8 gameId, uint8 duration) public checkAuthorization(gameId){
        games[gameId].startDuration = block.timestamp + duration;
    }

    /// @notice any user can join a game using the _gameId.
    /// @param _gameId The ID of the game to join
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
                            boards[_gameId][msg.sender][j][k] = uint8(uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,j,k))) %50) + 1;
                        }
                    }
                }
                drawnBoards[_gameId][msg.sender][2][2] = 100;
            }
            players[_gameId][msg.sender] = true;
        } else {
            revert GameAlreadyStarted();
        }
    }

    /// @notice generates a random number for difference games
    /// @param _gameId The ID of the game to join
    function generateRandomNumber(
        uint8 _gameId
    ) public{
        uint8 num = uint8(uint(
            keccak256(abi.encodePacked(block.timestamp, msg.sender))
        ) % 51);
        games[_gameId].generatedNumber = num;
    }

    /// @notice updates the drawnBoard of a user by the provided number. This will keep track of drawned number of any user in drawnBoards mapping.
    /// @param _gameId The ID of the game to join
    /// @param _number The number that has been drawn
    function drawnNumber(
        uint8 _gameId,
        uint8 _number
    ) public {
        if (!players[_gameId][msg.sender])
            revert Unauthorized(msg.sender);
        for (uint i = 0; i < 5; i++) {
            for (uint j = 0; j < 5; j++) {
                if (boards[_gameId][msg.sender][i][j] == _number) {
                    drawnBoards[_gameId][msg.sender][i][j] = 100;
                }
            }
        }
    }

    /// @notice returns a boolean value, whether game started or not.
    /// @param _gameId The ID of the game to check
    /// @return A boolean value indicating if the game has started
    function isGameStarted(uint8 _gameId) public view returns (bool) {
        return games[_gameId].owner!=address(0) && block.timestamp >= games[_gameId].startDuration;
    }

    /// @notice user check whether it becomes the winner of the game or not.
    /// @param _gameId The ID of the game to check
    function checkWinner(uint8 _gameId) public {
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
        for (uint256 i = drawnBoards[_gameId][msg.sender].length-1; i>=0; i--) {
            if(drawnBoards[_gameId][msg.sender][drawnBoards[_gameId][msg.sender].length-1-i][i]!=100){
                temp = false;
                break;
            }
        }
        if(temp) diagonal++;
        if(row+col+diagonal>=5) {
            erc20.transfer(msg.sender, games[_gameId].winningPrice);
            games[_gameId].winner = msg.sender;
        }
        else return;
    }
}