-- This is the top-level block of the project.
--
-- It connects the board inputs and outputs to the internal blocks:
--   1. control_unit
--   2. classifier
--   3. output_interface
--
-- Board inputs:
--   CLK   : clock from FPGA board
--   RESET : reset button
--   START : start button
--   SW    : four switches used as input features
--
-- Board outputs:
--   CLASS_LED : class result LED
--   SEG       : seven-segment cathodes
--   AN        : seven-segment anodes


entity top_level is
    port (
        CLK       : in  bit;
        RESET     : in  bit;
        START     : in  bit;
        SW        : in  bit_vector(3 downto 0);

        CLASS_LED : out bit;
        SEG       : out bit_vector(6 downto 0);
        AN        : out bit_vector(7 downto 0)
    );
end entity;

architecture structural of top_level is

    -- Control unit component.
    component control_unit
        port (
            clk         : in  bit;
            reset       : in  bit;
            start       : in  bit;
            load_inputs : out bit;
            compute_mac : out bit;
            done        : out bit
        );
    end component;

    -- Classifier component.
    component classifier
        port (
            clk          : in  bit;
            reset        : in  bit;
            SW           : in  bit_vector(3 downto 0);
            load_inputs  : in  bit;
            compute_mac  : in  bit;

            z            : out integer range -128 to 127;
            class_result : out bit
        );
    end component;

    -- Output interface component.
    component output_interface
        port (
            clk          : in  bit;
            reset        : in  bit;
            done         : in  bit;
            z            : in  integer range -128 to 127;
            class_result : in  bit;

            class_led    : out bit;
            SEG          : out bit_vector(6 downto 0);
            AN           : out bit_vector(7 downto 0)
        );
    end component;

    -- Internal control signals.
    signal load_inputs_int : bit;
    signal compute_mac_int : bit;
    signal done_int        : bit;

    -- Internal classifier result signals.
    signal z_int            : integer range -128 to 127;
    signal class_result_int : bit;

begin

    -- Control unit block creates the sequence:
    --   IDLE -> LOAD -> MAC -> DONE_STATE -> IDLE
    CU1: control_unit
        port map (
            clk         => CLK,
            reset       => RESET,
            start       => START,
            load_inputs => load_inputs_int,
            compute_mac => compute_mac_int,
            done        => done_int
        );

    -- Classifier block stores the switch inputs, computes the weighted sum,
    -- and creates the class result.
    CLASS1: classifier
        port map (
            clk          => CLK,
            reset        => RESET,
            SW           => SW,
            load_inputs  => load_inputs_int,
            compute_mac  => compute_mac_int,
            z            => z_int,
            class_result => class_result_int
        );

    -- Output interface block sends the class result to an LED and the score to
    -- the seven-segment display.
    OUT1: output_interface
        port map (
            clk          => CLK,
            reset        => RESET,
            done         => done_int,
            z            => z_int,
            class_result => class_result_int,
            class_led    => CLASS_LED,
            SEG          => SEG,
            AN           => AN
        );

end architecture;
