// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";

contract rps {
    event Commit(address player);
    event Reveal(address player, Weapon weapon);

    enum Stage {
        FirstCommit,
        SecondCommit,
        FirstReveal,
        SecondReveal,
        FinishGame
    }

    enum Weapon {
        None,
        Rock,
        Paper,
        Scissors
    }

    address public firstPlayer;
    address public secondPlayer;

    Weapon public weaponFirstPlayer;
    Weapon public weaponSecondPlayer;

    bytes32 public firstPlayerHash;
    bytes32 public secondPlayerHash;

    address public winner;

    Stage public stage = Stage.FirstCommit;

    constructor() {
        newGame();
    }

    function newGame() public {
        winner = address(0x0);
        firstPlayer = address(0x0);
        secondPlayer = address(0x0);

        firstPlayerHash = 0x0;
        secondPlayerHash = 0x0;

        weaponFirstPlayer = Weapon.None;
        weaponSecondPlayer = Weapon.None;

        stage = Stage.FirstCommit;
    }

    modifier isJoinable() {
        require(firstPlayer == address(0) || secondPlayer == address(0));
        _;
    }

    modifier isPlayer() {
        require(msg.sender == firstPlayer || msg.sender == secondPlayer);
        _;
    }

    modifier isCorrectChoice(Weapon weapon) {
        require(
            weapon == Weapon.Rock ||
                weapon == Weapon.Paper ||
                weapon == Weapon.Scissors
        );
        _;
    }

    modifier isAlreadyIn() {
        require(msg.sender != firstPlayer && msg.sender != secondPlayer);
        _;
    }

    function join() external isAlreadyIn isJoinable {
        if (firstPlayer == address(0)) {
            firstPlayer = msg.sender;
        } else {
            secondPlayer = msg.sender;
        }
    }

    function commit(bytes32 hash) public isPlayer {
        require(stage == Stage.FirstCommit || stage == Stage.SecondCommit);

        if (msg.sender == firstPlayer && firstPlayerHash == 0x0) {
            firstPlayerHash = hash;
        } else if (msg.sender == secondPlayer && secondPlayerHash == 0x0) {
            secondPlayerHash = hash;
        } else {
            return;
        }

        emit Commit(msg.sender);

        if (stage == Stage.FirstCommit) {
            stage = Stage.SecondCommit;
        } else {
            stage = Stage.FirstReveal;
        }
    }

    function reveal(Weapon weapon, uint32 salt)
        public
        isPlayer
        isCorrectChoice(weapon)
    {
        require(stage == Stage.FirstReveal || stage == Stage.SecondReveal);

        bytes32 getHash = sha256(
            bytes.concat(
                bytes(Strings.toString(uint256(weapon))),
                bytes(Strings.toString(salt))
            )
        );

        if (weapon == Weapon.None) {
            return;
        }

        if (msg.sender == firstPlayer && getHash == firstPlayerHash) {
            weaponFirstPlayer = weapon;
            emit Reveal(msg.sender, weapon);
            stage = Stage.SecondReveal;
        } else if (msg.sender == secondPlayer && getHash == secondPlayerHash) {
            weaponSecondPlayer = weapon;
            emit Reveal(msg.sender, weapon);
            stage = Stage.FinishGame;
        } else {
            return;
        }
    }

    function gameResult() private view returns (int8) {
        if (weaponFirstPlayer == weaponSecondPlayer) {
            return 0;
        }

        if (weaponFirstPlayer == Weapon.Rock) {
            if (weaponSecondPlayer == Weapon.Scissors) {
                return 1;
            } else {
                return 2;
            }
        }

        if (weaponFirstPlayer == Weapon.Paper) {
            if (weaponSecondPlayer == Weapon.Rock) {
                return 1;
            } else {
                return 2;
            }
        }

        if (weaponFirstPlayer == Weapon.Scissors) {
            if (weaponSecondPlayer == Weapon.Paper) {
                return 1;
            } else {
                return 2;
            }
        }

        return -1;
    }

    function finish() public isPlayer {
        require(stage == Stage.FinishGame);

        int8 result = gameResult();

        if (result == 0 || result == 1) {
            winner = firstPlayer;
        } else {
            winner = secondPlayer;
        }
    }
}