entity HalfSubstractor_TB is
	end entity;

architecture bench of HalfSubstractor_TB is	
	component HalfSubstractor
	port( A,B: in bit;
	      Bor,D: out bit);
	end component;
--declare signals	
	signal A_TB, B_TB: bit;
	signal Bor_TB, D_TB: bit;

begin
DUT1: HalfSubstractor
port map(
	A => A_TB,
	B => B_TB,
	Bor => Bor_TB,
	D => D_TB);


    stimulus: process
    begin

        -- Test 1: A = 0, B = 0
        A_TB <= '0';
        B_TB <= '0';
        wait for 10 ns;

        -- Test 2: A = 0, B = 1
        A_TB <= '0';
        B_TB <= '1';
        wait for 10 ns;

        -- Test 3: A = 1, B = 0
        A_TB <= '1';
        B_TB <= '0';
        wait for 10 ns;

        -- Test 4: A = 1, B = 1
        A_TB <= '1';
        B_TB <= '1';
        wait for 10 ns;

        wait;

    end process;

end architecture;
