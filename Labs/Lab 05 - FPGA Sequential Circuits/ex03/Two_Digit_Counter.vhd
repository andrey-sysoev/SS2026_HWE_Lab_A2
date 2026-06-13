entity Two_Digit_Counter is
    port (
        CLK        : in bit;
        START_STOP : in bit;
        CLEAR      : in bit;
        SEG        : out bit_vector(6 downto 0);
        AN         : out bit_vector(7 downto 0)
    );
end entity;

architecture behavior of Two_Digit_Counter is
    component clock_divider
        port (
            CLK   : in bit;
            CLK_N : out bit
        );
    end component;

    signal slowed_clk : bit;
    signal ones       : integer range 0 to 9 := 0;
    signal tens       : integer range 0 to 9 := 0;

    signal display_clk : bit := '0';
    signal display_count : integer range 0 to 50000 := 0;
    signal digit_select : bit := '0';
    signal display_digit : integer range 0 to 9 := 0;

begin
    CD1: clock_divider
        port map (
            CLK   => CLK,
            CLK_N => slowed_clk
        );

    Counter_Process: process(slowed_clk, CLEAR)
    begin
        if CLEAR = '1' then
            ones <= 0;
            tens <= 0;

        elsif slowed_clk'event and slowed_clk = '1' then

            if START_STOP = '1' then

                if ones = 9 then
                    ones <= 0;

                    if tens = 9 then
                        tens <= 0;
                    else
                        tens <= tens + 1;
                    end if;

                else
                    ones <= ones + 1;
                end if;

            end if;

        end if;
    end process;

    Display_Clock_Process: process(CLK)
    begin
        if CLK'event and CLK = '1' then
            if display_count = 50000 then
                display_count <= 0;
                display_clk <= not display_clk;
            else
                display_count <= display_count + 1;
            end if;
        end if;
    end process;

    Display_Process: process(display_clk)
    begin
        if display_clk'event and display_clk = '1' then
            digit_select <= not digit_select;
        end if;
    end process;

    display_digit <= ones when digit_select = '0' else tens;

    with display_digit select
        SEG <= "0000001" when 0, -- 0
               "1001111" when 1, -- 1
               "0010010" when 2, -- 2
               "0000110" when 3, -- 3
               "1001100" when 4, -- 4
               "0100100" when 5, -- 5
               "0100000" when 6, -- 6
               "0001111" when 7, -- 7
               "0000000" when 8, -- 8
               "0000100" when 9, -- 9
               "1111111" when others;

    -- Enable two rightmost 7-segment displays
    AN <= "11111110" when digit_select = '0' else
          "11111101";

end architecture;
