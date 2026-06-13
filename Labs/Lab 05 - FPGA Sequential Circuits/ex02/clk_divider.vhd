entity clock_divider is
      port( 
	   CLK : in bit;
	   CLK_N: out bit);
end entity;

architecture behavior of clock_divider is
	signal clk_reg : bit := '0'; 
	constant N     : integer := 100000000; -- use only positive even numbers N=2,4,6,8 etc...
	signal counter : integer range 0 to (N / 2) - 1 := 0; -- counter counts from 0 to (N/2)-1
begin
	Clock_Divider : process(CLK)
	begin
	if CLK'event and CLK = '1' then -- on each rising clock edge
	        if counter = (N / 2) - 1 then   -- when counter reaches max value
	            counter <= 0;               -- reset counter
	            clk_reg <= not clk_reg;
	        else
	            counter <= counter + 1;     -- continue counting
	        end if;
	    end if;
end process;

CLK_N <=clk_reg;

end architecture;
