entity BCDto7seg_TB is
end entity;

architecture bench of BCDto7seg_TB is

    component BCDto7seg
        port (
            SW : in bit_vector(8 downto 0);

            SEG : out bit_vector(6 downto 0);
            AN  : out bit_vector(7 downto 0);

            Cout_LED : out bit
        );
    end component;

    signal SW_TB       : bit_vector(8 downto 0);
    signal SEG_TB      : bit_vector(6 downto 0);
    signal AN_TB       : bit_vector(7 downto 0);
    signal Cout_LED_TB : bit;

begin

    DUT1: BCDto7seg
        port map (
            SW       => SW_TB,
            SEG      => SEG_TB,
            AN       => AN_TB,
            Cout_LED => Cout_LED_TB
        );

    stimulus: process
    begin

        -- Test 1: A = 0, B = 0, Ci = 0
        -- 0 + 0 = 0
        SW_TB <= "000000000";
        wait for 10 ns;

        -- Test 2: A = 1, B = 2, Ci = 0
        -- 1 + 2 = 3
        SW_TB <= "000100001";
        wait for 10 ns;

        -- Test 3: A = 3, B = 4, Ci = 0
        -- 3 + 4 = 7
        SW_TB <= "001000011";
        wait for 10 ns;

        -- Test 4: A = 5, B = 4, Ci = 0
        -- 5 + 4 = 9
        SW_TB <= "001000101";
        wait for 10 ns;

        -- Test 5: A = 8, B = 4, Ci = 0
        -- 8 + 4 = 12
        --  Cout_LED should be 1
        SW_TB <= "001001000";
        wait for 10 ns;

        -- Test 6: A = 9, B = 9, Ci = 0
        -- 9 + 9 = 18
        --  Cout_LED should be 1
        SW_TB <= "010011001";
        wait for 10 ns;
        wait;

    end process;

end architecture;
