module top;

	wire [7:0]result;
	wire overflow;
	integer board [8:0]; //a 9 element array storing all slots on the board

	//Here is what the board will look like
	//  0    1    2
	//  3    4    5
	//  6    7    8


	initial begin
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
			for (integer box =0; box < 9; box++){
				//inner loop is for every bit in the spot
				board[box] = 0; //set everything to 0	
			}
		end
	endtask

	function integer isBoardFull(input [1:0] in);
		begin
			integer isBoardFull = 1; //its full unless I say otherwise
			//outer loop is for every single spot
			for (integer box =0; box < 9; box ++){
				//inner loop is for every bit in the spot
				if (board[box][0] == 0 ){
					//something is empty
					isBoardFull = 0; //it is not full
				}
			}
		end
	endfunction


	/**
	  * Ok so my outputs here are going to be -1 if its garbage
	  * returning 
	  *   pls fix logic
 	  */
	function integer canIWinDiagonallyLeft(input [1:0] aaronCarpenterSucksEggs);
		begin
		integer counter =0;
		integer oppCounter = 0;
		integer flag = 0;
	
		if (takenByX(board[0])){
			//ok I got the top left corner
			counter++;
		}else if (takenByO(board[0])){
			flag = 1;
			oppCounter++;
		}
		if(takenByX(board[4])){
			//k i got the middle
			counter++;
		}else if (takenByO(board[4])){
			flag = 1;
			oppCounter++;
		}
		if(takenByX(board[8])){
			//ok i got bottom right
			counter++;
		}else if (takenByO(board[8])){
			flag = 1;
			oppCounter++;
		}
		
		if (counter == 3 || oppCounter == 3){
			canIWinDiagonallyLeft EXIT_CODE; //somebody has 3 in a row
		}else if (counter !=0 && flag){
			canIWinDiagonallyLeft = CONTESTED; //no way to win here. He owns at least one tile and so do I
		}else if (counter ==0 && oppCounter ==2) {
			canIWinDiagonallyLeft= oppCounter; //hes about to win make this my priority
		}else {
			canIWinDiagonallyLeft = counter; //will return how close I am to winning diagonally left
		}
		end
	endfunction

	/**
	  * Returns a 1 if its taken by an X, 0 otherwise
	  */
	integer takenByX(integer specificSpot){
		if (specificSpot == 2){
			takenByX = 1;
		}else {
			takenByX = 0;
		}
	}
	
	/**
	  * Returns a 1 if its taken by an O, 0 otherwise
	  */
	integer takenByO(integer specificSpot){
		if (specificSpot == 1){
			takenByO = 1;
		}else{
			takenByO = 0;
		}
	}
	
	/**
	  * Returns a 1 if its empty, 0 otherwise
	  */
	integer isEmpty(integer specificSpot){
		if (specificSpot == 0){
			isEmpty = 1;
		}else{
			isEmpty = 0;
		}
	}



	//determine turn
	//check if finished (check if three in row and check if the board is filled)
	//simulate game
	//determine Priority
	//insertCharacter
	//isTakenByX //done
	//isTakenByO done
	//isEmpty done
	//print the board
	//can I win horizontally
	//can i win vertically
	//can i win diagonally left
	//can i win diagonally right
	//init the board CHECK
	//is the board filled CHECK

endmodule
