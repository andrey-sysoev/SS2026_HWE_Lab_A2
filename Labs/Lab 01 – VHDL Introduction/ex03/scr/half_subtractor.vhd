entity HalfSubstractor is
	port( A,B: in bit;
	      Bor,D: out bit);
	end entity;

architecture Data of HalfSubstractor is
	begin
	 D <= A xor B;
	 Bor <= (not A) and B;
	end architecture;
