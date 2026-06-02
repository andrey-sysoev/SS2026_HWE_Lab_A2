entity BCDto7seg is
    port (
        SW : in bit_vector(8 downto 0);

        SEG : out bit_vector(6 downto 0);
        AN  : out bit_vector(7 downto 0);

        Cout_LED : out bit
    );
end entity;

architecture Structural of BCDto7seg is

    component BCD_Adder
        port (
            A3, A2, A1, A0 : in bit;
            B3, B2, B1, B0, Ci : in bit;
            S3, S2, S1, S0, Cout : out bit
        );
    end component;

    signal S3_int, S2_int, S1_int, S0_int : bit;
    signal Cout_int : bit;
    signal BCD : bit_vector(3 downto 0);

begin

    -- BCD Adder segment
    ADD1: BCD_Adder
        port map (
            A0 => SW(0),
            A1 => SW(1),
            A2 => SW(2),
            A3 => SW(3),

            B0 => SW(4),
            B1 => SW(5),
            B2 => SW(6),
            B3 => SW(7),

            Ci => SW(8),

            S0 => S0_int,
            S1 => S1_int,
            S2 => S2_int,
            S3 => S3_int,

            Cout => Cout_int
        );

    -- Combine BCD adder result into one 4-bit signal
    BCD <= S3_int & S2_int & S1_int & S0_int;

    -- Nexys A7 7-segment display
    -- SEG(6) = A
    -- SEG(5) = B
    -- SEG(4) = C
    -- SEG(3) = D
    -- SEG(2) = E
    -- SEG(1) = F
    -- SEG(0) = G

    with BCD select
        SEG <= "0000001" when "0000", -- 0
               "1001111" when "0001", -- 1
               "0010010" when "0010", -- 2
               "0000110" when "0011", -- 3
               "1001100" when "0100", -- 4
               "0100100" when "0101", -- 5
               "0100000" when "0110", -- 6
               "0001111" when "0111", -- 7
               "0000000" when "1000", -- 8
               "0000100" when "1001", -- 9
               "1111111" when others;

    -- !!!! Enable only the rightmost 7-segment display
    AN <= "11111110";

    -- Carry
    Cout_LED <= Cout_int;

end architecture;
