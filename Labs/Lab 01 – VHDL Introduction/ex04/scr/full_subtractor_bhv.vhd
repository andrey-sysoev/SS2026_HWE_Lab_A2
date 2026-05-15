entity FullSubstractor is
	port( A,B,Bin: in bit;
	      Bor,D: out bit);
	end entity;

architecture Data of FullSubstractor is
	begin
	 D <= A xor B;
	 Bor <= ((not A) and B) or ((not (A xor B)) and Bin);
	end architecture;
