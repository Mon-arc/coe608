module lab1 (
	input x1, x2,
	output f );

	assign f = (x1 & ~x2) | (~x1 & x2);

endmodule

/*
LIBRARY ieee ;
USE ieee.std_logic_1164.all ;
ENTITY lab1 IS
	PORT ( x1, x2 : IN STD_LOGIC ;
			 f		  :OUT STD_LOGIC );
END lab1;
ARCHITECTURE LogicFunction OF lab1 IS
BEGIN

	f <= (x1 AND NOT x2) OR (NOT x1 AND x2);
END LogicFunction ;
*/