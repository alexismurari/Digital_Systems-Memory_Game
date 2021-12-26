# Titlescreen

<p align="center">
  <img src="https://github.com/alexismurari/Digital_Systems-Memory_Game/blob/main/Titlescreen.png" width="600"/>
</p>

## Introduction

For this project, we designed and implemented a memory game on the FPGA board. We wanted to create a game that would be simple to understand and competitive between different players who would play the game. The concept of the game was to have players determine and remember a sequence of symbols that would increase in length as the game went on. A timer would be implemented to keep a record of the player’s score, which they could use to challenge others with or improve themselves with more practice. 

As for our main goals, we wanted to get the main logic of the game working by the first week. This would involve a finite state machine (FSM) module to determine correct and incorrect inputs and a random number generator module to provide the FSM the randomized values that would need to be determined by the player. For the second week, we wanted to include different difficulty modes along with a scoreboard so that we could have the entire game polished off and ready to play by the third.

Rules/Instructions: (See Appendix A for KEY and SW assignments)
KEY[3] is used a the ‘select’ key to input a number or to proceed to the next round.

A sequence of the letters A-F are displayed on HEX[3] in a loop. On the first round, one of the letters will be removed. You must identify and input the missing letter to continue.

Use SW[2:0] to select the missing letter and KEY[3] to enter it.
*SW[2:0] corresponds to binary digit inputs, where 0=A, 5=F. The input will also be displayed on HEX[0]

With each passing round, an additional letter will be removed and you will have to input all the letters that have been removed in the order that they were removed in. 

An incorrect input will require you to start from the first input again.












## The Design

Top Level Module:
The top module connects all of the sub modules needed for the game.

VGA:
We implemented the VGA to be able to display all the required information for the user to be able to play. 

Randomizer module (and storing the numbers obtained):
The randomizer module randomly chooses the sequence of letters that will be removed in each round. It is essential to make each game unique as predetermined letter sequences would defeat the purpose of consecutive attempts. This is accomplished on a 4-bit counter that increments at each positive edge of CLOCK_50, which allows for an unpredictable letter to be chosen and taken away when a player presses KEY[3] upon a new round. Each time a value is taken away, it is prevented from being chosen again in a single game. 

*Note: The numbers chosen are converted into letters when they are connected the HEX display (where A = 0 and F = 5).

- Randomizer module:
This module contains a 4-bit counter that increments at each positive edge of CLOCK_50 and loops through the numbers 0-5.

- Num_chosen:
This module takes the current value of the Randomizer module and stores it into a wire in the top level module called ‘rand’.

- Num_mem module:
This module handles the wires a, b, c, d, e, and f, which are initialized as 4’b1111. As the rounds go by, it stores the random values chosen by Num_chosen into the wires. A reset function is activated after the last round(3 on easy difficulty and 6 on hard) is met and completed but can also be done mid-game with SW[9] and the positive edge of KEY[3].

*FSM:*
This module handles the main logic of the game. Using the random letter values taken away by the [] module(/modules) and the inputs given by the player, it decides when a player has made a mistake or when they are allowed to advance to the next round or win the game.

The fsm uses 7 cases. Cases A-F correspond to the rounds of 1 to the max of 6. Case G is the win state and Case H is the error state. Starting at the default case A, the fsm checks whether the user inputs the correct first missing symbol and if so, it will either advance to the next case (in this case, B) or case G, the win state, depending on the current round. If the player at any point inputs the wrong input sequence then it will move to Case H, where a wire named “lose” is set to 1 until the input the correct first input again. The “lose” wire serves as a way for us to implement a penalty to the user in the scoreboard module. 

*Display module:*
On the HEX[2] we wanted to display all the letters in a loop except the letter(s) the user is supposed to find. In this module we implemented 4 different ways to display the letters. On the regular mode when both switch 7 and 8 are off, the letters are displayed in order with a 1 second interval between each letter. 
Turning switch 8 ‘on’, the interval will be only 0.5 seconds. 
Turning switch 7 ‘on’, the letter will be displayed in a scrambled order

*Scoreboard:*
To add the competitive part of the game we added a scoreboard which tracks the time (in seconds) the user takes to input all the letters and finish the game. In each round transition, the timer is paused to give the player a break. Whenever the user inputs a wrong letter/sequence, the timer’s speed will be doubled as a penalty until they input a correct value. At the end of the game after the user inputs the last letter sequence, the timer will stop. When a new game starts (on a win or after turning reset ‘on’) the timer goes back to 0. 

*hexDisplay:*
The hexDisplay module connects many of the outputs and inputs onto the HEX display. It displays the time given by the scoreboard module on HEX[5:3], the sequence of symbols on HEX[2] given by the display module, the current round value on HEX[1], and the SW[2:0] inputs on HEX[0] as letters.

In addition, it also detects round transition and displays the HEX[2:0] as “-” symbols while keeping the scoreboard on HEX[5:3] the same.
