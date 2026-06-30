-- This block implements the classifier block.
--
-- It contains following blocks:
--   1. Input Interface  : stores SW(3 downto 0) into internal signal x
--   2. ROM Weights      : fixed constants W0, W1, W2, W3, and B
--   3. MAC / Dot Product: calculates z = W0*x0 + W1*x1 + W2*x2 + W3*x3 + B
--   4. Activation Unit  : outputs class_result = '1' when z >= 0, else '0'


entity classifier is
    port (
        -- Clock input from the FPGA board.
        -- The classifier updates only on the rising edge of this clock.
        clk          : in  bit;

        -- Reset input.
        -- When reset = '1', stored inputs, score, and class output are cleared immediately.
        reset        : in  bit;

        -- 4-bit input vector from FPGA switches.
        -- SW(0) is x0, SW(1) is x1, SW(2) is x2, SW(3) is x3.
        SW           : in  bit_vector(3 downto 0);

        -- Control signal from the control unit.
        -- When load_inputs = '1', the current switch values are stored into x.
        load_inputs  : in  bit;

        -- Control signal from the control unit.
        -- When compute_mac = '1', the MAC score and class result are calculated.
        compute_mac  : in  bit;

        -- Output score of the classifier.
        -- Range is chosen large enough for the example weights below.
        z            : out integer range -128 to 127;

        -- Final classification result.
        -- '1' means class 1, '0' means class 0.
        class_result : out bit
    );
end entity classifier;

architecture behavior of classifier is

    -- Internal input register.
    -- This stores the switch values after load_inputs is activated.
    -- Using a register means the classifier works with a stable copy of SW.
    signal x : bit_vector(3 downto 0);

    -- Internal score register.
    -- The output port z is connected to this signal at the end of the architecture.
    signal z_reg : integer range -128 to 127;

    -- Fixed weights and bias used during inference 
    -- (ROM predefined constants)
    constant W0 : integer := 3;
    constant W1 : integer := -2;
    constant W2 : integer := 5;
    constant W3 : integer := -1;
    constant B  : integer := -4;

begin

    -- This process contains the input interface, MAC calculation,
    -- and activation unit.
    process(clk, reset)

        -- Local variables used only inside this process.
        variable sum : integer range -128 to 127;
        variable x0_i : integer range 0 to 1;
        variable x1_i : integer range 0 to 1;
        variable x2_i : integer range 0 to 1;
        variable x3_i : integer range 0 to 1;

    begin
        -- Asynchronous reset has priority over normal operation.
        if reset = '1' then

            -- Clear stored input features.
            x <= "0000";

            -- Clear stored score.
            z_reg <= 0;

            -- Clear class output.
            class_result <= '0';

        -- Rising edge clock detection using the built-in bit type.
        elsif clk'event and clk = '1' then

            -- Input Interface:
            -- Store the current switch values when the control unit requests it.
            if load_inputs = '1' then
                x <= SW;
            end if;

            -- MAC / Dot Product:
            -- Calculate the MAC score only when the control unit requests it.
            if compute_mac = '1' then

                if x(0) = '1' then
                    x0_i := 1;
                else
                    x0_i := 0;
                end if;

                if x(1) = '1' then
                    x1_i := 1;
                else
                    x1_i := 0;
                end if;

                if x(2) = '1' then
                    x2_i := 1;
                else
                    x2_i := 0;
                end if;

                if x(3) = '1' then
                    x3_i := 1;
                else
                    x3_i := 0;
                end if;

                -- z = W*x + B
                sum := B
                       + W0 * x0_i
                       + W1 * x1_i
                       + W2 * x2_i
                       + W3 * x3_i;

                -- Store the final score into the score register.
                z_reg <= sum;

                -- Activation Unit:
                -- Convert the numeric score into class 0 or class 1.
                if sum >= 0 then
                    class_result <= '1';
                else
                    class_result <= '0';
                end if;

            end if;

        end if;
    end process;

    -- Connect the internal score register to the output port.
    z <= z_reg;

end architecture behavior;
