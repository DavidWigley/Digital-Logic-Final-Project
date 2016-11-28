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

integer userInput = -1;
simulation(userInput);

initial begin
	#2 userInput = 5;
	#5 userInput = 8;
	#5 userInput = 3;

end

endmodule

module simulation(integer userInput);

	wire [7:0]result;
	wire overflow;
	integer board [8:0]; //a 9 element array storing all slots on the board
	integer errorMessage = 0; //this will become -1 if the user enters an invalid input and will bypass the rest of the simulation

	//I dont want to deal with passing this shit around and we're not graded on efficiency ... SO GLOBAL :)
	integer currentMatches = -1; //essentially how many x's I have in a certain winning combo unless its blocked
	integer myPriority = -1; //matches and priority are both keywords. Basically fuck verilog, its just too good.

	//Here is what the board will look like
	//  0    1    2
	//  3    4    5
	//  6    7    8


	initial begin
	initBoard(); // initialize the board (this should onley happen once)
		//So basically this is our print. TODO
		$monitor("| ",box[0], " | ",box[1]," | ",box[2],"\n ____________ "," \n | ",box[3], " | ",box[4]," | ",box[5],"\n ____________ ","\n | ",box[6], " | ",box[7]," | ",box[8]); //hopefully this looks somewhat right and technically this should update when these values update;
	end


	always@* begin
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
	task initBoard();
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

	endtask


	/*
	 * Function that will see if the game is finished or not. Bool return (in verilog its reg because verilog is so damn cool)
	 */
	function reg checkIfFinished(input verilogIsTrash);
		begin
			if (canIWinDiagonallyLeft(1) == `EXIT_CODE || canIWinDiagonallyRight(1) == `EXIT_CODE ||
					canIWinFirstRow(1) == `EXIT_CODE || canIWinSecondRow(1) == `EXIT_CODE || canIWinThirdRow(1) ||
					canIWinFirstColumn(1) == `EXIT_CODE || canIWinSecondColumn(1) == `EXIT_CODE || canIWinThirdColumn(1) == `EXIT_CODE ||
					isBoardFull(1) == 1)
				begin
					//someone won somehow or the board was filled
					checkIfFinished = 1;
					$finish // believe this is how you exit in verilog. Could always just stand behind carpenter when he plays then when he wins
					//or the board is full throw a hammar at his screen
				end
			else begin
				checkIfFinished = 0; //nobody has won yet
			end
		end
	endfunction

	/*
	 * Method that will search through winning combinations and prioritize a move depending on the board's current layout
	 */
	task determinePriority();
		begin
			//So basically this logic will look to see if I can win immediately or stop him
			//from winning immediately. If I cant then I'll choose the next best possible option prioritizing the diags
			currentMatches = -1;
			myPriority = -1; //rezero these

			//These must be if's and not else ifs because they all need to check. Else if would break after 1.
			//If these things run in parallel and I get threading problems I'm going to be upset
			if (canIWinDiagonallyLeft(1) > currentMatches) begin
				myPriority = `LDIAG;
				currentMatches = canIWinDiagonallyLeft(1);
			end

			if (canIWinDiagonallyRight(1) > currentMatches) begin
				currentMatches = canIWinDiagonallyRight(1);
				myPriority = `RDIAG;
			end

			if (canIWinFirstColumn(1) > currentMatches) begin
				currentMatches = canIWinFirstColumn(1);
				myPriority = `VERT1;
			end

			if (canIWinSecondColumn(1) > currentMatches) begin
				currentMatches = canIWinSecondColumn(1);
				myPriority = `VERT2;
			end

			if (canIWinThirdColumn(1) > currentMatches) begin
				currentMatches = canIWinThirdColumn(1);
				myPriority = `VERT3;
			end

			 if (canIWinFirstRow(1) > currentMatches) begin
				currentMatches = canIWinFirstRow(1);
				myPriority = `HORIZ1;
			end

			if (canIWinSecondRow(1) > currentMatches) begin
				currentMatches = canIWinSecondRow(1);
				myPriority = `HORIZ2;
			end

			if (canIWinThirdRow(1) > currentMatches) begin
				currentMatches = canIWinThirdRow(1);
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
				if (isEmpty(board[4])) begin
					//middle is always priority
					board[4]=`X;
				end else if (isEmpty(board[0])) begin
					//I already had middle take top left
					board[0]=`X;
				end else begin
					//I already had top left and middle take bottom right. Could add redundancy
					board[8]=`X;
				end
			end
			else if(myPriority==`RDIAG) begin
				//checks all the right diag spots to find missing and fill
				if (isEmpty(board[4])) begin
					//middle is always priority
					board[4]=`X;
				end
				else if (isEmpty(board[6])) begin
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
				if (isEmpty(board[0])) begin
					//top left
					board[0] = `X;
				end else if (isEmpty(board[3])) begin
					//middle left
					board[3] = `X;
				end else if (isEmpty(board[6])) begin
					//bottom left
					board[6] = `X;
				end
			end
			else if (myPriority == `VERT2) begin
				if (isEmpty(board[1])) begin
					//top middle
					board[1] = `X;
				end else if (isEmpty(board[4])) begin
					//middle middle
					board[4] = `X;
				end else if (isEmpty(board[7])) begin
					//bottom middle
					board[7] = `X;
				end
			end
			else if (myPriority == `VERT3) begin
				if (isEmpty(board[2])) begin
					//top right
					board[2] = `X;
				end else if (isEmpty(board[5])) begin
					//middle right
					board[5] = `X;
				end else if (isEmpty(board[8])) begin
					//bottom right
					board[8] = `X;
				end
			end
			else if (myPriority == `HORIZ1) begin
				if (isEmpty(board[0])) begin
					//top left
					board[0] = `X;
				end else if (isEmpty(board[1])) begin
					//top middle
					board[1] = `X;
				end else if (isEmpty(board[2])) begin
					//bottom middle
					board[2] = `X;
				end
			end
			else if (myPriority == `HORIZ2) begin
				if (isEmpty(board[3])) begin
					//middle left
					board[3] = `X;
				end else if (isEmpty(board[4])) begin
					//middle middle
					board[4] = `X;
				end else if (isEmpty(board[5])) begin
					//middle right
					board[5] = `X;
				end
			end
			else if (myPriority == `HORIZ3) begin
				if (isEmpty(board[6])) begin
					//bottom left
					board[6] = `X;
				end else if (isEmpty(board[7])) begin
					//bottom middle
					board[7] = `X;
				end else if (isEmpty(board[8])) begin
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
		integer used = 0;

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
	function reg isBoardFull(input in);
		begin
			integer isBoardFull = 1; //its full unless I say otherwise

		if (board[0] == `EMPTY && isBoardFull==1)begin
		isBoardFull =0;
		end
		if (board[1] == `EMPTY && isBoardFull==1)begin
		isBoardFull =0;
		end
		if (board[2] == `EMPTY && isBoardFull==1)begin
		isBoardFull =0;
		end
		if (board[3] == `EMPTY && isBoardFull==1)begin
		isBoardFull =0;
		end
		if (board[4] == `EMPTY && isBoardFull==1)begin
		isBoardFull =0;
		end
		if (board[5] == `EMPTY && isBoardFull==1)begin
		isBoardFull =0;
		end
		if (board[6] == `EMPTY && isBoardFull==1)begin
		isBoardFull =0;
		end
		if (board[7] == `EMPTY && isBoardFull==1)begin
		isBoardFull =0;
		end
		if (board[7] == `EMPTY && isBoardFull==1)begin
		isBoardFull =0;
		end

			//outer loop is for every single spot
			/*for (integer box =0; box < 9; box ++) begin
				//inner loop is for every bit in the spot
				if (board[box][0] == 0 )begin
					//something is empty
					isBoardFull = 0; //it is not full
				end
			end*/

		end
	endfunction


	/**
	  * Ok so my outputs here are going to be -2 if its garbage
	  * TODO
 	  */
	function integer canIWinDiagonallyLeft(input aaronCarpenterSucksEggs);
		begin
			integer counter =0;
			integer oppCounter = 0;

			if (takenByX(board[0]))begin
				//ok I got the top left corner
				counter = counter + 1;
			end else if (takenByO(board[0]))begin
				//he got top left
				oppCounter = oppCounter + 1;
			end

			if(takenByX(board[4]))begin
				//k i got the middle
				counter = counter + 1;
			end else if (takenByO(board[4]))begin
				//he got middle
				oppCounter = oppCounter + 1;
			end

			if(takenByX(board[8]))begin
				//ok i got bottom right
				counter = counter + 1;
			end else if (takenByO(board[8]))begin
				//he got bottom right
				oppCounter = oppCounter + 1;
			end

			if (counter == 3 || oppCounter == 3) begin
				canIWinDiagonallyLeft = `EXIT_CODE; //somebody has 3 in a row
			end else if (counter !=0 && oppCounter != 0) begin
				canIWinDiagonallyLeft = `CONTESTED; //no way to win here. He owns at least one tile and so do I
			end else if (counter == 2 && oppCounter == 0) begin
				canIWinDiagonallyLeft = `FORTHEWIN; //I'm about to win
			end else if (counter ==0 && oppCounter ==2) begin
				canIWinDiagonallyLeft = `BLOCK; //hes about to win make this my priority
			end else begin
				canIWinDiagonallyLeft = counter; //will return how close I am to winning diagonally left
			end
		end
	endfunction

	/**
	  * Ok so my outputs here are going to be -2 if its garbage
	  * TODO
 	  */
	function integer canIWinDiagonallyRight(input aaronCarpenterSucksEggs);
		begin
			integer counter =0;
			integer oppCounter = 0;

			if (takenByX(board[2]))begin
				//ok I got the top right corner
				counter = counter + 1;
			end else if (takenByO(board[2]))begin
				//he got top right
				oppCounter = oppCounter + 1;
			end

			if(takenByX(board[4]))begin
				//k i got the middle
				counter = counter + 1;
			end else if (takenByO(board[4]))begin
				//he got middle
				oppCounter = oppCounter + 1;
			end

			if(takenByX(board[6]))begin
				//ok i got bottom left
				counter = counter + 1;
			end else if (takenByO(board[6]))begin
				//he got bottom left
				oppCounter = oppCounter + 1;
			end

			if (counter == 3 || oppCounter == 3) begin
				canIWinDiagonallyRight= `EXIT_CODE; //somebody has 3 in a row
			end else if (counter !=0 && oppCounter != 0) begin
				canIWinDiagonallyRight = `CONTESTED; //no way to win here. He owns at least one tile and so do I
			end else if (counter == 2 && oppCounter == 0) begin
				canIWinDiagonallyRight = `FORTHEWIN; //I'm about to win
			end else if (counter ==0 && oppCounter ==2) begin
				canIWinDiagonallyRight = `BLOCK; //hes about to win make this my priority
			end else begin
				canIWinDiagonallyRight = counter; //will return how close I am to winning diagonally left
			end
		end
	endfunction

	/**
	 * Method that checks if the computer can win horizontally on the first row if not ranks how close or garbage
	 */
	function integer canIWinFirstRow(input tinaPoodInCarpentersBed);

		begin
			integer counter =0;
			integer oppCounter = 0;

			if (takenByX(board[0]))begin
				//ok I got the top right corner
				counter = counter + 1;
			end else if (takenByO(board[0]))begin
				//he got top right
				oppCounter = oppCounter + 1;
			end

			if(takenByX(board[1]))begin
				//k i got the middle
				counter = counter + 1;
			end else if (takenByO(board[1]))begin
				//he got middle
				oppCounter = oppCounter + 1;
			end

			if(takenByX(board[2]))begin
				//ok i got bottom left
				counter = counter + 1;
			end else if (takenByO(board[2]))begin
				//he got bottom left
				oppCounter = oppCounter + 1;
			end

			if (counter == 3 || oppCounter == 3) begin
				canIWinFirstRow = `EXIT_CODE; //somebody has 3 in a row
			end else if (counter !=0 && oppCounter != 0) begin
				canIWinFirstRow = `CONTESTED; //no way to win here. He owns at least one tile and so do I
			end else if (counter == 2 && oppCounter == 0) begin
				canIWinFirstRow = `FORTHEWIN; //I'm about to win
			end else if (counter ==0 && oppCounter ==2) begin
				canIWinFirstRow = `BLOCK; //hes about to win make this my priority
			end else begin
				canIWinFirstRow = counter; //will return how close I am to winning diagonally left
			end
		end
	endfunction

	/**
	 * Method that checks if the computer can win horizontally on the second row if not ranks how close or garbage
	 */
	function integer canIWinSecondRow(input tinaPoodInCarpentersBed);

		begin
			integer counter =0;
			integer oppCounter = 0;

			if (takenByX(board[3]))begin
				//ok I got the top right corner
				counter = counter + 1;
			end else if (takenByO(board[3]))begin
				//he got top right
				oppCounter = oppCounter + 1;
			end

			if(takenByX(board[4]))begin
				//k i got the middle
				counter = counter + 1;
			end else if (takenByO(board[4]))begin
				//he got middle
				oppCounter = oppCounter + 1;
			end

			if(takenByX(board[5]))begin
				//ok i got bottom left
				counter = counter + 1;
			end else if (takenByO(board[5]))begin
				//he got bottom left
				oppCounter = oppCounter + 1;
			end

			if (counter == 3 || oppCounter == 3) begin
				canIWinSecondRow = `EXIT_CODE; //somebody has 3 in a row
			end else if (counter !=0 && oppCounter != 0) begin
				canIWinSecondRow = `CONTESTED; //no way to win here. He owns at least one tile and so do I
			end else if (counter == 2 && oppCounter == 0) begin
				canIWinSecondRow = `FORTHEWIN; //I'm about to win
			end else if (counter ==0 && oppCounter ==2) begin
				canIWinSecondRow = `BLOCK; //hes about to win make this my priority
			end else begin
				canIWinSecondRow = counter; //will return how close I am to winning diagonally left
			end
		end
	endfunction

	/**
	 * Method that checks if the computer can win horizontally on the third row if not ranks how close or garbage
	 */
	function integer canIWinThirdRow(input alexPoodInCarpentersBedbutmostlytina); //ew tina gross

		begin
			integer counter =0;
			integer oppCounter = 0;

			if (takenByX(board[6]))begin
				//ok I got the top right corner
				counter = counter + 1;
			end else if (takenByO(board[6]))begin
				//he got top right
				oppCounter = oppCounter + 1;
			end

			if(takenByX(board[7]))begin
				//k i got the middle
				counter = counter + 1;
			end else if (takenByO(board[7]))begin
				//he got middle
				oppCounter = oppCounter + 1;
			end

			if(takenByX(board[8]))begin
				//ok i got bottom left
				counter = counter + 1;
			end else if (takenByO(board[8]))begin
				//he got bottom left
				oppCounter = oppCounter + 1;
			end

			if (counter == 3 || oppCounter == 3) begin
				canIWinThirdRow = `EXIT_CODE; //somebody has 3 in a row
			end else if (counter !=0 && oppCounter != 0) begin
				canIWinThirdRow = `CONTESTED; //no way to win here. He owns at least one tile and so do I
			end else if (counter == 2 && oppCounter == 0) begin
				canIWinThirdRow = `FORTHEWIN; //I'm about to win
			end else if (counter ==0 && oppCounter ==2) begin
				canIWinThirdRow = `BLOCK; //hes about to win make this my priority
			end else begin
				canIWinThirdRow = counter; //will return how close I am to winning diagonally left
			end
		end
	endfunction


	/**
	 * Method that checks if the computer can win vertically on the first column if not ranks how close or garbage
	 */
	function integer canIWinFirstColumn(input aaronCarpenterHaveMyBabies);

		begin
			integer counter =0;
			integer oppCounter = 0;

			if (takenByX(board[0]))begin
				//ok I got the top left corner
				counter = counter + 1;
			end else if (takenByO(board[0]))begin
				//he got top left
				oppCounter = oppCounter + 1;
			end

			if(takenByX(board[3]))begin
				//k i got the middle left
				counter = counter + 1;
			end else if (takenByO(board[3]))begin
				//he got middle left
				oppCounter = oppCounter + 1;
			end

			if(takenByX(board[6]))begin
				//ok i got bottom left
				counter = counter + 1;
			end else if (takenByO(board[6]))begin
				//he got bottom left
				oppCounter = oppCounter + 1;
			end

			if (counter == 3 || oppCounter == 3) begin
				canIWinFirstColumn = `EXIT_CODE; //somebody has 3 in a row
			end else if (counter !=0 && oppCounter != 0) begin
				canIWinFirstColumn = `CONTESTED; //no way to win here. He owns at least one tile and so do I
			end else if (counter == 2 && oppCounter == 0) begin
				canIWinFirstColumn = `FORTHEWIN; //I'm about to win
			end else if (counter ==0 && oppCounter ==2) begin
				canIWinFirstColumn = `BLOCK; //hes about to win make this my priority
			end else begin
				canIWinFirstColumn = counter; //will return how close I am to winning diagonally left
			end
		end
	endfunction


	/**
	 * Method that checks if the computer can win vertically on the second column if not ranks how close or garbage
	 */
	function integer canIWinSecondColumn(input aaronCarpenterIsTheSunshineOfMyLife);

		begin
			integer counter =0;
			integer oppCounter = 0;

			if (takenByX(board[1]))begin
				//ok I got the top middle
				counter = counter + 1;
			end else if (takenByO(board[1]))begin
				//he got top middle
				oppCounter = oppCounter + 1;
			end

			if(takenByX(board[4]))begin
				//k i got the center
				counter = counter + 1;
			end else if (takenByO(board[4]))begin
				//he got center
				oppCounter = oppCounter + 1;
			end

			if(takenByX(board[7]))begin
				//ok i got bottom middle
				counter = counter + 1;
			end else if (takenByO(board[7]))begin
				//he got bottom middle
				oppCounter = oppCounter + 1;
			end

			if (counter == 3 || oppCounter == 3) begin
				canIWinSecondColumn = `EXIT_CODE; //somebody has 3 in a row
			end else if (counter !=0 && oppCounter != 0) begin
				canIWinSecondColumn = `CONTESTED; //no way to win here. He owns at least one tile and so do I
			end else if (counter == 2 && oppCounter == 0) begin
				canIWinSecondColumn = `FORTHEWIN;
			end else if (counter ==0 && oppCounter ==2) begin
				canIWinSecondColumn = `BLOCK; //hes about to win make this my priority
			end else begin
				canIWinSecondColumn = counter; //will return how close I am to winning diagonally left
			end
		end
	endfunction

	/**
	 * Method that checks if the computer can win vertically on the third column if not ranks how close or garbage
	 */
	function integer canIWinThirdColumn(input aaronCarpenterIsTheGuyWhoPaysForWinrar;

		begin
			integer counter =0;
			integer oppCounter = 0;

			if (takenByX(board[2]))begin
				//ok I got the top right
				counter = counter + 1;
			end else if (takenByO(board[2]))begin
				//he got top right
				oppCounter = oppCounter + 1;
			end

			if(takenByX(board[5]))begin
				//k i got the center
				counter = counter + 1;
			end else if (takenByO(board[5]))begin
				//he got center
				oppCounter = oppCounter + 1;
			end

			if(takenByX(board[7]))begin
				//ok i got bottom middle
				counter = counter + 1;
			end else if (takenByO(board[7]))begin
				//he got bottom middle
				oppCounter = oppCounter + 1;
			end

			if (counter == 3 || oppCounter == 3) begin
				canIWinThirdRow = `EXIT_CODE; //somebody has 3 in a row
			end else if (counter !=0 && oppCounter != 0) begin
				canIWinThirdRow = `CONTESTED; //no way to win here. He owns at least one tile and so do I
			end else if (counter == 2 && oppCounter == 0) begin
				canIWinThirdRow = `FORTHEWIN;
			end else if (counter ==0 && oppCounter ==2) begin
				canIWinThirdRow = `BLOCK; //hes about to win make this my priority
			end else begin
				canIWinThirdRow = counter; //will return how close I am to winning diagonally left
			end

			end //IDK WHAT THE FUCK IS GOING ON WITH THE BRACKETS ITS FUCKED
		end

	endfunction

	/**
	  * Returns a 1 if its taken by an X, 0 otherwise
	  */
	function real takenByX(integer specificSpot);
		begin
			if (specificSpot == `X)begin
				takenByX = 1;
			end else begin
				takenByX = 0;
			end
		end
	endfunction

	/**
	  * Returns a 1 if its taken by an O, 0 otherwise
	  */
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
	function real isEmpty(integer specificSpot);
		begin
			if (specificSpot == `EMPTY) begin
				isEmpty = 1;
			end else begin
				isEmpty = 0;
			end
		end
	endfunction

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
