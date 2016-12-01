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
simulation mySimulation(userInput,sendSignal);

initial begin

	//Playing a full game where we tie :').
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
	#5 sendSignal = 0;


/* //This test case works in our favor (we win)
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
	   sendSignal = 1;*/
end

endmodule

module simulation(input integer userInput,input reg sendSignal);

	integer canIWinFirstRowVal;
	integer canIWinSecondRowVal;
	integer canIWinThirdRowVal;
	integer canIWinFirstColumnVal;
	integer canIWinSecondColumnVal;
	integer canIWinThirdColumnVal;
	integer canIWinDiagonallyLeftVal;
	integer canIWinDiagonallyRightVal;

	reg isEmpty0 =1;
	reg isEmpty1 =1;
	reg isEmpty2 =1;
	reg isEmpty3 =1;
	reg isEmpty4 =1;
	reg isEmpty5 =1;
	reg isEmpty6 =1;
	reg isEmpty7 =1;
	reg isEmpty8 =1;


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
		checkIfFinished();
		if (myPriority == -1) begin //if every priority returns garbage
			redundancy(); //insert an x into the first open spot found
		end
		else begin
		 insertX(); //now actually insert an x that is logical
		$display(board[0], " ",board[1]," ",board[2],"\n",board[3], " ",board[4]," ",board[5],"\n",board[6], " ",board[7]," ",board[8]); //hopefully this looks somewhat right and technically this should update when these values update;
		$display("X inserted, MyPriority was: ",myPriority, "\n\n\n\n");
		end
		#2 // I want the user to see if someone won
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
		board[0] = 0;
		board[1] = 0;
		board[2] = 0;
		board[3] = 0;
		board[4] = 0;
		board[5] = 0;
		board[6] = 0;
		board[7] = 0;
		board[8] = 0;

	end
	endtask


	/*
	 * Function that will see if the game is finished or not. Bool return (in verilog its reg because verilog is so damn cool)
	 */
	task checkIfFinished();
		begin
			if (canIWinDiagonallyLeftVal == 999 || canIWinDiagonallyRightVal == 999 ||
					canIWinFirstRowVal == 999 || canIWinSecondRowVal == 999 || canIWinThirdRowVal == 999||
					canIWinFirstColumnVal == 999 || canIWinSecondColumnVal == 999 || canIWinThirdColumnVal == 999 ||
					isBoardFullVal == 1)
				begin
					//someone won somehow or the board was filled
					checkIfFinishedVal = 1;
					$display(board[0], " ",board[1]," ",board[2],"\n",board[3], " ",board[4]," ",board[5],"\n",board[6], " ",board[7]," ",board[8]); //hopefully this looks somewhat right and technically this should update when these values update;
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
			currentMatches = -1;
			myPriority = -1; //rezero these
			canIWinFirstRowVal =0;
			canIWinSecondRowVal=0;
			canIWinThirdRowVal=0;
	 		canIWinFirstColumnVal=0;
	 		canIWinSecondColumnVal=0;
	 		canIWinThirdColumnVal=0;
			canIWinDiagonallyLeftVal=0;
			canIWinDiagonallyRightVal=0;

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
			//If these things run in parallel and I get threading problems I'm going to be upset
			if (canIWinDiagonallyLeftVal > currentMatches) begin
				myPriority = 1;
				currentMatches = canIWinDiagonallyLeftVal;
			end

			if (canIWinDiagonallyRightVal > currentMatches) begin
				currentMatches = canIWinDiagonallyRightVal;
				myPriority = 2;
			end

			if (canIWinFirstColumnVal > currentMatches) begin
				currentMatches = canIWinFirstColumnVal;
				myPriority = 3;
			end

			if (canIWinSecondColumnVal > currentMatches) begin
				currentMatches = canIWinSecondColumnVal;
				myPriority = 4;
			end

			if (canIWinThirdColumnVal > currentMatches) begin
				currentMatches = canIWinThirdColumnVal;
				myPriority = 5;
			end

			if (canIWinFirstRowVal > currentMatches) begin
				currentMatches = canIWinFirstRowVal;
				myPriority = 6;
			end

			if (canIWinSecondRowVal > currentMatches) begin
				currentMatches = canIWinSecondRowVal;
				myPriority = 7;
			end

			if (canIWinThirdRowVal > currentMatches) begin
				currentMatches = canIWinThirdRowVal;
				myPriority = 8;
			end
		end
	endtask

	/*
	 * Method responsible for actually inserting an x into the board. Called after move priority is determined.
	 */
	task insertX();
		begin
			//L DIAG
			if (myPriority== 1) begin
				//checks all the left diag spots to find missing and fill
				if (isEmpty4 == 1) begin
					//middle is always priority
					board[4]=2;
					$display("Box was: 4");
				end

				else if (isEmpty0 == 1) begin
					//I already had middle take top left
					board[0]=2;
					$display("Box was: 0");
				end

				else begin
					//I already had top left and middle take bottom right. Could add redundancy
					board[8]=2;
					$display("Box was: 8");
				end
			end
			//R DIAG
			else if(myPriority==2) begin
				//checks all the right diag spots to find missing and fill
				if (isEmpty4==1) begin
					//middle is always priority
					board[4]=2;
					$display("Box was: 4");
					$display(isEmpty4);
				end

				else if (isEmpty6==1) begin
					//I already had middle take bottom left
					board[6] =2;
					$display("Box was: 6");
				end

				else begin
					//I already had bottom left and middle take top right. Could add redundancy
					board[2]=2;
					$display("Box was: 2");
				end
			end
			//Verilog is the kid who just licks the walls in elementary school
			//1st row
			else if (myPriority == 6) begin
				if (isEmpty0==1) begin
					//top left
					board[0] = 2;
					$display("Box was: 0");
				end

				else if (isEmpty1==1) begin
					//top middle
					board[1] = 2;
					$display("Box was: 1");
				end

				 else if (isEmpty2==1) begin
					//bottom left
					board[2] = 2;
					$display("Box was: 2");
				end
			end
			//2nd row
			else if (myPriority == 7) begin
				if (isEmpty3 ==1) begin
					//middle left
					board[3] = 2;
					$display("Box was: 3");
				end

				else if (isEmpty4 ==1) begin
					//middle middle
					board[4] = 2;
					$display("Box was: 4");
				end

				else if (isEmpty5==1) begin
					//bottom middle
					board[5] = 2;
					$display("Box was: 5");
				end
			end
			//third row
			else if (myPriority == 8) begin
				if (isEmpty6 ==1) begin
					//bottom right
					board[6] = 2;
					$display("Box was: 6");
				end

				else if (isEmpty7 ==1) begin
					//bottom middle
					board[7] = 2;
					$display("Box was: 7");
				end

				else if (isEmpty8 ==1) begin
					//bottom right
					board[8] = 2;
					$display("Box was: 8");
				end
			end
			//first column
			else if (myPriority == 3) begin
				if (isEmpty0 == 1) begin
					//top left
					board[0] = 2;
					$display("Box was: 0");
				end

				else if (isEmpty3 ==1) begin
					//middle left
					board[3] = 2;
					$display("Box was: 3");
				end

				else if (isEmpty6 ==1) begin
					//bottom left
					board[6] = 2;
					$display("Box was: 6");
				end
			end
			//second column
			else if (myPriority == 4) begin
				if (isEmpty1 ==1) begin
					//top middle
					board[1] = 2;
					$display("Box was: 1");
				end

				else if (isEmpty4 ==1) begin
					//middle middle
					board[4] = 2;
					$display("Box was: 4");
				end

				else if (isEmpty7 ==1) begin
					//middle bottom
					board[7] = 2;
					$display("Box was: 7");
				end
			end
			//third column
			else if (myPriority == 5) begin
				if (isEmpty2 ==1) begin
					//top right
					board[2] = 2;
					$display("Box was: 2");
				end

				else if (isEmpty5 ==1) begin
					//middle right
					board[5] = 2;
					$display("Box was: 5");
				end

				else if (isEmpty8 == 1) begin
					//bottom right
					board[8] = 2;
					$display("Box was: 8");
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


		if (board[0] == 0 && used ==0)begin
			board[0] = 2;
			used =1;
		end
		if (board[1] == 0 && used ==0)begin
			board[1] = 2;
			used =1;
		end
		if (board[2] == 0 && used ==0)begin
			board[2] = 2;
			used =1;
		end
		if (board[3] == 0 && used ==0)begin
			board[3] = 2;
			used =1;
		end
		if (board[4] == 0 && used ==0)begin
			board[4] = 2;
			used =1;
		end
		if (board[5] == 0 && used ==0)begin
			board[5] = 2;
			used =1;
		end
		if (board[6] == 0 && used ==0)begin
			board[6] = 2;
			used =1;
		end
		if (board[7] == 0 && used ==0)begin
			board[7] = 2;
			used =1;
		end
		if (board[8] == 0 && used ==0)begin
			board[8] = 2;
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
		if (board[0] == 0 && isBoardFullVal==1)begin
			isBoardFullVal =0;
		end
		if (board[1] == 0 && isBoardFullVal==1)begin
			isBoardFullVal =0;
		end
		if (board[2] == 0 && isBoardFullVal==1)begin
			isBoardFullVal =0;
		end
		if (board[3] == 0 && isBoardFullVal==1)begin
			isBoardFullVal =0;
		end
		if (board[4] == 0 && isBoardFullVal==1)begin
			isBoardFullVal =0;
		end
		if (board[5] == 0 && isBoardFullVal==1)begin
			isBoardFullVal =0;
		end
		if (board[6] == 0 && isBoardFullVal==1)begin
			isBoardFullVal =0;
		end
		if (board[7] == 0 && isBoardFullVal==1)begin
			isBoardFullVal =0;
		end
		if (board[8] == 0 && isBoardFullVal==1)begin
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

			if (board[0] == 2)begin
				//ok I got the top left corner
				counter = counter + 1;
			end else if (board[0] == 1 )begin
				//he got top left
				oppCounter = oppCounter + 1;
			end

			if(board[4] == 2)begin
				//k i got the middle
				counter = counter + 1;
			end else if (board[4] == 1)begin
				//he got middle
				oppCounter = oppCounter + 1;
			end

			if(board[8] == 2)begin
				//ok i got bottom right
				counter = counter + 1;
			end else if (board[8] == 1)begin
				//he got bottom right
				oppCounter = oppCounter + 1;
			end

			if (counter == 3 || oppCounter == 3) begin
				canIWinDiagonallyLeftVal = 999; //somebody has 3 in a row
			end else if (counter !=0 && oppCounter != 0) begin
				canIWinDiagonallyLeftVal = -2; //no way to win here. He owns at least one tile and so do I
			end else if (counter == 2 && oppCounter == 0) begin
				canIWinDiagonallyLeftVal = 666; //I'm about to win
			end else if (counter ==0 && oppCounter ==2) begin
				canIWinDiagonallyLeftVal = 3; //hes about to win make this my priority
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

			if (board[2] == 2)begin
				//ok I got the top right corner
				counter = counter + 1;
			end else if (board[2]==1)begin
				//he got top right
				oppCounter = oppCounter + 1;
			end

			if(board[4]== 2)begin
				//k i got the middle
				counter = counter + 1;
			end else if (board[4]==1)begin
				//he got middle
				oppCounter = oppCounter + 1;
			end

			if(board[6] == 2)begin
				//ok i got bottom left
				counter = counter + 1;
			end else if (board[6] ==1)begin
				//he got bottom left
				oppCounter = oppCounter + 1;
			end

			if (counter == 3 || oppCounter == 3) begin
				canIWinDiagonallyRightVal= 999; //somebody has 3 in a row
			end else if (counter !=0 && oppCounter != 0) begin
				canIWinDiagonallyRightVal = -2; //no way to win here. He owns at least one tile and so do I
			end else if (counter == 2 && oppCounter == 0) begin
				canIWinDiagonallyRightVal = 666; //I'm about to win
			end else if (counter ==0 && oppCounter ==2) begin
				canIWinDiagonallyRightVal = 3; //hes about to win make this my priority
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

			if (board[0] == 2)begin
				//ok I got the top right corner
				counter = counter + 1;
			end else if (board[0] == 1)begin
				//he got top right
				oppCounter = oppCounter + 1;
			end

			if(board[1] == 2)begin
				//k i got the middle
				counter = counter + 1;
			end else if (board[1] == 1)begin
				//he got middle
				oppCounter = oppCounter + 1;
			end

			if(board[2] == 2)begin
				//ok i got bottom left
				counter = counter + 1;
			end else if (board[2] == 1)begin
				//he got bottom left
				oppCounter = oppCounter + 1;
			end

			if (counter == 3 || oppCounter == 3) begin
				canIWinFirstRowVal = 999; //somebody has 3 in a row
			end else if (counter !=0 && oppCounter != 0) begin
				canIWinFirstRowVal = -2; //no way to win here. He owns at least one tile and so do I
			end else if (counter == 2 && oppCounter == 0) begin
				canIWinFirstRowVal = 666; //I'm about to win
			end else if (counter ==0 && oppCounter ==2) begin
				canIWinFirstRowVal = 3; //hes about to win make this my priority
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

			if (board[3] == 2)begin
				//ok I got the middle left
				counter = counter + 1;
			end else if (board[3] == 1)begin
				//he got middle left
				oppCounter = oppCounter + 1;
			end

			if(board[4] ==`X)begin
				//k i got the middle
				counter = counter + 1;
			end else if (board[4] == 1)begin
				//he got middle
				oppCounter = oppCounter + 1;
			end

			if(board[5] == 2)begin
				//ok i got middle right
				counter = counter + 1;
			end else if (board[5] == 1)begin
				//he got middle right
				oppCounter = oppCounter + 1;
			end

			if (counter == 3 || oppCounter == 3) begin
				canIWinSecondRowVal = 999; //somebody has 3 in a row
			end else if (counter !=0 && oppCounter != 0) begin
				canIWinSecondRowVal = -2; //no way to win here. He owns at least one tile and so do I
			end else if (counter == 2 && oppCounter == 0) begin
				canIWinSecondRowVal = 666; //I'm about to win
			end else if (counter ==0 && oppCounter ==2) begin
				canIWinSecondRowVal = 3; //hes about to win make this my priority
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

			if (board[6]==2)begin
				//ok I got the bottom left corner
				counter = counter + 1;
			end else if (board[6]==1)begin
				//he got bottom left
				oppCounter = oppCounter + 1;
			end

			if(board[7]==2)begin
				//k i got the bottom middle
				counter = counter + 1;
			end else if (board[7]==1)begin
				//he got bottom middle
				oppCounter = oppCounter + 1;
			end

			if(board[8] ==2)begin
				//ok i got bottom right
				counter = counter + 1;
			end else if (board[8] == 1)begin
				//he got bottom right
				oppCounter = oppCounter + 1;
			end

			if (counter == 3 || oppCounter == 3) begin
				canIWinThirdRowVal = 999; //somebody has 3 in a row
			end else if (counter !=0 && oppCounter != 0) begin
				canIWinThirdRowVal = -2; //no way to win here. He owns at least one tile and so do I
			end else if (counter == 2 && oppCounter == 0) begin
				canIWinThirdRowVal = 666; //I'm about to win
			end else if (counter ==0 && oppCounter ==2) begin
				canIWinThirdRowVal = 3; //hes about to win make this my priority
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

			if (board[0]==2)begin
				//ok I got the top left corner
				counter = counter + 1;
			end else if (board[0]==1)begin
				//he got top left
				oppCounter = oppCounter + 1;
			end

			if(board[3]==2)begin
				//k i got the middle left
				counter = counter + 1;
			end else if (board[3]==1)begin
				//he got middle left
				oppCounter = oppCounter + 1;
			end

			if(board[6]==2)begin
				//ok i got bottom left
				counter = counter + 1;
			end else if (board[6]==1)begin
				//he got bottom left
				oppCounter = oppCounter + 1;
			end

			if (counter == 3 || oppCounter == 3) begin
				canIWinFirstColumnVal = 999; //somebody has 3 in a row
			end else if (counter !=0 && oppCounter != 0) begin
				canIWinFirstColumnVal = -2; //no way to win here. He owns at least one tile and so do I
			end else if (counter == 2 && oppCounter == 0) begin
				canIWinFirstColumnVal = 666; //I'm about to win
			end else if (counter ==0 && oppCounter ==2) begin
				canIWinFirstColumnVal = 3; //hes about to win make this my priority
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

			if (board[1]==2)begin
				//ok I got the top middle
				counter = counter + 1;
			end else if (board[1]==1)begin
				//he got top middle
				oppCounter = oppCounter + 1;
			end

			if(board[4]==2)begin
				//k i got the center
				counter = counter + 1;
			end else if (board[4]==1)begin
				//he got center
				oppCounter = oppCounter + 1;
			end

			if(board[7]==2)begin
				//ok i got bottom middle
				counter = counter + 1;
			end else if (board[7]==1)begin
				//he got bottom middle
				oppCounter = oppCounter + 1;
			end

			if (counter == 3 || oppCounter == 3) begin
				canIWinSecondColumnVal = 999; //somebody has 3 in a row
			end else if (counter !=0 && oppCounter != 0) begin
				canIWinSecondColumnVal = -2; //no way to win here. He owns at least one tile and so do I
			end else if (counter == 2 && oppCounter == 0) begin
				canIWinSecondColumnVal = 666;
			end else if (counter ==0 && oppCounter ==2) begin
				canIWinSecondColumnVal = 3; //hes about to win make this my priority
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

			if (board[2]==2)begin
				//ok I got the top right
				counter = counter + 1;
			end

			else if (board[2]==1)begin
				//he got top right
				oppCounter = oppCounter + 1;
			end

			if(board[5]==2)begin
				//k i got middle right
				counter = counter + 1;
			end

			else if (board[5]==1)begin
				//he got middle right
				oppCounter = oppCounter + 1;
			end

			if(board[8]==2)begin
				//ok i got bottom right
				counter = counter + 1;
			end

			else if (board[8]==1)begin
				//he got bottom right
				oppCounter = oppCounter + 1;
			end

			if (counter == 3 || oppCounter == 3) begin
				canIWinThirdColumnVal = 999; //somebody has 3 in a row
			end

			else if (counter !=0 && oppCounter != 0) begin
				canIWinThirdColumnVal = -2; //no way to win here. He owns at least one tile and so do I
			end

			else if (counter == 2 && oppCounter == 0) begin
				canIWinThirdColumnVal = 666;
			end

			else if (counter ==0 && oppCounter ==2) begin
				canIWinThirdColumnVal = 3; //hes about to win make this my priority
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
			if (board[0] != 0) begin
				isEmpty0 = 0;
			end
			if (board[1] != 0) begin
				isEmpty1 = 0;
			end
			if (board[2] != 0) begin
				isEmpty2 = 0;
			end
			if (board[3] != 0) begin
				isEmpty3 = 0;
			end
			if (board[4] != 0) begin
				isEmpty4 = 0;
				//$display("4 is filled now");
			end
			if (board[5] != 0) begin
				isEmpty5 = 0;
			end
			if (board[6] != 0) begin
				isEmpty6 = 0;
			end
			if (board[7] != 0) begin
				isEmpty7 = 0;
			end
			if (board[8] != 0) begin
				isEmpty8 = 0;
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
					if (board[i]== 2) begin
						xCounter++;
					end else if (board[i] == 'O) begin
						oCounter++;
					end
			end

			if (xCounter > oCounter) begin
				determineTurn =  'O; //there are more x's on the board than o's its the o's turn
			end else begin
				determineTurn = 2;
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


endmodule
