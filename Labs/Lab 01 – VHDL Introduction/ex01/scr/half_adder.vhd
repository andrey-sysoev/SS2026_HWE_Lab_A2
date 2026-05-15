entity HalfAdder is
	port( A,B: in bit;
	      S,C: out bit);
	end entity;

architecture Data of HalfAdder is
	begin
	 S <= A xor B;
	 C <= A and B;
	end architecture;
