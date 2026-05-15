entity FullSubstractor_TB is
	end entity;

architecture bench of FullSubstractor_TB is	
	component FullSubstractor
	port( A,B,Bin: in bit;
	      Bor,D: out bit);
	end component;
--declare signals	
	signal A_TB, B_TB, Bin_TB: bit;
	signal Bor_TB, D_TB: bit;

begin
DUT1: FullSubstractor
port map(
	A => A_TB,
	B => B_TB,
	Bin => Bin_TB,
	Bor => Bor_TB,
	D => D_TB);


    stimulus: process
	begin
        -- Test 1: A=0, B=0, Bin=0
        A_TB <= '0';
        B_TB <= '0';
        Bin_TB <= '0';
        wait for 10 ns;

        -- Test 2: A=0, B=0, Bin=1
        A_TB <= '0';
        B_TB <= '0';
        Bin_TB <= '1';
        wait for 10 ns;

        -- Test 3: A=0, B=1, Bin=0
        A_TB <= '0';
        B_TB <= '1';
        Bin_TB <= '0';
        wait for 10 ns;

        -- Test 4: A=0, B=1, Bin=1
        A_TB <= '0';
        B_TB <= '1';
        Bin_TB <= '1';
        wait for 10 ns;

        -- Test 5: A=1, B=0, Bin=0
        A_TB <= '1';
        B_TB <= '0';
        Bin_TB <= '0';
        wait for 10 ns;

        -- Test 6: A=1, B=0, Bin=1
        A_TB <= '1';
        B_TB <= '0';
        Bin_TB <= '1';
        wait for 10 ns;

        -- Test 7: A=1, B=1, Bin=0
        A_TB <= '1';
        B_TB <= '1';
        Bin_TB <= '0';
        wait for 10 ns;

        -- Test 8: A=1, B=1, Bin=1
        A_TB <= '1';
        B_TB <= '1';
        Bin_TB <= '1';
        wait for 10 ns;

        wait;

    end process;

end architecture;
