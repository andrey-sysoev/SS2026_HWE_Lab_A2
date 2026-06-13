entity clock_divider_tb is
end entity;

architecture bench of clock_divider_tb is

    component clock_divider
        port (
            CLK   : in bit;
            CLK_N : out bit
        );
    end component;

    signal CLK_TB   : bit := '0';
    signal CLK_N_TB : bit;

begin
    DUT1: clock_divider
        port map (
            CLK   => CLK_TB,
            CLK_N => CLK_N_TB
        );

    clock_process: process
    begin
        CLK_TB <= '0';
        wait for 20 ns;

        CLK_TB <= '1';
        wait for 20 ns;
    end process;

    -- Simulation time
    stimulus: process
    begin
        wait for 300 ns;
        wait;
    end process;

end architecture;
