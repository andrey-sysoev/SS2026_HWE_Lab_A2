entity FullAdder_TB is
	end entity;

architecture bench of FullAdder_TB is
	component FullAdder
	port(A,B,Cin: in bit;
	     S,C: out bit);
	end component;
--declare signals
	signal A_TB, B_TB, Cin_TB: bit;
	signal S_TB, C_TB: bit;
begin
DUT1: FullAdder
port map(
	A => A_TB,
	B => B_TB,
	Cin => Cin_TB,
	C => C_TB,
	S => S_TB);

stimulus: process
    begin

        -- Test 1:A=0 B=0 Cin=0
        A_TB <= '0';
        B_TB <= '0';
        Cin_TB <= '0';
        wait for 10 ns;
 
        -- Test 2:A=0 B=0 Cin=1
        A_TB <= '0';
        B_TB <= '0';
        Cin_TB <= '1';
        wait for 10 ns;

        -- Test 3:A=0 B=1 Cin=0
        A_TB <= '0';
        B_TB <= '1';
        Cin_TB <= '0';
        wait for 10 ns;

        -- Test 4:A=0 B=1 Cin=1
        A_TB <= '0';
        B_TB <= '1';
        Cin_TB <= '1';
        wait for 10 ns;

        -- Test 5:A=1 B=0 Cin=0
        A_TB <= '1';
        B_TB <= '0';
        Cin_TB <= '0';
        wait for 10 ns;

        -- Test 6:A=1 B=0 Cin=1
        A_TB <= '1';
        B_TB <= '0';
        Cin_TB <= '1';
        wait for 10 ns;

        -- Test 7:A=1 B=1 Cin=0
        A_TB <= '1';
        B_TB <= '1';
        Cin_TB <= '0';
        wait for 10 ns;

        -- Test 8:A=1 B=1 Cin=1
        A_TB <= '1';
        B_TB <= '1';
        Cin_TB <= '1';
        wait for 10 ns;
   
	wait;

	end process;

end architecture;
