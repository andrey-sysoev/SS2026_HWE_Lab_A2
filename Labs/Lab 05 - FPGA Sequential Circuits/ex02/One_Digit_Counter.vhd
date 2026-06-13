entity One_Digit_Counter is
    port (
        CLK        : in bit;
        START_STOP : in bit;
        CLEAR      : in bit;
        SEG        : out bit_vector(6 downto 0);
        AN         : out bit_vector(7 downto 0)
    );
end entity;

architecture behavior of One_Digit_Counter is
    component clock_divider
        port (
            CLK   : in bit;
            CLK_N : out bit
        );
    end component;

    signal slowed_clk : bit;
    signal count    : integer range 0 to 9 := 0;

begin
    CD1: clock_divider
        port map (
            CLK   => CLK,
            CLK_N => slowed_clk
        );

    Counter_Process: process(slowed_clk, CLEAR)
    begin
        if CLEAR = '1' then
            count <= 0;

        elsif slowed_clk'event and slowed_clk = '1' then

            if START_STOP = '1' then

                if count = 9 then
                    count <= 0;
                else
                    count <= count + 1;
                end if;

            end if;

        end if;
    end process;

    with count select
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
 -- !!!! Enable only the rightmost 7-segment display
    AN <= "11111110";

end architecture;
