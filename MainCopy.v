`define EXIT_CODE = 999
`define CONTESTED = -2
`define FORTHEWIN = 666
`define BLOCK = 3

//got sick of having to remember #'s
`define EMPTY 0
`define O 1
`define X 2


//priority naming
`define LDIAG = 1
`define RDIAG = 2
`define HORIZ1 = 3
`define HORIZ2 = 4
`define HORIZ3 = 5
`define VERT1 = 6
`define VERT2 = 7
`define VERT3 = 8

module test();

reg sendSignal = 0;
integer userInput = -1;
simulation(userInput,sendSignal);

initial begin

//So basically this is our print. TODO

	#2 userInput = 5;
	   sendSignal = 1;
	#1 sendSignal = 0;
	#5 userInput = 8;
	   sendSignal = 1;
	#1 sendSignal = 0;
	#5 userInput = 3;
	   sendSignal = 1;
	#1 sendSignal = 0;

end

endmodule

module simulation(integer userInput,reg sendSignal);

	integer canIWinFirstRowVal;
	integer canIWinSecondRowVal;
	integer canIWinThirdRowVal;
	integer canIWinFirstColumnVal;
	integer canIWinSecondColumnVal;
	integer canIWinThirdColumnVal;
	integer canIWinDiagonallyLeftVal;
	integer canIWinDiagonallyRightVal;

	reg isEmpty0 =0;
	reg isEmpty1 =0;
	reg isEmpty2 =0;
	reg isEmpty3 =0;
	reg isEmpty4 =0;
	reg isEmpty5 =0;
	reg isEmpty6 =0;
	reg isEmpty7 =0;
	reg isEmpty8 =0;


	wire [7:0]result;
	wire overflow;
	integer board [8:0]; //a 9 element array storing all slots on the board
	integer errorMessage = 0; //this will become -1 if the user enters an invalid input and will bypass the rest of the simulation

	//I dont want to deal with passing this shit around and we're not graded on efficiency ... SO GLOBAL :)
	integer currentMatches = -1; //essentially how many x's I have in a certain winning combo unless its blocked
	integer myPriority = -1; //matches and priority are both keywords. Basically fuck verilog, its just too good.
	integer checkIfFinishedVal = 0;
	integer isBoardFullVal = 0; //its full unless I say otherwise

	integer counter = 0;
	integer oppCounter = 0;


	integer used = 0;

	//Here is what the board will look like
	//  0    1    2
	//  3    4    5
	//  6    7    8


	initial begin
	initBoard(); // initialize the board (this should onley happen once)
		
	end


	always@(posedge sendSignal)begin
		if (userInput > 8 || userInput < 0)begin
			errorMessage = -1;
		end
		else begin
		if (board[userInput] == `EMPTY)begin //the slot the user wants to use is empty
			board[userInput] = `O; //enter a 0 for the user
			#2; // I want the user to see the changes they have made to the board
		end
		else begin
			errorMessage = -1; //the slot wasnt empty so by setting this to -1 the computer shouldnt add another x
		end
		end
	if (errorMessage != -1) begin //if the users input is valid
		myPriority = -1; //resetting these variables from the last simulation
		currentMatches = -1; //resetting these variables from the last simulation
		determinePriority(); // determine the new priority based on the board
		if (myPriority == -1) begin //if every priority returns garbage
			redundancy(); //insert an x into the first open spot found
		end
		else begin
		insertX(); //now actually insert an x that is logical
		end
		#2; // I want the user to see if someone won
		checkIfFinished();
	end
	errorMessage = 0; //reset error message to 0 for the next input
  end

	//THE COMPUTER WILL CONTROL X

	/**
	  * The convention for storing letters is the following
	  * 0 = empty
	  * 1 = O
	  * 2 = X
	  * else means something is fucked
      */
	task initBoard(); begin
		board[0] = `EMPTY;
		board[1] = `EMPTY;
		board[2] = `EMPTY;
		board[3] = `EMPTY;
		board[4] = `EMPTY;
		board[5] = `EMPTY;
		board[6] = `EMPTY;
		board[7] = `EMPTY;
		board[8] = `EMPTY;
			 /*//outer loop is for every single spot
			for (integer box =0; box < 9; box++)begin
				//inner loop is for every bit in the spot
				board[box] = `EMPTY; //set everything to 0
			end */
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
					$finish; // believe this is how you exit in verilog. Could always just stand behind carpenter when he plays then when he wins
					//or the board is full throw a hammar at his screen
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
			currentMatches = -1;
			myPriority = -1; //rezero these

			//These must be if's and not else ifs because they all need to check. Else if would break after 1.
			//If these things run in parallel and I get threading problems I'm going to be upset
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
			if (myPriority== `LDIAG) begin
				//checks all the left diag spots to find missing and fill
				if (isEmpty4 == 1) begin
					//middle is always priority
					board[4]=`X;
				end 
				
				else if (isEmpty0 == 1) begin
					//I already had middle take top left
					board[0]=`X;
				end

				else begin
					//I already had top left and middle take bottom right. Could add redundancy
					board[8]=`X;
				end
			end
			else if(myPriority==`RDIAG) begin
				//checks all the right diag spots to find missing and fill
				if (isEmpty4==1) begin
					//middle is always priority
					board[4]=`X;
				end

				else if (isEmpty6==1) begin
					//I already had middle take bottom left
					board[6] =`X;
				end

				else begin
					//I already had bottom left and middle take top right. Could add redundancy
					board[2]=`X;
				end
			end
			//Verilog is the kid who just licks the walls in elementary school
			else if (myPriority == `VERT1) begin
				if (isEmpty0==1) begin
					//top left
					board[0] = `X;
				end

				else if (isEmpty3==1) begin
					//middle left
					board[3] = `X;
				end

				 else if (isEmpty6==1) begin
					//bottom left
					board[6] = `X;
				end
			end
			else if (myPriority == `VERT2) begin
				if (isEmpty1 ==1) begin
					//top middle
					board[1] = `X;
				end

				else if (isEmpty4 ==1) begin
					//middle middle
					board[4] = `X;
				end

				else if (isEmpty7==1) begin
					//bottom middle
					board[7] = `X;
				end
			end
			else if (myPriority == `VERT3) begin
				if (isEmpty2 ==1) begin
					//top right
					board[2] = `X;
				end

				else if (isEmpty5 ==1) begin
					//middle right
					board[5] = `X;
				end

				else if (isEmpty8 ==1) begin
					//bottom right
					board[8] = `X;
				end
			end
			else if (myPriority == `HORIZ1) begin
				if (isEmpty0 == 1) begin
					//top left
					board[0] = `X;
				end 

				else if (isEmpty1 ==1) begin
					//top middle
					board[1] = `X;
				end

				else if (isEmpty2 ==1) begin
					//bottom middle
					board[2] = `X;
				end
			end
			else if (myPriority == `HORIZ2) begin
				if (isEmpty3 ==1) begin
					//middle left
					board[3] = `X;
				end

				else if (isEmpty4 ==1) begin
					//middle middle
					board[4] = `X;
				end

				else if (isEmpty5 ==1) begin
					//middle right
					board[5] = `X;
				end
			end
			else if (myPriority == `HORIZ3) begin
				if (isEmpty6 ==1) begin
					//bottom left
					board[6] = `X;
				end

				else if (isEmpty7 ==1) begin
					//bottom middle
					board[7] = `X;
				end

				else if (isEmpty8 == 1) begin
					//bottom right
					board[8] = `X;
				end
			end
		end
	endtask



	/* there is a bug for case X O X
							   - X O
							   O X O
	Solution is to add redundancy. If no prioritiy is assigned find an open spot
	*/
	task redundancy();
		begin
		

		if (board[0] == `EMPTY && used ==0)begin
			board[0] = `X;
			used =1;
		end
		if (board[1] == `EMPTY && used ==0)begin
			board[1] = `X;
			used =1;
		end
		if (board[2] == `EMPTY && used ==0)begin
			board[2] = `X;
			used =1;
		end
		if (board[3] == `EMPTY && used ==0)begin
			board[3] = `X;
			used =1;
		end
		if (board[4] == `EMPTY && used ==0)begin
			board[4] = `X;
			used =1;
		end
		if (board[5] == `EMPTY && used ==0)begin
			board[5] = `X;
			used =1;
		end
		if (board[6] == `EMPTY && used ==0)begin
			board[6] = `X;
			used =1;
		end
		if (board[7] == `EMPTY && used ==0)begin
			board[7] = `X;
			used =1;
		end
		if (board[8] == `EMPTY && used ==0)begin
			board[8] = `X;
			used =1;
		end

		end
	endtask

	/**
 	  * Says its full unless I find an instance where its not
	  */
	task isBoardFull();
		begin
		isBoardFullVal = 1; //assume board is full unless proven otherwise
		if (board[0] == `EMPTY && isBoardFullVal==1)begin
			isBoardFullVal =0;
		end
		if (board[1] == `EMPTY && isBoardFullVal==1)begin
			isBoardFullVal =0;
		end
		if (board[2] == `EMPTY && isBoardFullVal==1)begin
			isBoardFullVal =0;
		end
		if (board[3] == `EMPTY && isBoardFullVal==1)begin
			isBoardFullVal =0;
		end
		if (board[4] == `EMPTY && isBoardFullVal==1)begin
			isBoardFullVal =0;
		end
		if (board[5] == `EMPTY && isBoardFullVal==1)begin
			isBoardFullVal =0;
		end
		if (board[6] == `EMPTY && isBoardFullVal==1)begin
			isBoardFullVal =0;
		end
		if (board[7] == `EMPTY && isBoardFullVal==1)begin
			isBoardFullVal =0;
		end
		if (board[8] == `EMPTY && isBoardFullVal==1)begin
			isBoardFullVal =0;
		end


		end
	endtask


	/**
	  * Ok so my outputs here are going to be -2 if its garbage
	  * TODO
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
	  * Ok so my outputs here are going to be -2 if its garbage
	  * TODO
 	  */
	task canIWinDiagonallyRight();
		begin
			counter =0;
			oppCounter = 0;

			if (board[2] == `X)begin
				//ok I got the top right corner
				counter = counter + 1;
			end else if (board[2]==`O)begin
				//he got top right
				oppCounter = oppCounter + 1;
			end

			if(board[4]== `X)begin
				//k i got the middle
				counter = counter + 1;
			end else if (board[4]==`O)begin
				//he got middle
				oppCounter = oppCounter + 1;
			end

			if(board[6] == `X)begin
				//ok i got bottom left
				counter = counter + 1;
			end else if (board[6] ==`O)begin
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
				//ok I got the top right corner
				counter = counter + 1;
			end else if (board[0] == `O)begin
				//he got top right
				oppCounter = oppCounter + 1;
			end

			if(board[1] == `X)begin
				//k i got the middle
				counter = counter + 1;
			end else if (board[1] == `O)begin
				//he got middle
				oppCounter = oppCounter + 1;
			end

			if(board[2] == `X)begin
				//ok i got bottom left
				counter = counter + 1;
			end else if (board[2] == `O)begin
				//he got bottom left
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
				//ok I got the top right corner
				counter = counter + 1;
			end else if (board[3] == `O)begin
				//he got top right
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
				//ok i got bottom left
				counter = counter + 1;
			end else if (board[5] == `O)begin
				//he got bottom left
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

			if (board[6]==`X)begin
				//ok I got the top right corner
				counter = counter + 1;
			end else if (board[6]==`O)begin
				//he got top right
				oppCounter = oppCounter + 1;
			end

			if(board[7]==`X)begin
				//k i got the middle
				counter = counter + 1;
			end else if (board[7]==`O)begin
				//he got middle
				oppCounter = oppCounter + 1;
			end

			if(board[8] ==`X)begin
				//ok i got bottom left
				counter = counter + 1;
			end else if (board[8] == `O)begin
				//he got bottom left
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

			if (board[0]==`X)begin
				//ok I got the top left corner
				counter = counter + 1;
			end else if (board[0]==`O)begin
				//he got top left
				oppCounter = oppCounter + 1;
			end

			if(board[3]==`X)begin
				//k i got the middle left
				counter = counter + 1;
			end else if (board[3]==`O)begin
				//he got middle left
				oppCounter = oppCounter + 1;
			end

			if(board[6]==`X)begin
				//ok i got bottom left
				counter = counter + 1;
			end else if (board[6]==`O)begin
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

			if (board[1]==`X)begin
				//ok I got the top middle
				counter = counter + 1;
			end else if (board[1]==`O)begin
				//he got top middle
				oppCounter = oppCounter + 1;
			end

			if(board[4]==`X)begin
				//k i got the center
				counter = counter + 1;
			end else if (board[4]==`O)begin
				//he got center
				oppCounter = oppCounter + 1;
			end

			if(board[7]==`X)begin
				//ok i got bottom middle
				counter = counter + 1;
			end else if (board[7]==`O)begin
				//he got bottom middle
				oppCounter = oppCounter + 1;
			end

			if (counter == 3 || oppCounter == 3) begin
				canIWinSecondColumnVal = `EXIT_CODE; //somebody has 3 in a row
			end else if (counter !=0 && oppCounter != 0) begin
				canIWinSecondColumnVal = `CONTESTED; //no way to win here. He owns at least one tile and so do I
			end else if (counter == 2 && oppCounter == 0) begin
				canIWinSecondColumnVal = `FORTHEWIN;
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

			if (board[2]==`X)begin
				//ok I got the top right
				counter = counter + 1;
			end

			else if (board[2]==`O)begin
				//he got top right
				oppCounter = oppCounter + 1;
			end

			if(board[5]==`X)begin
				//k i got the center
				counter = counter + 1;
			end

			else if (board[5]==`O)begin
				//he got center
				oppCounter = oppCounter + 1;
			end

			if(board[7]==`X)begin
				//ok i got bottom middle
				counter = counter + 1;
			end

			else if (board[7]==`O)begin
				//he got bottom middle
				oppCounter = oppCounter + 1;
			end

			if (counter == 3 || oppCounter == 3) begin
				canIWinThirdRowVal = `EXIT_CODE; //somebody has 3 in a row
			end

			else if (counter !=0 && oppCounter != 0) begin
				canIWinThirdRowVal = `CONTESTED; //no way to win here. He owns at least one tile and so do I
			end

			else if (counter == 2 && oppCounter == 0) begin
				canIWinThirdRowVal = `FORTHEWIN;
			end

			else if (counter ==0 && oppCounter ==2) begin
				canIWinThirdRowVal = `BLOCK; //hes about to win make this my priority
			end

			else begin
				canIWinThirdRowVal = counter; //will return how close I am to winning diagonally left
			end


		end

	endtask

	/*
/**
	  * Returns a 1 if its taken by an X, 0 otherwise

	function real takenByX(integer specificSpot);
		begin
			if (specificSpot == `X)begin
				takenByX = 1;
			end else begin
				takenByX = 0;
			end
		end
	endtask

	/**
	  * Returns a 1 if its taken by an O, 0 otherwise

	function real takenByO(integer specificSpot);
		begin
			if (specificSpot == 'O) begin
				takenByO = 1;
			end else begin
				takenByO = 0;
			end
		end
	endfunction

	/**
	  * Returns a 1 if its empty, 0 otherwise
	  */
	task isEmpty();
		begin
			if (board[0] == `EMPTY) begin
				isEmpty0 = 1;
			end
			if (board[1] == `EMPTY) begin
				isEmpty1 = 1;
			end
			if (board[2] == `EMPTY) begin
				isEmpty2 = 1;
			end
			if (board[3] == `EMPTY) begin
				isEmpty3 = 1;
			end
			if (board[4] == `EMPTY) begin
				isEmpty4 = 1;
			end
			if (board[5] == `EMPTY) begin
				isEmpty5 = 1;
			end
			if (board[6] == `EMPTY) begin
				isEmpty6 = 1;
			end
			if (board[7] == `EMPTY) begin
				isEmpty7 = 1;
			end
			if (board[8] == `EMPTY) begin
				isEmpty8 = 1;
			end

		end
	endtask

	/* Might go turn by turn as in deploy by deploy

	/*
	 * I'm not actually sure if we want this. Basically tells whos turn it is but I'm not sure if we want to do this. IDK

	function real determineTurn(real blah);
		begin
			integer xCounter = 0;
			integer oCounter = 0;
			for (int i = 0; i < 9; i++) begin
					if (board[i]== `X) begin
						xCounter++;
					end else if (board[i] == 'O) begin
						oCounter++;
					end
			end

			if (xCounter > oCounter) begin
				determineTurn =  'O; //there are more x's on the board than o's its the o's turn
			end else begin
				determineTurn = `X;
			end
		end
	endfunction

	*/

	//determine turn
	//check if finished (check if three in row and check if the board is filled) cool
	//simulate game....confused as to how to implement. Supposedly we do test cases similar to how the calculator was and dont do keyboard input
	//determine Priority check
	//insertCharacter check
	//isTakenByX //done
	//isTakenByO done
	//isEmpty done
	//print the board HANDLED BY MONITOR
	//can I win horizontally done row by row for fault reasons and to make it easier to flag which row had what.
	//can i win vertically good but brackets are fucked up in third one. cant spot error
	//can i win diagonally left ok
	//can i win diagonally right ok
	//init the board CHECK
	//is the board filled CHECK

	/* there is a bug for case X O X
							   - X O
							   O X O
	Solution is to add redundancy. If no prioritiy is assigned find an open spot
	*/

endmodule
