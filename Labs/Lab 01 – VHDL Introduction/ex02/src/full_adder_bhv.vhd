entity FullAdder is
	port(A,B,Cin: in bit;
	     S,C: out bit);
	end entity;

architecture Data of FullAdder is
	begin
	S <= (A xor B) xor Cin;
	C <= ((A xor B) and Cin) or (A and B);
   
end architecture;
