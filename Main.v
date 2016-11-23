`define EXITCODE = 999
`define CONTESTED = -2
`define FORTHEWIN = 666
`define BLOCK = 3

module top;

	wire [7:0]result;
	wire overflow;
	integer board [8:0]; //a 9 element array storing all slots on the board

	//Here is what the board will look like
	//  0    1    2
	//  3    4    5
	//  6    7    8
	

	initial begin
		//So basically this is our print. TODO
		$monitor("input1: ", input1, "\t input2: ",input2,"\t opcode: ",opcode,"\t overflow: ",overflow,"\t result: ",result);
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
		begin
			//outer loop is for every single spot
			for (integer box =0; box < 9; box++)begin
				//inner loop is for every bit in the spot
				board[box] = 0; //set everything to 0	
			end
		end
	endtask

	/**
 	  * Says its full unless I find an instance where its not
	  */
	function integer isBoardFull(input [1:0] in);
		begin
			integer isBoardFull = 1; //its full unless I say otherwise
			//outer loop is for every single spot
			for (integer box =0; box < 9; box ++) begin
				//inner loop is for every bit in the spot
				if (board[box][0] == 0 )begin
					//something is empty
					isBoardFull = 0; //it is not full
				end
			end
		end
	endfunction


	/**
	  * Ok so my outputs here are going to be -2 if its garbage
	  * TODO
 	  */
	function integer canIWinDiagonallyLeft(input [1:0] aaronCarpenterSucksEggs);
		begin
		integer counter =0;
		integer oppCounter = 0;
	
		if (takenByX(board[0]))begin
			//ok I got the top left corner
			counter = counter + 1;
		else if (takenByO(board[0]))begin
			//he got top left
			oppCounter = oppCounter + 1;
		end
		if(takenByX(board[4]))begin
			//k i got the middle
			counter = counter + 1;
		else if (takenByO(board[4]))begin
			//he got middle
			oppCounter = oppCounter + 1;
		end
		if(takenByX(board[8]))begin
			//ok i got bottom right
			counter = counter + 1;
		else if (takenByO(board[8]))begin
			//he got bottom right
			oppCounter = oppCounter + 1;
		end
		
		if (counter == 3 || oppCounter == 3) begin
			canIWinDiagonallyLeft = EXIT_CODE; //somebody has 3 in a row
		else if (counter !=0 && oppCounter != 0) begin
			canIWinDiagonallyLeft = CONTESTED; //no way to win here. He owns at least one tile and so do I
		else if (counter == 2 && oppCounter == 0) begin
			canIWinDiagonallyLeft = FORTHEWIN;
		else if (counter ==0 && oppCounter ==2) begin
			canIWinDiagonallyLeft = BLOCK; //hes about to win make this my priority
		else begin
			canIWinDiagonallyLeft = counter; //will return how close I am to winning diagonally left
		end

	endfunction

/**
	  * Ok so my outputs here are going to be -2 if its garbage
	  * TODO
 	  */
	function integer canIWinDiagonallyRight(input [1:0] aaronCarpenterSucksEggs);
		begin
		integer counter =0;
		integer oppCounter = 0;
	
		if (takenByX(board[2]))begin
			//ok I got the top right corner
			counter = counter + 1;
		else if (takenByO(board[2]))begin
			//he got top right
			oppCounter = oppCounter + 1;
		end
		if(takenByX(board[4]))begin
			//k i got the middle
			counter = counter + 1;
		else if (takenByO(board[4]))begin
			//he got middle
			oppCounter = oppCounter + 1;
		end
		if(takenByX(board[6]))begin
			//ok i got bottom left
			counter = counter + 1;
		else if (takenByO(board[6]))begin
			//he got bottom left
			oppCounter = oppCounter + 1;
		end
		
		if (counter == 3 || oppCounter == 3) begin
			canIWinDiagonallyRight= EXIT_CODE; //somebody has 3 in a row
		else if (counter !=0 && oppCounter != 0) begin
			canIWinDiagonallyRight = CONTESTED; //no way to win here. He owns at least one tile and so do I
		else if (counter == 2 && oppCounter == 0) begin
			canIWinDiagonallyRight = FORTHEWIN;
		else if (counter ==0 && oppCounter ==2) begin
			canIWinDiagonallyRight = BLOCK; //hes about to win make this my priority
		else begin
			canIWinDiagonallyRight = counter; //will return how close I am to winning diagonally left
		end

	endfunction

	/*
	 * Method that checks if either player can win horizontally (about to win)
	 */
	function integer canIWinFirstRow(input tinaPoodInCarpentersBed);
		
			begin
		integer counter =0;
		integer oppCounter = 0;
	
		if (takenByX(board[0]))begin
			//ok I got the top right corner
			counter = counter + 1;
		else if (takenByO(board[0]))begin
			//he got top right
			oppCounter = oppCounter + 1;
		end
		if(takenByX(board[1]))begin
			//k i got the middle
			counter = counter + 1;
		else if (takenByO(board[1]))begin
			//he got middle
			oppCounter = oppCounter + 1;
		end
		if(takenByX(board[2]))begin
			//ok i got bottom left
			counter = counter + 1;
		else if (takenByO(board[2]))begin
			//he got bottom left
			oppCounter = oppCounter + 1;
		end
		
		if (counter == 3 || oppCounter == 3) begin
			canIWinFirstRow = EXIT_CODE; //somebody has 3 in a row
		else if (counter !=0 && oppCounter != 0) begin
			canIWinFirstRow = CONTESTED; //no way to win here. He owns at least one tile and so do I
		else if (counter == 2 && oppCounter == 0) begin
			canIWinFirstRow = FORTHEWIN;
		else if (counter ==0 && oppCounter ==2) begin
			canIWinFirstRow = BLOCK; //hes about to win make this my priority
		else begin
			canIWinFirstRow = counter; //will return how close I am to winning diagonally left
		end
	endfunction

