//win condition states
`define EXIT_CODE 999
`define CONTESTED -2
`define FORTHEWIN 666
`define BLOCK 3

//Tile state consts
`define EMPTY 0
`define O 1
`define X 2


//priority naming
`define LDIAG 1
`define RDIAG 2
`define HORIZ1 3
`define HORIZ2 4
`define HORIZ3 5
`define VERT1 6
`define VERT2 7
`define VERT3 8

module test();

reg sendSignal = 0;
integer userInput = -1;
simulation mySimulation(userInput,sendSignal);

initial begin

/*	//Playing a full game where we tie :').
	#2 userInput = 5;
	   sendSignal = 1;
	#5 sendSignal = 0;
	#5 userInput = 8;
	   sendSignal = 1;
	#5 sendSignal = 0;
	#2 userInput = 6;
	   sendSignal = 1;
	#5 sendSignal = 0;
	#2 userInput = 1;
	   sendSignal = 1;
	#5 sendSignal = 0;
	#2 userInput = 3;
	   sendSignal = 1;
	#5 sendSignal = 0; */


 //This test case works in our favor (we win)
	#2 userInput = 5;
	   sendSignal = 1;
	#5 sendSignal = 0;
	#5 userInput = 8;
	   sendSignal = 1;
	#5 sendSignal = 0;
	#5 userInput = 3;
	   sendSignal = 1;
	#5 sendSignal = 0;
	#5  userInput = 0;
	   sendSignal = 1;
end

endmodule

	//THE COMPUTER WILL CONTROL X


module simulation(input integer userInput,input reg sendSignal);

	//global vars for storing each win combos state
	integer canIWinFirstRowVal;
	integer canIWinSecondRowVal;
	integer canIWinThirdRowVal;
	integer canIWinFirstColumnVal;
	integer canIWinSecondColumnVal;
	integer canIWinThirdColumnVal;
	integer canIWinDiagonallyLeftVal;
	integer canIWinDiagonallyRightVal;

	
	reg isEmptyVals[8:0]; //9 element array storing taken or empty values for all tiles
	integer board [8:0]; //a 9 element array storing all slots on the board
	integer errorMessage = 0; //this will become -1 if the user enters an invalid input and will bypass the rest of the simulation

	//I dont want to deal with passing this shit around and we're not graded on efficiency ... SO GLOBAL :)
	integer currentMatches = -1; //essentially how many x's I have in a certain winning combo unless its blocked
	integer myPriority = -1; //matches and priority are both keywords. Basically fuck verilog, its just too good.
	integer checkIfFinishedVal = 0;
	integer isBoardFullVal = 0; //its full unless I say otherwise

	//global var that gets reused for counting how many myself and the opponent have. I'll rezero when needed elsewhere
	integer counter = 0;
	integer oppCounter = 0;


	//Here is what the board will look like
	//  0    1    2
	//  3    4    5
	//  6    7    8


	initial begin
		initBoard(); // initialize the board (this should onley happen once)
		initEmpties(); //set all the empty variables for tile state (taken/empty) to show that they have not been taken
		$display(board[0], " ",board[1]," ",board[2],"\n",board[3], " ",board[4]," ",board[5],"\n",board[6], " ",board[7]," ",board[8], "\n\n\n\n"); //hopefully this looks somewhat right and technically this should update when these values update;

	end


	always@(posedge sendSignal)begin
		if (userInput > 8 || userInput < 0)begin
			errorMessage = -1;
		end
		else begin
			if (board[userInput] == 0)begin //the slot the user wants to use is empty
				board[userInput] = 1; //enter a 0 for the user
			end
			else begin
				errorMessage = -1; //the slot wasnt empty so by setting this to -1 the computer shouldnt add another x
			end
		end
		if (errorMessage != -1) begin //if the users input is valid
			myPriority = -1; //resetting these variables from the last simulation
			currentMatches = -1; //resetting these variables from the last simulation

			isEmpty();
			determinePriority(); // determine the new priority based on the board
			isBoardFull(); //make sure the board isnt full. Doesnt call exit just sets a var
			checkIfFinished(); //check if someone has won or the boards full. If so quit
			if (myPriority == -1) begin //if every priority returns garbage
				redundancy(); //insert an x into the first open spot found
			end
			else begin
				insertX(); //now actually insert an x that is logical
				$display(board[0], " ",board[1]," ",board[2],"\n",board[3], " ",board[4]," ",board[5],"\n",board[6], " ",board[7]," ",board[8]); //hopefully this looks somewhat right and technically this should update when these values update;
				$display("X inserted, MyPriority was: ",myPriority, "\n\n\n\n");
			end

			isBoardFull(); //make sure the board isnt full. Doesnt call exit just sets a var
			checkIfFinished(); //check if someone has won or the boards full. If so quit
		end
	errorMessage = 0; //reset error message to 0 for the next input
  end


	/**
	 * Make all the spots empty.
	 * Run concurrently. Each is independent. Parallelize
     */
	task initBoard(); begin
		board[0] <= `EMPTY;
		board[1] <= `EMPTY;
		board[2] <= `EMPTY;
		board[3] <= `EMPTY;
		board[4] <= `EMPTY;
		board[5] <= `EMPTY;
		board[6] <= `EMPTY;
		board[7] <= `EMPTY;
		board[8] <= `EMPTY;
	end
	endtask

	/**
	 * Make all the is empty variables true because all tiles are empty
	 * Run concurrently. Each is independent. Parallelize
	 */
	task initEmpties(); begin
		isEmptyVals[0] <= 1;
		isEmptyVals[1] <= 1;
		isEmptyVals[2] <= 1;
		isEmptyVals[3] <= 1;
		isEmptyVals[4] <= 1;
		isEmptyVals[5] <= 1;
		isEmptyVals[6] <= 1;
		isEmptyVals[7] <= 1;
		isEmptyVals[8] <= 1;
	end
	endtask

	/*
	 * Function that will see if the game is finished or not. Bool return (in verilog its reg because verilog is so damn cool)
	 */
	task checkIfFinished();
		begin
			if (canIWinDiagonallyLeftVal == `EXIT_CODE || canIWinDiagonallyRightVal == `EXIT_CODE ||
					canIWinFirstRowVal == `EXIT_CODE || canIWinSecondRowVal == `EXIT_CODE || canIWinThirdRowVal == `EXIT_CODE||
					canIWinFirstColumnVal == `EXIT_CODE || canIWinSecondColumnVal == `EXIT_CODE || canIWinThirdColumnVal == `EXIT_CODE ||
					isBoardFullVal == 1)
				begin
					//someone won somehow or the board was filled
					checkIfFinishedVal = 1;
					$display(board[0], " ",board[1]," ",board[2],"\n",board[3], " ",board[4]," ",board[5],"\n",board[6], " ",board[7]," ",board[8]); //hopefully this looks somewhat right and technically this should update when these values update;
					$finish; // believe this is how you exit in verilog. Could always just stand behind carpenter when he plays then when he wins or the board is full throw a hammer at his screen
				end

			else begin
				checkIfFinishedVal = 0; //nobody has won yet
			end
		end
	endtask

	/*
	 * Method that will search through winning combinations and prioritize a move depending on the board's current layout
	 */
	task determinePriority();
		begin
			//run concurrently reset these values. Ik efficiency doesnt matter but this is something that can be parallelized
			currentMatches <= -1;
			myPriority <= -1; //rezero these
			canIWinFirstRowVal <= 0;
			canIWinSecondRowVal<=0;
			canIWinThirdRowVal<=0;
	 		canIWinFirstColumnVal<=0;
	 		canIWinSecondColumnVal<=0;
	 		canIWinThirdColumnVal<=0;
			canIWinDiagonallyLeftVal<=0;
			canIWinDiagonallyRightVal<=0;

			canIWinFirstRow();
			canIWinSecondRow();
			canIWinThirdRow();
			canIWinFirstColumn();
			canIWinSecondColumn();
			canIWinThirdColumn();
			canIWinDiagonallyLeft();
			canIWinDiagonallyRight();

			//So basically this logic will look to see if I can win immediately or stop him
			//from winning immediately. If I cant then I'll choose the next best possible option prioritizing the diags

			//These must be if's and not else ifs because they all need to check. Else if would break after 1.
			//I need to compare all of them
			
			if (canIWinDiagonallyLeftVal > currentMatches) begin
				myPriority = `LDIAG;
				currentMatches = canIWinDiagonallyLeftVal;
			end

			if (canIWinDiagonallyRightVal > currentMatches) begin
				currentMatches = canIWinDiagonallyRightVal;
				myPriority = `RDIAG;
			end

			if (canIWinFirstColumnVal > currentMatches) begin
				currentMatches = canIWinFirstColumnVal;
				myPriority = `VERT1;
			end

			if (canIWinSecondColumnVal > currentMatches) begin
				currentMatches = canIWinSecondColumnVal;
				myPriority = `VERT2;
			end

			if (canIWinThirdColumnVal > currentMatches) begin
				currentMatches = canIWinThirdColumnVal;
				myPriority = `VERT3;
			end

			if (canIWinFirstRowVal > currentMatches) begin
				currentMatches = canIWinFirstRowVal;
				myPriority = `HORIZ1;
			end

			if (canIWinSecondRowVal > currentMatches) begin
				currentMatches = canIWinSecondRowVal;
				myPriority = `HORIZ2;
			end

			if (canIWinThirdRowVal > currentMatches) begin
				currentMatches = canIWinThirdRowVal;
				myPriority = `HORIZ3;
			end
		end
	endtask

	/*
	 * Method responsible for actually inserting an x into the board. Called after move priority is determined.
	 */
	task insertX();
		begin
			//L DIAG
			if (myPriority == `LDIAG) begin
				//checks all the left diag spots to find missing and fill
				if (isEmptyVals[4] == 1) begin
					//middle is always priority
					board[4]=`X;
					$display("Box was: 4");
				end

				else if (isEmptyVals[0] == 1) begin
					//I already had middle take top left
					board[0]=`X;
					$display("Box was: 0");
				end

				else begin
					//I already had top left and middle take bottom right. Could add redundancy
					board[8]=`X;
					$display("Box was: 8");
				end
			end
			//R DIAG
			else if(myPriority == `RDIAG) begin
				//checks all the right diag spots to find missing and fill
				if (isEmptyVals[4]==1) begin
					//middle is always priority
					board[4]=`X;
					$display("Box was: 4");
				end

				else if (isEmptyVals[6]==1) begin
					//I already had middle take bottom left
					board[6] =`X;
					$display("Box was: 6");
				end

				else begin
					//I already had bottom left and middle take top right. Could add redundancy w/ elif
					board[2]=`X;
					$display("Box was: 2");
				end
			end
			//1st row
			else if (myPriority == `HORIZ1) begin
				if (isEmptyVals[0]==1) begin
					//top left
					board[0] = `X;
					$display("Box was: 0");
				end

				else if (isEmptyVals[1]==1) begin
					//top middle
					board[1] = `X;
					$display("Box was: 1");
				end

				 else if (isEmptyVals[2]==1) begin
					//top right
					board[2] = `X;
					$display("Box was: 2");
				end
			end
			//2nd row
			else if (myPriority == `HORIZ2) begin
				if (isEmptyVals[3] ==1) begin
					//middle left
					board[3] = `X;
					$display("Box was: 3");
				end

				else if (isEmptyVals[4] ==1) begin
					//middle middle
					board[4] = `X;
					$display("Box was: 4");
				end

				else if (isEmptyVals[5]==1) begin
					//middle right
					board[5] = `X;
					$display("Box was: 5");
				end
			end
			//third row
			else if (myPriority == `HORIZ3) begin
				if (isEmptyVals[6] ==1) begin
					//bottom left
					board[6] = `X;
					$display("Box was: 6");
				end

				else if (isEmptyVals[7] ==1) begin
					//bottom middle
					board[7] = `X;
					$display("Box was: 7");
				end

				else if (isEmptyVals[8] ==1) begin
					//bottom right
					board[8] = `X;
					$display("Box was: 8");
				end
			end
			//first column
			else if (myPriority == `VERT1) begin
				if (isEmptyVals[0] == 1) begin
					//top left
					board[0] = `X;
					$display("Box was: 0");
				end

				else if (isEmptyVals[3] ==1) begin
					//middle left
					board[3] = `X;
					$display("Box was: 3");
				end

				else if (isEmptyVals[6] ==1) begin
					//bottom left
					board[6] = `X;
					$display("Box was: 6");
				end
			end
			//second column
			else if (myPriority == `VERT2) begin
				if (isEmptyVals[1] ==1) begin
					//top middle
					board[1] = `X;
					$display("Box was: 1");
				end

				else if (isEmptyVals[4] ==1) begin
					//middle middle
					board[4] = `X;
					$display("Box was: 4");
				end

				else if (isEmptyVals[7] ==1) begin
					//middle bottom
					board[7] = `X;
					$display("Box was: 7");
				end
			end
			//third column
			else if (myPriority == `VERT3) begin
				if (isEmptyVals[2] ==1) begin
					//top right
					board[2] = `X;
					$display("Box was: 2");
				end

				else if (isEmptyVals[5] ==1) begin
					//middle right
					board[5] = `X;
					$display("Box was: 5");
				end

				else if (isEmptyVals[8] == 1) begin
					//bottom right
					board[8] = `X;
					$display("Box was: 8");
				end
			end
		end
	endtask

	/* there is a bug for case X O X
							   - X O
							   O X O
	Solution is to add redundancy. If no prioritiy is assigned find an open spot
	Technically should never get here due to sheer improbality of getting here.
	I literally think it is impossible. In cases where the board can be fed in (ie game in progess)
	its possible but I'm not sure if you can get here through a game with the computer using the logic implemented.
	Anyways its a redundancy for a reason.
	*/
	task redundancy();
		begin

		if (board[0] == `EMPTY)begin
			board[0] = `X;
		end
		
		else if (board[1] == `EMPTY)begin
			board[1] = `X;
		end
		
		else if (board[2] == `EMPTY)begin
			board[2] = `X;
		end
		
		else if (board[3] == `EMPTY)begin
			board[3] = `X;
		end
		
		else if (board[4] == `EMPTY)begin
			board[4] = `X;
		end
		
		else if (board[5] == `EMPTY)begin
			board[5] = `X;
		end
		
		else if (board[6] == `EMPTY)begin
			board[6] = `X;
		end
		
		else if (board[7] == `EMPTY)begin
			board[7] = `X;
		end
		
		else if (board[8] == `EMPTY)begin
			board[8] = `X;
		end

		end
	endtask

	/**
 	  * Says its full unless I find an instance where its not
	  */
	task isBoardFull();
		begin
			isBoardFullVal = 1; //assume board is full unless proven otherwise
			
			if (board[0] == `EMPTY)begin
				isBoardFullVal =0;
			end
			
			else if (board[1] == `EMPTY)begin
				isBoardFullVal =0;
			end
			
			else if (board[2] == `EMPTY)begin
				isBoardFullVal =0;
			end
			
			else if (board[3] == `EMPTY)begin
				isBoardFullVal =0;
			end
			
			else if (board[4] == `EMPTY)begin
				isBoardFullVal =0;
			end
			
			else if (board[5] == `EMPTY)begin
				isBoardFullVal =0;
			end
			
			else if (board[6] == `EMPTY)begin
				isBoardFullVal =0;
			end
			
			else if (board[7] == `EMPTY)begin
				isBoardFullVal =0;
			end
			
			else if (board[8] == `EMPTY)begin
				isBoardFullVal =0;
			end
			
		end
		
	endtask

	/**
      * Method that checks if the computer can win on the main diagonal if not ranks how close or garbage
 	  */
	task canIWinDiagonallyLeft();
		begin
			counter =0;
			oppCounter = 0;

			if (board[0] == `X)begin
				//ok I got the top left corner
				counter = counter + 1;
			end else if (board[0] == `O )begin
				//he got top left
				oppCounter = oppCounter + 1;
			end

			if(board[4] == `X)begin
				//k i got the middle
				counter = counter + 1;
			end else if (board[4] == `O)begin
				//he got middle
				oppCounter = oppCounter + 1;
			end

			if(board[8] == `X)begin
				//ok i got bottom right
				counter = counter + 1;
			end else if (board[8] == `O)begin
				//he got bottom right
				oppCounter = oppCounter + 1;
			end

			if (counter == 3 || oppCounter == 3) begin
				canIWinDiagonallyLeftVal = `EXIT_CODE; //somebody has 3 in a row
			end else if (counter !=0 && oppCounter != 0) begin
				canIWinDiagonallyLeftVal = `CONTESTED; //no way to win here. He owns at least one tile and so do I
			end else if (counter == 2 && oppCounter == 0) begin
				canIWinDiagonallyLeftVal = `FORTHEWIN; //I'm about to win
			end else if (counter ==0 && oppCounter ==2) begin
				canIWinDiagonallyLeftVal = `BLOCK; //hes about to win make this my priority
			end else begin
				canIWinDiagonallyLeftVal = counter; //will return how close I am to winning diagonally left
			end
		end
	endtask

	/**
	  * Method that checks if the computer can win on the secondary diagonal if not ranks how close or garbage
 	  */
	task canIWinDiagonallyRight();
		begin
			counter =0;
			oppCounter = 0;

			if (board[2] == `X)begin
				//ok I got the top right corner
				counter = counter + 1;
			end else if (board[2]== `O)begin
				//he got top right
				oppCounter = oppCounter + 1;
			end

			if(board[4]== `X)begin
				//k i got the middle
				counter = counter + 1;
			end else if (board[4]== `O)begin
				//he got middle
				oppCounter = oppCounter + 1;
			end

			if(board[6] == `X)begin
				//ok i got bottom left
				counter = counter + 1;
			end else if (board[6] == `O)begin
				//he got bottom left
				oppCounter = oppCounter + 1;
			end

			if (counter == 3 || oppCounter == 3) begin
				canIWinDiagonallyRightVal= `EXIT_CODE; //somebody has 3 in a row
			end else if (counter !=0 && oppCounter != 0) begin
				canIWinDiagonallyRightVal = `CONTESTED; //no way to win here. He owns at least one tile and so do I
			end else if (counter == 2 && oppCounter == 0) begin
				canIWinDiagonallyRightVal = `FORTHEWIN; //I'm about to win
			end else if (counter ==0 && oppCounter ==2) begin
				canIWinDiagonallyRightVal = `BLOCK; //hes about to win make this my priority
			end else begin
				canIWinDiagonallyRightVal = counter; //will return how close I am to winning diagonally left
			end
		end
	endtask

	/**
	 * Method that checks if the computer can win horizontally on the first row if not ranks how close or garbage
	 */
	task canIWinFirstRow();

		begin
			counter =0;
			oppCounter = 0;

			if (board[0] == `X)begin
				//ok I got the top left corner
				counter = counter + 1;
			end else if (board[0] == `O)begin
				//he got top left
				oppCounter = oppCounter + 1;
			end

			if(board[1] == `X)begin
				//k i got the top middle
				counter = counter + 1;
			end else if (board[1] == `O)begin
				//he got top middle
				oppCounter = oppCounter + 1;
			end

			if(board[2] == `X)begin
				//ok i got top right
				counter = counter + 1;
			end else if (board[2] == `O)begin
				//he got top right
				oppCounter = oppCounter + 1;
			end

			if (counter == 3 || oppCounter == 3) begin
				canIWinFirstRowVal = `EXIT_CODE; //somebody has 3 in a row
			end else if (counter !=0 && oppCounter != 0) begin
				canIWinFirstRowVal = `CONTESTED; //no way to win here. He owns at least one tile and so do I
			end else if (counter == 2 && oppCounter == 0) begin
				canIWinFirstRowVal = `FORTHEWIN; //I'm about to win
			end else if (counter ==0 && oppCounter ==2) begin
				canIWinFirstRowVal = `BLOCK; //hes about to win make this my priority
			end else begin
				canIWinFirstRowVal = counter; //will return how close I am to winning diagonally left
			end
		end
	endtask

	/**
	 * Method that checks if the computer can win horizontally on the second row if not ranks how close or garbage
	 */
	task canIWinSecondRow();

		begin
			counter =0;
			oppCounter = 0;

			if (board[3] == `X)begin
				//ok I got the middle left
				counter = counter + 1;
			end else if (board[3] == `O)begin
				//he got middle left
				oppCounter = oppCounter + 1;
			end

			if(board[4] ==`X)begin
				//k i got the middle
				counter = counter + 1;
			end else if (board[4] == `O)begin
				//he got middle
				oppCounter = oppCounter + 1;
			end

			if(board[5] == `X)begin
				//ok i got middle right
				counter = counter + 1;
			end else if (board[5] == `O)begin
				//he got middle right
				oppCounter = oppCounter + 1;
			end

			if (counter == 3 || oppCounter == 3) begin
				canIWinSecondRowVal = `EXIT_CODE; //somebody has 3 in a row
			end else if (counter !=0 && oppCounter != 0) begin
				canIWinSecondRowVal = `CONTESTED; //no way to win here. He owns at least one tile and so do I
			end else if (counter == 2 && oppCounter == 0) begin
				canIWinSecondRowVal = `FORTHEWIN; //I'm about to win
			end else if (counter ==0 && oppCounter ==2) begin
				canIWinSecondRowVal = `BLOCK; //hes about to win make this my priority
			end else begin
				canIWinSecondRowVal = counter; //will return how close I am to winning diagonally left
			end
		end
	endtask

	/**
	 * Method that checks if the computer can win horizontally on the third row if not ranks how close or garbage
	 */
	task canIWinThirdRow();

		begin
			counter =0;
			oppCounter = 0;

			if (board[6]== `X)begin
				//ok I got the bottom left corner
				counter = counter + 1;
			end else if (board[6]== `O)begin
				//he got bottom left
				oppCounter = oppCounter + 1;
			end

			if(board[7]== `X)begin
				//k i got the bottom middle
				counter = counter + 1;
			end else if (board[7]== `O)begin
				//he got bottom middle
				oppCounter = oppCounter + 1;
			end

			if(board[8] == `X)begin
				//ok i got bottom right
				counter = counter + 1;
			end else if (board[8] == `O)begin
				//he got bottom right
				oppCounter = oppCounter + 1;
			end

			if (counter == 3 || oppCounter == 3) begin
				canIWinThirdRowVal = `EXIT_CODE; //somebody has 3 in a row
			end else if (counter !=0 && oppCounter != 0) begin
				canIWinThirdRowVal = `CONTESTED; //no way to win here. He owns at least one tile and so do I
			end else if (counter == 2 && oppCounter == 0) begin
				canIWinThirdRowVal = `FORTHEWIN; //I'm about to win
			end else if (counter ==0 && oppCounter ==2) begin
				canIWinThirdRowVal = `BLOCK; //hes about to win make this my priority
			end else begin
				canIWinThirdRowVal = counter; //will return how close I am to winning diagonally left
			end
		end
	endtask

	/**
	 * Method that checks if the computer can win vertically on the first column if not ranks how close or garbage
	 */
	task canIWinFirstColumn();

		begin
			counter =0;
			oppCounter = 0;

			if (board[0]== `X)begin
				//ok I got the top left corner
				counter = counter + 1;
			end else if (board[0]== `O)begin
				//he got top left
				oppCounter = oppCounter + 1;
			end

			if(board[3]== `X)begin
				//k i got the middle left
				counter = counter + 1;
			end else if (board[3]== `O)begin
				//he got middle left
				oppCounter = oppCounter + 1;
			end

			if(board[6]== `X)begin
				//ok i got bottom left
				counter = counter + 1;
			end else if (board[6]== `O)begin
				//he got bottom left
				oppCounter = oppCounter + 1;
			end

			if (counter == 3 || oppCounter == 3) begin
				canIWinFirstColumnVal = `EXIT_CODE; //somebody has 3 in a row
			end else if (counter !=0 && oppCounter != 0) begin
				canIWinFirstColumnVal = `CONTESTED; //no way to win here. He owns at least one tile and so do I
			end else if (counter == 2 && oppCounter == 0) begin
				canIWinFirstColumnVal = `FORTHEWIN; //I'm about to win
			end else if (counter ==0 && oppCounter ==2) begin
				canIWinFirstColumnVal = `BLOCK; //hes about to win make this my priority
			end else begin
				canIWinFirstColumnVal = counter; //will return how close I am to winning diagonally left
			end
		end
	endtask

	/**
	 * Method that checks if the computer can win vertically on the second column if not ranks how close or garbage
	 */
	task canIWinSecondColumn();

		begin
			counter =0;
			oppCounter = 0;

			if (board[1]== `X)begin
				//ok I got the top middle
				counter = counter + 1;
			end else if (board[1]== `O)begin
				//he got top middle
				oppCounter = oppCounter + 1;
			end

			if(board[4]== `X)begin
				//k i got the center
				counter = counter + 1;
			end else if (board[4]== `O)begin
				//he got center
				oppCounter = oppCounter + 1;
			end

			if(board[7]== `X)begin
				//ok i got bottom middle
				counter = counter + 1;
			end else if (board[7]== `O)begin
				//he got bottom middle
				oppCounter = oppCounter + 1;
			end

			if (counter == 3 || oppCounter == 3) begin
				canIWinSecondColumnVal = `EXIT_CODE; //somebody has 3 in a row
			end else if (counter !=0 && oppCounter != 0) begin
				canIWinSecondColumnVal = `CONTESTED; //no way to win here. He owns at least one tile and so do I
			end else if (counter == 2 && oppCounter == 0) begin
				canIWinSecondColumnVal = `FORTHEWIN; //have an immediate win possibility
			end else if (counter ==0 && oppCounter ==2) begin
				canIWinSecondColumnVal = `BLOCK; //hes about to win make this my priority
			end else begin
				canIWinSecondColumnVal = counter; //will return how close I am to winning diagonally left
			end
		end
	endtask

	/**
	 * Method that checks if the computer can win vertically on the third column if not ranks how close or garbage
	 */
	task canIWinThirdColumn();

		begin
			counter =0;
			oppCounter = 0;

			if (board[2]== `X)begin
				//ok I got the top right
				counter = counter + 1;
			end

			else if (board[2]== `O)begin
				//he got top right
				oppCounter = oppCounter + 1;
			end

			if(board[5]== `X)begin
				//k i got middle right
				counter = counter + 1;
			end

			else if (board[5]== `O)begin
				//he got middle right
				oppCounter = oppCounter + 1;
			end

			if(board[8]== `X)begin
				//ok i got bottom right
				counter = counter + 1;
			end

			else if (board[8]== `O)begin
				//he got bottom right
				oppCounter = oppCounter + 1;
			end

			if (counter == 3 || oppCounter == 3) begin
				canIWinThirdColumnVal = `EXIT_CODE; //somebody has 3 in a row
			end

			else if (counter !=0 && oppCounter != 0) begin
				canIWinThirdColumnVal = `CONTESTED; //no way to win here. He owns at least one tile and so do I
			end

			else if (counter == 2 && oppCounter == 0) begin
				canIWinThirdColumnVal = `FORTHEWIN; //have an immediate win possibility
			end

			else if (counter ==0 && oppCounter ==2) begin
				canIWinThirdColumnVal = `BLOCK; //hes about to win make this my priority
			end

			else begin
				canIWinThirdColumnVal = counter; //will return how close I am to winning diagonally left
			end

		end

	endtask

	/**
	  * Returns a 1 if its empty, 0 otherwise
	  */
	task isEmpty();
		begin
			if (board[0] != `EMPTY) begin
				isEmptyVals[0] = 0;
			end
			if (board[1] != `EMPTY) begin
				isEmptyVals[1] = 0;
			end
			if (board[2] != `EMPTY) begin
				isEmptyVals[2] = 0;
			end
			if (board[3] != `EMPTY) begin
				isEmptyVals[3] = 0;
			end
			if (board[4] != `EMPTY) begin
				isEmptyVals[4] = 0;
			end
			if (board[5] != `EMPTY) begin
				isEmptyVals[5] = 0;
			end
			if (board[6] != `EMPTY) begin
				isEmptyVals[6] = 0;
			end
			if (board[7] != `EMPTY) begin
				isEmptyVals[7] = 0;
			end
			if (board[8] != `EMPTY) begin
				isEmptyVals[8] = 0;
			end

		end
	endtask


endmodule