function integer canIWinSecondRow(input tinaPoodInCarpentersBed);
		
			begin
		integer counter =0;
		integer oppCounter = 0;
	
		if (takenByX(board[3]))begin
			//ok I got the top right corner
			counter = counter + 1;
		else if (takenByO(board[3]))begin
			//he got top right
			oppCounter = oppCounter + 1;
		end
		if(takenByX(board[4]))begin
			//k i got the middle
			counter = counter + 1;
		else if (takenByO(board[4]))begin
			//he got middle
			oppCounter = oppCounter + 1;
		end
		if(takenByX(board[5]))begin
			//ok i got bottom left
			counter = counter + 1;
		else if (takenByO(board[5]))begin
			//he got bottom left
			oppCounter = oppCounter + 1;
		end
		
		if (counter == 3 || oppCounter == 3) begin
			canIWinSecondRow = EXIT_CODE; //somebody has 3 in a row
		else if (counter !=0 && oppCounter != 0) begin
			canIWinSecondRow = CONTESTED; //no way to win here. He owns at least one tile and so do I
		else if (counter == 2 && oppCounter == 0) begin
			canIWinSecondRow = FORTHEWIN;
		else if (counter ==0 && oppCounter ==2) begin
			canIWinSecondRow = BLOCK; //hes about to win make this my priority
		else begin
			canIWinSecondRow = counter; //will return how close I am to winning diagonally left
		end
	endfunction
	
function integer canIWinThirdRow(input alexPoodInCarpentersBedbutmostlytina);
		
			begin
		integer counter =0;
		integer oppCounter = 0;
	
		if (takenByX(board[6]))begin
			//ok I got the top right corner
			counter = counter + 1;
		else if (takenByO(board[6]))begin
			//he got top right
			oppCounter = oppCounter + 1;
		end
		if(takenByX(board[7]))begin
			//k i got the middle
			counter = counter + 1;
		else if (takenByO(board[7]))begin
			//he got middle
			oppCounter = oppCounter + 1;
		end
		if(takenByX(board[8]))begin
			//ok i got bottom left
			counter = counter + 1;
		else if (takenByO(board[8]))begin
			//he got bottom left
			oppCounter = oppCounter + 1;
		end
		
		if (counter == 3 || oppCounter == 3) begin
			canIWinThirdRow = EXIT_CODE; //somebody has 3 in a row
		else if (counter !=0 && oppCounter != 0) begin
			canIWinThirdRow = CONTESTED; //no way to win here. He owns at least one tile and so do I
		else if (counter == 2 && oppCounter == 0) begin
			canIWinThirdRow = FORTHEWIN;
		else if (counter ==0 && oppCounter ==2) begin
			canIWinThirdRow = BLOCK; //hes about to win make this my priority
		else begin
			canIWinThirdRow = counter; //will return how close I am to winning diagonally left
		end
	endfunction

	/**
	  * Returns a 1 if its taken by an X, 0 otherwise
	  */
	function integer takenByX(integer specificSpot);
		begin
		if (specificSpot == 2)begin
			takenByX = 1;
		else begin
			takenByX = 0;
		end
	endfunction
	
	/**
	  * Returns a 1 if its taken by an O, 0 otherwise
	  */
	function integer takenByO(integer specificSpot);
		begin
		if (specificSpot == 1) begin
			takenByO = 1;
		else begin
			takenByO = 0;
		end
	endfunction
	
	/**
	  * Returns a 1 if its empty, 0 otherwise
	  */
	function integer isEmpty(integer specificSpot);
		if (specificSpot == 0) begin
			isEmpty = 1;
		else begin
			isEmpty = 0;
		end
	endfunction



	//determine turn
	//check if finished (check if three in row and check if the board is filled)
	//simulate game
	//determine Priority
	//insertCharacter
	//isTakenByX //done
	//isTakenByO done
	//isEmpty done
	//print the board HANDLED BY MONITOR
	//can I win horizontally
	//can i win vertically
	//can i win diagonally left ok
	//can i win diagonally right 
	//init the board CHECK
	//is the board filled CHECK

	/* there is a bug for case X O X
							   - X O
							   O X O
	Solution is to add redundancy. If no prioritiy is assigned find an open spot
	*/ 

endmodule